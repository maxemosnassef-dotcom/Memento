import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento/core/error/failures.dart';
import 'package:memento/core/result.dart';
import 'package:memento/domain/entities/memory.dart';
import 'package:memento/domain/repositories/media_ingest_port.dart';
import 'package:memento/domain/repositories/memory_repository.dart';
import 'package:memento/domain/usecases/create_memory.dart';
import 'package:memento/domain/value_objects/distance.dart';
import 'package:memento/domain/value_objects/geo_anchor.dart';
import 'package:memento/domain/value_objects/photo_reference.dart';

class FakeMemoryRepository implements MemoryRepository {
  FakeMemoryRepository();

  final List<Memory> captured = [];

  @override
  Future<Result<Memory>> save(Memory memory) async {
    captured.add(memory);
    return Result.ok(memory);
  }

  @override
  Future<Result<Memory?>> findById(String id) async =>
      Result.err(const NotFoundFailure('unused'));

  @override
  Future<Result<List<Memory>>> findByDateRange(
          DateTime startUtcInclusive, DateTime endUtcExclusive) async =>
      Result.ok(const <Memory>[]);

  @override
  Future<Result<List<Memory>>> findByCalendarDay(
          {required int month, required int day}) async =>
      Result.ok(const <Memory>[]);

  @override
  Future<Result<List<Memory>>> findWithinRadius(
          {required GeoAnchor center, required Distance radius}) async =>
      Result.ok(const <Memory>[]);

  @override
  Future<Result<List<Memory>>> findByTaggedContacts(
          Set<String> contactIds) async =>
      Result.ok(const <Memory>[]);

  @override
  Future<Result<List<Memory>>> findGeoAnchored({required int limit}) async =>
      Result.ok(const <Memory>[]);

  @override
  Future<Result<void>> delete(String id) async => Result.ok(null);
}

class StubMediaIngest implements MediaIngestPort {
  StubMediaIngest({this.failOnCall = -1});

  int calls = 0;
  final int failOnCall;

  @override
  Future<Result<PhotoReference>> ingestPhoto(Uint8List bytes) async {
    calls++;
    if (calls == failOnCall) {
      return Result.err(const CryptoFailure('ingest failed'));
    }
    return Result.ok(PhotoReference.encryptedLocal(
      id: 'photo-$calls',
      sandboxRelativePath: 'media/photo-$calls.mbox',
      checksumSha256: 'sha-$calls',
    ));
  }

  @override
  Future<Result<Uint8List>> readDecrypted(PhotoReference reference) async =>
      Result.err(const CapabilityFailure('unused'));
}

void main() {
  test('CreateMemory ingests photos and persists entity with references',
      () async {
    final repo = FakeMemoryRepository();
    final media = StubMediaIngest();
    var idsIssued = 0;
    final useCase = CreateMemory(repo, media,
        idFactory: () => 'mem-${++idsIssued}');

    final result = await useCase.execute(MemoryDraft(
      title: '  Beach day  ',
      whenLocal: DateTime(2024, 7, 20, 15),
      journalText: ' Salt, sun, sand ',
      anchor: GeoAnchor.of(latitude: 54.3, longitude: 10.1),
      rawPhotos: [Uint8List(4), Uint8List(6)],
      taggedContactIds: {'c1'},
    ));

    expect(media.calls, 2);
    final memory = result.getOrNull()!;
    expect(memory.id, 'mem-1');
    expect(memory.title, 'Beach day');
    expect(memory.journal!.text, 'Salt, sun, sand');
    expect(memory.photos.length, 2);
    expect(
      memory.photos.every((p) => p.kind == PhotoStorageKind.encryptedLocal),
      isTrue,
    );
    expect(memory.anchor!.latitude, 54.3);
    expect(memory.taggedContactIds, {'c1'});
    expect(repo.captured.single.id, 'mem-1');
  });

  test('CreateMemory aborts with failure when a photo cannot be sealed',
      () async {
    final repo = FakeMemoryRepository();
    final media = StubMediaIngest(failOnCall: 2);
    final useCase = CreateMemory(repo, media, idFactory: () => 'mem-x');

    final result = await useCase.execute(MemoryDraft(
      title: 'Trip',
      whenLocal: DateTime(2024, 5, 5),
      rawPhotos: [Uint8List(1), Uint8List(1), Uint8List(1)],
    ));

    expect(result.isErr, isTrue);
    expect(result.failureOrNull(), isA<CryptoFailure>());
    expect(repo.captured, isEmpty);
  });

  test('CreateMemory rejects blank titles without touching storage', () async {
    final repo = FakeMemoryRepository();
    final media = StubMediaIngest();
    final useCase = CreateMemory(repo, media, idFactory: () => 'id');

    final result = await useCase.execute(
      MemoryDraft(title: '   ', whenLocal: DateTime(2024, 5, 5)),
    );

    expect(result.failureOrNull(), isA<ValidationFailure>());
    expect(media.calls, 0);
    expect(repo.captured, isEmpty);
  });
}

import 'dart:typed_data';

import '../../core/error/failures.dart';
import '../../core/result.dart';
import '../../core/use_case.dart';
import '../entities/memory.dart';
import '../repositories/media_ingest_port.dart';
import '../repositories/memory_repository.dart';
import '../value_objects/geo_anchor.dart';
import '../value_objects/journal_entry.dart';
import '../value_objects/photo_reference.dart';

class MemoryDraft {
  final String title;
  final DateTime whenLocal;
  final String? journalText;
  final GeoAnchor? anchor;
  final List<Uint8List> rawPhotos;
  final Set<String> taggedContactIds;

  const MemoryDraft({
    required this.title,
    required this.whenLocal,
    this.journalText,
    this.anchor,
    this.rawPhotos = const [],
    this.taggedContactIds = const {},
  });
}

class CreateMemory extends UseCase<Memory, MemoryDraft> {
  final MemoryRepository _memories;
  final MediaIngestPort _media;
  final String Function() _idFactory;

  const CreateMemory(
    this._memories,
    this._media, {
    required String Function() idFactory,
  }) : _idFactory = idFactory;

  @override
  Future<Result<Memory>> execute(MemoryDraft input) async {
    final title = input.title.trim();
    if (title.isEmpty) {
      return Result.err(const ValidationFailure('A memory needs a title'));
    }

    final photoReferences = <PhotoReference>[];
    for (final bytes in input.rawPhotos) {
      final ingestResult = await _media.ingestPhoto(bytes);
      final failure = ingestResult.failureOrNull();
      if (failure != null) return Result.err(failure);
      photoReferences.add(ingestResult.getOrNull()!);
    }

    JournalEntry? journal;
    final rawJournal = input.journalText?.trim() ?? '';
    if (rawJournal.isNotEmpty) {
      try {
        journal = JournalEntry.of(rawJournal);
      } on ArgumentError catch (e) {
        return Result.err(ValidationFailure('${e.message ?? e.name}'));
      }
    }

    final memory = Memory.create(
      id: _idFactory(),
      title: title,
      whenLocal: input.whenLocal,
      journal: journal,
      anchor: input.anchor,
      photos: photoReferences,
      taggedContactIds: input.taggedContactIds,
    );

    return _memories.save(memory);
  }
}

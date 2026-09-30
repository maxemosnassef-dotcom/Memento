import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/error/mapping.dart';
import '../../core/result.dart';
import '../../domain/repositories/media_ingest_port.dart';
import '../../domain/value_objects/photo_reference.dart';
import 'encrypted_media_store.dart';

class EncryptedMediaIngestor implements MediaIngestPort {
  final EncryptedMediaStore _store;
  final Uuid _uuid;

  EncryptedMediaIngestor(this._store, {Uuid uuid = const Uuid()})
      : _uuid = uuid;

  @override
  Future<Result<PhotoReference>> ingestPhoto(Uint8List bytes) async {
    try {
      if (bytes.isEmpty) {
        return Result.err(const ValidationFailure('Empty photo payload'));
      }
      final meta = await _store.ingest(bytes);
      return Result.ok(PhotoReference.encryptedLocal(
        id: _uuid.v4(),
        sandboxRelativePath: meta.relativePath,
        checksumSha256: meta.sha256,
      ));
    } on AppException catch (e) {
      return Result.err(e.toFailure());
    } catch (e) {
      return Result.err(CryptoFailure('$e'));
    }
  }

  @override
  Future<Result<Uint8List>> readDecrypted(PhotoReference reference) async {
    try {
      switch (reference.kind) {
        case PhotoStorageKind.cloud:
          return Result.err(
            const CapabilityFailure('Cloud media delivery is not provisioned yet'),
          );
        case PhotoStorageKind.encryptedLocal:
          final bytes = await _store.readDecrypted(
            reference.sandboxRelativePath!,
          );
          return Result.ok(bytes);
      }
    } on AppException catch (e) {
      return Result.err(e.toFailure());
    } catch (e) {
      return Result.err(CryptoFailure('$e'));
    }
  }
}

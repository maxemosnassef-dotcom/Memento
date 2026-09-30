import 'dart:typed_data';

import '../../core/result.dart';
import '../value_objects/photo_reference.dart';

abstract interface class MediaIngestPort {
  Future<Result<PhotoReference>> ingestPhoto(Uint8List bytes);

  Future<Result<Uint8List>> readDecrypted(PhotoReference reference);
}

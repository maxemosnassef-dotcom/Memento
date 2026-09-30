import 'dart:typed_data';

import '../../core/result.dart';
import '../../core/use_case.dart';
import '../repositories/media_ingest_port.dart';
import '../value_objects/photo_reference.dart';

class GetPhotoImage extends UseCase<Uint8List, PhotoReference> {
  final MediaIngestPort _media;

  const GetPhotoImage(this._media);

  @override
  Future<Result<Uint8List>> execute(PhotoReference input) =>
      _media.readDecrypted(input);
}

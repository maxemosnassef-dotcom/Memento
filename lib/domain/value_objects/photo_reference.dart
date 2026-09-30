enum PhotoStorageKind { encryptedLocal, cloud }

class PhotoReference {
  final String id;
  final PhotoStorageKind kind;
  final String? sandboxRelativePath;
  final Uri? remoteUrl;
  final String checksumSha256;

  const PhotoReference._(
    this.id,
    this.kind,
    this.sandboxRelativePath,
    this.remoteUrl,
    this.checksumSha256,
  );

  factory PhotoReference.encryptedLocal({
    required String id,
    required String sandboxRelativePath,
    required String checksumSha256,
  }) {
    if (sandboxRelativePath.isEmpty) {
      throw ArgumentError('sandboxRelativePath must not be empty');
    }
    if (sandboxRelativePath.startsWith('/') ||
        sandboxRelativePath.contains('..')) {
      throw ArgumentError(
        'sandboxRelativePath must be relative and cannot traverse upward',
      );
    }
    return PhotoReference._(id, PhotoStorageKind.encryptedLocal,
        sandboxRelativePath, null, checksumSha256);
  }

  factory PhotoReference.cloud({
    required String id,
    required Uri remoteUrl,
    required String checksumSha256,
  }) {
    if (!remoteUrl.isScheme('HTTPS')) {
      throw ArgumentError('remoteUrl must use HTTPS');
    }
    return PhotoReference._(
        id, PhotoStorageKind.cloud, null, remoteUrl, checksumSha256);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PhotoReference && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PhotoReference($id, ${kind.name}, ${sandboxRelativePath ?? remoteUrl})';
}

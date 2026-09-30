import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/error/exceptions.dart';
import '../security/aes_gcm_crypto_engine.dart';

class EncryptedMediaStore {
  static const String _mediaDirName = 'media';
  static const String _fileExtension = '.mbox';

  final AesGcmCryptoEngine _engine;
  final Uuid _uuid;

  String? _cachedRoot;

  EncryptedMediaStore(this._engine, {Uuid uuid = const Uuid()})
      : _uuid = uuid;

  Future<String> get root async {
    final cached = _cachedRoot;
    if (cached != null) return cached;
    final documents = await getApplicationDocumentsDirectory();
    final rootPath = p.join(documents.path, _mediaDirName);
    await Directory(rootPath).create(recursive: true);
    _cachedRoot = rootPath;
    return rootPath;
  }

  Future<({String relativePath, String sha256, int byteSize})> ingest(
    Uint8List originalBytes,
  ) async {
    final digest = sha256.convert(originalBytes).toString();
    final sealed = await _engine.seal(originalBytes);
    final relativePath = '$_mediaDirName/${_uuid.v4()}$_fileExtension';
    final target = await _resolveInsideSandbox(relativePath);
    await File(target).writeAsBytes(sealed, flush: true);
    return (
      relativePath: relativePath,
      sha256: digest,
      byteSize: sealed.lengthInBytes,
    );
  }

  Future<Uint8List> readDecrypted(String relativePath) async {
    final absolutePath = await _resolveInsideSandbox(relativePath);
    final file = File(absolutePath);
    if (!await file.exists()) {
      throw CacheException('Encrypted media missing: $relativePath');
    }
    final sealed = await file.readAsBytes();
    return _engine.open(sealed);
  }

  Future<void> purge(String relativePath) async {
    final absolutePath = await _resolveInsideSandbox(relativePath);
    final file = File(absolutePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> exists(String relativePath) async {
    final absolutePath = await _resolveInsideSandbox(relativePath);
    return File(absolutePath).exists();
  }

  Future<String> _resolveInsideSandbox(String relativePath) async {
    final sandboxRoot = await root;
    final normalized = p.normalize(p.join(sandboxRoot, relativePath));
    if (!p.isWithin(sandboxRoot, normalized)) {
      throw const SandboxEscapeException('Rejected path outside media sandbox');
    }
    return normalized;
  }

  String fingerprintOf(List<int> bytes) => sha256.convert(bytes).toString();

  String encodePayloadForTransport(Uint8List bytes) => base64.encode(bytes);
}

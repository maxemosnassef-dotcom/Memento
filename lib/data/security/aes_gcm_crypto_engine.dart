import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../core/error/exceptions.dart';
import '../../core/security/key_vault.dart';

class AesGcmCryptoEngine implements CryptoEngine {
  static const int _nonceLength = 12;
  static const int _macLength = 16;

  final AesGcm _algorithm = AesGcm.with256bits();
  final SecretKey _masterKey;

  AesGcmCryptoEngine(this._masterKey);

  @override
  Future<Uint8List> seal(Uint8List clearBytes) async {
    final secretBox = await _algorithm.encrypt(
      clearBytes,
      secretKey: _masterKey,
    );
    return Uint8List.fromList(secretBox.concatenation());
  }

  @override
  Future<Uint8List> open(Uint8List sealedBytes) async {
    if (sealedBytes.length < _nonceLength + _macLength) {
      throw const CryptoException('Sealed payload too short');
    }
    try {
      final box = SecretBox.fromConcatenation(
        sealedBytes,
        nonceLength: _nonceLength,
        macLength: _macLength,
      );
      final clear = await _algorithm.decrypt(box, secretKey: _masterKey);
      return Uint8List.fromList(clear);
    } on SecretBoxAuthenticationError {
      throw const CryptoException('Integrity check failed - tampered payload');
    } catch (e) {
      throw CryptoException('Decryption failed: $e');
    }
  }
}

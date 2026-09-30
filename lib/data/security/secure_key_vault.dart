import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/security/key_vault.dart';

class SecureKeyVault implements KeyVault {
  static const String _dbPassphraseKey = 'memento.db.passphrase.v1';
  static const String _mediaMasterKey = 'memento.media.master.v1';
  static const int _passphraseBytes = 48;
  static const int _mediaKeyBytes = 32;

  final FlutterSecureStorage _storage;

  SecureKeyVault({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.unlocked_this_device,
                synchronizable: false,
              ),
            );

  @override
  Future<String> databasePassphrase() async =>
      _getOrCreateSecret(_dbPassphraseKey, _passphraseBytes);

  @override
  Future<Uint8List> mediaMasterKey() async {
    final base64Key = await _getOrCreateSecret(_mediaMasterKey, _mediaKeyBytes);
    return Uint8List.fromList(base64.decode(base64Key));
  }

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  Future<String> _getOrCreateSecret(String key, int byteLength) async {
    var existing = await _storage.read(key: key);
    if (existing == null || existing.isEmpty) {
      existing = _generateRandomBase64(byteLength);
      await _storage.write(key: key, value: existing);
    }
    return existing;
  }

  String _generateRandomBase64(int byteLength) {
    final random = Random.secure();
    final bytes = List<int>.generate(byteLength, (_) => random.nextInt(256));
    return base64.encode(bytes);
  }
}

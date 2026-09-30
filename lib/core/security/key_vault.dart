import 'dart:typed_data';

abstract interface class KeyVault {
  Future<String> databasePassphrase();

  Future<Uint8List> mediaMasterKey();

  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

abstract interface class CryptoEngine {
  Future<Uint8List> seal(Uint8List clearBytes);

  Future<Uint8List> open(Uint8List sealedBytes);
}

import '../../domain/repositories/alert_throttle.dart';
import '../security/secure_key_vault.dart';

class SecureAlertThrottle implements AlertThrottle {
  static const String _prefix = 'throttle.';

  final SecureKeyVault _vault;

  const SecureAlertThrottle(this._vault);

  @override
  Future<bool> shouldDeliver({
    required String key,
    required Duration muteWindow,
  }) async {
    final storageKey = _prefixed(key);
    final previousRaw = await _vault.read(storageKey);
    final now = DateTime.now().toUtc();

    if (previousRaw != null) {
      final previous = DateTime.tryParse(previousRaw);
      if (previous != null && now.difference(previous) < muteWindow) {
        return false;
      }
    }
    await _vault.write(storageKey, now.toIso8601String());
    return true;
  }

  @override
  Future<void> reset(String key) => _vault.delete(_prefixed(key));

  String _prefixed(String key) =>
      key.startsWith(_prefix) ? key : '$_prefix$key';
}

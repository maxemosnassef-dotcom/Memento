abstract interface class AlertThrottle {
  Future<bool> shouldDeliver({
    required String key,
    required Duration muteWindow,
  });

  Future<void> reset(String key);
}

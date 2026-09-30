import '../../core/result.dart';

class MemoryAlert {
  final String id;
  final String title;
  final String summary;
  final Map<String, String> payload;

  const MemoryAlert({
    required this.id,
    required this.title,
    required this.summary,
    this.payload = const {},
  });
}

abstract interface class NotificationPort {
  Future<bool> isAuthorized();

  Future<bool> requestAuthorization();

  Future<Result<void>> present(MemoryAlert alert);

  Future<Result<void>> dismiss(String alertId);
}

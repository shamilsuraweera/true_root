import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
  });
}

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier() : super(const []);

  void add({required String title, required String message}) {
    final item = AppNotification(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      message: message,
      createdAt: DateTime.now(),
    );
    state = [item, ...state];
  }

  void clear() {
    state = const [];
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  (ref) => NotificationsNotifier(),
);

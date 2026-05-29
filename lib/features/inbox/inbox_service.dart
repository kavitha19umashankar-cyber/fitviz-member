import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyMessages = 'inbox_messages';
const _maxMessages = 50;

/// Static helper called from NotificationService (no Riverpod needed).
Future<void> saveInboxMessageFromFcm({
  required String id,
  required String title,
  required String body,
  String? route,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyMessages);
    List<dynamic> list = [];
    if (raw != null) {
      list = jsonDecode(raw) as List<dynamic>;
    }
    final msg = InboxMessage(
      id: id,
      title: title,
      body: body,
      receivedAt: DateTime.now(),
      route: route,
    );
    list.insert(0, msg.toJson());
    if (list.length > _maxMessages) list = list.sublist(0, _maxMessages);
    await prefs.setString(_keyMessages, jsonEncode(list));
  } catch (_) {}
}

class InboxMessage {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool read;
  final String? route;

  const InboxMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.read = false,
    this.route,
  });

  InboxMessage copyWith({bool? read}) {
    return InboxMessage(
      id: id,
      title: title,
      body: body,
      receivedAt: receivedAt,
      read: read ?? this.read,
      route: route,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'receivedAt': receivedAt.toIso8601String(),
        'read': read,
        'route': route,
      };

  factory InboxMessage.fromJson(Map<String, dynamic> j) => InboxMessage(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        receivedAt: DateTime.parse(j['receivedAt'] as String),
        read: j['read'] as bool? ?? false,
        route: j['route'] as String?,
      );
}

class InboxNotifier extends Notifier<List<InboxMessage>> {
  @override
  List<InboxMessage> build() {
    _load();
    return [];
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyMessages);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => InboxMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    } catch (_) {}
  }

  Future<void> add(InboxMessage msg) async {
    final updated = [msg, ...state].take(_maxMessages).toList();
    state = updated;
    await _persist(updated);
  }

  Future<void> markRead(String id) async {
    final updated = state
        .map((m) => m.id == id ? m.copyWith(read: true) : m)
        .toList();
    state = updated;
    await _persist(updated);
  }

  Future<void> markAllRead() async {
    final updated = state.map((m) => m.copyWith(read: true)).toList();
    state = updated;
    await _persist(updated);
  }

  Future<void> delete(String id) async {
    final updated = state.where((m) => m.id != id).toList();
    state = updated;
    await _persist(updated);
  }

  Future<void> _persist(List<InboxMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyMessages, jsonEncode(messages.map((m) => m.toJson()).toList()));
  }

  int get unreadCount => state.where((m) => !m.read).length;
}

final inboxProvider =
    NotifierProvider<InboxNotifier, List<InboxMessage>>(InboxNotifier.new);

final inboxUnreadCountProvider = Provider<int>((ref) {
  final messages = ref.watch(inboxProvider);
  return messages.where((m) => !m.read).length;
});

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message.dart';

/// Persists the conversation history for each target language.
///
/// History is stored as a JSON list so that reopening the app restores
/// the previous conversation without reloading any model.
class ChatRepository {
  static const _keyPrefix = 'chat_history_';

  Future<List<ChatMessage>> loadMessages(String languageCode) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('$_keyPrefix$languageCode');

    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  Future<void> saveMessages(
    String languageCode,
    List<ChatMessage> messages,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      messages.map((message) => message.toJson()).toList(growable: false),
    );

    await preferences.setString('$_keyPrefix$languageCode', encoded);
  }

  Future<void> clearMessages(String languageCode) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove('$_keyPrefix$languageCode');
  }
}


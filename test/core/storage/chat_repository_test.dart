import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:language_learning_app/core/models/chat_message.dart';
import 'package:language_learning_app/core/models/model_types.dart';
import 'package:language_learning_app/core/storage/chat_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatRepository repository;

  ChatMessage message({
    required String id,
    required MessageRole role,
    required String text,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      text: text,
      createdAt: DateTime.utc(2026, 10, 5, 12, 30),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = ChatRepository();
  });

  group('ChatMessage', () {
    test('round trips through JSON', () {
      final original = message(
        id: 'abc',
        role: MessageRole.assistant,
        text: 'Bonjour !',
      );

      final restored = ChatMessage.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.role, original.role);
      expect(restored.text, original.text);
      expect(restored.createdAt, original.createdAt);
    });

    test('falls back to system role for an unknown role name', () {
      final restored = ChatMessage.fromJson({
        'id': 'abc',
        'role': 'not-a-role',
        'text': 'Hello',
        'createdAt': '2026-10-05T12:30:00.000Z',
      });

      expect(restored.role, MessageRole.system);
    });
  });

  group('ChatRepository', () {
    test('returns an empty history when nothing is stored', () async {
      final messages = await repository.loadMessages('fr');

      expect(messages, isEmpty);
    });

    test('saves and restores messages for a language', () async {
      final messages = [
        message(id: '1', role: MessageRole.user, text: 'Salut'),
        message(id: '2', role: MessageRole.assistant, text: 'Salut !'),
      ];

      await repository.saveMessages('fr', messages);
      final restored = await repository.loadMessages('fr');

      expect(restored, hasLength(2));
      expect(restored.first.text, 'Salut');
      expect(restored.last.role, MessageRole.assistant);
    });

    test('keeps histories separate per language', () async {
      await repository.saveMessages('fr', [
        message(id: '1', role: MessageRole.user, text: 'Salut'),
      ]);
      await repository.saveMessages('es', [
        message(id: '2', role: MessageRole.user, text: 'Hola'),
      ]);

      final french = await repository.loadMessages('fr');
      final spanish = await repository.loadMessages('es');

      expect(french.single.text, 'Salut');
      expect(spanish.single.text, 'Hola');
    });

    test('clears the history for a language', () async {
      await repository.saveMessages('fr', [
        message(id: '1', role: MessageRole.user, text: 'Salut'),
      ]);

      await repository.clearMessages('fr');

      expect(await repository.loadMessages('fr'), isEmpty);
    });

    test('returns an empty history when the stored value is corrupt',
        () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('chat_history_fr', 'not json');

      expect(await repository.loadMessages('fr'), isEmpty);
    });
  });
}
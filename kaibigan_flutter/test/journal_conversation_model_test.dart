import 'package:flutter_test/flutter_test.dart';

import 'package:kaibigan_flutter/features/journaling/journal_model.dart';

void main() {
  test(
      'structured journal turns round-trip through the existing response field',
      () {
    final entry = JournalEntry(
      id: 'entry',
      title: 'Conversation',
      content: 'Chat one\n\nChat two',
      aiResponse: 'Reply one\n\n---\n\nReply two',
      companionId: 'kai',
      createdAt: DateTime(2026, 8, 25),
      conversationTurns: const [
        JournalConversationTurn(
          userText: 'Chat one',
          aiResponse: 'Reply one',
          companionId: 'kai',
        ),
        JournalConversationTurn(
          userText: 'Chat two',
          aiResponse: 'Reply two',
          companionId: 'ann',
        ),
      ],
    );

    final stored = entry.toMap();
    expect(stored['ai_response'], startsWith('__KAIBIGAN_TURNS_V1__'));
    final restored = JournalEntry.fromMap(stored);

    expect(restored.turnsForDisplay, hasLength(2));
    expect(restored.turnsForDisplay[0].userText, 'Chat one');
    expect(restored.turnsForDisplay[0].aiResponse, 'Reply one');
    expect(restored.turnsForDisplay[1].userText, 'Chat two');
    expect(restored.turnsForDisplay[1].aiResponse, 'Reply two');
    expect(restored.turnsForDisplay[1].companionId, 'ann');
    expect(restored.aiResponse, 'Reply one\n\n---\n\nReply two');
  });

  test('legacy records are interleaved when message and reply counts match',
      () {
    final legacy = JournalEntry(
      id: 'legacy',
      title: 'Legacy conversation',
      content: 'Chat one\n\nChat two',
      aiResponse: 'Reply one\n\n---\n\nReply two',
      companionId: 'kai',
      createdAt: DateTime(2026, 8, 25),
    );

    expect(legacy.turnsForDisplay, hasLength(2));
    expect(legacy.turnsForDisplay[0].userText, 'Chat one');
    expect(legacy.turnsForDisplay[0].aiResponse, 'Reply one');
    expect(legacy.turnsForDisplay[1].userText, 'Chat two');
    expect(legacy.turnsForDisplay[1].aiResponse, 'Reply two');
  });

  test('ambiguous legacy paragraphs stay intact instead of guessing', () {
    final legacy = JournalEntry(
      id: 'legacy',
      title: 'One long thought',
      content: 'Paragraph one\n\nParagraph two',
      aiResponse: 'One response',
      companionId: 'kai',
      createdAt: DateTime(2026, 8, 25),
    );

    expect(legacy.turnsForDisplay, hasLength(1));
    expect(legacy.turnsForDisplay.single.userText, legacy.content);
    expect(legacy.turnsForDisplay.single.aiResponse, 'One response');
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:kaibigan_flutter/features/journaling/journal_model.dart';

void main() {
  test('structured journal turns round-trip through their JSON column', () {
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
    expect(stored['ai_response'], 'Reply one\n\n---\n\nReply two');
    expect(stored['conversation_turns'], hasLength(2));
    expect(stored, isNot(contains('reflection_seed_stage')));
    final restored = JournalEntry.fromMap(stored);

    expect(restored.turnsForDisplay, hasLength(2));
    expect(restored.turnsForDisplay[0].userText, 'Chat one');
    expect(restored.turnsForDisplay[0].aiResponse, 'Reply one');
    expect(restored.turnsForDisplay[1].userText, 'Chat two');
    expect(restored.turnsForDisplay[1].aiResponse, 'Reply two');
    expect(restored.turnsForDisplay[1].companionId, 'ann');
    expect(restored.aiResponse, 'Reply one\n\n---\n\nReply two');
  });

  test(
      'encoded legacy conversations remain readable before and after migration',
      () {
    const legacyResponse =
        '__KAIBIGAN_TURNS_V1__[{"user":"Old note","assistant":"Old reply","companion":"kai"}]';
    final legacy = JournalEntry.fromMap({
      'id': 'legacy',
      'ai_response': legacyResponse,
      'conversation_turns': [],
      'reflection_seed_stage': 3,
    });
    expect(legacy.turnsForDisplay.single.userText, 'Old note');
    expect(legacy.aiResponse, 'Old reply');
    final updated = legacy.toMap();
    expect(updated['ai_response'], 'Old reply');
    expect(updated['conversation_turns'], hasLength(1));
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

import '../../core/services/ai_service.dart';
import '../../core/utils/language_helper.dart';
import 'journal_model.dart';

/// Somewhere in the app a feeling can actually be taken, rather than only
/// named. Each value maps to a screen the reflection page can open.
enum JournalFollowUpKind {
  breathing,
  grounding,
  gratitude,
  moodCheckIn,
  sleepLog,
  comfortCorner,
}

/// One suggested next move, with the reason it was chosen.
///
/// The reason matters as much as the suggestion: an unexplained "try
/// breathing" reads as a stock prompt, while "a slower out-breath reaches
/// anxiety faster than analysis does" is a claim the person can accept or
/// reject.
class JournalFollowUp {
  const JournalFollowUp({
    required this.kind,
    required this.title,
    required this.rationale,
  });

  final JournalFollowUpKind kind;
  final String title;
  final String rationale;
}

/// Where this entry sits among the ones before it.
///
/// A single entry read in isolation loses the only thing journalling is
/// unusually good at showing: what keeps coming back.
class JournalContextReading {
  const JournalContextReading({
    required this.wordCount,
    required this.entriesThisWeek,
    required this.recurringEmotions,
    required this.followUps,
    this.daysSinceLastEntry,
    this.continuityNote,
    this.recurrenceNote,
  });

  final int wordCount;
  final int entriesThisWeek;

  /// Emotions in this entry that also appeared in recent earlier entries.
  final List<String> recurringEmotions;

  final List<JournalFollowUp> followUps;

  /// Null when this is the first entry on record.
  final int? daysSinceLastEntry;

  /// The rhythm of writing, in one sentence.
  final String? continuityNote;

  /// What has been repeating, in one sentence. Null when nothing has.
  final String? recurrenceNote;

  bool get hasContext => continuityNote != null || recurrenceNote != null;
}

/// Reads an entry against the ones before it. Arithmetic and stored emotion
/// labels only — no model call, so this works when the network does not.
abstract final class JournalReflectionInsights {
  /// Entries older than this say little about the present.
  static const int recentWindowDays = 30;

  /// How many earlier entries are scanned for a repeated emotion.
  static const int recurrenceSampleSize = 5;

  /// An emotion has to show up in this many of the sampled entries, this one
  /// included, before it is called recurring. Twice is a coincidence.
  static const int recurrenceThreshold = 3;

  static JournalContextReading read({
    required JournalEntry entry,
    required List<JournalEntry> previousEntries,
    required String language,
    AIJournalSaveSummary? summary,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    String pick(String english, String filipino) =>
        LanguageHelper.pick(language, english: english, filipino: filipino);

    final earlier = previousEntries
        .where((other) => other.id != entry.id)
        .where((other) => other.createdAt.isBefore(entry.createdAt))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final weekStart = DateTime(
      reference.year,
      reference.month,
      reference.day - 6,
    );
    final entriesThisWeek = 1 +
        earlier
            .where((other) => !other.createdAt.toLocal().isBefore(weekStart))
            .length;

    final previous = earlier.isEmpty ? null : earlier.first;
    final daysSince = previous == null
        ? null
        : _wholeDaysBetween(previous.createdAt, entry.createdAt);

    final emotions = summary?.emotions ?? const <String>[];
    final sample = earlier
        .where((other) =>
            entry.createdAt.difference(other.createdAt).inDays <=
            recentWindowDays)
        .take(recurrenceSampleSize)
        .toList(growable: false);

    final recurring = <String>[];
    for (final emotion in emotions) {
      final appearances = 1 +
          sample
              .where((other) =>
                  other.summary?.emotions.contains(emotion) ?? false)
              .length;
      if (appearances >= recurrenceThreshold) recurring.add(emotion);
    }

    String? continuityNote;
    if (previous == null) {
      continuityNote = pick(
        'This is the first entry you have kept here. There is nothing to '
            'compare it with yet, which is its own kind of beginning.',
        'Ito ang unang talang itinago mo rito. Wala pa itong maihahambing, '
            'at iyon mismo ang simula.',
      );
    } else if (daysSince != null && daysSince >= 7) {
      continuityNote = pick(
        'Your first entry in $daysSince days. Coming back after a gap is '
            'worth as much as writing every day.',
        'Ito ang unang tala mo sa loob ng $daysSince araw. Kasinghalaga ng '
            'araw-araw na pagsulat ang pagbabalik matapos ang pagitan.',
      );
    } else if (entriesThisWeek >= 3) {
      continuityNote = pick(
        'Your ${_ordinal(entriesThisWeek, language)} entry in seven days. '
            'That is enough writing for patterns to start showing.',
        'Ito ang ${_ordinal(entriesThisWeek, language)} mong tala sa loob ng '
            'pitong araw. Sapat na iyan para magsimulang lumitaw ang pattern.',
      );
    } else if (daysSince != null && daysSince <= 1) {
      continuityNote = pick(
        'You also wrote ${daysSince == 0 ? 'earlier today' : 'yesterday'}. '
            'Two entries close together often say more together than apart.',
        'Nagsulat ka rin ${daysSince == 0 ? 'kanina' : 'kahapon'}. Madalas, '
            'mas marami ang sinasabi ng dalawang magkalapit na tala kapag '
            'magkasama.',
      );
    }

    String? recurrenceNote;
    if (recurring.isNotEmpty) {
      final named = recurring
          .take(2)
          .map((emotion) => _emotionWord(emotion, language))
          .join(pick(' and ', ' at '));
      recurrenceNote = pick(
        '$named has been showing up across your recent entries, not only '
            'this one. A feeling that keeps returning usually has a situation '
            'behind it worth naming.',
        'Paulit-ulit na lumalabas ang $named sa mga huling tala mo, hindi '
            'lang dito. Ang damdaming bumabalik ay kadalasang may sitwasyong '
            'dapat pangalanan.',
      );
    }

    return JournalContextReading(
      wordCount: _wordCount(entry.content),
      entriesThisWeek: entriesThisWeek,
      daysSinceLastEntry: daysSince,
      recurringEmotions: recurring,
      continuityNote: continuityNote,
      recurrenceNote: recurrenceNote,
      followUps: followUpsFor(emotions: emotions, language: language),
    );
  }

  /// At most two next moves, matched to what the entry was actually about.
  ///
  /// Order matters: the harder feelings are answered first, because someone
  /// who wrote about being overwhelmed is not helped by being offered the
  /// gratitude garden.
  static List<JournalFollowUp> followUpsFor({
    required List<String> emotions,
    required String language,
  }) {
    String pick(String english, String filipino) =>
        LanguageHelper.pick(language, english: english, filipino: filipino);
    final found = emotions.map((emotion) => emotion.toLowerCase()).toSet();
    final followUps = <JournalFollowUp>[];

    void add(JournalFollowUpKind kind, String titleEn, String titleFil,
        String whyEn, String whyFil) {
      if (followUps.length >= 2 ||
          followUps.any((followUp) => followUp.kind == kind)) {
        return;
      }
      followUps.add(JournalFollowUp(
        kind: kind,
        title: pick(titleEn, titleFil),
        rationale: pick(whyEn, whyFil),
      ));
    }

    if (found.contains('anxious') || found.contains('overwhelmed')) {
      add(
        JournalFollowUpKind.breathing,
        'Two minutes of slower breathing',
        'Dalawang minutong mabagal na paghinga',
        'A longer out-breath reaches a keyed-up nervous system faster than '
            'thinking it through does.',
        'Mas mabilis maabot ng mahabang paghinga palabas ang balisang '
            'katawan kaysa sa pag-iisip nang paulit-ulit.',
      );
    }
    if (found.contains('frustrated') || found.contains('uncertain')) {
      add(
        JournalFollowUpKind.grounding,
        'Run 5–4–3–2–1 grounding',
        'Subukan ang 5–4–3–2–1',
        'Naming what is around you interrupts the loop without asking you to '
            'resolve anything first.',
        'Ang pagpangalan sa nakapaligid sa iyo ay pumuputol sa paulit-ulit na '
            'isip nang hindi kailangang may malutas muna.',
      );
    }
    if (found.contains('tired')) {
      add(
        JournalFollowUpKind.sleepLog,
        'Log last night',
        'Itala ang kagabi',
        'Tiredness that keeps appearing in writing is worth measuring. A few '
            'logged nights show whether it is sleep or something else.',
        'Ang pagod na paulit-ulit lumalabas sa sulat ay dapat masukat. '
            'Ipapakita ng ilang gabing may tala kung tulog nga ba ito o iba.',
      );
    }
    if (found.contains('sad') || found.contains('lonely')) {
      add(
        JournalFollowUpKind.comfortCorner,
        'Sit in the comfort corner',
        'Dumaan sa comfort corner',
        'Some feelings do not need solving today. This is the part of the app '
            'built for staying with one.',
        'May mga damdaming hindi kailangang lutasin ngayon. Para dito ang '
            'bahaging ito ng app.',
      );
    }
    if (found.contains('grateful') ||
        found.contains('happy') ||
        found.contains('proud') ||
        found.contains('relieved') ||
        found.contains('excited')) {
      add(
        JournalFollowUpKind.gratitude,
        'Plant this in your garden',
        'Itanim ito sa hardin mo',
        'Good moments fade faster than hard ones. Writing one down is how it '
            'stays available on a worse day.',
        'Mas mabilis maglaho ang magagandang sandali kaysa sa mabibigat. Ang '
            'pagsulat nito ang nagpapanatili nitong maaalala sa mas mabigat '
            'na araw.',
      );
    }

    if (followUps.isEmpty) {
      add(
        JournalFollowUpKind.moodCheckIn,
        'Check in on where you are now',
        'Kumustahin ang sarili ngayon',
        'Writing often shifts something. A check-in right after gives your '
            'week a data point your memory will not keep.',
        'Madalas may nagbabago pagkatapos magsulat. Ang check-in ngayon ay '
            'nagbibigay ng talang hindi maaalala ng isip mo mamaya.',
      );
    }
    return followUps;
  }

  static int _wordCount(String content) =>
      content.trim().isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).length;

  static int _wholeDaysBetween(DateTime earlier, DateTime later) {
    final from = DateTime(earlier.year, earlier.month, earlier.day);
    final to = DateTime(later.year, later.month, later.day);
    return to.difference(from).inDays;
  }

  static String _ordinal(int value, String language) {
    if (LanguageHelper.normalize(language) == 'filipino') {
      return switch (value) {
        3 => 'pangatlo',
        4 => 'pang-apat',
        5 => 'panlima',
        6 => 'pang-anim',
        7 => 'pampito',
        _ => 'pang-$value',
      };
    }
    return switch (value) {
      3 => 'third',
      4 => 'fourth',
      5 => 'fifth',
      6 => 'sixth',
      7 => 'seventh',
      _ => '${value}th',
    };
  }

  static String _emotionWord(String emotion, String language) {
    final english = emotion.isEmpty
        ? emotion
        : emotion[0].toUpperCase() + emotion.substring(1);
    return LanguageHelper.pick(
      language,
      english: english,
      filipino: switch (emotion) {
        'happy' => 'Kasiyahan',
        'anxious' => 'Pagkabalisa',
        'tired' => 'Pagod',
        'grateful' => 'Pasasalamat',
        'excited' => 'Pananabik',
        'sad' => 'Lungkot',
        'overwhelmed' => 'Pagkabigat',
        'calm' => 'Kalmado',
        'hopeful' => 'Pag-asa',
        'frustrated' => 'Inis',
        'relieved' => 'Ginhawa',
        'lonely' => 'Pag-iisa',
        'proud' => 'Pagmamalaki',
        'uncertain' => 'Pag-aalinlangan',
        'peaceful' => 'Kapayapaan',
        'nostalgic' => 'Pananabik sa nakaraan',
        _ => english,
      },
    );
  }
}

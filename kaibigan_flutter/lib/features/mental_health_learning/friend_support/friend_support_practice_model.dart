import '../learning_model.dart';

/// A situation the practice partner plays. Each one targets the skills taught
/// by a lesson, so practice reinforces something the person just read.
class PracticeScenario {
  const PracticeScenario({
    required this.id,
    required this.lessonId,
    required this.friendName,
    required this.situation,
    required this.opener,
    required this.skillFocus,
    required this.watchFor,
    this.isSensitive = false,
  });

  final String id;

  /// The lesson this scenario practises.
  final String lessonId;

  final String friendName;

  /// One line of context shown to the user before they start.
  final LearningCopy situation;

  /// The friend's first message.
  final LearningCopy opener;

  /// What a good reply does here, shown as a reminder during practice.
  final List<LearningCopy> skillFocus;

  /// What the model is told to steer the conversation toward.
  final String watchFor;

  /// Scenarios that touch on hopelessness, which show the safety reminder and
  /// route toward encouraging real help rather than handling it alone.
  final bool isSensitive;
}

class PracticeScenarios {
  const PracticeScenarios._();

  static const all = <PracticeScenario>[
    PracticeScenario(
      id: 'practice-overwhelm',
      lessonId: 'friend-support-listen',
      friendName: 'Emma',
      situation: LearningCopy(
        english:
            'Emma messages you late on a weeknight. She has been quiet for '
            'about two weeks.',
        filipino:
            'Nag-message si Emma nang gabi ng weekday. Dalawang linggo na '
            'siyang tahimik.',
      ),
      opener: LearningCopy(
        english:
            "sorry for the late message. i honestly don't know why i'm even "
            "typing this. everything just feels like too much right now and i "
            "can't explain it properly.",
        filipino:
            'sorry sa late message. hindi ko alam kung bakit ko pa ito '
            'tine-type. ang bigat lang ng lahat ngayon at hindi ko '
            'maipaliwanag nang maayos.',
      ),
      skillFocus: [
        LearningCopy(
          english: 'Listen first. Do not reach for a solution yet.',
          filipino: 'Makinig muna. Huwag munang magbigay ng solusyon.',
        ),
        LearningCopy(
          english: 'Let her know the message landed and she is not a burden.',
          filipino:
              'Ipaalam na nabasa mo siya at hindi siya pabigat.',
        ),
      ],
      watchFor:
          'Emma is exhausted and struggling to name what is wrong. She opens '
          'up more when she feels listened to, and goes quieter or more formal '
          'if she is given quick advice or told to look on the bright side.',
    ),
    PracticeScenario(
      id: 'practice-minimised',
      lessonId: 'friend-support-listen',
      friendName: 'Jared',
      situation: LearningCopy(
        english:
            'Jared has been told more than once that he is overreacting. He '
            'brings something up carefully.',
        filipino:
            'Ilang beses nang sinabihan si Jared na OA daw siya. Maingat '
            'niyang binabanggit ang isang bagay.',
      ),
      opener: LearningCopy(
        english:
            "it's probably nothing. i just keep waking up at 3am with my "
            "chest tight and then i can't get back to sleep. people say i'm "
            "being dramatic so never mind.",
        filipino:
            'baka wala lang ito. lagi lang akong nagigising ng 3am na masikip '
            'ang dibdib tapos hindi na ako makabalik sa tulog. sabi nila OA '
            'daw ako kaya wag na lang.',
      ),
      skillFocus: [
        LearningCopy(
          english: 'Take it seriously without dramatising it either.',
          filipino: 'Seryosohin ito nang hindi rin pinalalaki.',
        ),
        LearningCopy(
          english: 'Do not agree that he is overreacting to smooth it over.',
          filipino:
              'Huwag sumang-ayon na OA siya para lang mapadali ang usapan.',
        ),
      ],
      watchFor:
          'Jared expects to be dismissed and will withdraw the moment he is. '
          'He says more when his experience is taken at face value.',
    ),
    PracticeScenario(
      id: 'practice-hopeless',
      lessonId: 'friend-support-safety',
      friendName: 'Ren',
      situation: LearningCopy(
        english:
            'Ren has been withdrawing from your group. Tonight the tone of '
            'their message is flatter than usual.',
        filipino:
            'Lumalayo si Ren sa inyong grupo. Ngayong gabi, mas walang buhay '
            'ang tono ng message niya.',
      ),
      opener: LearningCopy(
        english:
            "i've stopped trying to explain it to people. honestly it feels "
            "like nothing i do changes anything and i'm tired of pretending "
            "otherwise.",
        filipino:
            'tumigil na akong magpaliwanag sa mga tao. pakiramdam ko wala '
            'namang nagbabago sa kahit anong gawin ko at pagod na akong '
            'magkunwari.',
      ),
      skillFocus: [
        LearningCopy(
          english: 'Ask directly and calmly whether they are safe.',
          filipino: 'Magtanong nang diretso at kalmado kung ligtas sila.',
        ),
        LearningCopy(
          english: 'Stay with them and point toward real help. Do not promise '
              'to keep a danger secret.',
          filipino:
              'Manatili sa tabi nila at ituro ang totoong tulong. Huwag '
              'mangakong itatago ang panganib.',
        ),
      ],
      watchFor:
          'Ren feels stuck and unseen. Being asked directly and calmly about '
          'safety is a relief, not an offence. Ren does not describe methods '
          'or plans at any point.',
      isSensitive: true,
    ),
    PracticeScenario(
      id: 'practice-boundaries',
      lessonId: 'friend-support-boundaries',
      friendName: 'Alex',
      situation: LearningCopy(
        english:
            'Alex leans on you often. You care about them, and you are also '
            'running low yourself this week.',
        filipino:
            'Madalas umasa si Alex sa iyo. Mahalaga sila sa iyo, pero '
            'kapos ka rin ngayong linggo.',
      ),
      opener: LearningCopy(
        english:
            "hey can i call? i know it's the third time this week, you're "
            "literally the only person i can talk to about this stuff.",
        filipino:
            'uy pwede ba akong tumawag? alam kong pangatlong beses na '
            'ngayong linggo, ikaw lang talaga ang nakakausap ko tungkol dito.',
      ),
      skillFocus: [
        LearningCopy(
          english: 'Be honest about your limit without withdrawing care.',
          filipino:
              'Maging tapat sa hangganan mo nang hindi binabawi ang malasakit.',
        ),
        LearningCopy(
          english: 'Widen their circle instead of becoming their only support.',
          filipino:
              'Palawakin ang bilog nila sa halip na ikaw lang ang suporta.',
        ),
      ],
      watchFor:
          'Alex is genuinely struggling and also relying on one person for '
          'everything. A warm, specific boundary lands better than either a '
          'silent yes or a flat no.',
    ),
  ];

  static PracticeScenario byId(String id) => all.firstWhere(
        (scenario) => scenario.id == id,
        orElse: () => all.first,
      );

  static List<PracticeScenario> forLesson(String lessonId) =>
      all.where((scenario) => scenario.lessonId == lessonId).toList();
}

enum PracticeFeedbackTone { strong, mixed, offTrack, unsafe }

/// One observation about a reply the user just sent.
class PracticeFeedbackPoint {
  const PracticeFeedbackPoint({
    required this.label,
    required this.detail,
    required this.isStrength,
  });

  final String label;
  final String detail;

  /// True for "this worked", false for "try this instead".
  final bool isStrength;
}

/// The result of one practice exchange: how the friend answers, plus what the
/// reply did well and what to try next.
class PracticeTurnResult {
  const PracticeTurnResult({
    required this.friendReply,
    required this.tone,
    required this.headline,
    required this.points,
    this.modelPhrase = '',
    this.safetyNotice,
    this.isOffline = false,
    this.endsPractice = false,
  });

  final String friendReply;
  final PracticeFeedbackTone tone;

  /// One sentence naming what the reply did.
  final String headline;

  final List<PracticeFeedbackPoint> points;

  /// A concrete phrase the user could have used. May be empty.
  final String modelPhrase;

  /// An explicit safety notice with crisis hotlines, separate from the friend's dialogue.
  final String? safetyNotice;

  final bool isOffline;

  /// True when the exchange should stop, for example after a safety intercept.
  final bool endsPractice;

  bool get hasModelPhrase => modelPhrase.trim().isNotEmpty;
  bool get hasSafetyNotice => safetyNotice != null && safetyNotice!.trim().isNotEmpty;
}

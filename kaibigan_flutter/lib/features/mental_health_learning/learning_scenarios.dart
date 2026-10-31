import 'learning_model.dart';

class LearningScenario {
  const LearningScenario({required this.prompt, required this.choices,
    required this.helpfulIndex, required this.explanation});
  final LearningCopy prompt;
  final List<LearningCopy> choices;
  final int helpfulIndex;
  final LearningCopy explanation;
}

LearningScenario _scenario(String prompt, String promptFil,
    String helpful, String helpfulFil, String other, String otherFil,
    String why, String whyFil, {bool reverse = false}) {
  final correct = LearningCopy(english: helpful, filipino: helpfulFil);
  final alternative = LearningCopy(english: other, filipino: otherFil);
  return LearningScenario(prompt: LearningCopy(english: prompt, filipino: promptFil),
      choices: reverse ? [alternative, correct] : [correct, alternative],
      helpfulIndex: reverse ? 1 : 0,
      explanation: LearningCopy(english: why, filipino: whyFil));
}

/// Authored, optional learning examples. Responses stay in memory and are
/// never interpreted as symptoms, diagnostic answers, or a health assessment.
abstract final class LearningScenarios {
  static final byLesson = <String, LearningScenario>{
    'mental-health-basics': _scenario(
      'A friend says, “I should only care for my mental health when something is wrong.” What would you say?',
      'Sabi ng kaibigan mo, “Aalagaan ko lang ang mental health kapag may problema.” Ano ang sasabihin mo?',
      'Everyday care matters, even on good days.', 'Mahalaga ang pang-araw-araw na pag-aalaga, kahit maayos ang araw.',
      'Wait until things become difficult.', 'Maghintay muna hanggang maging mahirap ang sitwasyon.',
      'Mental health is part of everyday health. Small habits and supportive relationships can matter before a crisis.',
      'Bahagi ng araw-araw na kalusugan ang mental health. Mahalaga ang maliliit na gawi at suportang ugnayan kahit walang krisis.'),
    'stress-burnout': _scenario(
      'Your week is overloaded. Which response makes room for recovery?', 'Siksik ang linggo mo. Alin ang nagbibigay ng puwang para makabawi?',
      'Choose one priority and make space for a break.', 'Pumili ng isang prayoridad at maglaan ng pahinga.',
      'Push through every task without stopping.', 'Tapusin ang lahat nang walang pahinga.',
      'Rest and manageable expectations are practical responses to overload. You do not have to earn a pause.',
      'Makakatulong ang pahinga at makatotohanang inaasahan kapag overloaded. Hindi kailangang paghirapan muna ang karapatang magpahinga.', reverse: true),
    'understanding-anxiety': _scenario(
      'A worrying thought feels certain. What can create a little distance?', 'Parang tiyak ang isang nakakabahalang isipin. Ano ang makapagbibigay ng kaunting distansya?',
      'Notice it as a thought, then return to what is around you.', 'Kilalanin itong isipin, saka ibalik ang pansin sa paligid.',
      'Treat the thought as proof of what will happen.', 'Ituring itong patunay ng mangyayari.',
      'A strong feeling is real, but it does not make every prediction a fact. Persistent anxiety deserves support.',
      'Totoo ang matinding damdamin, pero hindi lahat ng hula ay katotohanan. Karapat-dapat sa suporta ang nagpapatuloy na anxiety.'),
    'low-mood-depression': _scenario(
      'Someone has been struggling with low mood. Which response is kinder?', 'Nahihirapan ang isang tao dahil sa mababang mood. Alin ang mas may malasakit?',
      'Listen and help them find support they feel comfortable with.', 'Makinig at tumulong humanap ng suportang komportable sila.',
      'Tell them to be grateful and cheer up.', 'Sabihing magpasalamat na lang at sumaya.',
      'Depression is not a failure of gratitude or effort. Listening and professional support can be important.',
      'Hindi kakulangan sa pasasalamat o pagsisikap ang depression. Maaaring mahalaga ang pakikinig at propesyonal na suporta.', reverse: true),
    'sleep-and-mind': _scenario(
      'It is time to wind down. Which small change supports a steadier routine?', 'Oras nang magpahinga. Aling maliit na pagbabago ang susuporta sa mas regular na routine?',
      'Keep a gentle, consistent wind-down time.', 'Panatilihin ang banayad at regular na oras ng paghahanda sa pagtulog.',
      'Expect one perfect night to fix everything.', 'Umasa na maaayos ng isang perpektong gabi ang lahat.',
      'Sleep habits build over time. One difficult night does not erase the care you have been practising.',
      'Unti-unting nabubuo ang gawi sa pagtulog. Hindi binubura ng isang mahirap na gabi ang pag-aalaga mo sa sarili.'),
    'asking-for-help': _scenario(
      'You want support but do not know how to begin. Which opening is clearer?', 'Gusto mo ng suporta pero hindi mo alam paano magsimula. Alin ang mas malinaw na pambungad?',
      '“I have been having a hard time. Could you listen for a few minutes?”', '“Nahihirapan ako lately. Puwede mo ba akong pakinggan nang ilang minuto?”',
      'Wait until you can explain every feeling perfectly.', 'Maghintay hanggang maipaliwanag mo nang perpekto ang lahat.',
      'A simple, specific request is enough to begin. You do not need a perfect explanation to deserve support.',
      'Sapat ang simple at tiyak na pakiusap para magsimula. Hindi kailangan ng perpektong paliwanag para maging karapat-dapat sa suporta.', reverse: true),
    'panic-attacks': _scenario(
      'A friend is frightened by a wave of panic. What is a supportive first response?', 'Natakot ang kaibigan mo sa biglang panic. Ano ang suportadong unang tugon?',
      'Stay calm, listen, and ask what would help them feel supported.', 'Manatiling kalmado, makinig, at itanong kung anong suporta ang makakatulong.',
      'Tell them they are overreacting.', 'Sabihing sobra lang ang reaksiyon nila.',
      'Panic can feel intense. Calm support helps avoid adding shame. New or concerning physical symptoms should not be assumed to be panic.',
      'Maaaring matindi ang panic. Nakakaiwas sa dagdag na hiya ang mahinahong suporta. Huwag basta ituring na panic ang bago o nakababahalang pisikal na sintomas.'),
    'emotional-regulation': _scenario(
      'You feel angry during a conversation. Which response gives you more choice?', 'Nakaramdam ka ng galit habang nakikipag-usap. Alin ang nagbibigay ng mas maraming pagpipilian?',
      'Name the feeling and pause before responding.', 'Pangalanan ang damdamin at huminto muna bago tumugon.',
      'Reply immediately because the feeling is strong.', 'Sumagot agad dahil matindi ang damdamin.',
      'A pause does not make the feeling disappear. It gives you room to choose what you do with it.',
      'Hindi agad nawawala ang damdamin sa paghinto. Nagbibigay ito ng puwang para piliin ang gagawin mo.', reverse: true),
    'self-compassion': _scenario(
      'You made a mistake. Which inner response combines kindness with responsibility?', 'Nagkamali ka. Aling tugon sa sarili ang may kabaitan at pananagutan?',
      '“This was hard. I can acknowledge it and choose a next step.”', '“Mahirap ito. Maaari kong kilalanin ang nangyari at pumili ng susunod na hakbang.”',
      '“This mistake defines who I am.”', '“Ang pagkakamaling ito ang buong pagkatao ko.”',
      'Self-compassion can acknowledge a mistake without turning it into a verdict on your worth.',
      'Maaaring kilalanin ang pagkakamali nang hindi hinahatulan ang halaga mo bilang tao.'),
    'healthy-boundaries': _scenario(
      'You care about a friend, but cannot talk tonight. Which message is clear and caring?', 'Mahalaga sa iyo ang kaibigan mo, pero hindi ka makakausap ngayong gabi. Aling mensahe ang malinaw at may malasakit?',
      '“I care about you. I cannot talk tonight, but I can check in tomorrow.”', '“Mahalaga ka sa akin. Hindi ako makakausap ngayon, pero maaari akong mangumusta bukas.”',
      'Agree to talk even though you know you cannot.', 'Pumayag kahit alam mong hindi mo kaya.',
      'A boundary states your capacity. Caring about someone does not require unlimited availability.',
      'Ipinapahayag ng boundary ang kaya mo. Hindi kailangan ng walang limitasyong oras para magmalasakit.', reverse: true),
    'grief-and-loss': _scenario(
      'A grieving friend feels better one day and worse the next. What would you say?', 'Mas maayos ang isang araw ng nagluluksa mong kaibigan, pero mas mahirap ang kasunod. Ano ang sasabihin mo?',
      '“Grief can move unevenly. I am here with you.”', '“Maaaring pabago-bago ang pagdadalamhati. Narito ako para sa iyo.”',
      '“You should be past this by now.”', '“Dapat nakalimutan mo na ito.”',
      'Grief does not follow one fixed timetable. Presence is often more helpful than pressure to recover on schedule.',
      'Walang iisang iskedyul ang pagdadalamhati. Mas makakatulong ang presensya kaysa pagpilit na makabawi agad.'),
    'types-of-care': _scenario(
      'You are exploring support options. Which approach leaves room for your needs?', 'Sinusuri mo ang mga uri ng suporta. Alin ang nagbibigay ng puwang para sa pangangailangan mo?',
      'Ask a qualified provider about options and what to expect.', 'Magtanong sa kwalipikadong provider tungkol sa mga opsyon at aasahan.',
      'Assume the same approach works for everyone.', 'Ipagpalagay na pareho ang angkop para sa lahat.',
      'Care can take different forms. Asking questions helps you understand the options and participate in decisions.',
      'Iba-iba ang anyo ng pangangalaga. Makakatulong ang pagtatanong para maunawaan ang mga opsyon at makibahagi sa mga desisyon.', reverse: true),
    'understanding-adhd': _scenario(
      'Someone finds it hard to organise a task. Which response avoids blame?', 'Nahihirapan ang isang tao na ayusin ang gawain. Alin ang umiiwas sa paninisi?',
      'Offer a clear first step and ask what support helps.', 'Mag-alok ng malinaw na unang hakbang at itanong kung anong suporta ang makakatulong.',
      'Call them lazy for finding it difficult.', 'Tawagin silang tamad dahil nahihirapan sila.',
      'A difficulty with attention or organisation is not a measure of character. A lesson alone cannot determine whether someone has ADHD.',
      'Hindi sukatan ng pagkatao ang hirap sa atensyon o pag-aayos ng gawain. Hindi sapat ang isang aralin para malaman kung may ADHD ang isang tao.'),
    'understanding-ocd': _scenario(
      'A friend says OCD is just liking things tidy. Which response adds understanding?', 'Sabi ng kaibigan mo, hilig lang sa kalinisan ang OCD. Alin ang nagdaragdag ng pag-unawa?',
      'OCD can involve distressing obsessions and compulsions.', 'Maaaring may nakababahalang obsessions at compulsions ang OCD.',
      'Agree that it is only a personality preference.', 'Sumang-ayon na personalidad o hilig lang ito.',
      'Reducing OCD to tidiness overlooks the distress it can cause. Diagnosis belongs with a qualified professional.',
      'Hindi nakikita ang hirap na dulot ng OCD kapag itinuturing lang itong kalinisan. Kwalipikadong propesyonal ang nagsasagawa ng diagnosis.', reverse: true),
    'understanding-bipolar': _scenario(
      'Someone uses “bipolar” to describe an ordinary change of mood. What is more accurate?', 'Ginamit ang “bipolar” para sa karaniwang pagbabago ng mood. Alin ang mas tumpak?',
      'Ordinary mood changes are not enough to identify bipolar disorder.', 'Hindi sapat ang karaniwang pagbabago ng mood para matukoy ang bipolar disorder.',
      'Any change from happy to sad confirms the condition.', 'Kinukumpirma ng bawat pagbabago mula saya tungo sa lungkot ang kondisyon.',
      'The lesson explains a condition, not a label to apply to yourself or someone else. A professional assessment considers a fuller pattern.',
      'Ipinapaliwanag ng aralin ang kondisyon, hindi label para sa sarili o iba. Isinasaalang-alang sa propesyonal na pagsusuri ang mas malawak na pattern.'),
    'understanding-ptsd': _scenario(
      'A friend does not want to discuss a painful experience. Which response respects their pace?', 'Ayaw pag-usapan ng kaibigan mo ang masakit na karanasan. Alin ang gumagalang sa bilis nila?',
      'Respect their choice and ask what support feels okay.', 'Igalang ang pagpili nila at itanong kung anong suporta ang komportable.',
      'Insist that they tell you every detail.', 'Ipilit na ikuwento nila ang bawat detalye.',
      'Support does not require someone to disclose details before they are ready. Avoid pressuring them to relive an experience.',
      'Hindi kailangan ng detalye bago sila maging handa para makapagbigay ng suporta. Iwasang pilitin silang balikan ang karanasan.', reverse: true),
    'understanding-eating-disorders': _scenario(
      'Someone is struggling around eating. Which response avoids judging by appearance?', 'Nahihirapan ang isang tao kaugnay ng pagkain. Alin ang umiiwas sa paghusga batay sa itsura?',
      'Take their concerns seriously and encourage qualified support.', 'Seryosohin ang pag-aalala nila at hikayatin ang kwalipikadong suporta.',
      'Decide whether help is needed from body size alone.', 'Magpasya kung kailangan ng tulong batay lamang sa laki ng katawan.',
      'Appearance alone cannot tell you what someone is experiencing. Compassionate support matters without body comments.',
      'Hindi sapat ang itsura para malaman ang karanasan ng isang tao. Mahalaga ang may malasakit na suporta nang walang komento sa katawan.'),
    'understanding-schizophrenia': _scenario(
      'A friend is learning about schizophrenia. Which response reduces stigma?', 'Nag-aaral tungkol sa schizophrenia ang kaibigan mo. Alin ang nakababawas sa stigma?',
      'Use respectful language and learn from reliable sources.', 'Gumamit ng magalang na salita at matuto mula sa maaasahang sanggunian.',
      'Treat a diagnosis as someone’s entire identity.', 'Ituring ang diagnosis bilang buong pagkatao nila.',
      'A person is more than a condition. Respect and qualified care matter more than stereotypes.',
      'Higit sa kondisyon ang isang tao. Mas mahalaga ang respeto at kwalipikadong pangangalaga kaysa stereotype.', reverse: true),
    'social-anxiety': _scenario(
      'Someone fears being judged in a social situation. Which response leaves them a choice?', 'Natatakot mahusgahan ang isang tao sa pakikisalamuha. Alin ang nagbibigay sa kanila ng pagpipilian?',
      'Listen and ask whether a smaller, supported step feels manageable.', 'Makinig at itanong kung kaya ang mas maliit na hakbang na may suporta.',
      'Force them into the most difficult situation immediately.', 'Pilitin sila agad sa pinakamahirap na sitwasyon.',
      'Support respects a person’s pace. Persistent difficulties can be discussed with a qualified professional.',
      'Iginagalang ng suporta ang bilis ng isang tao. Maaaring talakayin ang nagpapatuloy na hirap sa kwalipikadong propesyonal.'),
    'substance-use-mental-health': _scenario(
      'A friend is worried about substance use. Which response keeps the door to support open?', 'Nag-aalala ang kaibigan mo tungkol sa paggamit ng substance. Alin ang nagpapanatiling bukas sa suporta?',
      'Listen without shame and encourage qualified support.', 'Makinig nang walang pagpapahiya at hikayatin ang kwalipikadong suporta.',
      'Tell them the concern proves they have failed.', 'Sabihing patunay ito na nabigo sila.',
      'Shame can make asking for help harder. Support can begin with a calm conversation and qualified care.',
      'Maaaring magpahirap sa paghingi ng tulong ang hiya. Maaaring magsimula ang suporta sa mahinahong usapan at kwalipikadong pangangalaga.', reverse: true),
    'supporting-someone': _scenario(
      'Your friend shares a difficult day. Which opening invites them to feel heard?', 'Ibinahagi ng kaibigan mo ang mahirap na araw. Aling pambungad ang nagpaparamdam na pinakikinggan sila?',
      '“Would you like me to listen, or think through options with you?”', '“Gusto mo bang makinig ako, o mag-isip tayo ng mga opsyon?”',
      'Give advice before finding out what they need.', 'Magbigay agad ng payo bago alamin ang kailangan nila.',
      'Asking what kind of support they want makes the conversation collaborative rather than assuming you must fix it.',
      'Nagiging sama-samang usapan ang pagtatanong sa suportang gusto nila, sa halip na ipagpalagay na kailangan mong ayusin ang lahat.'),
  };
}

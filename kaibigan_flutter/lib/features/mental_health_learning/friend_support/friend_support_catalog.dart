import '../learning_model.dart';
import 'friend_support_model.dart';

class FriendSupportCatalog {
  const FriendSupportCatalog._();

  static const List<LearningCopy> takeaways = [
    LearningCopy(
      english: 'Listen before trying to fix',
      filipino: 'Makinig bago subukang ayusin ang problema',
    ),
    LearningCopy(
      english: 'Take someone\'s feelings seriously',
      filipino: 'Seryosohin ang nararamdaman ng isang tao',
    ),
    LearningCopy(
      english: 'Recognize when someone may be in danger',
      filipino: 'Makilala kung maaaring nasa panganib ang isang tao',
    ),
    LearningCopy(
      english: 'Encourage people to seek additional support',
      filipino: 'Hikayatin ang iba na humingi ng karagdagang suporta',
    ),
    LearningCopy(
      english: 'Stay present without taking everything on yourself',
      filipino: 'Manatiling present nang hindi inaako ang lahat ng responsibilidad',
    ),
    LearningCopy(
      english: 'Know when it\'s time to ask for help',
      filipino: 'Malaman kung kailan oras na para humingi ng tulong',
    ),
  ];

  static const List<FriendSupportLesson> lessons = [
    // LESSON 1
    FriendSupportLesson(
      id: 'friend-support-listen',
      order: 1,
      title: LearningCopy(
        english: 'Listen Before You Fix',
        filipino: 'Makinig Bago Magbigay ng Solusyon',
      ),
      subtitle: LearningCopy(
        english:
            'When a friend is struggling, listen without judging or immediately giving advice.',
        filipino:
            'Kapag nahihirapan ang isang kaibigan, makinig nang walang panghuhusga o agarang payo.',
      ),
      whatYoullLearn: LearningCopy(
        english:
            'When a friend is struggling, your first job isn\'t always to solve their problem. Sometimes, what they need most is someone who will listen without judging or immediately giving advice.\n\nYou don\'t need to completely understand what they\'re going through. You can still show that you care.',
        filipino:
            'Kapag nahihirapan ang isang kaibigan, hindi mo kailangang agad ayusin ang problema niya. Minsan, ang pinaka-kailangan niya ay isang taong makikinig nang walang panghuhusga o agad na pagbibigay ng payo.\n\nHindi mo kailangang lubos na maintindihan ang pinagdadaanan niya. Maaari mo pa ring ipakita na nagmamalasakit ka.',
      ),
      pointsHeader: LearningCopy(
        english: 'Helpful Responses',
        filipino: 'Mga Makakatulong na Sagot',
      ),
      points: [
        LearningCopy(
          english: '“That sounds really difficult.”',
          filipino: '“Mukhang napakahirap ng pinagdadaanan mo.”',
        ),
        LearningCopy(
          english: '“I\'m here if you want to talk.”',
          filipino: '“Nandito lang ako kung gusto mong magkwento.”',
        ),
        LearningCopy(
          english: '“I might not fully understand, but I want to listen.”',
          filipino:
              '“Baka hindi ko lubos na naiintindihan, pero gusto kitang pakinggan.”',
        ),
        LearningCopy(
          english: '“You don\'t have to figure everything out right now.”',
          filipino: '“Hindi mo kailangang ayusin lahat ngayon.”',
        ),
      ],
      avoidHeader: LearningCopy(
        english: 'Try to Avoid',
        filipino: 'Mga Dapat Iwasan',
      ),
      avoidPoints: [
        LearningCopy(
          english: '“Just don\'t think about it.”',
          filipino: '“Huwag mo na lang isipin.”',
        ),
        LearningCopy(
          english: '“Other people have it worse.”',
          filipino: '“Mas malala pa nga ang pinagdadaanan ng ibang tao.”',
        ),
        LearningCopy(
          english: '“Here\'s what you should do…”',
          filipino: '“Ito kasi ang dapat mong gawin…”',
        ),
        LearningCopy(
          english: '“Everything will be fine.”',
          filipino: '“Magiging okay din ang lahat.”',
        ),
      ],
      questions: [
        // Question 1
        FriendSupportQuestion(
          id: 'listen-q1',
          contextQuote: LearningCopy(
            english:
                '“I\'ve been feeling really overwhelmed lately. I don\'t know who I can talk to.”',
            filipino:
                '“Sobrang overwhelmed na ako nitong mga nakaraan. Hindi ko alam kung sino ang pwede kong makausap.”',
          ),
          prompt: LearningCopy(
            english: 'What would be the most supportive response?',
            filipino: 'Ano ang pinaka-suportadong sagot?',
          ),
          options: [
            FriendSupportOption(
              id: 'A',
              text: LearningCopy(
                english: '“Everyone feels overwhelmed sometimes. You just need to relax.”',
                filipino: '“Lahat naman nakakaranas ng stress. Mag-relax ka lang.”',
              ),
              explanation: LearningCopy(
                english:
                    '“Everyone feels overwhelmed” may be true, but it can make your friend\'s feelings seem ordinary or unimportant.',
                filipino:
                    'Maaaring totoo na lahat ay nakakaranas ng stress, pero maaaring maramdaman ng kaibigan mo na minamaliit o hindi mahalaga ang pinagdadaanan niya.',
              ),
            ),
            FriendSupportOption(
              id: 'B',
              text: LearningCopy(
                english: '“You should make a schedule so you can manage everything better.”',
                filipino:
                    '“Gumawa ka na lang ng schedule para mas maayos mong mapamahalaan lahat.”',
              ),
              explanation: LearningCopy(
                english:
                    'Practical advice isn\'t necessarily bad, but giving solutions before understanding the problem can make someone feel unheard.',
                filipino:
                    'Hindi masama ang praktikal na payo, pero kung agad kang nagbibigay ng solusyon bago mo maintindihan ang problema, maaaring maramdaman niyang hindi mo siya pinakikinggan.',
              ),
            ),
            FriendSupportOption(
              id: 'C',
              text: LearningCopy(
                english:
                    '“I\'m sorry you\'re going through that. I\'m here to listen if you want to talk about what\'s been happening.”',
                filipino:
                    '“Pasensya na at pinagdadaanan mo ’yan. Nandito ako para makinig kung gusto mong ikwento kung ano ang nangyayari.”',
              ),
              explanation: LearningCopy(
                english:
                    'It acknowledges that your friend is struggling and gives them space to talk. You aren\'t pretending to have all the answers—you\'re simply showing that you\'re present and willing to listen.',
                filipino:
                    'Kinikilala nito na nahihirapan ang kaibigan mo at binibigyan siya ng pagkakataong magsalita. Hindi mo kailangang magkaroon agad ng lahat ng sagot—ipinapakita mo lang na nandiyan ka at handang makinig.',
              ),
            ),
            FriendSupportOption(
              id: 'D',
              text: LearningCopy(
                english: '“Don\'t worry, everything will work itself out.”',
                filipino: '“Huwag kang mag-alala, maaayos din ang lahat.”',
              ),
              explanation: LearningCopy(
                english:
                    'Trying to reassure someone that “everything will work out” can unintentionally dismiss how serious or painful things feel to them right now.',
                filipino:
                    'Maaaring gusto mo lang siyang bigyan ng reassurance, pero ang pagsasabing “maaayos din ang lahat” ay maaaring makaramdam siyang hindi mo nauunawaan kung gaano kabigat ang nararamdaman niya ngayon.',
              ),
            ),
          ],
          correctIndex: 2,
          hint: LearningCopy(
            english:
                'Think about what would make your friend feel safe enough to open up, rather than immediately trying to solve the problem.',
            filipino:
                'Isipin kung alin ang makakapagparamdam sa kaibigan mo na ligtas siyang mag-open up, sa halip na agad subukang ayusin ang problema niya.',
          ),
          correctExplanation: LearningCopy(
            english:
                'It acknowledges that your friend is struggling and gives them space to talk. You aren\'t pretending to have all the answers—you\'re simply showing that you\'re present and willing to listen.',
            filipino:
                'Kinikilala nito na nahihirapan ang kaibigan mo at binibigyan siya ng pagkakataong magsalita. Hindi mo kailangang magkaroon agad ng lahat ng sagot—ipinapakita mo lang na nandiyan ka at handang makinig.',
          ),
        ),
        // Question 2
        FriendSupportQuestion(
          id: 'listen-q2',
          prompt: LearningCopy(
            english:
                'Your friend tells you about a painful experience, but you aren\'t sure what to say. What should you do?',
            filipino:
                'Nagkukwento ang kaibigan mo tungkol sa isang masakit na karanasan, pero hindi mo alam kung ano ang sasabihin. Ano ang dapat mong gawin?',
          ),
          options: [
            FriendSupportOption(
              id: 'A',
              text: LearningCopy(
                english: 'Change the subject so they don\'t feel uncomfortable.',
                filipino: 'Palitan ang usapan para hindi siya maasiwa.',
              ),
              explanation: LearningCopy(
                english:
                    'Changing the subject may communicate that you\'re uncomfortable hearing about their feelings.',
                filipino:
                    'Ang pagpapalit ng usapan ay maaaring magbigay ng impresyon na hindi ka komportable sa nararamdaman o kwento niya.',
              ),
            ),
            FriendSupportOption(
              id: 'B',
              text: LearningCopy(
                english: 'Immediately tell them about a similar experience you\'ve had.',
                filipino: 'Ikwento agad ang sarili mong karanasan na katulad nito.',
              ),
              explanation: LearningCopy(
                english:
                    'Sharing your own experience can sometimes help, but immediately making the conversation about yourself can take attention away from your friend.',
                filipino:
                    'Minsan ay nakakatulong ang pagbabahagi ng sarili mong karanasan, pero kung agad mong gagawin itong tungkol sa iyo, maaaring mawala ang focus sa kaibigan mo.',
              ),
            ),
            FriendSupportOption(
              id: 'C',
              text: LearningCopy(
                english:
                    'Listen, acknowledge what they\'re saying, and ask gentle questions if they want to continue.',
                filipino:
                    'Makinig, kilalanin ang nararamdaman niya, at magtanong nang mahinahon kung gusto pa niyang magpatuloy.',
              ),
              explanation: LearningCopy(
                english:
                    'Listening and gently acknowledging their experience shows that you care without taking control of the conversation.',
                filipino:
                    'Ang pakikinig at pagkilala sa nararamdaman niya ay nagpapakita na nagmamalasakit ka nang hindi mo kinokontrol ang usapan.',
              ),
            ),
            FriendSupportOption(
              id: 'D',
              text: LearningCopy(
                english: 'Give them several solutions for how they can fix the situation.',
                filipino:
                    'Bigyan siya agad ng maraming solusyon kung paano niya maaayos ang problema.',
              ),
              explanation: LearningCopy(
                english:
                    'A list of solutions can feel overwhelming, especially when the person may simply need someone to listen first.',
                filipino:
                    'Ang maraming solusyon ay maaaring maging overwhelming, lalo na kung ang kailangan niya muna ay isang taong makikinig.',
              ),
            ),
          ],
          correctIndex: 2,
          hint: LearningCopy(
            english:
                'You don\'t need the perfect words. Focus on being present and making space for them.',
            filipino:
                'Hindi mo kailangang magkaroon ng perpektong sasabihin. Ang mahalaga ay nandiyan ka at binibigyan mo siya ng pagkakataong magsalita.',
          ),
          correctExplanation: LearningCopy(
            english:
                'Listening and gently acknowledging their experience shows that you care without taking control of the conversation.',
            filipino:
                'Ang pakikinig at pagkilala sa nararamdaman niya ay nagpapakita na nagmamalasakit ka nang hindi mo kinokontrol ang usapan.',
          ),
        ),
        // Question 3
        FriendSupportQuestion(
          id: 'listen-q3',
          contextQuote: LearningCopy(
            english: '“I feel like nobody understands me.”',
            filipino: '“Parang walang nakakaintindi sa akin.”',
          ),
          prompt: LearningCopy(
            english: 'What is the best response?',
            filipino: 'Ano ang pinakamagandang sagot?',
          ),
          options: [
            FriendSupportOption(
              id: 'A',
              text: LearningCopy(
                english: '“I understand exactly how you feel.”',
                filipino: '“Naiintindihan ko exactly kung ano ang nararamdaman mo.”',
              ),
              explanation: LearningCopy(
                english:
                    'Saying you understand exactly how someone feels can unintentionally minimize their unique experience.',
                filipino:
                    'Ang pagsasabing eksaktong naiintindihan mo ang nararamdaman niya ay maaaring makapagpaliit sa pagiging unique ng kanyang karanasan.',
              ),
            ),
            FriendSupportOption(
              id: 'B',
              text: LearningCopy(
                english: '“You shouldn\'t feel that way. You have people who care about you.”',
                filipino:
                    '“Hindi mo dapat maramdaman ’yan. May mga taong nagmamalasakit naman sa iyo.”',
              ),
              explanation: LearningCopy(
                english:
                    'It argues against their feelings instead of first acknowledging them.',
                filipino:
                    'Sa halip na kilalanin muna ang nararamdaman niya, kinokontra nito ang nararamdaman niya.',
              ),
            ),
            FriendSupportOption(
              id: 'C',
              text: LearningCopy(
                english:
                    '“I may not completely understand what you\'re going through, but I care about you and I\'m willing to listen.”',
                filipino:
                    '“Baka hindi ko lubos na naiintindihan ang pinagdadaanan mo, pero nagmamalasakit ako sa iyo at handa akong makinig.”',
              ),
              explanation: LearningCopy(
                english:
                    'It recognizes that you may not have the same experience while still communicating genuine care and willingness to listen.',
                filipino:
                    'Kinikilala nito na maaaring hindi mo nararanasan ang parehong bagay, habang ipinapakita pa rin ang tunay mong pagmamalasakit at kahandaang makinig.',
              ),
            ),
            FriendSupportOption(
              id: 'D',
              text: LearningCopy(
                english: '“You just need to think more positively.”',
                filipino: '“Kailangan mo lang mag-isip nang positibo.”',
              ),
              explanation: LearningCopy(
                english:
                    '“Think positively” oversimplifies emotional struggles and can make someone feel blamed for how they feel.',
                filipino:
                    'Masyadong pinapasimple ng “mag-isip nang positibo” ang isang mabigat na emosyonal na sitwasyon at maaaring magmukhang kasalanan niya ang kanyang nararamdaman.',
              ),
            ),
          ],
          correctIndex: 2,
          hint: LearningCopy(
            english:
                'You don\'t have to claim that you understand everything. Honest empathy is better than pretending.',
            filipino:
                'Hindi mo kailangang sabihin na lubos mong naiintindihan ang nararamdaman niya. Mas mabuting maging tapat at empathetic kaysa magkunwaring alam mo ang lahat.',
          ),
          correctExplanation: LearningCopy(
            english:
                'It recognizes that you may not have the same experience while still communicating genuine care and willingness to listen.',
            filipino:
                'Kinikilala nito na maaaring hindi mo nararanasan ang parehong bagay, habang ipinapakita pa rin ang tunay mong pagmamalasakit at kahandaang makinig.',
          ),
        ),
      ],
    ),

    // LESSON 2
    FriendSupportLesson(
      id: 'friend-support-safety',
      order: 2,
      title: LearningCopy(
        english: 'Take Suicidal Thoughts Seriously',
        filipino: 'Seryosohin ang Pagbanggit Tungkol sa Pagpapakamatay',
      ),
      subtitle: LearningCopy(
        english:
            'Stay calm, listen without judgment, ask directly, and help connect to safety support.',
        filipino:
            'Manatiling kalmado, makinig nang walang panghuhusga, direktang magtanong, at tumulong makakuha ng tamang suporta.',
      ),
      whatYoullLearn: LearningCopy(
        english:
            'When someone says they are thinking about suicide or hurting themselves, take them seriously.\n\nYou don\'t need to panic or have the perfect response. Stay calm, listen, show care, and help connect them with appropriate support.\n\nYou can also ask directly if they\'re thinking about hurting themselves. Asking about suicide doesn\'t mean you\'re putting the idea into their head.',
        filipino:
            'Kapag sinabi ng isang tao na naiisip niyang magpakamatay o saktan ang sarili niya, seryosohin ito.\n\nHindi mo kailangang mag-panic o magkaroon agad ng perpektong sagot. Manatiling kalmado, makinig, magpakita ng malasakit, at tumulong na makakuha siya ng tamang suporta.\n\nMaaari mo ring direktang tanungin kung naiisip ba niyang saktan ang sarili niya. Ang pagtatanong tungkol sa suicide ay hindi nangangahulugang ikaw ang naglagay ng ideya sa isip niya.',
      ),
      pointsHeader: LearningCopy(
        english: 'Remember',
        filipino: 'Tandaan',
      ),
      points: [
        LearningCopy(
          english: 'Listen without judging.',
          filipino: 'Makinig nang walang panghuhusga.',
        ),
        LearningCopy(
          english: 'Take suicidal statements seriously.',
          filipino: 'Seryosohin ang anumang pagbanggit tungkol sa suicide.',
        ),
        LearningCopy(
          english: 'Ask directly when you\'re concerned about their safety.',
          filipino: 'Direktang magtanong kung nag-aalala ka tungkol sa kaligtasan niya.',
        ),
        LearningCopy(
          english: 'Don\'t guilt-trip them.',
          filipino: 'Huwag siyang i-guilt trip.',
        ),
        LearningCopy(
          english: 'Don\'t promise to keep dangerous situations secret.',
          filipino: 'Huwag mangako na itatago mo ang isang delikadong sitwasyon.',
        ),
        LearningCopy(
          english: 'Get additional help when someone\'s safety may be at risk.',
          filipino:
              'Humingi ng karagdagang tulong kapag maaaring nasa panganib ang kanyang kaligtasan.',
        ),
      ],
      avoidHeader: null,
      avoidPoints: [],
      questions: [
        // Question 1
        FriendSupportQuestion(
          id: 'safety-q1',
          contextQuote: LearningCopy(
            english:
                '“I\'ve been thinking about killing myself. I don\'t know how much longer I can do this.”',
            filipino:
                '“Naiisip kong magpakamatay. Hindi ko na alam kung hanggang kailan ko kakayanin.”',
          ),
          prompt: LearningCopy(
            english: 'What is the most supportive response?',
            filipino: 'Ano ang pinaka-suportadong sagot?',
          ),
          options: [
            FriendSupportOption(
              id: 'A',
              text: LearningCopy(
                english: '“Think about your family. They would be devastated if you did that.”',
                filipino: '“Isipin mo ang pamilya mo. Masisira sila kapag ginawa mo ’yan.”',
              ),
              explanation: LearningCopy(
                english:
                    'Using family members to create guilt can increase shame and emotional pressure rather than helping the person feel supported.',
                filipino:
                    'Ang paggamit ng guilt tungkol sa pamilya ay maaaring magdagdag ng pressure at hiya sa halip na makatulong sa taong nahihirapan.',
              ),
            ),
            FriendSupportOption(
              id: 'B',
              text: LearningCopy(
                english: '“You should pray more and go to church.”',
                filipino: '“Dapat mas magdasal ka at magsimba.”',
              ),
              explanation: LearningCopy(
                english:
                    'Faith can be meaningful to someone, but telling them to simply pray or attend church does not address an immediate safety concern and should never replace appropriate crisis support.',
                filipino:
                    'Maaaring mahalaga ang pananampalataya sa isang tao, pero ang simpleng pagsasabing magdasal o magsimba ay hindi sapat para tugunan ang agarang safety concern at hindi dapat pumalit sa naaangkop na tulong.',
              ),
            ),
            FriendSupportOption(
              id: 'C',
              text: LearningCopy(
                english:
                    '“I might not fully understand what you\'re going through, but I\'m here to listen and help you through this. I don\'t want you to face this alone.”',
                filipino:
                    '“Baka hindi ko lubos na naiintindihan ang pinagdadaanan mo, pero nandito ako para makinig at tulungan kang harapin ’to. Ayokong harapin mo ’to nang mag-isa.”',
              ),
              explanation: LearningCopy(
                english:
                    'It responds with compassion, avoids judgment, and communicates that the person doesn\'t have to face the situation alone. In a real crisis, this should be followed by getting appropriate help and making sure they\'re not left alone when immediate danger is present.',
                filipino:
                    'Nagpapakita ito ng malasakit, hindi nanghuhusga, at ipinaparamdam na hindi niya kailangang harapin ang sitwasyon nang mag-isa. Sa totoong crisis, dapat itong sundan ng pagkuha ng naaangkop na tulong at pagtiyak na hindi siya maiiwan mag-isa kung may agarang panganib.',
              ),
            ),
            FriendSupportOption(
              id: 'D',
              text: LearningCopy(
                english: '“Don\'t say that. You have so much to live for.”',
                filipino: '“Huwag mong sabihin ’yan. Ang dami mo pang dahilan para mabuhay.”',
              ),
              explanation: LearningCopy(
                english:
                    'It may be intended as encouragement, but it argues against the person\'s feelings instead of first taking their pain seriously.',
                filipino:
                    'Maaaring mabuti ang intensyon nito, pero kinokontra nito ang nararamdaman ng tao sa halip na kilalanin muna ang kanyang sakit.',
              ),
            ),
          ],
          correctIndex: 2,
          hint: LearningCopy(
            english:
                'Focus on acknowledging their pain and staying connected, rather than trying to guilt, debate, or immediately dismiss what they said.',
            filipino:
                'Subukang kilalanin ang sakit na nararamdaman niya at manatiling konektado, sa halip na takutin, i-guilt trip, o kontrahin agad ang nararamdaman niya.',
          ),
          correctExplanation: LearningCopy(
            english:
                'It responds with compassion, avoids judgment, and communicates that the person doesn\'t have to face the situation alone. In a real crisis, this should be followed by getting appropriate help and making sure they\'re not left alone when immediate danger is present.',
            filipino:
                'Nagpapakita ito ng malasakit, hindi nanghuhusga, at ipinaparamdam na hindi niya kailangang harapin ang sitwasyon nang mag-isa. Sa totoong crisis, dapat itong sundan ng pagkuha ng naaangkop na tulong at pagtiyak na hindi siya maiiwan mag-isa kung may agarang panganib.',
          ),
        ),
        // Question 2
        FriendSupportQuestion(
          id: 'safety-q2',
          contextQuote: LearningCopy(
            english: '“Sometimes I wish I could just disappear.”',
            filipino: '“Minsan gusto ko na lang mawala.”',
          ),
          prompt: LearningCopy(
            english: 'What is the best response if you\'re concerned about their safety?',
            filipino:
                'Ano ang pinakamagandang sagot kung nag-aalala ka tungkol sa kaligtasan niya?',
          ),
          options: [
            FriendSupportOption(
              id: 'A',
              text: LearningCopy(
                english: '“Don\'t talk like that. You\'re just having a bad day.”',
                filipino: '“Huwag kang magsalita nang ganyan. Masama lang talaga araw mo.”',
              ),
              explanation: LearningCopy(
                english:
                    'It dismisses what your friend said and assumes you already know what they\'re experiencing.',
                filipino:
                    'Minamaliit nito ang sinabi ng kaibigan mo at ipinapalagay na alam mo na kung ano ang pinagdadaanan niya.',
              ),
            ),
            FriendSupportOption(
              id: 'B',
              text: LearningCopy(
                english: '“What do you mean? Are you thinking about hurting yourself?”',
                filipino: '“Ano ang ibig mong sabihin? Naiisip mo bang saktan ang sarili mo?”',
              ),
              explanation: LearningCopy(
                english:
                    'It directly checks whether your friend may be thinking about self-harm or suicide. Asking calmly and without judgment can help you understand how serious the situation is and what support is needed.',
                filipino:
                    'Direkta nitong sinusuri kung maaaring naiisip ng kaibigan mo ang self-harm o suicide. Ang mahinahon at walang-panghuhusgang pagtatanong ay makakatulong para maintindihan kung gaano kaseryoso ang sitwasyon at kung anong suporta ang kailangan.',
              ),
            ),
            FriendSupportOption(
              id: 'C',
              text: LearningCopy(
                english:
                    '“You shouldn\'t say things like that because people might misunderstand you.”',
                filipino:
                    '“Huwag kang magsabi ng ganyan kasi baka iba ang isipin ng mga tao.”',
              ),
              explanation: LearningCopy(
                english:
                    'It focuses on how their words might be perceived rather than on their wellbeing.',
                filipino:
                    'Mas nakatuon ito sa kung ano ang iisipin ng ibang tao kaysa sa kaligtasan at kapakanan ng kaibigan mo.',
              ),
            ),
            FriendSupportOption(
              id: 'D',
              text: LearningCopy(
                english: '“Let\'s not talk about negative things right now.”',
                filipino: '“Huwag na nating pag-usapan ang mga negative na bagay.”',
              ),
              explanation: LearningCopy(
                english:
                    'Changing the subject can leave an important safety concern unaddressed.',
                filipino:
                    'Ang pagpapalit ng usapan ay maaaring mag-iwan ng seryosong safety concern na hindi natutugunan.',
              ),
            ),
          ],
          correctIndex: 1,
          hint: LearningCopy(
            english:
                'When you\'re genuinely concerned about someone\'s safety, don\'t avoid the question just because it feels uncomfortable.',
            filipino:
                'Kapag tunay kang nag-aalala tungkol sa kaligtasan ng isang tao, huwag iwasan ang tanong dahil lang hindi ito komportable.',
          ),
          correctExplanation: LearningCopy(
            english:
                'It directly checks whether your friend may be thinking about self-harm or suicide. Asking calmly and without judgment can help you understand how serious the situation is and what support is needed.',
            filipino:
                'Direkta nitong sinusuri kung maaaring naiisip ng kaibigan mo ang self-harm o suicide. Ang mahinahon at walang-panghuhusgang pagtatanong ay makakatulong para maintindihan kung gaano kaseryoso ang sitwasyon at kung anong suporta ang kailangan.',
          ),
        ),
        // Question 3
        FriendSupportQuestion(
          id: 'safety-q3',
          prompt: LearningCopy(
            english:
                'Your friend tells you they are thinking about suicide and asks you to promise that you won\'t tell anyone. What should you do?',
            filipino:
                'Sinabi ng kaibigan mo na naiisip niyang magpakamatay at hiniling niyang mangako kang hindi mo ito sasabihin kahit kanino. Ano ang dapat mong gawin?',
          ),
          options: [
            FriendSupportOption(
              id: 'A',
              text: LearningCopy(
                english: '“I promise. You can trust me.”',
                filipino: '“Nangangako ako. Pwede mo akong pagkatiwalaan.”',
              ),
              explanation: LearningCopy(
                english:
                    'A promise of secrecy can prevent the person from receiving the help they need.',
                filipino:
                    'Ang pangakong mananatiling sikreto ang sitwasyon ay maaaring makahadlang sa pagkuha ng kinakailangang tulong.',
              ),
            ),
            FriendSupportOption(
              id: 'B',
              text: LearningCopy(
                english: '“Fine, I\'ll tell everyone so they can watch you.”',
                filipino: '“Sige, sasabihin ko sa lahat para mabantayan ka nila.”',
              ),
              explanation: LearningCopy(
                english:
                    'Telling everyone unnecessarily can violate their privacy and potentially make them feel exposed or betrayed.',
                filipino:
                    'Ang pagsasabi sa lahat ay maaaring lumabag sa privacy niya at magparamdam sa kanya na ipinahiya o ipinagkanulo siya.',
              ),
            ),
            FriendSupportOption(
              id: 'C',
              text: LearningCopy(
                english:
                    '“I care about your trust, but if I think you\'re in danger, I may need to involve someone who can help keep you safe.”',
                filipino:
                    '“Mahalaga sa akin ang tiwala mo, pero kung sa tingin ko ay nasa panganib ka, baka kailangan kong magsabi sa taong makakatulong na mapanatili kang ligtas.”',
              ),
              explanation: LearningCopy(
                english:
                    'It respects the person\'s trust while making it clear that safety comes first when there may be immediate danger. In a serious situation, involving a trusted adult, family member, professional, crisis service, or emergency service may be necessary.',
                filipino:
                    'Nirerespeto nito ang tiwala ng kaibigan mo habang nililinaw na mas mahalaga ang kaligtasan kapag may posibilidad ng seryosong panganib. Sa ganitong sitwasyon, maaaring kailanganing magsabi sa isang trusted person, kapamilya, propesyonal, crisis service, o emergency service.',
              ),
            ),
            FriendSupportOption(
              id: 'D',
              text: LearningCopy(
                english: '“Okay, then I won\'t talk to you about it anymore.”',
                filipino: '“Okay, hindi na lang kita kakausapin tungkol dito.”',
              ),
              explanation: LearningCopy(
                english:
                    'Ending the conversation can make the person feel abandoned at a moment when connection may be especially important.',
                filipino:
                    'Ang pagtigil sa pakikipag-usap ay maaaring magparamdam na iniwan mo siya sa panahong kailangan niya ng connection at suporta.',
              ),
            ),
          ],
          correctIndex: 2,
          hint: LearningCopy(
            english:
                'Think about the difference between respecting someone\'s privacy and keeping a dangerous secret.',
            filipino:
                'Isipin ang pagkakaiba ng pagrespeto sa privacy at pagtatago ng isang delikadong sitwasyon.',
          ),
          correctExplanation: LearningCopy(
            english:
                'It respects the person\'s trust while making it clear that safety comes first when there may be immediate danger. In a serious situation, involving a trusted adult, family member, professional, crisis service, or emergency service may be necessary.',
            filipino:
                'Nirerespeto nito ang tiwala ng kaibigan mo habang nililinaw na mas mahalaga ang kaligtasan kapag may posibilidad ng seryosong panganib. Sa ganitong sitwasyon, maaaring kailanganing magsabi sa isang trusted person, kapamilya, propesyonal, crisis service, o emergency service.',
          ),
        ),
      ],
    ),

    // LESSON 3
    FriendSupportLesson(
      id: 'friend-support-boundaries',
      order: 3,
      title: LearningCopy(
        english: 'You Don\'t Have to Handle It Alone',
        filipino: 'Hindi Mo Kailangang Harapin Ito Mag-isa',
      ),
      subtitle: LearningCopy(
        english:
            'Being a supportive friend doesn\'t mean carrying everything on your own shoulders.',
        filipino:
            'Ang pagiging mabuting kaibigan ay hindi nangangahulugang kailangan mong dalhin ang lahat nang mag-isa.',
      ),
      whatYoullLearn: LearningCopy(
        english:
            'Being a supportive friend doesn\'t mean becoming someone\'s therapist or taking complete responsibility for their wellbeing.\n\nYou can listen, stay present, encourage professional help, involve trusted people, and ask for help yourself.\n\nSupporting someone doesn\'t mean carrying everything alone.',
        filipino:
            'Ang pagiging mabuting kaibigan ay hindi nangangahulugang kailangan mong maging therapist niya o ikaw lang ang maging responsable sa kanyang kalagayan.\n\nMaaari kang makinig, manatiling present, hikayatin siyang humingi ng propesyonal na tulong, magsama ng taong pinagkakatiwalaan niya, at humingi rin ng tulong para sa sarili mo.\n\nAng pagsuporta sa isang tao ay hindi nangangahulugang kailangan mong dalhin ang lahat nang mag-isa.',
      ),
      pointsHeader: LearningCopy(
        english: 'Helpful Actions',
        filipino: 'Mga Makakatulong na Gawin',
      ),
      points: [
        LearningCopy(
          english: 'Listen and check in.',
          filipino: 'Makinig at mag-check in sa kanya.',
        ),
        LearningCopy(
          english: 'Encourage them to seek professional support.',
          filipino: 'Hikayatin siyang humingi ng propesyonal na suporta.',
        ),
        LearningCopy(
          english: 'Help them contact someone they trust.',
          filipino: 'Tulungan siyang makipag-ugnayan sa taong pinagkakatiwalaan niya.',
        ),
        LearningCopy(
          english: 'Stay with them when appropriate during a crisis.',
          filipino: 'Manatili sa tabi niya kung naaangkop habang may crisis.',
        ),
        LearningCopy(
          english: 'Ask for help when the situation is beyond what you can safely handle.',
          filipino: 'Humingi ng tulong kapag lampas na sa kaya mong hawakan nang ligtas.',
        ),
      ],
      avoidHeader: LearningCopy(
        english: 'Avoid',
        filipino: 'Mga Dapat Iwasan',
      ),
      avoidPoints: [
        LearningCopy(
          english: '“I\'m the only person you need.”',
          filipino: '“Ako lang ang kailangan mo.”',
        ),
        LearningCopy(
          english: '“Don\'t tell anyone else.”',
          filipino: '“Huwag mo nang sabihin sa iba.”',
        ),
        LearningCopy(
          english: 'Taking complete responsibility for their recovery.',
          filipino: 'Akuin ang buong responsibilidad sa kanyang recovery.',
        ),
        LearningCopy(
          english: 'Abandoning them with “Just see a therapist.”',
          filipino: 'Iwan siya sa pamamagitan ng pagsasabing “Mag-therapy ka na lang.”',
        ),
      ],
      questions: [
        // Question 1
        FriendSupportQuestion(
          id: 'boundaries-q1',
          contextQuote: LearningCopy(
            english: '“I don\'t think I can handle this anymore.”',
            filipino: '“Hindi ko na yata kaya ’to.”',
          ),
          prompt: LearningCopy(
            english:
                'Your friend has been struggling for weeks. They\'ve stopped attending school, isolated themselves, and say: What is the best response?',
            filipino:
                'Ilang linggo nang nahihirapan ang kaibigan mo. Hindi na siya pumapasok sa school, lumalayo sa ibang tao, at sinabi niya: Ano ang pinakamagandang sagot?',
          ),
          options: [
            FriendSupportOption(
              id: 'A',
              text: LearningCopy(
                english: '“You need professional help. Just make an appointment.”',
                filipino:
                    '“Kailangan mo ng professional help. Magpa-appointment ka na lang.”',
              ),
              explanation: LearningCopy(
                english:
                    'Professional help may be appropriate, but simply telling someone to “make an appointment” can feel cold or dismissive.',
                filipino:
                    'Maaaring tama na kailangan niya ng professional help, pero ang simpleng pagsasabing “magpa-appointment ka na lang” ay maaaring magmukhang malamig o dismissive.',
              ),
            ),
            FriendSupportOption(
              id: 'B',
              text: LearningCopy(
                english: '“Don\'t worry, I\'ll handle this. You don\'t need to tell anyone else.”',
                filipino:
                    '“Huwag kang mag-alala, ako na ang bahala. Hindi mo kailangang magsabi sa iba.”',
              ),
              explanation: LearningCopy(
                english:
                    'One friend should not become someone\'s only source of support, especially when serious safety concerns may exist.',
                filipino:
                    'Hindi dapat maging iisang source of support ang isang kaibigan, lalo na kung may seryosong concern tungkol sa kanyang kaligtasan.',
              ),
            ),
            FriendSupportOption(
              id: 'C',
              text: LearningCopy(
                english:
                    '“I\'m really glad you told me. I care about you, and I think it would be good to get some support from someone who can help. I can stay with you while we figure out who to reach out to.”',
                filipino:
                    '“Masaya akong sinabi mo sa akin. Nagmamalasakit ako sa iyo, at sa tingin ko makakatulong kung makakuha ka ng suporta mula sa taong makakatulong talaga. Sasamahan kita habang iniisip natin kung sino ang pwede nating lapitan.”',
              ),
              explanation: LearningCopy(
                english:
                    'It shows care, encourages additional support, and offers to help the person take the next step instead of leaving them to figure everything out alone.',
                filipino:
                    'Nagpapakita ito ng malasakit, hinihikayat ang karagdagang suporta, at nag-aalok ng tulong sa susunod na hakbang sa halip na iwan siyang mag-isa na mag-figure out ng lahat.',
              ),
            ),
            FriendSupportOption(
              id: 'D',
              text: LearningCopy(
                english: '“Maybe you just need to take a break from everything for a few days.”',
                filipino:
                    '“Baka kailangan mo lang magpahinga muna sa lahat ng bagay nang ilang araw.”',
              ),
              explanation: LearningCopy(
                english:
                    'Rest can sometimes help with stress, but this response may underestimate the seriousness of the situation.',
                filipino:
                    'Maaaring makatulong ang pahinga sa stress, pero maaaring hindi nito makilala kung gaano kaseryoso ang sitwasyon.',
              ),
            ),
          ],
          correctIndex: 2,
          hint: LearningCopy(
            english:
                'Look for an answer that combines compassion + practical support, without pretending that you alone can fix everything.',
            filipino:
                'Hanapin ang sagot na pinagsasama ang malasakit + praktikal na suporta, nang hindi nagpapanggap na ikaw lang ang makakaayos ng lahat.',
          ),
          correctExplanation: LearningCopy(
            english:
                'It shows care, encourages additional support, and offers to help the person take the next step instead of leaving them to figure everything out alone.',
            filipino:
                'Nagpapakita ito ng malasakit, hinihikayat ang karagdagang suporta, at nag-aalok ng tulong sa susunod na hakbang sa halip na iwan siyang mag-isa na mag-figure out ng lahat.',
          ),
        ),
        // Question 2
        FriendSupportQuestion(
          id: 'boundaries-q2',
          contextQuote: LearningCopy(
            english: '“I don\'t want to talk to anyone else. You\'re the only person I trust.”',
            filipino:
                '“Ayoko nang makipag-usap sa iba. Ikaw lang ang pinagkakatiwalaan ko.”',
          ),
          prompt: LearningCopy(
            english: 'What is the healthiest response?',
            filipino: 'Ano ang pinakamalusog na sagot?',
          ),
          options: [
            FriendSupportOption(
              id: 'A',
              text: LearningCopy(
                english: '“That\'s okay. I\'ll be the only person you need.”',
                filipino: '“Okay lang. Ako na lang ang kailangan mo.”',
              ),
              explanation: LearningCopy(
                english:
                    'It creates unhealthy dependence and puts an unrealistic amount of responsibility on one person.',
                filipino:
                    'Maaari itong lumikha ng unhealthy dependence at maglagay ng sobrang bigat na responsibilidad sa isang tao.',
              ),
            ),
            FriendSupportOption(
              id: 'B',
              text: LearningCopy(
                english: '“Then you need to figure this out yourself.”',
                filipino: '“Kung gano’n, ikaw na ang bahalang mag-handle nito.”',
              ),
              explanation: LearningCopy(
                english:
                    'It abandons the person when they\'re already struggling.',
                filipino:
                    'Iniiwan nito ang taong nahihirapan na harapin ang sitwasyon nang mag-isa.',
              ),
            ),
            FriendSupportOption(
              id: 'C',
              text: LearningCopy(
                english:
                    '“I\'m glad you trust me. I\'ll listen and support you, but I also want to help you find other people who can support you too.”',
                filipino:
                    '“Masaya akong pinagkakatiwalaan mo ako. Makikinig at susuporta ako sa iyo, pero gusto ko rin kitang tulungang makahanap ng ibang taong pwede mong sandalan.”',
              ),
              explanation: LearningCopy(
                english:
                    'It values the trust between you while encouraging a wider support network. Different people can provide different kinds of help.',
                filipino:
                    'Pinapahalagahan nito ang tiwala ng kaibigan mo habang hinihikayat siyang magkaroon ng mas malawak na support system. Iba\'t ibang tao ang maaaring magbigay ng iba\'t ibang uri ng tulong.',
              ),
            ),
            FriendSupportOption(
              id: 'D',
              text: LearningCopy(
                english: '“You shouldn\'t depend on friends for emotional problems.”',
                filipino:
                    '“Hindi dapat umaasa sa kaibigan kapag may emotional problems.”',
              ),
              explanation: LearningCopy(
                english:
                    'Friends can absolutely provide emotional support. The goal isn\'t to remove friendship from the equation—it\'s to make sure the person has enough support.',
                filipino:
                    'Maaari namang magbigay ng emotional support ang mga kaibigan. Hindi kailangang alisin ang friendship bilang source of support—mas mahalaga na magkaroon siya ng sapat at iba\'t ibang suporta.',
              ),
            ),
          ],
          correctIndex: 2,
          hint: LearningCopy(
            english:
                'A good friend can provide support without becoming the person\'s entire support system.',
            filipino:
                'Maaaring maging supportive na kaibigan nang hindi nagiging buong support system ng isang tao.',
          ),
          correctExplanation: LearningCopy(
            english:
                'It values the trust between you while encouraging a wider support network. Different people can provide different kinds of help.',
            filipino:
                'Pinapahalagahan nito ang tiwala ng kaibigan mo habang hinihikayat siyang magkaroon ng mas malawak na support system. Iba\'t ibang tao ang maaaring magbigay ng iba\'t ibang uri ng tulong.',
          ),
        ),
        // Question 3
        FriendSupportQuestion(
          id: 'boundaries-q3',
          prompt: LearningCopy(
            english:
                'You are supporting a friend who is struggling, but you\'re starting to feel overwhelmed yourself. What should you do?',
            filipino:
                'Sinusuportahan mo ang isang kaibigan na nahihirapan, pero nagsisimula ka na ring ma-overwhelm. Ano ang dapat mong gawin?',
          ),
          options: [
            FriendSupportOption(
              id: 'A',
              text: LearningCopy(
                english: 'Keep everything to yourself because their problems are more important.',
                filipino: 'Sarilinin ang lahat dahil mas mahalaga naman ang problema niya.',
              ),
              explanation: LearningCopy(
                english:
                    'Ignoring your own limits can lead to exhaustion and make it harder for you to support anyone effectively.',
                filipino:
                    'Ang pag-ignore sa sarili mong limitasyon ay maaaring humantong sa emotional exhaustion at gawing mas mahirap para sa iyo na makatulong nang maayos.',
              ),
            ),
            FriendSupportOption(
              id: 'B',
              text: LearningCopy(
                english: 'Tell your friend that they\'re becoming a burden.',
                filipino: 'Sabihin sa kaibigan mo na nagiging pabigat na siya.',
              ),
              explanation: LearningCopy(
                english:
                    'Calling someone a burden can increase shame and make them less likely to seek help.',
                filipino:
                    'Ang pagsasabing “pabigat ka” ay maaaring magdagdag ng hiya at maging dahilan para mas lalo siyang mahirapang humingi ng tulong.',
              ),
            ),
            FriendSupportOption(
              id: 'C',
              text: LearningCopy(
                english:
                    'Set healthy boundaries and reach out to someone you trust for support while continuing to care about your friend.',
                filipino:
                    'Magtakda ng healthy boundaries at humingi ng suporta sa taong pinagkakatiwalaan mo habang patuloy na nagmamalasakit sa kaibigan mo.',
              ),
              explanation: LearningCopy(
                english:
                    'You can care deeply about someone while recognizing your own limits. Getting support for yourself can help you remain a healthier and more reliable friend.',
                filipino:
                    'Maaari kang lubos na magmalasakit sa isang tao habang kinikilala ang sarili mong limitasyon. Ang paghingi ng suporta para sa sarili mo ay makakatulong para manatili kang mas healthy at maaasahang kaibigan.',
              ),
            ),
            FriendSupportOption(
              id: 'D',
              text: LearningCopy(
                english: 'Stop responding to your friend completely.',
                filipino: 'Bigla na lang tumigil sa pagsagot sa kanya.',
              ),
              explanation: LearningCopy(
                english:
                    'Suddenly disappearing can make the person feel abandoned. If you need space, communicate your boundaries rather than disappearing without explanation.',
                filipino:
                    'Ang biglaang pagkawala ay maaaring magparamdam sa kaibigan mo na iniwan mo siya. Kung kailangan mo ng space, mas mabuting sabihin nang maayos ang iyong boundaries kaysa bigla na lang mawala.',
              ),
            ),
          ],
          correctIndex: 2,
          hint: LearningCopy(
            english:
                'Remember: supporting someone doesn\'t require sacrificing your own wellbeing or handling everything alone.',
            filipino:
                'Tandaan: ang pagsuporta sa isang tao ay hindi nangangahulugang kailangan mong isakripisyo ang sarili mong kapakanan o harapin ang lahat nang mag-isa.',
          ),
          correctExplanation: LearningCopy(
            english:
                'You can care deeply about someone while recognizing your own limits. Getting support for yourself can help you remain a healthier and more reliable friend.',
            filipino:
                'Maaari kang lubos na magmalasakit sa isang tao habang kinikilala ang sarili mong limitasyon. Ang paghingi ng suporta para sa sarili mo ay makakatulong para manatili kang mas healthy at maaasahang kaibigan.',
          ),
        ),
      ],
    ),
  ];

  static FriendSupportLesson? byId(String id) {
    for (final lesson in lessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }
}

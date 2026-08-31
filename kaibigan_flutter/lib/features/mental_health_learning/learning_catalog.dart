import 'package:flutter/material.dart';

import 'learning_model.dart';

const _whatItIs = LearningCopy(
  english: 'What it can feel like',
  filipino: 'Ano ang maaaring maramdaman',
);

const _whatHelps = LearningCopy(
  english: 'A gentle next step',
  filipino: 'Isang banayad na susunod na hakbang',
);

abstract final class LearningCatalog {
  static const paths = <LearningPath>[
    LearningPath(
      id: 'understand-me',
      title: LearningCopy(
        english: 'Understand what I am feeling',
        filipino: 'Unawain ang nararamdaman ko',
      ),
      description: LearningCopy(
        english: 'Start with emotions, stress, anxiety, and low mood.',
        filipino: 'Magsimula sa emotions, stress, anxiety, at low mood.',
      ),
      icon: Icons.self_improvement_rounded,
      lessonIds: [
        'mental-health-basics',
        'emotional-regulation',
        'stress-burnout',
        'understanding-anxiety',
        'low-mood-depression',
      ],
    ),
    LearningPath(
      id: 'conditions',
      title: LearningCopy(
        english: 'Learn about a condition',
        filipino: 'Matuto tungkol sa kondisyon',
      ),
      description: LearningCopy(
        english: 'Clear explanations without labels or self-diagnosis.',
        filipino: 'Malinaw na paliwanag nang walang paglalagay ng label.',
      ),
      icon: Icons.psychology_alt_outlined,
      lessonIds: [
        'understanding-anxiety',
        'social-anxiety',
        'low-mood-depression',
        'understanding-adhd',
        'understanding-ocd',
        'understanding-bipolar',
        'understanding-ptsd',
        'understanding-eating-disorders',
        'understanding-schizophrenia',
        'substance-use-mental-health',
      ],
    ),
    LearningPath(
      id: 'cope-now',
      title: LearningCopy(
        english: 'Build skills for difficult moments',
        filipino: 'Bumuo ng skills para sa mahirap na sandali',
      ),
      description: LearningCopy(
        english: 'Practical tools for panic, sleep, and emotional overload.',
        filipino: 'Practical tools para sa panic, tulog, at overwhelm.',
      ),
      icon: Icons.bolt_rounded,
      lessonIds: [
        'panic-attacks',
        'emotional-regulation',
        'self-compassion',
        'sleep-and-mind',
        'healthy-boundaries',
      ],
    ),
    LearningPath(
      id: 'support-someone',
      title: LearningCopy(
        english: 'Support someone I care about',
        filipino: 'Suportahan ang mahalaga sa akin',
      ),
      description: LearningCopy(
        english: 'Listen well, respond safely, and help them connect.',
        filipino: 'Makinig, tumugon nang ligtas, at tumulong kumonekta.',
      ),
      icon: Icons.diversity_1_outlined,
      lessonIds: [
        'supporting-someone',
        'asking-for-help',
        'types-of-care',
        'suicide-safety',
        'philippines-support-contacts',
      ],
    ),
  ];

  static final lessons = <LearningLesson>[
    LearningLesson(
      id: 'mental-health-basics',
      category: LearningCategory.foundations,
      title: const LearningCopy(
        english: 'Mental health, simply explained',
        filipino: 'Mental health, sa simpleng paliwanag',
      ),
      summary: const LearningCopy(
        english: 'Understand what mental health is and why it can change.',
        filipino:
            'Unawain kung ano ang mental health at kung bakit ito nagbabago.',
      ),
      readMinutes: 4,
      icon: Icons.psychology_alt_rounded,
      sections: const [
        LearningSection(
          heading: LearningCopy(
            english: 'It is part of everyday health',
            filipino: 'Bahagi ito ng pang-araw-araw na kalusugan',
          ),
          body: LearningCopy(
            english:
                'Mental health includes how we think, feel, relate to people, and respond to stress. Everyone has mental health, just as everyone has physical health.',
            filipino:
                'Kasama sa mental health ang paraan ng pag-iisip, pagdama, pakikitungo sa iba, at pagharap sa stress. Lahat tayo ay may mental health, tulad ng pisikal na kalusugan.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'It moves, not stays fixed',
            filipino: 'Nagbabago ito, hindi permanente',
          ),
          body: LearningCopy(
            english:
                'Sleep, relationships, health, money, school, work, loss, and belonging can all affect how we are doing. A difficult season is not a personal failure.',
            filipino:
                'Maaaring maapektuhan ito ng tulog, relasyon, kalusugan, pera, pag-aaral, trabaho, pagkawala, at pakiramdam na kabilang ka. Ang mahirap na panahon ay hindi personal na kabiguan.',
          ),
        ),
        LearningSection(
          heading: _whatHelps,
          body: LearningCopy(
            english:
                'Notice changes with curiosity. Small routines, honest conversations, and professional care can each help; they do not need to happen all at once.',
            filipino:
                'Pansinin ang mga pagbabago nang walang paghuhusga. Makakatulong ang maliliit na routine, tapat na usapan, at propesyonal na suporta—hindi kailangang sabay-sabay.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Look at patterns, not one isolated day',
            filipino: 'Tingnan ang pattern, hindi isang araw lang',
          ),
          body: LearningCopy(
            english:
                'A check-in becomes more useful when you compare it with sleep, stress, connection, health, and daily functioning over time. Ask what changed, how long it has lasted, and what helps. Patterns can guide a conversation with a professional, but they are not a diagnosis by themselves.',
            filipino:
                'Mas kapaki-pakinabang ang check-in kapag inihambing sa tulog, stress, koneksyon, kalusugan, at daily functioning sa paglipas ng panahon. Itanong kung ano ang nagbago, gaano katagal, at ano ang nakakatulong. Gabay ang pattern sa usapan sa professional, ngunit hindi ito diagnosis.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english: 'What has been supporting your mental health lately?',
        filipino: 'Ano ang nakakatulong sa mental health mo nitong mga araw?',
      ),
      medlinePlusQuery: 'mental health',
      sourceUrl: Uri.parse(
          'https://www.nimh.nih.gov/health/topics/caring-for-your-mental-health'),
      sourceLabel: 'National Institute of Mental Health',
    ),
    LearningLesson(
      id: 'understanding-anxiety',
      category: LearningCategory.conditions,
      title: const LearningCopy(
        english: 'Understanding anxiety',
        filipino: 'Pag-unawa sa anxiety',
      ),
      summary: const LearningCopy(
        english: 'Learn why alarm feelings appear and when support may help.',
        filipino:
            'Alamin kung bakit lumilitaw ang pakiramdam ng alarma at kung kailan makakatulong ang suporta.',
      ),
      readMinutes: 6,
      icon: Icons.air_rounded,
      sections: const [
        LearningSection(
          heading: _whatItIs,
          body: LearningCopy(
            english:
                'Anxiety is the mind and body preparing for possible danger. It may bring racing thoughts, a tight chest, restlessness, irritability, or an urge to avoid something.',
            filipino:
                'Ang anxiety ay paghahanda ng isip at katawan sa posibleng panganib. Maaaring mabilis ang isip, sumikip ang dibdib, hindi mapakali, madaling mainis, o gustong umiwas.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'When it becomes a concern',
            filipino: 'Kapag nagiging alalahanin ito',
          ),
          body: LearningCopy(
            english:
                'Anxiety deserves attention when it is intense, keeps returning, or interferes with sleep, relationships, study, work, or everyday tasks. Only a qualified professional can diagnose a condition.',
            filipino:
                'Nararapat itong bigyang-pansin kapag matindi, paulit-ulit, o nakakaistorbo sa tulog, relasyon, pag-aaral, trabaho, o pang-araw-araw na gawain. Propesyonal lamang ang maaaring mag-diagnose.',
          ),
        ),
        LearningSection(
          heading: _whatHelps,
          body: LearningCopy(
            english:
                'Try a longer exhale, name what is happening, and choose one manageable action. If anxiety keeps shrinking your life, consider talking with a mental health professional.',
            filipino:
                'Subukang pahabain ang paghinga palabas, pangalanan ang nararanasan, at pumili ng isang kayang hakbang. Kung paliit nang paliit ang mundo mo dahil dito, kausapin ang mental health professional.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Map the loop with curiosity',
            filipino: 'I-map ang loop nang may curiosity',
          ),
          body: LearningCopy(
            english:
                'Write four short notes: the situation, the prediction your mind made, what happened in your body, and what you did next. Then add what actually happened. This can reveal avoidance, reassurance-seeking, or catastrophic predictions that keep anxiety going—and give you one place to experiment gently.',
            filipino:
                'Isulat ang apat: sitwasyon, prediction ng isip, nangyari sa katawan, at ginawa mo pagkatapos. Idagdag kung ano talaga ang nangyari. Maaaring makita rito ang avoidance, reassurance-seeking, o catastrophic predictions na nagpapatuloy sa anxiety—at isang puwedeng subukang baguhin nang dahan-dahan.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Different anxiety disorders need proper assessment',
            filipino: 'Kailangan ng tamang assessment sa anxiety disorders',
          ),
          body: LearningCopy(
            english:
                'Generalized anxiety, panic disorder, social anxiety, and specific phobias can overlap, but they are not identical. Physical conditions, medicines, caffeine, and substance use can also produce anxiety-like symptoms. A clinician can review the pattern and discuss evidence-based options such as psychotherapy, medication, or both. Do not start, stop, or share prescription medicine without medical guidance.',
            filipino:
                'Maaaring mag-overlap ang generalized anxiety, panic disorder, social anxiety, at specific phobias, pero hindi sila pare-pareho. Maaari ring magmukhang anxiety ang pisikal na kondisyon, gamot, caffeine, at substance use. Maaaring suriin ng clinician ang pattern at talakayin ang psychotherapy, gamot, o pareho. Huwag magsimula, huminto, o magbahagi ng prescription medicine nang walang medical guidance.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english: 'What does anxiety usually ask you to avoid?',
        filipino: 'Ano ang madalas ipaiwas sa iyo ng anxiety?',
      ),
      medlinePlusQuery: 'anxiety',
      sourceUrl:
          Uri.parse('https://www.nimh.nih.gov/health/topics/anxiety-disorders'),
      sourceLabel: 'National Institute of Mental Health',
    ),
    LearningLesson(
      id: 'low-mood-depression',
      category: LearningCategory.conditions,
      title: const LearningCopy(
        english: 'Low mood and depression',
        filipino: 'Mababang mood at depression',
      ),
      summary: const LearningCopy(
        english: 'Know the difference between a hard day and signs to watch.',
        filipino:
            'Kilalanin ang kaibahan ng mahirap na araw at mga senyales na dapat bantayan.',
      ),
      readMinutes: 6,
      icon: Icons.water_drop_outlined,
      sections: const [
        LearningSection(
          heading: _whatItIs,
          body: LearningCopy(
            english:
                'Sadness and low energy can be natural responses to disappointment, stress, or loss. Depression is more than an occasional low day and can affect interest, sleep, appetite, concentration, hope, and daily functioning.',
            filipino:
                'Ang lungkot at mababang enerhiya ay maaaring natural na tugon sa kabiguan, stress, o pagkawala. Higit sa paminsang malungkot na araw ang depression at maaari nitong maapektuhan ang interes, tulog, gana, focus, pag-asa, at araw-araw na gawain.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'You do not have to prove it is serious',
            filipino: 'Hindi mo kailangang patunayang malala ito',
          ),
          body: LearningCopy(
            english:
                'If changes last, feel heavy, or make life harder, reaching out is reasonable. Support can begin with a trusted person, a doctor, counselor, psychologist, or psychiatrist.',
            filipino:
                'Kung tumatagal, mabigat, o nagpapahirap sa buhay ang mga pagbabago, makatuwirang humingi ng tulong. Maaaring magsimula sa pinagkakatiwalaang tao, doktor, counselor, psychologist, o psychiatrist.',
          ),
        ),
        LearningSection(
          heading: _whatHelps,
          body: LearningCopy(
            english:
                'Lower the bar for the next step: drink water, open a curtain, message someone safe, or arrange care. If you might harm yourself, seek urgent help now and do not stay alone.',
            filipino:
                'Gawing maliit ang susunod na hakbang: uminom ng tubig, buksan ang kurtina, mag-message sa ligtas na tao, o magpa-appointment. Kung maaari mong saktan ang sarili, humingi agad ng tulong at huwag mag-isa.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Use structure when motivation is low',
            filipino: 'Gumamit ng structure kapag mababa ang motivation',
          ),
          body: LearningCopy(
            english:
                'Waiting to feel motivated can keep the day frozen. Choose one care task, one necessary task, and one connecting task, then make each unusually small. Action does not cure depression, but a little structure can create evidence that movement is still possible while you arrange appropriate support.',
            filipino:
                'Maaaring ma-freeze ang araw kung hihintayin munang magkaroon ng motivation. Pumili ng isang care task, necessary task, at connecting task, at gawing napakaliit ang bawat isa. Hindi nito ginagamot ang depression, ngunit nagbibigay ito ng structure habang naghahanap ng tamang suporta.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Depression is treatable, and care is individualized',
            filipino: 'Nagagamot ang depression at iba-iba ang tamang care',
          ),
          body: LearningCopy(
            english:
                'Treatment may include psychotherapy, medication, lifestyle support, or a combination, depending on severity, health history, preferences, and access. Improvement may be gradual, so follow-up matters. A clinician should also consider grief, bipolar disorder, thyroid problems, medication effects, and other conditions that can resemble or accompany depression. Never stop prescribed medication abruptly without speaking with the prescriber.',
            filipino:
                'Maaaring kasama sa treatment ang psychotherapy, gamot, lifestyle support, o kombinasyon depende sa tindi, health history, preference, at access. Maaaring unti-unti ang improvement kaya mahalaga ang follow-up. Dapat ding isaalang-alang ng clinician ang grief, bipolar disorder, thyroid problems, epekto ng gamot, at ibang kondisyong maaaring kahawig o kasama ng depression. Huwag biglang ihinto ang prescribed medicine nang hindi kinakausap ang prescriber.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english:
            'Who is one safe person you could tell when things feel heavy?',
        filipino: 'Sino ang isang ligtas na taong makakausap mo kapag mabigat?',
      ),
      medlinePlusQuery: 'depression',
      sourceUrl: Uri.parse('https://www.nimh.nih.gov/health/topics/depression'),
      sourceLabel: 'National Institute of Mental Health',
    ),
    LearningLesson(
      id: 'stress-burnout',
      category: LearningCategory.coping,
      title: const LearningCopy(
        english: 'Stress, overload, and burnout',
        filipino: 'Stress, sobrang bigat, at burnout',
      ),
      summary: const LearningCopy(
        english: 'Spot overload early and make recovery more realistic.',
        filipino:
            'Mapansin nang maaga ang sobrang bigat at gawing mas makatotohanan ang pahinga.',
      ),
      readMinutes: 5,
      icon: Icons.battery_2_bar_rounded,
      sections: const [
        LearningSection(
          heading: _whatItIs,
          body: LearningCopy(
            english:
                'Stress can sharpen attention for a short time. When demands stay high and recovery stays low, people may feel exhausted, detached, tense, forgetful, or unable to switch off.',
            filipino:
                'Maaaring patalasin ng stress ang atensyon sa maikling panahon. Kapag laging mataas ang hinihingi at kulang ang pahinga, maaaring mapagod, manhid, tensiyonado, makalimutin, o hindi makapagpahinga ang isip.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Rest is not only sleep',
            filipino: 'Hindi lang tulog ang pahinga',
          ),
          body: LearningCopy(
            english:
                'Recovery can include fewer decisions, clearer boundaries, quiet, movement, play, food, connection, or asking others to share the load. The right kind depends on what drained you.',
            filipino:
                'Maaaring kasama sa recovery ang mas kaunting desisyon, malinaw na hangganan, katahimikan, galaw, laro, pagkain, pakikipag-ugnayan, o paghahati ng responsibilidad. Depende ito sa pinagmulan ng pagod.',
          ),
        ),
        LearningSection(
          heading: _whatHelps,
          body: LearningCopy(
            english:
                'Separate what is urgent from what is merely loud. Pick one task to finish, one to delay, and one source of support to contact.',
            filipino:
                'Ihiwalay ang tunay na kailangang gawin sa maingay lamang. Pumili ng isang tatapusin, isang ipagpapaliban, at isang taong mahihingan ng tulong.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Build an early-warning plan',
            filipino: 'Gumawa ng early-warning plan',
          ),
          body: LearningCopy(
            english:
                'List your first three overload signs—perhaps skipped meals, short replies, headaches, doom-scrolling, or working later. Beside each sign, write a small response you can use before exhaustion peaks. Include one boundary and one person who can help you notice when your capacity is slipping.',
            filipino:
                'Ilista ang unang tatlong senyales ng overload—halimbawa, hindi pagkain, maiikling sagot, sakit ng ulo, doom-scrolling, o late na trabaho. Katabi nito, isulat ang maliit na tugon bago lumala ang pagod. Isama ang isang boundary at isang taong makakapansin kapag nauubos ka.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english: 'What kind of rest are you missing most?',
        filipino: 'Anong uri ng pahinga ang pinakakulang sa iyo?',
      ),
      medlinePlusQuery: 'stress management',
      sourceUrl: Uri.parse(
          'https://www.nimh.nih.gov/health/publications/so-stressed-out-fact-sheet'),
      sourceLabel: 'National Institute of Mental Health',
    ),
    LearningLesson(
      id: 'sleep-and-mind',
      category: LearningCategory.coping,
      title: const LearningCopy(
        english: 'Sleep and your mind',
        filipino: 'Tulog at iyong isip',
      ),
      summary: const LearningCopy(
        english: 'See how sleep and emotional wellbeing influence each other.',
        filipino:
            'Alamin kung paano nagkakaapekto ang tulog at emotional wellbeing.',
      ),
      readMinutes: 4,
      icon: Icons.bedtime_outlined,
      sections: const [
        LearningSection(
          heading: LearningCopy(
            english: 'A two-way relationship',
            filipino: 'Dalawang-direksyong ugnayan',
          ),
          body: LearningCopy(
            english:
                'Poor sleep can make emotions harder to regulate, while worry, low mood, pain, and stress can make sleep harder. One rough night does not mean something is wrong.',
            filipino:
                'Maaaring pahirapan ng kulang na tulog ang pag-regulate ng emosyon, habang ang pag-aalala, lungkot, sakit, at stress ay maaaring magpahirap sa pagtulog. Hindi ibig sabihin na may mali dahil sa isang gabing hindi maayos.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Consistency can be kinder than perfection',
            filipino: 'Mas mahalaga ang consistency kaysa perfection',
          ),
          body: LearningCopy(
            english:
                'A fairly steady wake time, morning light, less late caffeine, and a short wind-down cue can support the body clock. Build one change at a time.',
            filipino:
                'Makakatulong sa body clock ang halos pare-parehong oras ng paggising, liwanag sa umaga, kaunting caffeine sa gabi, at maikling wind-down cue. Isa-isahin ang pagbabago.',
          ),
        ),
        LearningSection(
          heading: _whatHelps,
          body: LearningCopy(
            english:
                'If sleep problems persist or come with loud snoring, breathing pauses, extreme daytime sleepiness, or major mood changes, consider medical advice.',
            filipino:
                'Kung tuloy-tuloy ang problema sa tulog o may malakas na hilik, paghinto ng paghinga, sobrang antok sa araw, o malaking pagbabago sa mood, kumonsulta sa doktor.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Run a one-week experiment',
            filipino: 'Subukan ang one-week experiment',
          ),
          body: LearningCopy(
            english:
                'Choose one change—such as a stable wake time or moving caffeine earlier—and track it for seven days with sleep quality and daytime energy. Keep expectations modest. One variable at a time makes it easier to see what helps and avoids turning bedtime into another performance test.',
            filipino:
                'Pumili ng isang pagbabago—tulad ng pare-parehong wake time o mas maagang caffeine—at i-track nang pitong araw kasama ang sleep quality at energy sa araw. Maging realistic. Mas madaling makita ang epekto ng isang variable at hindi nagiging performance test ang pagtulog.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english: 'What is one calming cue your evening could use?',
        filipino: 'Anong calming cue ang maaari mong idagdag sa gabi?',
      ),
      medlinePlusQuery: 'healthy sleep',
      sourceUrl:
          Uri.parse('https://www.nhlbi.nih.gov/health/sleep-deprivation'),
      sourceLabel: 'National Heart, Lung, and Blood Institute',
    ),
    LearningLesson(
      id: 'asking-for-help',
      category: LearningCategory.support,
      title: const LearningCopy(
        english: 'How to ask for help',
        filipino: 'Paano humingi ng tulong',
      ),
      summary: const LearningCopy(
        english: 'Turn “I need help” into a first conversation or appointment.',
        filipino:
            'Gawing unang usapan o appointment ang “Kailangan ko ng tulong.”',
      ),
      readMinutes: 5,
      icon: Icons.forum_outlined,
      sections: const [
        LearningSection(
          heading: LearningCopy(
            english: 'You can start without the perfect words',
            filipino: 'Hindi kailangan ng perpektong salita',
          ),
          body: LearningCopy(
            english:
                'Try: “I have not felt like myself lately, and it is affecting my daily life. Can you listen and help me think about what to do next?” You may read it from your phone.',
            filipino:
                'Subukan: “Hindi ako parang sarili ko nitong mga araw at apektado na ang araw-araw ko. Maaari mo ba akong pakinggan at tulungang mag-isip ng susunod na hakbang?” Maaari mo itong basahin mula sa phone.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Preparing for professional care',
            filipino: 'Paghahanda para sa propesyonal na tulong',
          ),
          body: LearningCopy(
            english:
                'Write down what changed, when it began, what makes it better or worse, medicines or substances you use, and how sleep and daily life are affected. Bring questions and ask what happens next.',
            filipino:
                'Isulat kung ano ang nagbago, kailan nagsimula, ano ang nagpapabuti o nagpapalala, mga gamot o substance na ginagamit, at epekto sa tulog at araw-araw. Magdala ng tanong at alamin ang susunod na hakbang.',
          ),
        ),
        LearningSection(
          heading: _whatHelps,
          body: LearningCopy(
            english:
                'If the first person is not a good fit, that does not mean help will never fit. Ask about options, cost, privacy, language, and whether a trusted person can join you.',
            filipino:
                'Kung hindi akma ang unang nakausap, hindi ibig sabihin na walang tulong na babagay. Magtanong tungkol sa options, bayad, privacy, wika, at kung puwedeng may kasamang pinagkakatiwalaang tao.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Decide what you need from the conversation',
            filipino: 'Alamin ang kailangan mo sa usapan',
          ),
          body: LearningCopy(
            english:
                'Before reaching out, choose the request: listening without advice, help finding a provider, company during an appointment, practical help, or a safety check. A specific request makes it easier for a caring person to respond. If they cannot help, ask who else might be able to.',
            filipino:
                'Bago lumapit, piliin ang request: pakikinig nang walang advice, tulong humanap ng provider, kasama sa appointment, practical help, o safety check. Mas madaling tumugon ang nagmamalasakit kapag specific. Kung hindi nila kaya, itanong kung sino pa ang maaaring tumulong.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english: 'What would make asking for help feel one step safer?',
        filipino:
            'Ano ang magpapadama na isang hakbang na mas ligtas ang paghingi ng tulong?',
      ),
      medlinePlusQuery: 'mental health services',
      sourceUrl: Uri.parse('https://www.nimh.nih.gov/health/find-help'),
      sourceLabel: 'National Institute of Mental Health',
    ),
    LearningLesson(
      id: 'panic-attacks',
      category: LearningCategory.conditions,
      title: const LearningCopy(
        english: 'When panic takes over',
        filipino: 'Kapag nangingibabaw ang panic',
      ),
      summary: const LearningCopy(
        english:
            'Understand the panic cycle and make the next wave less frightening.',
        filipino:
            'Unawain ang panic cycle at gawing mas hindi nakakatakot ang susunod na wave.',
      ),
      readMinutes: 6,
      icon: Icons.waves_rounded,
      sections: const [
        LearningSection(
          heading: LearningCopy(
            english: 'Panic is a powerful false alarm',
            filipino: 'Ang panic ay isang malakas na false alarm',
          ),
          body: LearningCopy(
            english:
                'A panic attack is a sudden surge of fear or discomfort. A pounding heart, fast breathing, dizziness, tingling, nausea, unreality, or fear of losing control can feel dangerous even when the body’s alarm system is misfiring. Symptoms often peak within minutes, then gradually settle.',
            filipino:
                'Ang panic attack ay biglaang bugso ng takot o discomfort. Ang mabilis na tibok, paghinga, hilo, pamamanhid, pagduduwal, pakiramdam na hindi totoo ang paligid, o takot mawalan ng kontrol ay maaaring mukhang delikado kahit false alarm ang katawan. Karaniwang tumitindi ito sa loob ng ilang minuto at unti-unting humuhupa.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Fear can feed the cycle',
            filipino: 'Maaaring palakasin ng takot ang cycle',
          ),
          body: LearningCopy(
            english:
                'A body sensation can trigger a frightening thought—“I am not safe”—which adds more adrenaline and stronger sensations. Avoiding every place connected with panic may bring short relief but can teach the brain that those places are dangerous.',
            filipino:
                'Maaaring magpasimula ng nakakatakot na isip ang sensasyon sa katawan—“Hindi ako ligtas”—na nagdadagdag ng adrenaline at mas malakas na sensasyon. Ang pag-iwas sa lahat ng lugar na nauugnay sa panic ay pansamantalang ginhawa ngunit maaaring turuan ang utak na delikado ang mga iyon.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Ride the wave without fighting it',
            filipino: 'Sakyan ang wave nang hindi nilalabanan',
          ),
          body: LearningCopy(
            english:
                'Plant both feet, soften your shoulders, and let the exhale run slightly longer than the inhale. Name five neutral things you see. Remind yourself: “This is an alarm. It is intense, and it will pass.” The goal is not instant calm; it is staying oriented while the wave falls.',
            filipino:
                'Ilapat ang dalawang paa, luwagan ang balikat, at pahabain nang kaunti ang exhale kaysa inhale. Pangalanan ang limang neutral na bagay na nakikita. Sabihin: “Alarm ito. Matindi, pero lilipas.” Hindi kailangang kumalma agad; manatiling nakatuon habang humuhupa ang wave.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Know when to get checked',
            filipino: 'Alamin kung kailan magpapatingin',
          ),
          body: LearningCopy(
            english:
                'New, severe, or unusual chest pain, fainting, injury, breathing trouble, or symptoms you cannot confidently recognize need medical assessment. Repeated panic attacks or growing avoidance are also good reasons to seek professional support; effective treatments are available.',
            filipino:
                'Ang bago, matindi, o kakaibang sakit sa dibdib, pagkahimatay, injury, hirap huminga, o sintomas na hindi mo makilala ay nangangailangan ng medical assessment. Ang paulit-ulit na panic o lumalaking pag-iwas ay dahilan din para humingi ng propesyonal na tulong.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english: 'Which reminder could help you stay oriented during a wave?',
        filipino: 'Anong paalala ang makakatulong sa iyo sa gitna ng wave?',
      ),
      medlinePlusQuery: 'panic disorder',
      sourceUrl: Uri.parse(
          'https://www.nimh.nih.gov/health/publications/panic-disorder-when-fear-overwhelms'),
      sourceLabel: 'National Institute of Mental Health',
    ),
    LearningLesson(
      id: 'emotional-regulation',
      category: LearningCategory.emotions,
      title: const LearningCopy(
        english: 'Making room for big emotions',
        filipino: 'Pagbibigay-lugar sa matinding emosyon',
      ),
      summary: const LearningCopy(
        english: 'Work with emotions without letting them choose every action.',
        filipino:
            'Harapin ang emosyon nang hindi nito pinipili ang bawat kilos.',
      ),
      readMinutes: 6,
      icon: Icons.tune_rounded,
      sections: const [
        LearningSection(
          heading: LearningCopy(
            english: 'Emotions carry information, not instructions',
            filipino: 'May mensahe ang emosyon, hindi utos',
          ),
          body: LearningCopy(
            english:
                'Anger may point to unfairness or a crossed boundary. Fear may point to uncertainty. Sadness may point to loss. The message matters, but the first urge—shout, flee, shut down—is not always the action that serves you best.',
            filipino:
                'Maaaring ituro ng galit ang kawalan ng katarungan o nalampasang boundary. Maaaring ituro ng takot ang uncertainty at ng lungkot ang pagkawala. Mahalaga ang mensahe, ngunit hindi palaging pinakamainam ang unang urge—sumigaw, tumakas, o manahimik.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Name it with more precision',
            filipino: 'Pangalanan nang mas tiyak',
          ),
          body: LearningCopy(
            english:
                '“Bad” can become disappointed, ashamed, lonely, overstimulated, jealous, or worried. A precise label can reduce confusion and reveal a more useful need: reassurance, space, repair, rest, information, or protection.',
            filipino:
                'Ang “masama” ay maaaring disappointed, nahihiya, lonely, overstimulated, jealous, o worried. Ang mas tiyak na label ay nakababawas ng kalituhan at nagpapakita ng pangangailangan: reassurance, space, pag-aayos, pahinga, impormasyon, o proteksyon.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Regulate the body before solving',
            filipino: 'Ayusin muna ang katawan bago mag-solve',
          ),
          body: LearningCopy(
            english:
                'When intensity is high, use temperature, slower breathing, a brief walk, unclenching, or sensory grounding. Then ask: “What happened? What story did my mind add? What action matches my values?” This creates space between feeling and response.',
            filipino:
                'Kapag matindi, gumamit ng malamig na tubig, mabagal na paghinga, maikling lakad, pagluwag ng katawan, o sensory grounding. Pagkatapos itanong: “Ano ang nangyari? Anong kuwento ang idinagdag ng isip? Anong kilos ang tugma sa values ko?”',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Repair matters more than perfect control',
            filipino: 'Mas mahalaga ang pag-aayos kaysa perfect control',
          ),
          body: LearningCopy(
            english:
                'No one regulates perfectly. If emotion led to harm, pause, take responsibility without excuses, ask what the other person needs, and describe what you will try next time. Repair is a skill, not proof that you failed.',
            filipino:
                'Walang perpektong pag-regulate. Kung nakasakit dahil sa emosyon, huminto, umako nang walang dahilan, itanong ang kailangan ng kausap, at sabihin ang susubukan sa susunod. Skill ang repair, hindi patunay ng kabiguan.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english: 'What emotion have you been calling simply “bad”?',
        filipino: 'Anong emosyon ang tinatawag mo lang na “masama”?',
      ),
      medlinePlusQuery: 'emotional wellness',
      sourceUrl: Uri.parse(
          'https://www.nih.gov/health-information/emotional-wellness-toolkit'),
      sourceLabel: 'National Institutes of Health',
    ),
    LearningLesson(
      id: 'self-compassion',
      category: LearningCategory.coping,
      title: const LearningCopy(
        english: 'Self-compassion without excuses',
        filipino: 'Self-compassion nang walang palusot',
      ),
      summary: const LearningCopy(
        english:
            'Respond to mistakes with honesty, warmth, and accountability.',
        filipino:
            'Harapin ang pagkakamali nang tapat, mahinahon, at responsable.',
      ),
      readMinutes: 5,
      icon: Icons.volunteer_activism_outlined,
      sections: const [
        LearningSection(
          heading: LearningCopy(
            english: 'Kindness and accountability can coexist',
            filipino: 'Puwedeng magsama ang kabaitan at pananagutan',
          ),
          body: LearningCopy(
            english:
                'Self-compassion is not pretending a mistake did not matter. It means seeing the situation clearly without turning one action into a verdict on your worth. Shame says “I am bad”; accountability says “I did something I need to understand and repair.”',
            filipino:
                'Hindi self-compassion ang pagkukunwaring walang epekto ang pagkakamali. Ito ay malinaw na pagtingin nang hindi ginagawang hatol sa iyong halaga ang isang kilos. Sabi ng shame, “Masama ako”; sabi ng accountability, “May ginawa akong kailangang unawain at ayusin.”',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Notice the inner voice',
            filipino: 'Pansinin ang boses sa loob',
          ),
          body: LearningCopy(
            english:
                'Catch absolute phrases such as “I always ruin everything.” Replace them with facts: “That conversation went badly, I was overwhelmed, and I can apologize.” Accurate language reduces threat and makes learning easier.',
            filipino:
                'Pansinin ang absolute na salita tulad ng “Lagi kong sinisira ang lahat.” Palitan ng facts: “Hindi naging maayos ang usapan, overwhelmed ako, at maaari akong humingi ng tawad.” Nakababawas ng threat ang tumpak na wika.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Use the friend test',
            filipino: 'Gamitin ang friend test',
          ),
          body: LearningCopy(
            english:
                'Ask what you would say to a close friend in the same situation. Keep the honesty, remove the humiliation, and turn it toward one next action. A useful response often sounds like: “This hurts. You are not alone. What is the kindest responsible step?”',
            filipino:
                'Itanong kung ano ang sasabihin sa malapit na kaibigan sa parehong sitwasyon. Panatilihin ang katapatan, alisin ang pagpapahiya, at ituon sa isang susunod na kilos: “Masakit ito. Hindi ka nag-iisa. Ano ang mabait at responsableng hakbang?”',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Practice in ordinary moments',
            filipino: 'Magsanay sa ordinaryong sandali',
          ),
          body: LearningCopy(
            english:
                'Start with a missed deadline, awkward moment, or low-energy day rather than your deepest pain. Put a hand somewhere steady, name the difficulty, remember that imperfection is human, then choose a small act of care or repair.',
            filipino:
                'Magsimula sa missed deadline, awkward na sandali, o low-energy day kaysa sa pinakamalalim na sakit. Ilagay ang kamay sa komportableng bahagi, pangalanan ang hirap, alalahaning tao ang lahat, at pumili ng maliit na care o repair.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english: 'What would honest kindness sound like in your situation?',
        filipino: 'Ano ang tunog ng tapat na kabaitan sa sitwasyon mo?',
      ),
      medlinePlusQuery: 'self esteem',
      sourceUrl: Uri.parse(
          'https://www.nimh.nih.gov/health/topics/caring-for-your-mental-health'),
      sourceLabel: 'National Institute of Mental Health',
    ),
    LearningLesson(
      id: 'healthy-boundaries',
      category: LearningCategory.support,
      title: const LearningCopy(
        english: 'Boundaries that protect connection',
        filipino: 'Boundaries na nagpoprotekta sa ugnayan',
      ),
      summary: const LearningCopy(
        english: 'Set limits clearly without making them punishments.',
        filipino: 'Magtakda ng limit nang malinaw at hindi bilang parusa.',
      ),
      readMinutes: 6,
      icon: Icons.shield_outlined,
      sections: const [
        LearningSection(
          heading: LearningCopy(
            english: 'A boundary describes your action',
            filipino: 'Inilalarawan ng boundary ang kilos mo',
          ),
          body: LearningCopy(
            english:
                'A request asks someone to change; a boundary explains what you will do to protect time, safety, energy, or dignity. “Do not shout at me” is a request. “If shouting begins, I will pause the conversation and return when we are calmer” is a boundary.',
            filipino:
                'Humihiling ang request na magbago ang iba; ipinapaliwanag ng boundary ang gagawin mo para protektahan ang oras, kaligtasan, enerhiya, o dignidad. Request ang “Huwag mo akong sigawan.” Boundary ang “Kapag may sigawan, ihihinto ko muna ang usapan at babalik kapag kalmado na.”',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Clear is kinder than hidden resentment',
            filipino: 'Mas mabait ang malinaw kaysa tahimik na sama ng loob',
          ),
          body: LearningCopy(
            english:
                'State the limit early, briefly, and without a courtroom case. Try: “I cannot lend money right now,” or “I can help for 30 minutes.” Overexplaining can invite negotiation when the answer is already clear.',
            filipino:
                'Sabihin nang maaga, maikli, at walang mahabang depensa. Subukan: “Hindi ako makakapagpahiram ngayon,” o “Makakatulong ako nang 30 minuto.” Maaaring magbukas ng negotiation ang sobrang paliwanag kahit malinaw na ang sagot.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Guilt does not always mean wrongdoing',
            filipino: 'Hindi palaging kasalanan ang ibig sabihin ng guilt',
          ),
          body: LearningCopy(
            english:
                'A new limit can feel uncomfortable, especially when you learned to keep peace by always saying yes. Discomfort may mean the pattern is unfamiliar, not that the boundary is cruel. Check whether the limit is respectful, proportionate, and possible to follow.',
            filipino:
                'Maaaring hindi komportable ang bagong limit, lalo kung natutong laging umoo para walang gulo. Maaaring ibig sabihin ng discomfort na bago ang pattern, hindi malupit ang boundary. Tingnan kung magalang, sapat, at kaya itong sundin.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Safety comes before perfect communication',
            filipino: 'Kaligtasan muna bago perfect communication',
          ),
          body: LearningCopy(
            english:
                'In controlling or abusive situations, direct boundary-setting may increase danger. Prioritize a safety plan and confidential support from a qualified service or trusted person. You do not owe an unsafe person a polished explanation.',
            filipino:
                'Sa controlling o abusive na sitwasyon, maaaring magpalala ng panganib ang direktang boundary. Unahin ang safety plan at confidential support mula sa serbisyo o pinagkakatiwalaang tao. Hindi mo utang sa unsafe na tao ang perpektong paliwanag.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english: 'Which limit would reduce quiet resentment in your life?',
        filipino: 'Anong limit ang makababawas sa tahimik na sama ng loob?',
      ),
      medlinePlusQuery: 'healthy relationships',
      sourceUrl: Uri.parse(
          'https://www.nih.gov/health-information/your-healthiest-self-wellness-toolkits'),
      sourceLabel: 'National Institutes of Health',
    ),
    LearningLesson(
      id: 'grief-and-loss',
      category: LearningCategory.emotions,
      title: const LearningCopy(
        english: 'Grief has no tidy timeline',
        filipino: 'Walang maayos na timeline ang grief',
      ),
      summary: const LearningCopy(
        english: 'Make sense of changing reactions after loss.',
        filipino: 'Unawain ang pabago-bagong reaksyon pagkatapos ng pagkawala.',
      ),
      readMinutes: 6,
      icon: Icons.energy_savings_leaf_outlined,
      sections: const [
        LearningSection(
          heading: LearningCopy(
            english: 'Loss changes more than mood',
            filipino: 'Higit sa mood ang binabago ng pagkawala',
          ),
          body: LearningCopy(
            english:
                'Grief may follow a death, breakup, migration, illness, lost role, missed future, or major change. It can affect sleep, appetite, concentration, memory, identity, faith, and the body. Relief, numbness, anger, love, guilt, and laughter can exist beside sadness.',
            filipino:
                'Maaaring sundan ng grief ang kamatayan, breakup, migration, sakit, nawalang role, hindi natupad na future, o malaking pagbabago. Maaari nitong maapektuhan ang tulog, gana, focus, memory, identity, faith, at katawan. Puwedeng magsabay ang relief, pamamanhid, galit, pagmamahal, guilt, tawa, at lungkot.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Waves do not mean you are going backward',
            filipino: 'Hindi paurong ang pagdating ng mga wave',
          ),
          body: LearningCopy(
            english:
                'A smell, anniversary, song, or ordinary task can reactivate grief after a steadier period. Healing is rarely a straight line. The wave reflects connection and memory, not failure to “move on.”',
            filipino:
                'Maaaring buhayin muli ng amoy, anniversary, kanta, o ordinaryong gawain ang grief matapos ang mas maayos na panahon. Hindi tuwid ang healing. Ipinapakita ng wave ang koneksyon at alaala, hindi kabiguang “mag-move on.”',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Move between grieving and living',
            filipino: 'Magpalitan sa pagdadalamhati at pamumuhay',
          ),
          body: LearningCopy(
            english:
                'Some moments face the loss: talk, cry, remember, create a ritual. Other moments restore life: eat, work, laugh, rest, solve a practical task. Moving between both is a healthy rhythm, not avoidance or disloyalty.',
            filipino:
                'May mga sandaling haharap sa pagkawala: makipag-usap, umiyak, alalahanin, gumawa ng ritual. May sandaling magbabalik sa buhay: kumain, magtrabaho, tumawa, magpahinga, mag-ayos ng gawain. Healthy rhythm ang paglipat sa dalawa.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Seek care when you feel stuck or unsafe',
            filipino: 'Humingi ng tulong kapag stuck o unsafe',
          ),
          body: LearningCopy(
            english:
                'Professional support may help when distress stays intense, functioning keeps declining, guilt becomes consuming, substances become the main coping tool, or thoughts of death feel unsafe. Grief support is not only for emergencies.',
            filipino:
                'Makakatulong ang propesyonal na suporta kapag nananatiling matindi ang distress, humihina ang functioning, nilalamon ng guilt, substance ang pangunahing coping, o unsafe ang thoughts of death. Hindi lang para sa emergency ang grief support.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english: 'What is one gentle way to honor what changed?',
        filipino: 'Ano ang isang banayad na paraan para kilalanin ang nagbago?',
      ),
      medlinePlusQuery: 'grief',
      sourceUrl: Uri.parse('https://medlineplus.gov/bereavement.html'),
      sourceLabel: 'MedlinePlus',
    ),
    LearningLesson(
      id: 'types-of-care',
      category: LearningCategory.support,
      title: const LearningCopy(
        english: 'Finding the right kind of care',
        filipino: 'Paghanap ng tamang uri ng pangangalaga',
      ),
      summary: const LearningCopy(
        english: 'Compare support options and prepare useful questions.',
        filipino: 'Ihambing ang support options at maghanda ng mga tanong.',
      ),
      readMinutes: 7,
      icon: Icons.health_and_safety_outlined,
      sections: const [
        LearningSection(
          heading: LearningCopy(
            english: 'Different professionals play different roles',
            filipino: 'Magkakaiba ang role ng mga professional',
          ),
          body: LearningCopy(
            english:
                'Counselors, psychologists, psychiatrists, social workers, and primary-care doctors may overlap but have different training. Psychiatrists are medical doctors who can prescribe; psychologists often provide assessment and therapy; counselors and social workers may provide therapy and practical support depending on local licensing.',
            filipino:
                'Maaaring mag-overlap ngunit magkaiba ang training ng counselors, psychologists, psychiatrists, social workers, at doctors. Medical doctor ang psychiatrist at maaaring magreseta; madalas nagbibigay ng assessment at therapy ang psychologist; maaaring magbigay ng therapy at practical support ang counselor at social worker depende sa lisensya.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Therapy is not one single method',
            filipino: 'Hindi iisang paraan ang therapy',
          ),
          body: LearningCopy(
            english:
                'Some approaches focus on thoughts and behavior, others on emotions, relationships, trauma, acceptance, or practical problem-solving. Ask what approach is recommended, what sessions may involve, how progress is reviewed, and what alternatives exist.',
            filipino:
                'May approach na nakatuon sa isip at behavior, iba sa emotions, relasyon, trauma, acceptance, o practical problem-solving. Itanong ang recommended approach, mangyayari sa sessions, paano susukatin ang progress, at anong alternatives.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Fit is both practical and relational',
            filipino: 'Praktikal at relational ang fit',
          ),
          body: LearningCopy(
            english:
                'Cost, schedule, location, language, cultural understanding, privacy, and accessibility all matter. You should also feel heard, respected, and able to ask questions. A provider can challenge you without shaming or dismissing you.',
            filipino:
                'Mahalaga ang bayad, schedule, lugar, wika, cultural understanding, privacy, at accessibility. Dapat maramdaman mong pinakikinggan, nirerespeto, at malayang magtanong. Maaaring hamunin ka ng provider nang hindi ipinapahiya o binabalewala.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Prepare a short first-visit note',
            filipino: 'Maghanda ng maikling first-visit note',
          ),
          body: LearningCopy(
            english:
                'List your main concern, when it began, impact on daily life, relevant health history, medicines, substances, sleep, and any safety concerns. Add three questions. You do not need to tell your entire story in the first session; begin with what feels most important and safe.',
            filipino:
                'Ilista ang pangunahing concern, kailan nagsimula, epekto sa araw-araw, health history, gamot, substances, tulog, at safety concerns. Magdagdag ng tatlong tanong. Hindi kailangang ikuwento lahat sa unang session; magsimula sa pinakamahalaga at ligtas.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english:
            'Which practical factor matters most for care to work for you?',
        filipino:
            'Anong practical factor ang pinakamahalaga para gumana ang care?',
      ),
      medlinePlusQuery: 'mental health services',
      sourceUrl: Uri.parse('https://www.nimh.nih.gov/health/find-help'),
      sourceLabel: 'National Institute of Mental Health',
    ),
    LearningLesson(
      id: 'understanding-adhd',
      category: LearningCategory.conditions,
      title: const LearningCopy(
        english: 'Understanding ADHD',
        filipino: 'Pag-unawa sa ADHD',
      ),
      summary: const LearningCopy(
        english:
            'Learn how attention, activity, and impulse regulation can affect daily life.',
        filipino:
            'Alamin kung paano naaapektuhan ng attention, activity, at impulse regulation ang araw-araw.',
      ),
      readMinutes: 7,
      icon: Icons.bolt_rounded,
      sections: const [
        LearningSection(
          heading: LearningCopy(
            english: 'ADHD is a neurodevelopmental disorder',
            filipino: 'Ang ADHD ay neurodevelopmental disorder',
          ),
          body: LearningCopy(
            english:
                'ADHD involves a persistent pattern of inattention, hyperactivity, impulsivity, or a combination that interferes with functioning. Symptoms begin in childhood, although some people are recognized only when adult responsibilities become harder to manage. ADHD is not laziness, low intelligence, bad parenting, or a simple lack of discipline.',
            filipino:
                'Ang ADHD ay persistent na pattern ng inattention, hyperactivity, impulsivity, o kombinasyon na nakakaapekto sa functioning. Nagsisimula ang symptoms sa childhood, kahit may mga taong nakikilala lamang kapag mas mahirap na ang adult responsibilities. Hindi ito katamaran, mababang intelligence, maling pagpapalaki, o simpleng kulang sa disiplina.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'It can look different across people and ages',
            filipino: 'Magkakaiba ang anyo nito sa bawat tao at edad',
          ),
          body: LearningCopy(
            english:
                'One person may lose track of time, forget steps, or struggle to begin tasks. Another may feel internally restless, interrupt, make quick decisions, or need constant movement. Interests, urgency, novelty, and structure can change performance, so being able to focus intensely sometimes does not rule ADHD out. Symptoms must appear across more than one setting—not only during one stressful week.',
            filipino:
                'Maaaring mawala ang sense of time, makalimot ng steps, o mahirapang magsimula ang isang tao. Ang iba ay internally restless, nakaka-interrupt, mabilis magdesisyon, o laging kailangang gumalaw. Nakakaapekto ang interest, urgency, novelty, at structure, kaya hindi ibig sabihin na walang ADHD dahil nakaka-hyperfocus minsan. Dapat lumitaw ang symptoms sa higit sa isang setting.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Assessment looks beyond a checklist',
            filipino: 'Higit sa checklist ang assessment',
          ),
          body: LearningCopy(
            english:
                'A qualified clinician reviews childhood history, current functioning, school or work patterns, relationships, health, sleep, medicines, and substance use. Anxiety, depression, trauma, learning disorders, autism, sleep problems, and some medical conditions can overlap with ADHD. Online quizzes can organize questions, but they cannot confirm a diagnosis.',
            filipino:
                'Sinusuri ng qualified clinician ang childhood history, current functioning, school o work patterns, relationships, health, tulog, gamot, at substance use. Maaaring mag-overlap ang anxiety, depression, trauma, learning disorders, autism, sleep problems, at ilang medical conditions. Makakatulong ang online quiz sa questions pero hindi ito diagnosis.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Support changes the environment as well as the person',
            filipino: 'Binabago ng support ang environment, hindi lang ang tao',
          ),
          body: LearningCopy(
            english:
                'Evidence-based care may include medication, psychotherapy or behavioral support, parent education, and school or workplace accommodations. External reminders, visible steps, shorter work intervals, movement, and fewer distractions can reduce friction. Medication must be prescribed and monitored; never borrow stimulants or change a dose without the prescriber.',
            filipino:
                'Maaaring kasama sa evidence-based care ang gamot, psychotherapy o behavioral support, parent education, at school o workplace accommodations. Nakakatulong ang external reminders, visible steps, maiikling work interval, movement, at mas kaunting distraction. Dapat prescribed at monitored ang gamot; huwag manghiram ng stimulant o baguhin ang dose nang walang prescriber.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english: 'Which task becomes easier when its steps are visible?',
        filipino: 'Anong gawain ang mas madali kapag nakikita ang mga steps?',
      ),
      medlinePlusQuery: 'attention deficit hyperactivity disorder',
      sourceUrl: Uri.parse(
          'https://www.nimh.nih.gov/health/topics/attention-deficit-hyperactivity-disorder-adhd'),
      sourceLabel: 'National Institute of Mental Health',
    ),
    LearningLesson(
      id: 'understanding-ocd',
      category: LearningCategory.conditions,
      title: const LearningCopy(
        english: 'Understanding OCD',
        filipino: 'Pag-unawa sa OCD',
      ),
      summary: const LearningCopy(
        english:
            'Understand obsessions, compulsions, and why OCD is more than neatness.',
        filipino:
            'Unawain ang obsessions, compulsions, at kung bakit higit sa pagiging malinis ang OCD.',
      ),
      readMinutes: 7,
      icon: Icons.repeat_rounded,
      sections: const [
        LearningSection(
          heading: LearningCopy(
            english: 'OCD is not a personality quirk',
            filipino: 'Hindi personality quirk ang OCD',
          ),
          body: LearningCopy(
            english:
                'Obsessive-compulsive disorder can involve intrusive, unwanted thoughts, images, or urges called obsessions and repetitive actions or mental rituals called compulsions. Themes may involve contamination, harm, mistakes, morality, religion, relationships, or symmetry. The thoughts do not reveal a person’s character or intentions, and OCD is not simply liking order.',
            filipino:
                'Maaaring kabilang sa obsessive-compulsive disorder ang intrusive at unwanted thoughts, images, o urges na obsessions at paulit-ulit na kilos o mental rituals na compulsions. Maaaring tungkol ito sa contamination, harm, mistakes, morality, religion, relationships, o symmetry. Hindi ipinapakita ng thoughts ang character o intention ng tao, at hindi lang ito pagkagusto sa kaayusan.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Temporary relief can strengthen the cycle',
            filipino: 'Maaaring palakasin ng pansamantalang relief ang cycle',
          ),
          body: LearningCopy(
            english:
                'A distressing obsession creates doubt or fear. Checking, washing, repeating, confessing, researching, avoiding, or asking for reassurance may briefly lower distress. That relief teaches the brain to repeat the ritual the next time doubt appears. Compulsions can be invisible, such as reviewing memories or repeating a phrase mentally.',
            filipino:
                'Lumilikha ng doubt o fear ang distressing obsession. Maaaring pansamantalang bumaba ang distress sa checking, washing, repeating, confessing, researching, avoiding, o reassurance. Tinuturuan ng relief ang utak na ulitin ang ritual sa susunod. Maaari ring invisible ang compulsion, tulad ng pagre-review ng memory o pag-uulit ng phrase sa isip.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Specialized treatment matters',
            filipino: 'Mahalaga ang specialized treatment',
          ),
          body: LearningCopy(
            english:
                'OCD is assessed by a qualified professional who considers time, distress, impairment, and other possible conditions. Evidence-based care commonly includes exposure and response prevention, a form of cognitive behavioral therapy, and sometimes medication. Exposure is planned and collaborative; it is not forcing someone into danger or dismissing their fear.',
            filipino:
                'Ina-assess ng qualified professional ang oras, distress, impairment, at ibang posibleng kondisyon. Karaniwang kasama sa evidence-based care ang exposure and response prevention, isang uri ng cognitive behavioral therapy, at minsan gamot. Planned at collaborative ang exposure; hindi ito pagpilit sa panganib o pagbalewala sa takot.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Support without joining the ritual',
            filipino: 'Sumuporta nang hindi sumasali sa ritual',
          ),
          body: LearningCopy(
            english:
                'Repeated reassurance can accidentally maintain OCD even when it comes from love. Ask how the person and their clinician want you to respond. You might validate the distress without proving the obsession true or false: “I can see this is painful. How can I support your treatment plan right now?”',
            filipino:
                'Maaaring mapanatili ng repeated reassurance ang OCD kahit galing sa pagmamahal. Itanong kung paano nais ng tao at clinician na tumugon ka. Puwedeng kilalanin ang distress nang hindi pinapatunayang tama o mali ang obsession: “Nakikita kong mahirap ito. Paano ko susuportahan ang treatment plan mo ngayon?”',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english: 'Where does short-term reassurance create a longer loop?',
        filipino: 'Saan nagiging mas mahabang loop ang short-term reassurance?',
      ),
      medlinePlusQuery: 'obsessive compulsive disorder',
      sourceUrl: Uri.parse(
          'https://www.nimh.nih.gov/health/topics/obsessive-compulsive-disorder-ocd'),
      sourceLabel: 'National Institute of Mental Health',
    ),
    LearningLesson(
      id: 'understanding-bipolar',
      category: LearningCategory.conditions,
      title: const LearningCopy(
        english: 'Understanding bipolar disorder',
        filipino: 'Pag-unawa sa bipolar disorder',
      ),
      summary: const LearningCopy(
        english:
            'Learn why mood episodes are different from ordinary mood changes.',
        filipino:
            'Alamin kung bakit iba ang mood episodes sa ordinaryong pagbabago ng mood.',
      ),
      readMinutes: 8,
      icon: Icons.contrast_rounded,
      sections: const [
        LearningSection(
          heading: LearningCopy(
            english: 'Bipolar disorder involves distinct episodes',
            filipino: 'May distinct episodes ang bipolar disorder',
          ),
          body: LearningCopy(
            english:
                'Bipolar disorders involve clear changes in mood, energy, activity, sleep, thinking, and functioning that last for days or longer—not ordinary reactions that shift hour by hour. Episodes can include mania or hypomania and depression. Bipolar I includes mania; bipolar II includes hypomania and major depressive episodes. Only a qualified clinician can determine the diagnosis.',
            filipino:
                'Kasama sa bipolar disorders ang malinaw na pagbabago sa mood, energy, activity, sleep, thinking, at functioning na tumatagal ng ilang araw o higit pa—hindi ordinaryong reaksyon na nagbabago kada oras. Maaaring may mania o hypomania at depression. May mania sa bipolar I; may hypomania at major depressive episodes sa bipolar II. Qualified clinician lamang ang makakapag-diagnose.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Mania is more than feeling energetic',
            filipino: 'Higit sa pagiging energetic ang mania',
          ),
          body: LearningCopy(
            english:
                'Possible signs include needing much less sleep without feeling tired, unusually fast speech or thoughts, inflated confidence, distractibility, agitation, and risky spending, sex, driving, or business decisions. Severe mania may include psychosis or require hospital care. Hypomania is less severe but still represents a noticeable change from the person’s usual functioning.',
            filipino:
                'Maaaring kasama ang kaunting tulog pero hindi pagod, sobrang bilis ng salita o isip, unusually mataas na confidence, distractibility, agitation, at risky spending, sex, driving, o business decisions. Maaaring may psychosis o kailangan ng hospital care sa severe mania. Mas banayad ang hypomania pero kapansin-pansing iba pa rin sa usual functioning.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Diagnosis depends on the pattern over time',
            filipino:
                'Nakadepende ang diagnosis sa pattern sa paglipas ng panahon',
          ),
          body: LearningCopy(
            english:
                'ADHD, trauma, substance use, thyroid disease, medication effects, depression, and other conditions can resemble parts of bipolar disorder. A clinician reviews the timing and duration of episodes, impairment, family and medical history, medicines, and substances. A mood diary can support assessment but cannot diagnose bipolar disorder.',
            filipino:
                'Maaaring kahawig ng ilang bahagi nito ang ADHD, trauma, substance use, thyroid disease, epekto ng gamot, depression, at ibang kondisyon. Sinusuri ng clinician ang timing at duration ng episodes, impairment, family at medical history, medicines, at substances. Makakatulong ang mood diary pero hindi ito diagnosis.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Consistent treatment and sleep protection matter',
            filipino:
                'Mahalaga ang consistent treatment at pagprotekta sa tulog',
          ),
          body: LearningCopy(
            english:
                'Treatment commonly includes mood-stabilizing medication, psychotherapy, education, routine, and monitoring. Sleep loss can destabilize mood for some people. Do not stop medication abruptly or use an antidepressant without prescriber oversight. If someone is severely agitated, unsafe, psychotic, unable to care for themselves, or making dangerous decisions, seek urgent professional help.',
            filipino:
                'Karaniwang kasama sa treatment ang mood-stabilizing medication, psychotherapy, education, routine, at monitoring. Maaaring mag-destabilize ng mood ang kulang na tulog. Huwag biglang ihinto ang gamot o gumamit ng antidepressant nang walang prescriber oversight. Kung severely agitated, unsafe, psychotic, hindi maalagaan ang sarili, o gumagawa ng dangerous decisions, humingi agad ng professional help.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english: 'What change in sleep or energy would be important to notice?',
        filipino: 'Anong pagbabago sa tulog o energy ang mahalagang mapansin?',
      ),
      medlinePlusQuery: 'bipolar disorder',
      sourceUrl: Uri.parse(
          'https://www.nimh.nih.gov/health/publications/bipolar-disorder'),
      sourceLabel: 'National Institute of Mental Health',
    ),
    LearningLesson(
      id: 'understanding-ptsd',
      category: LearningCategory.conditions,
      title: const LearningCopy(
        english: 'Trauma and PTSD',
        filipino: 'Trauma at PTSD',
      ),
      summary: const LearningCopy(
        english:
            'Understand trauma responses, PTSD patterns, and routes to recovery.',
        filipino:
            'Unawain ang trauma responses, PTSD patterns, at mga daan sa recovery.',
      ),
      readMinutes: 7,
      icon: Icons.safety_check_rounded,
      sections: const [
        LearningSection(
          heading: LearningCopy(
            english: 'Trauma responses are not weakness',
            filipino: 'Hindi kahinaan ang trauma responses',
          ),
          body: LearningCopy(
            english:
                'After a frightening or harmful event, people may feel watchful, numb, jumpy, angry, guilty, disconnected, or unable to sleep. Many reactions lessen with time and support. PTSD is diagnosed when a particular pattern of symptoms persists and interferes with life; experiencing trauma does not automatically mean someone will develop PTSD.',
            filipino:
                'Pagkatapos ng nakakatakot o harmful na pangyayari, maaaring maging watchful, numb, jumpy, galit, guilty, disconnected, o hirap matulog ang tao. Maraming reaksyon ang humuhupa sa oras at suporta. Dina-diagnose ang PTSD kapag persistent ang partikular na pattern at nakakaistorbo sa buhay; hindi automatic na magkaka-PTSD ang nakaranas ng trauma.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'PTSD can affect memory, safety, and connection',
            filipino: 'Maaaring maapektuhan ang memory, safety, at connection',
          ),
          body: LearningCopy(
            english:
                'Symptoms may include intrusive memories or nightmares, avoiding reminders, negative changes in beliefs and mood, and increased arousal such as being easily startled. Triggers can be obvious or subtle. A trigger is a reminder that activates the alarm system; it is not proof that the danger is happening again.',
            filipino:
                'Maaaring may intrusive memories o nightmares, pag-iwas sa reminders, negative changes sa beliefs at mood, at increased arousal tulad ng madaling magulat. Maaaring obvious o subtle ang triggers. Reminder ang trigger na nag-a-activate ng alarm system; hindi ito proof na nangyayari ulit ang danger.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Recovery does not require telling everything at once',
            filipino: 'Hindi kailangang ikuwento agad ang lahat para gumaling',
          ),
          body: LearningCopy(
            english:
                'A trauma-informed clinician begins with safety, consent, goals, and stabilization. Evidence-based psychotherapies can help people process traumatic memories and reduce avoidance; medication may help some symptoms. Treatment should be paced collaboratively. Pressuring someone to disclose details before they are ready can be harmful.',
            filipino:
                'Nagsisimula ang trauma-informed clinician sa safety, consent, goals, at stabilization. Makakatulong ang evidence-based psychotherapy sa pag-process ng traumatic memories at pagliit ng avoidance; maaaring makatulong ang gamot sa ilang symptoms. Dapat collaborative ang pace. Maaaring makasakit ang pagpilit magkuwento bago handa.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Ground in the present, then widen support',
            filipino: 'Mag-ground sa present at palawakin ang support',
          ),
          body: LearningCopy(
            english:
                'During a trigger, orient to the current date and place, notice stable objects, feel your feet, and slow the exhale if comfortable. Avoid using alcohol or drugs as the main coping strategy. Seek professional care when symptoms persist, functioning declines, or safety is at risk. Immediate danger still requires emergency help.',
            filipino:
                'Sa trigger, alalahanin ang current date at place, pansinin ang stable objects, damhin ang paa, at bagalan ang exhale kung comfortable. Iwasang gawing main coping ang alcohol o drugs. Humingi ng professional care kapag persistent ang symptoms, bumababa ang functioning, o may safety risk. Emergency help ang kailangan sa immediate danger.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english:
            'What helps your body recognize that this moment is different?',
        filipino:
            'Ano ang tumutulong sa katawan mong makilalang iba ang sandaling ito?',
      ),
      medlinePlusQuery: 'post traumatic stress disorder',
      sourceUrl: Uri.parse(
          'https://www.nimh.nih.gov/health/publications/post-traumatic-stress-disorder-ptsd'),
      sourceLabel: 'National Institute of Mental Health',
    ),
    LearningLesson(
      id: 'understanding-eating-disorders',
      category: LearningCategory.conditions,
      title: const LearningCopy(
        english: 'Understanding eating disorders',
        filipino: 'Pag-unawa sa eating disorders',
      ),
      summary: const LearningCopy(
        english:
            'Recognize serious eating concerns without judging someone’s body.',
        filipino:
            'Kilalanin ang serious eating concerns nang hindi hinuhusgahan ang katawan.',
      ),
      readMinutes: 8,
      icon: Icons.restaurant_rounded,
      sections: const [
        LearningSection(
          heading: LearningCopy(
            english: 'Eating disorders can affect any body',
            filipino:
                'Maaaring makaapekto ang eating disorder sa anumang katawan',
          ),
          body: LearningCopy(
            english:
                'Eating disorders are serious illnesses involving disturbances in eating behavior and often thoughts about food, weight, shape, or control. They affect people of every age, gender, background, and body size. You cannot tell how medically unwell someone is by appearance, and an eating disorder is not a choice or a failure of willpower.',
            filipino:
                'Serious illnesses ang eating disorders na may disturbance sa eating behavior at madalas sa thoughts tungkol sa food, weight, shape, o control. Nakakaapekto ito sa bawat age, gender, background, at body size. Hindi malalaman sa itsura kung gaano kalala ang medical condition, at hindi ito choice o kakulangan sa willpower.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Signs are broader than restriction',
            filipino: 'Mas malawak sa restriction ang mga senyales',
          ),
          body: LearningCopy(
            english:
                'Patterns may include severe restriction, binge eating with loss of control, vomiting or other compensatory behaviors, compulsive exercise, rigid food rules, secretive eating, intense body checking, or fear around meals. Diagnoses include anorexia nervosa, bulimia nervosa, binge-eating disorder, avoidant/restrictive food intake disorder, and others.',
            filipino:
                'Maaaring kasama ang severe restriction, binge eating na may loss of control, vomiting o ibang compensatory behavior, compulsive exercise, rigid food rules, secretive eating, intense body checking, o takot sa meals. Kabilang sa diagnoses ang anorexia nervosa, bulimia nervosa, binge-eating disorder, avoidant/restrictive food intake disorder, at iba pa.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Medical assessment may be urgent',
            filipino: 'Maaaring urgent ang medical assessment',
          ),
          body: LearningCopy(
            english:
                'Eating disorders can affect the heart, electrolytes, digestion, hormones, bones, concentration, and mood. Fainting, chest pain, confusion, severe weakness, vomiting blood, inability to keep fluids down, or signs of immediate danger need urgent medical help. Normal-looking laboratory results do not always mean the disorder is harmless.',
            filipino:
                'Maaaring maapektuhan ang heart, electrolytes, digestion, hormones, bones, concentration, at mood. Kailangan ng urgent medical help sa fainting, chest pain, confusion, severe weakness, vomiting blood, hindi makainom, o immediate danger. Hindi palaging ibig sabihin ng normal-looking lab results na harmless ang disorder.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Recovery often needs a coordinated team',
            filipino: 'Madalas kailangan ng coordinated team sa recovery',
          ),
          body: LearningCopy(
            english:
                'Care may involve medical monitoring, nutrition support from a qualified professional, psychotherapy, family support, and medication for some symptoms. Avoid praising weight loss, debating appearance, or giving diet advice. Express specific concern about behavior and wellbeing: “I have noticed meals seem frightening lately. I care about you and want to help you get checked.”',
            filipino:
                'Maaaring kasama sa care ang medical monitoring, nutrition support mula sa qualified professional, psychotherapy, family support, at gamot para sa ilang symptoms. Iwasang purihin ang weight loss, makipagtalo tungkol sa appearance, o magbigay ng diet advice. Sabihin ang specific concern sa behavior at wellbeing.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english: 'How can concern focus on wellbeing instead of appearance?',
        filipino: 'Paano maitututok ang concern sa wellbeing kaysa appearance?',
      ),
      medlinePlusQuery: 'eating disorders',
      sourceUrl: Uri.parse(
          'https://www.nimh.nih.gov/health/publications/eating-disorders'),
      sourceLabel: 'National Institute of Mental Health',
    ),
    LearningLesson(
      id: 'understanding-schizophrenia',
      category: LearningCategory.conditions,
      title: const LearningCopy(
        english: 'Schizophrenia and psychosis',
        filipino: 'Schizophrenia at psychosis',
      ),
      summary: const LearningCopy(
        english:
            'Replace frightening myths with accurate information and compassionate support.',
        filipino:
            'Palitan ang nakakatakot na myths ng accurate information at compassionate support.',
      ),
      readMinutes: 8,
      icon: Icons.hub_outlined,
      sections: const [
        LearningSection(
          heading: LearningCopy(
            english: 'Schizophrenia is not a “split personality”',
            filipino: 'Hindi “split personality” ang schizophrenia',
          ),
          body: LearningCopy(
            english:
                'Schizophrenia is a mental disorder that can affect how a person perceives reality, organizes thoughts, expresses emotion, and functions. Psychosis may include hallucinations, delusions, or disorganized thinking. Other symptoms can include reduced motivation, less emotional expression, social withdrawal, and cognitive difficulty. People with schizophrenia are not defined by the diagnosis.',
            filipino:
                'Ang schizophrenia ay mental disorder na maaaring makaapekto sa perception of reality, organization ng thoughts, expression ng emotion, at functioning. Maaaring kasama sa psychosis ang hallucinations, delusions, o disorganized thinking. Maaari ring may reduced motivation, less emotional expression, social withdrawal, at cognitive difficulty. Hindi nade-define ng diagnosis ang tao.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Psychosis has several possible causes',
            filipino: 'Maraming posibleng sanhi ang psychosis',
          ),
          body: LearningCopy(
            english:
                'Psychosis can occur in schizophrenia, bipolar disorder, severe depression, medical or neurological illness, medication effects, and substance use. A thorough professional assessment is essential. Sudden confusion, fever, head injury, intoxication, withdrawal, or a rapid first episode may require urgent medical evaluation.',
            filipino:
                'Maaaring mangyari ang psychosis sa schizophrenia, bipolar disorder, severe depression, medical o neurological illness, epekto ng gamot, at substance use. Kailangan ng thorough professional assessment. Maaaring urgent ang sudden confusion, fever, head injury, intoxication, withdrawal, o mabilis na first episode.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Treatment can support meaningful recovery',
            filipino: 'Makakasuporta ang treatment sa meaningful recovery',
          ),
          body: LearningCopy(
            english:
                'Treatment commonly includes antipsychotic medication, coordinated specialty care, psychotherapy, family education, rehabilitation, and support for housing, school, or work. Starting care early can improve outcomes. Medication decisions require a prescriber, including discussion of benefits and side effects; abruptly stopping can increase relapse risk.',
            filipino:
                'Karaniwang kasama sa treatment ang antipsychotic medication, coordinated specialty care, psychotherapy, family education, rehabilitation, at support sa housing, school, o work. Makakatulong ang maagang care. Kailangan ng prescriber sa medication decisions at pagtalakay ng benefits at side effects; maaaring tumaas ang relapse risk sa biglang paghinto.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Respond calmly without arguing about reality',
            filipino:
                'Tumugon nang kalmado nang hindi nakikipagtalo sa reality',
          ),
          body: LearningCopy(
            english:
                'Speak simply, reduce noise, respect personal space, and acknowledge emotion without confirming a delusion: “That sounds frightening. I do not see it the same way, but I want to help you feel safe.” Seek urgent help if the person may harm themselves or others, cannot meet basic needs, is extremely agitated, or has a medical emergency.',
            filipino:
                'Magsalita nang simple, bawasan ang ingay, respetuhin ang personal space, at kilalanin ang emotion nang hindi kinukumpirma ang delusion: “Mukhang nakakatakot iyon. Hindi ko iyon nakikita sa parehong paraan, pero gusto kitang tulungang maging safe.” Humingi agad ng tulong kung may risk sa sarili o iba, hindi matugunan ang basic needs, extremely agitated, o may medical emergency.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english: 'What language protects dignity while offering safety?',
        filipino:
            'Anong wika ang nagpoprotekta sa dignidad habang nag-aalok ng safety?',
      ),
      medlinePlusQuery: 'schizophrenia',
      sourceUrl: Uri.parse(
          'https://www.nimh.nih.gov/health/publications/schizophrenia'),
      sourceLabel: 'National Institute of Mental Health',
    ),
    LearningLesson(
      id: 'social-anxiety',
      category: LearningCategory.conditions,
      title: const LearningCopy(
        english: 'When social situations feel unsafe',
        filipino: 'Kapag hindi ligtas ang pakiramdam sa social situations',
      ),
      summary: const LearningCopy(
        english:
            'Understand social anxiety, avoidance, and how gradual support can help.',
        filipino:
            'Unawain ang social anxiety, avoidance, at gradual na suporta.',
      ),
      readMinutes: 7,
      icon: Icons.groups_2_outlined,
      outcomes: const [
        LearningCopy(
          english: 'Recognize the anxiety–avoidance cycle.',
          filipino: 'Makilala ang anxiety–avoidance cycle.',
        ),
        LearningCopy(
          english: 'Know when ordinary shyness may need support.',
          filipino: 'Malaman kung kailan kailangan ng support.',
        ),
      ],
      searchTerms: const [
        'shy',
        'judged',
        'embarrassed',
        'public speaking',
        'people',
        'hiya',
        'takot makipag-usap',
      ],
      sections: const [
        LearningSection(
          type: LearningSectionType.explanation,
          heading: LearningCopy(
            english: 'It is more than simply being shy',
            filipino: 'Higit ito sa pagiging mahiyain',
          ),
          body: LearningCopy(
            english:
                'Social anxiety is an intense fear of being watched, judged, embarrassed, or rejected. It can appear during conversations, classes, work, eating around others, meeting new people, or performing. A diagnosis requires professional assessment; one uncomfortable event does not define a disorder.',
            filipino:
                'Ang social anxiety ay matinding takot na mapanood, ma-judge, mapahiya, o ma-reject. Maaari itong lumabas sa usapan, klase, trabaho, pagkain kasama ang iba, o performance. Professional assessment ang kailangan sa diagnosis; hindi sapat ang isang uncomfortable na event.',
          ),
        ),
        LearningSection(
          type: LearningSectionType.signs,
          heading: LearningCopy(
            english: 'The mind and body can both react',
            filipino: 'Maaaring mag-react ang isip at katawan',
          ),
          body: LearningCopy(
            english:
                'Someone may blush, sweat, tremble, feel sick, notice a racing heart, or feel their mind go blank. They may rehearse conversations, expect rejection, avoid eye contact, decline invitations, or replay small moments afterward. What matters is persistence and interference with daily life.',
            filipino:
                'Maaaring mamula, pagpawisan, manginig, masuka, bumilis ang tibok, o ma-blanko. Maaaring paulit-ulit i-rehearse ang usapan, umasa ng rejection, umiwas sa eye contact, o balikan ang maliliit na pagkakamali. Mahalaga kung persistent at nakakaistorbo ito sa araw-araw.',
          ),
        ),
        LearningSection(
          type: LearningSectionType.example,
          heading: LearningCopy(
            english: 'Avoidance gives short relief but keeps fear powerful',
            filipino: 'Panandalian ang relief ng avoidance',
          ),
          body: LearningCopy(
            english:
                'Skipping a meeting may lower anxiety today, yet it also prevents the brain from learning that discomfort can rise and then settle. Effective therapy often builds a gradual ladder—from a small hello, to asking one question, to a longer interaction—at a pace planned with support.',
            filipino:
                'Maaaring bumaba ang anxiety kapag iniwasan ang meeting, pero hindi natututuhan ng utak na maaaring tumaas at humupa ang discomfort. Madalas gumagamit ang therapy ng gradual ladder—mula sa simpleng hello, isang tanong, hanggang mas mahabang interaction—sa ligtas na pace.',
          ),
        ),
        LearningSection(
          type: LearningSectionType.seekHelp,
          heading: LearningCopy(
            english: 'Treatment can make social life feel possible again',
            filipino: 'Makakatulong ang treatment para maging posible muli',
          ),
          body: LearningCopy(
            english:
                'Cognitive behavioral therapy, including gradual exposure, is commonly used. Some people also discuss medication with a qualified prescriber. Consider professional support when fear repeatedly limits school, work, relationships, healthcare, or ordinary tasks you want to do.',
            filipino:
                'Karaniwang ginagamit ang cognitive behavioral therapy at gradual exposure. May ilan ding nakikipag-usap sa qualified prescriber tungkol sa medication. Humingi ng professional support kapag paulit-ulit na nalilimitahan ang school, work, relationships, healthcare, o ordinary tasks.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english: 'What is one social step small enough to feel possible?',
        filipino: 'Ano ang isang social step na maliit at kayang subukan?',
      ),
      relatedLessonIds: const ['understanding-anxiety', 'asking-for-help'],
      medlinePlusQuery: 'social anxiety disorder',
      sourceUrl: Uri.parse(
        'https://www.nimh.nih.gov/health/publications/social-anxiety-disorder-more-than-just-shyness',
      ),
      sourceLabel: 'National Institute of Mental Health',
    ),
    LearningLesson(
      id: 'substance-use-mental-health',
      category: LearningCategory.conditions,
      title: const LearningCopy(
        english: 'Substance use and mental health',
        filipino: 'Substance use at mental health',
      ),
      summary: const LearningCopy(
        english:
            'Understand why substance use and mental health often affect each other.',
        filipino:
            'Unawain kung bakit madalas magkaugnay ang substance use at mental health.',
      ),
      readMinutes: 7,
      icon: Icons.sync_alt_rounded,
      outcomes: const [
        LearningCopy(
          english: 'Recognize a two-way relationship without blame.',
          filipino: 'Makilala ang two-way relationship nang walang sisihan.',
        ),
        LearningCopy(
          english: 'Know why integrated professional care matters.',
          filipino: 'Malaman kung bakit mahalaga ang integrated care.',
        ),
      ],
      searchTerms: const [
        'alcohol',
        'drugs',
        'addiction',
        'bisyo',
        'withdrawal',
        'coping with substances',
      ],
      sensitivityNotice: const LearningCopy(
        english:
            'This lesson mentions substance dependence, overdose, and withdrawal without describing methods of use.',
        filipino:
            'Binabanggit ng lesson ang dependence, overdose, at withdrawal nang walang detalye ng paggamit.',
      ),
      sections: const [
        LearningSection(
          type: LearningSectionType.explanation,
          heading: LearningCopy(
            english: 'The relationship can move in both directions',
            filipino: 'Maaaring gumalaw sa dalawang direksyon',
          ),
          body: LearningCopy(
            english:
                'A person may use alcohol or drugs to escape distress, sleep, socialize, or quiet difficult memories. Substance effects can also trigger or worsen anxiety, depression, sleep problems, impulsivity, or psychosis. Shared biology, stress, trauma, and environment can contribute to both.',
            filipino:
                'Maaaring gumamit ng alcohol o drugs para takasan ang distress, matulog, makisalamuha, o patahimikin ang mahirap na alaala. Maaari ring mag-trigger o magpalala ang substances ng anxiety, depression, sleep problems, impulsivity, o psychosis. Maaaring may shared biology, stress, trauma, at environment.',
          ),
        ),
        LearningSection(
          type: LearningSectionType.mythFact,
          heading: LearningCopy(
            english: 'Myth: it is only a matter of willpower',
            filipino: 'Myth: willpower lang ang kailangan',
          ),
          body: LearningCopy(
            english:
                'Fact: substance use disorders are treatable health conditions shaped by brain, behavior, health, and context. Shame can delay care. Respectful support, harm-reduction conversations, medical assessment, therapy, medication when appropriate, and recovery communities may all have roles.',
            filipino:
                'Fact: treatable health condition ang substance use disorder na naaapektuhan ng brain, behavior, health, at context. Nakaka-delay ng care ang hiya. Maaaring makatulong ang respectful support, harm reduction, medical assessment, therapy, tamang medication, at recovery communities.',
          ),
        ),
        LearningSection(
          type: LearningSectionType.signs,
          heading: LearningCopy(
            english: 'Look for loss of control and growing consequences',
            filipino: 'Pansinin ang pagkawala ng control at consequences',
          ),
          body: LearningCopy(
            english:
                'Possible signs include using more than intended, repeated unsuccessful attempts to cut down, strong cravings, risky use, tolerance, withdrawal, or continued use despite harm to health, school, work, money, or relationships. Only a qualified professional can assess a disorder.',
            filipino:
                'Maaaring signs ang paggamit nang higit sa plano, hindi matagumpay na pagbabawas, cravings, risky use, tolerance, withdrawal, o tuloy na paggamit kahit may harm sa health, school, work, money, o relationships. Qualified professional lang ang maaaring mag-assess.',
          ),
        ),
        LearningSection(
          type: LearningSectionType.seekHelp,
          heading: LearningCopy(
            english: 'Treat both concerns together',
            filipino: 'Sabay na tugunan ang dalawang concern',
          ),
          body: LearningCopy(
            english:
                'Tell a clinician about both mental health symptoms and substance use, including prescriptions and supplements. Suddenly stopping some substances can be medically dangerous; seek medical guidance. Call emergency services for overdose, severe withdrawal, unconsciousness, breathing difficulty, seizure, or immediate danger.',
            filipino:
                'Sabihin sa clinician ang mental health symptoms at substance use, kasama ang prescriptions at supplements. Maaaring medical danger ang biglang paghinto ng ilang substance; humingi ng medical guidance. Tumawag sa emergency para sa overdose, severe withdrawal, unconsciousness, hirap huminga, seizure, o immediate danger.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english: 'What would make an honest conversation about use feel safer?',
        filipino:
            'Ano ang magpapaligtas sa honest na usapan tungkol sa paggamit?',
      ),
      relatedLessonIds: const ['types-of-care', 'asking-for-help'],
      medlinePlusQuery: 'substance use disorder mental health',
      sourceUrl: Uri.parse(
        'https://nida.nih.gov/research-topics/co-occurring-disorders',
      ),
      sourceLabel: 'National Institute on Drug Abuse',
    ),
    LearningLesson(
      id: 'supporting-someone',
      category: LearningCategory.support,
      title: const LearningCopy(
        english: 'How to support someone well',
        filipino: 'Paano suportahan nang maayos ang isang tao',
      ),
      summary: const LearningCopy(
        english:
            'Listen without taking over, offer concrete help, and protect your limits.',
        filipino:
            'Makinig nang hindi inaagaw ang control, mag-alok ng tulong, at alagaan ang limits.',
      ),
      readMinutes: 6,
      icon: Icons.volunteer_activism_outlined,
      outcomes: const [
        LearningCopy(
          english: 'Start a caring conversation without diagnosing.',
          filipino:
              'Magsimula ng caring conversation nang hindi nagda-diagnose.',
        ),
        LearningCopy(
          english: 'Offer specific help while keeping healthy boundaries.',
          filipino: 'Mag-alok ng specific help habang may healthy boundaries.',
        ),
      ],
      searchTerms: const [
        'friend',
        'family',
        'partner',
        'help a friend',
        'makinig',
        'support loved one',
      ],
      sections: const [
        LearningSection(
          type: LearningSectionType.support,
          heading: LearningCopy(
            english: 'Begin with what you have noticed',
            filipino: 'Magsimula sa napansin mo',
          ),
          body: LearningCopy(
            english:
                'Choose a private, unhurried moment. Try: “I have noticed you seem exhausted and have been pulling away. I care about you. Do you want to talk?” Describe observations rather than assigning a diagnosis, and allow them to decline without ending your care.',
            filipino:
                'Pumili ng private at hindi minamadaling oras. Subukan: “Napansin kong pagod ka at lumalayo nitong mga araw. Mahalaga ka sa akin. Gusto mo bang mag-usap?” Ilarawan ang napansin kaysa magbigay ng diagnosis, at payagang tumanggi.',
          ),
        ),
        LearningSection(
          type: LearningSectionType.example,
          heading: LearningCopy(
            english: 'Listen for the help they actually want',
            filipino: 'Pakinggan kung anong tulong ang gusto nila',
          ),
          body: LearningCopy(
            english:
                'Ask whether they want listening, problem-solving, company, or help finding care. Reflect what you heard before giving advice. Avoid minimizing, forced positivity, comparisons, or promises that everything will quickly be fine.',
            filipino:
                'Tanungin kung gusto nila ng pakikinig, problem-solving, kasama, o tulong maghanap ng care. Ibalik muna ang narinig bago mag-advice. Iwasan ang pagmamaliit, forced positivity, comparison, o pangakong mabilis magiging okay.',
          ),
        ),
        LearningSection(
          type: LearningSectionType.practice,
          heading: LearningCopy(
            english: 'Make the offer concrete and easy to accept',
            filipino: 'Gawing specific at madaling tanggapin ang offer',
          ),
          body: LearningCopy(
            english:
                'Instead of “Let me know if you need anything,” offer one action: sit with them while they call, help list providers, bring food, walk together, or check in tomorrow. Ask permission and follow through. Support is collaboration, not control.',
            filipino:
                'Sa halip na “Sabihin mo lang kung may kailangan,” mag-alok ng isang action: samahan tumawag, tumulong maglista ng provider, magdala ng pagkain, maglakad, o mag-check in bukas. Humingi ng permission at tuparin ang offer.',
          ),
        ),
        LearningSection(
          type: LearningSectionType.seekHelp,
          heading: LearningCopy(
            english: 'Safety overrides secrecy',
            filipino: 'Mas mahalaga ang safety kaysa secrecy',
          ),
          body: LearningCopy(
            english:
                'Take statements about suicide, self-harm, violence, overdose, or inability to stay safe seriously. Ask directly about immediate danger, involve crisis or emergency help, and do not promise secrecy. Keep your own safety and limits in view; one caring person cannot replace a care team.',
            filipino:
                'Seryosohin ang usapan tungkol sa suicide, self-harm, violence, overdose, o hindi manatiling safe. Direktang itanong ang immediate danger, humingi ng crisis o emergency help, at huwag mangakong ililihim. Alagaan din ang sariling safety at limits.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english:
            'What is one specific offer you could make without taking over?',
        filipino: 'Ano ang isang specific offer na hindi inaagaw ang control?',
      ),
      relatedLessonIds: const ['asking-for-help', 'suicide-safety'],
      medlinePlusQuery: 'helping someone with mental illness',
      sourceUrl: Uri.parse(
        'https://www.nimh.nih.gov/health/topics/caring-for-your-mental-health',
      ),
      sourceLabel: 'National Institute of Mental Health',
    ),
    LearningLesson(
      id: 'suicide-safety',
      category: LearningCategory.support,
      title: const LearningCopy(
        english: 'Responding to suicidal thoughts',
        filipino: 'Pagtugon sa suicidal thoughts',
      ),
      summary: const LearningCopy(
        english:
            'Recognize urgent warning signs and connect with immediate support.',
        filipino:
            'Kilalanin ang urgent warning signs at kumonekta sa immediate support.',
      ),
      readMinutes: 6,
      icon: Icons.health_and_safety_outlined,
      outcomes: const [
        LearningCopy(
          english: 'Know when to seek immediate help.',
          filipino: 'Malaman kung kailan hihingi ng immediate help.',
        ),
        LearningCopy(
          english: 'Use direct, compassionate language.',
          filipino: 'Gumamit ng direct at compassionate na wika.',
        ),
      ],
      searchTerms: const [
        'suicide',
        'suicidal',
        'self harm',
        'want to die',
        'unsafe',
        'ayoko na',
        'saktan ang sarili',
      ],
      sensitivityNotice: const LearningCopy(
        english:
            'This lesson discusses suicidal thoughts and warning signs without describing methods. You can leave at any time and use the support contacts below.',
        filipino:
            'Tinatalakay ng lesson ang suicidal thoughts at warning signs nang walang methods. Maaari kang umalis anumang oras at gamitin ang support contacts sa ibaba.',
      ),
      sections: const [
        LearningSection(
          type: LearningSectionType.signs,
          heading: LearningCopy(
            english: 'Treat new or escalating warning signs seriously',
            filipino: 'Seryosohin ang bago o lumalalang warning signs',
          ),
          body: LearningCopy(
            english:
                'Urgent signs can include talking about wanting to die, feeling hopeless or trapped, unbearable pain, being a burden, making a plan, saying goodbye, giving away important items, dangerous risk-taking, severe agitation, or sudden major behavior changes. Warning signs require attention, not certainty.',
            filipino:
                'Maaaring urgent signs ang pagsasabing gustong mamatay, hopeless o trapped, unbearable pain, pabigat, paggawa ng plano, pamamaalam, pamimigay ng importanteng bagay, dangerous risks, severe agitation, o biglang malaking behavior change. Kailangan ng attention kahit walang certainty.',
          ),
        ),
        LearningSection(
          type: LearningSectionType.mythFact,
          heading: LearningCopy(
            english: 'Asking directly does not plant the idea',
            filipino: 'Hindi itinatanim ng direct na tanong ang idea',
          ),
          body: LearningCopy(
            english:
                'Ask plainly and calmly: “Are you thinking about suicide?” Research summarized by NIMH indicates that asking does not increase suicidal thoughts. Listen without judgment. Do not debate, shame, challenge, or promise secrecy about immediate danger.',
            filipino:
                'Magtanong nang diretso at kalmado: “Iniisip mo bang magpakamatay?” Ayon sa research na inilalahad ng NIMH, hindi pinapataas ng tanong ang suicidal thoughts. Makinig nang walang judgment. Huwag makipagtalo, manisi, o mangakong ililihim ang immediate danger.',
          ),
        ),
        LearningSection(
          type: LearningSectionType.support,
          heading: LearningCopy(
            english: 'Be there, connect, and reduce immediate danger',
            filipino: 'Manatili, kumonekta, at bawasan ang immediate danger',
          ),
          body: LearningCopy(
            english:
                'If danger may be immediate, stay with the person when safe, involve a trusted person, reduce access to obvious means of harm when you can do so safely, and contact crisis or emergency support. Follow up afterward; ongoing caring contact matters.',
            filipino:
                'Kung maaaring immediate ang danger, manatili kasama nila kung safe, magsama ng trusted person, bawasan ang access sa obvious means of harm kung ligtas, at tumawag sa crisis o emergency support. Mag-follow up pagkatapos; mahalaga ang patuloy na caring contact.',
          ),
        ),
        LearningSection(
          type: LearningSectionType.seekHelp,
          heading: LearningCopy(
            english: 'Use immediate support in the Philippines',
            filipino: 'Gamitin ang immediate support sa Pilipinas',
          ),
          body: LearningCopy(
            english:
                'For imminent danger, serious injury, or an attempt in progress, call 911 or go to the nearest emergency department. For mental health crisis support, try the NCMH Crisis Hotline at 1553 or 0917-899-8727. If one option does not connect, try another and involve someone nearby.',
            filipino:
                'Para sa imminent danger, serious injury, o attempt na nangyayari, tumawag sa 911 o pumunta sa nearest emergency department. Para sa mental health crisis support, subukan ang NCMH Crisis Hotline na 1553 o 0917-899-8727. Kung hindi kumonekta, subukan ang iba at magsama ng taong malapit.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english:
            'Which person and crisis contact can be part of a safety plan?',
        filipino:
            'Sinong tao at crisis contact ang maaaring isama sa safety plan?',
      ),
      relatedLessonIds: const [
        'philippines-support-contacts',
        'supporting-someone',
        'asking-for-help',
      ],
      medlinePlusQuery: 'suicide prevention warning signs',
      sourceUrl: Uri.parse(
        'https://www.nimh.nih.gov/health/publications/5-action-steps-to-help-someone-having-thoughts-of-suicide',
      ),
      sourceLabel: 'National Institute of Mental Health',
    ),
    LearningLesson(
      id: 'philippines-support-contacts',
      category: LearningCategory.support,
      title: const LearningCopy(
        english: 'Who to contact for support',
        filipino: 'Sino ang tatawagan para sa suporta',
      ),
      summary: const LearningCopy(
        english:
            'Choose between routine care, crisis support, and emergency help in the Philippines.',
        filipino:
            'Pumili sa routine care, crisis support, at emergency help sa Pilipinas.',
      ),
      readMinutes: 5,
      icon: Icons.contact_phone_outlined,
      sections: const [
        LearningSection(
          heading: LearningCopy(
            english: 'Match the contact to the level of urgency',
            filipino: 'Itugma ang contact sa level ng urgency',
          ),
          body: LearningCopy(
            english:
                'Routine support fits ongoing symptoms without immediate danger: a primary-care doctor, counselor, psychologist, psychiatrist, school clinic, workplace service, or local health center can be a starting point. Crisis support fits intense distress or thoughts of self-harm that need immediate conversation and safety planning. Emergency help fits imminent danger, serious injury, overdose, severe confusion, or inability to stay safe.',
            filipino:
                'Para sa ongoing symptoms na walang immediate danger, maaaring magsimula sa doctor, counselor, psychologist, psychiatrist, school clinic, workplace service, o local health center. Para sa intense distress o self-harm thoughts, kailangan ng crisis support at safety planning. Para sa imminent danger, serious injury, overdose, severe confusion, o hindi manatiling safe, emergency help ang kailangan.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Philippine numbers to save',
            filipino: 'Mga numerong dapat i-save sa Pilipinas',
          ),
          body: LearningCopy(
            english:
                'For an immediate emergency, call the nationwide Unified 911 hotline. For mental health crisis support, the National Center for Mental Health lists 1553 and 0917-899-8727. Availability and network access can change, so keep a trusted person and a nearby hospital or local emergency contact in your personal safety plan as backups.',
            filipino:
                'Para sa immediate emergency, tumawag sa nationwide Unified 911. Para sa mental health crisis support, inililista ng National Center for Mental Health ang 1553 at 0917-899-8727. Maaaring magbago ang availability at network access, kaya mag-save rin ng trusted person at nearby hospital o local emergency contact bilang backup.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Prepare one sentence before you call',
            filipino: 'Maghanda ng isang sentence bago tumawag',
          ),
          body: LearningCopy(
            english:
                'If words are difficult, begin with: “I am in [location]. I am worried I may not stay safe. I need help now.” Share your name if you can, exact location, immediate danger, injuries or substances involved, and whether someone safe is with you. If one line does not connect and danger is immediate, try 911, go to the nearest emergency department, or ask someone nearby to call.',
            filipino:
                'Kung mahirap magsalita, simulan sa: “Nasa [location] ako. Nag-aalala akong baka hindi ako manatiling safe. Kailangan ko ng tulong ngayon.” Sabihin kung kaya ang pangalan, exact location, immediate danger, injury o substance, at kung may kasama. Kung hindi kumonekta at immediate ang danger, subukan ang 911, pumunta sa nearest emergency department, o magpatulong tumawag.',
          ),
        ),
        LearningSection(
          heading: LearningCopy(
            english: 'Stay with the person when it is safe to do so',
            filipino: 'Manatili kasama ng tao kung ligtas gawin',
          ),
          body: LearningCopy(
            english:
                'Listen without challenging or lecturing, reduce access to obvious means of harm if you can do so safely, and involve emergency or crisis support. Do not promise secrecy about immediate danger. If you are also at risk, move to safety and call emergency services. After the immediate crisis, help arrange follow-up care and a written safety plan.',
            filipino:
                'Makinig nang walang lecture, bawasan ang access sa obvious means of harm kung safe, at tumawag sa emergency o crisis support. Huwag mangakong ililihim ang immediate danger. Kung nasa risk ka rin, lumipat sa safety at tumawag sa emergency services. Pagkatapos ng crisis, tumulong mag-arrange ng follow-up care at written safety plan.',
          ),
        ),
      ],
      reflection: const LearningCopy(
        english: 'Which two contacts will you save before you need them?',
        filipino: 'Aling dalawang contact ang ise-save mo bago kailanganin?',
      ),
      medlinePlusQuery: 'mental health crisis support',
      sourceUrl: Uri.parse(
          'https://ncmh.gov.ph/images/pdf/docs/ncmhcovid19publicadvise5.pdf'),
      sourceLabel: 'National Center for Mental Health Philippines',
    ),
  ];

  static LearningLesson byId(String id) => lessons.firstWhere(
        (lesson) => lesson.id == id,
        orElse: () => lessons.first,
      );
}

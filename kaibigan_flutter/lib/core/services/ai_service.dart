import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_logger.dart';
import '../utils/env_config.dart';
import 'ai_memory_service.dart';

class GroqResponse {
  final String content;
  final String? reasoning;

  GroqResponse({required this.content, this.reasoning});
}

class AIService {
  /// Detects if user input contains self-harm, suicidal intent, or crisis triggers
  static bool isCrisisMessage(String text) {
    final lower = text.toLowerCase();
    final crisisTerms = [
      'papakamatay',
      'magpapakamatay',
      'magpakamatay',
      'mamatay na ko',
      'mamatay na ako',
      'mamatay na ko',
      'gusto ko nang mamatay',
      'gusto ko ng mamatay',
      'ayaw ko na mabuhay',
      'ayaw kona mabuhay',
      'ayaw ko nang mabuhay',
      'wakasan ang buhay',
      'laslas',
      'suicide',
      'suicidal',
      'kill myself',
      'end my life',
      'want to die',
      'don\'t want to live',
      'dont want to live',
      'hanging myself',
      'overdose',
    ];
    return crisisTerms.any((term) => lower.contains(term));
  }

  /// Provides urgent, compassionate crisis intervention response with 24/7 Philippine hotlines
  static String getCrisisResponse(String companionId, String language) {
    if (language == 'english') {
      return "I hear how much pain you're carrying right now, and your life is deeply precious. Please don't go through this alone. Reach out right away to compassionate professionals who are ready to support you 24/7:\n\n"
             "• National Center for Mental Health (NCMH): 1553 (Toll-Free) or 0917-899-8727\n"
             "• Hopeline Philippines: 0917-558-4673 / (02) 8804-4673\n"
             "• In Touch Crisis Line: 0917-800-1123 / (02) 8893-7603\n\n"
             "Please call or text one of these numbers now. You don't have to carry this heavy burden all by yourself, and I am here with you.";
    } else if (language == 'filipino') {
      return "Naririnig kita, at mahalaga ang buhay mo. Alam kong napakabigat ng pinagdadaanan mo ngayon, pero pakiusap, huwag mong harapin ito nang nag-iisa. Nandito ang tulong para sa iyo 24/7:\n\n"
             "• NCMH Crisis Hotline: 1553 (Toll-Free) o 0917-899-8727\n"
             "• Hopeline Philippines: 0917-558-4673 / (02) 8804-4673\n"
             "• In Touch Crisis Line: 0917-800-1123 / (02) 8893-7603\n\n"
             "Pakiusap, tumawag ka agad sa alinman sa mga numero sa taas. May mga taong handang makinig at magmalasakit sa iyo ngayong oras na ito.";
    } else { // Taglish
      return "Naiintindihan ko kung gaano kabigat ang nararamdaman mo ngayon, at mahalaga ang buhay mo. Pakiusap, huwag mong solohin 'to. Humingi tayo agad ng tulong sa mga propesyonal na handang makinig 24/7:\n\n"
             "• NCMH Crisis Hotline: 1553 (Toll-Free) or 0917-899-8727\n"
             "• Hopeline Philippines: 0917-558-4673 / (02) 8804-4673\n"
             "• In Touch Crisis Line: 0917-800-1123 / (02) 8893-7603\n\n"
             "Pakiusap, tumawag ka agad sa alinman sa mga hotlines na 'to. May mga taong totoong nagmamalasakit sa'yo, at nandito rin ako para sa'yo.";
    }
  }

  static Future<String> generateCompanionResponse({
    required String userText,
    required String companionId, // 'kai', 'ann', 'bee'
    required String language,    // 'taglish', 'filipino', 'english'
    String? mood,
    bool useReasoning = true,
  }) async {
    // 0. Safety Intercept: Immediate Crisis Intervention for self-harm or suicidal statements
    if (isCrisisMessage(userText)) {
      return getCrisisResponse(companionId, language);
    }

    final apiKey = EnvConfig.groqApiKey;
    final systemPrompt = _getSystemPrompt(companionId, language);

    ApiLogger.logRequest(
      apiName: 'Groq AI Service',
      method: 'POST',
      url: 'https://api.groq.com/openai/v1/chat/completions',
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: {
        'model': EnvConfig.primaryAiModel,
        'companion': companionId,
        'language': language,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userText},
        ],
        'temperature': 0.7,
      },
    );

    if (apiKey.isEmpty || apiKey == 'gsk_your_groq_api_key_here') {
      return _getOfflineFallbackResponse(companionId, userText, language);
    }

    if (useReasoning) {
      try {
        final res = await _callGroqReasoning(
          apiKey: apiKey,
          model: EnvConfig.reasoningAiModel,
          systemPrompt: systemPrompt,
          userText: userText,
        );
        if (res.content.isNotEmpty) {
          return res.content;
        }
      } catch (e) {
        print("Groq Reasoning Model error: $e. Falling back to primary model...");
      }
    }

    // 1. Try Primary Text Generation Model (llama-3.3-70b-versatile)
    try {
      return await _callGroqText(
        apiKey: apiKey,
        model: EnvConfig.primaryAiModel,
        systemPrompt: systemPrompt,
        userText: userText,
      );
    } catch (e) {
      print("Groq Primary Model error: $e. Retrying with fallback model...");
      // 2. Try Fallback Text Generation Model (llama-3.1-8b-instant)
      try {
        return await _callGroqText(
          apiKey: apiKey,
          model: EnvConfig.fallbackAiModel,
          systemPrompt: systemPrompt,
          userText: userText,
        );
      } catch (fallbackErr) {
        print("Groq Fallback Model error: $fallbackErr. Using offline response.");
        return _getOfflineFallbackResponse(companionId, userText, language);
      }
    }
  }

  /// Calls Groq Chat Completions API with Reasoning Model parameters
  static Future<GroqResponse> _callGroqReasoning({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userText,
  }) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final bool isGptOss = model.startsWith('openai/');

    final Map<String, dynamic> requestBody = {
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userText},
      ],
      'temperature': 0.7,
      'max_tokens': 1000,
    };

    if (isGptOss) {
      requestBody['include_reasoning'] = true;
      requestBody['reasoning_effort'] = 'medium';
    }

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json; charset=utf-8',
    };

    ApiLogger.logRequest(
      apiName: 'Groq AI (Reasoning: $model)',
      method: 'POST',
      url: url.toString(),
      headers: headers,
      body: requestBody,
    );

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(requestBody),
    ).timeout(const Duration(seconds: 15));

    ApiLogger.logResponse(
      apiName: 'Groq AI (Reasoning: $model)',
      statusCode: response.statusCode,
      url: url.toString(),
      body: response.body,
      reasonPhrase: response.reasonPhrase,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final message = data['choices'][0]['message'];
      final content = message['content'] ?? '';
      final reasoning = message['reasoning'];

      // Strip <think> tags if present in raw content
      String cleanedContent = content
          .toString()
          .replaceAll(RegExp(r'<think>[\s\S]*?<\/think>'), '')
          .trim();
      if (cleanedContent.isEmpty && content.toString().isNotEmpty) {
        cleanedContent = content.toString().trim();
      }

      ApiLogger.logRetrievedDataDisplayed(
        screenName: 'JournalEditorScreen / UnifiedEntriesScreen',
        componentName: '_buildAiReplyBox (MarkdownBody)',
        displayedData: cleanedContent,
        note: 'Rendered dynamically in UI with companion mascot theme',
      );

      return GroqResponse(
        content: cleanedContent,
        reasoning: reasoning?.toString(),
      );
    } else {
      throw Exception('Groq Reasoning API error ${response.statusCode}: ${response.body}');
    }
  }

  /// Calls Groq Standard Chat Completions API (text generation)
  static Future<String> _callGroqText({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userText,
  }) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json; charset=utf-8',
    };
    final requestBody = {
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userText},
      ],
      'temperature': 0.7,
      'max_tokens': 750,
    };

    ApiLogger.logRequest(
      apiName: 'Groq AI ($model)',
      method: 'POST',
      url: url.toString(),
      headers: headers,
      body: requestBody,
    );

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(requestBody),
    ).timeout(const Duration(seconds: 12));

    ApiLogger.logResponse(
      apiName: 'Groq AI ($model)',
      statusCode: response.statusCode,
      url: url.toString(),
      body: response.body,
      reasonPhrase: response.reasonPhrase,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final text = data['choices'][0]['message']['content'].toString().trim();

      ApiLogger.logRetrievedDataDisplayed(
        screenName: 'JournalEditorScreen / UnifiedEntriesScreen',
        componentName: '_buildAiReplyBox (MarkdownBody)',
        displayedData: text,
        note: 'Rendered dynamically in UI with companion mascot theme',
      );

      return text;
    } else {
      throw Exception('Groq Text API error ${response.statusCode}: ${response.body}');
    }
  }

  static String _getSystemPrompt(String companionId, String language) {
    String personaName = companionId == 'ann' ? 'Ann' : (companionId == 'bee' ? 'Bee' : 'Kai');
    String memoryContext = AIMemoryService.getMemoryContextPrompt();

    String personaStyle = "";
    if (companionId == 'ann') {
      personaStyle = "You are Ann, a warm, gentle, nurturing, and empathetic Filipino best friend (kaibigan) and wellness companion.";
    } else if (companionId == 'bee') {
      personaStyle = "You are Bee, an energetic, cheerful, and encouraging Filipino wellness companion.";
    } else {
      personaStyle = "You are Kai, a calm, grounded, deeply understanding, and supportive Filipino guy friend (kaibigan) and wellness companion.";
    }

    String langGuide = "";
    if (language == 'filipino') {
      langGuide = "Wika: Gamitin ang natural, magiliw, at taos-pusong wikang Filipino/Tagalog. Maging mapagkalinga at madaling lapitan.";
    } else if (language == 'english') {
      langGuide = "Language: Write in warm, gentle, empathetic, and conversational English, like a trusted close friend.";
    } else {
      langGuide = "Language: Write in natural, modern Taglish (conversational mix of Tagalog and English as used by young Filipinos). Avoid awkward formal Tagalog or robotic translations. Speak naturally like a caring friend chatting in a cafe.";
    }

    return '''
$personaStyle
You are $personaName, the user's personal Kaibigan (trusted companion). The user is writing in their private journal to reflect on their thoughts, feelings, day, or struggles.

$langGuide

${memoryContext.isNotEmpty ? "$memoryContext\n\n" : ""}GUIDELINES FOR YOUR REFLECTION:
1. TALK LIKE A REAL, CARING FRIEND:
   - Speak directly to the user with warmth, sincerity, and compassion.
   - Acknowledge and validate whatever they shared—whether it's joy, stress, tiredness, confusion, or gratitude.
   - Do NOT use robotic headers like "Growth Reflection:" or "Gentle Question:" or "Insight:". Write naturally in cozy, flowing paragraphs.

2. STRUCTURE YOUR RESPONSE WITH BEAUTIFUL MARKDOWN:
   - Start with a warm, empathetic reflection (1-2 short paragraphs) that shows you truly listened, giving them comfort, perspective, or a gentle reminder to breathe.
   - End with a single, thoughtful, non-intrusive question or comforting sign-off formatted naturally in italics (*tulad nito*), encouraging them to look inward with kindness.

3. ABSOLUTE GUARDRAILS:
   - NEVER say "As an AI", "I am a language model", "I don't have feelings", or break character.
   - Do not give clinical medical diagnoses or preach.
   - Keep the length concise and cozy (around 60 to 120 words), making it a delight and comfort to read.
   - Always finish all thoughts and sentences completely.
''';
  }

  static String _getOfflineFallbackResponse(String companionId, String userText, String language) {
    String reply;
    if (companionId == 'ann') {
      if (language == 'english') {
        reply = "I hear you, and your feelings are completely valid. Take a deep breath—you don't have to carry all this pressure at once. How are you taking care of yourself today?";
      } else {
        reply = "Naiintindihan ko ang nararamdaman mo. Mahirap man ang mga pinagdadaanan mo ngayon, nandito lang ako para makinig. Huwag mong kalimutang magpahinga kahit sandali.";
      }
    } else if (companionId == 'bee') {
      if (language == 'english') {
        reply = "Thank you for sharing your heart with me! You are doing so much better than you give yourself credit for. What is one small gentle thing you can do for yourself right now?";
      } else {
        reply = "Ang galing mo kasi pinili mong mag-express ngayon! Valid na valid ang nararamdaman mo. Anong maliit na bagay ang pwedeng magpagaan ng dibdib mo ngayon?";
      }
    } else { // Kai
      if (language == 'english') {
        reply = "I understand how you feel. When everything feels heavy at once, it's okay to slow down. What do you think is causing the biggest pressure right now?";
      } else {
        reply = "Naiintindihan ko. Kapag sabay-sabay dumadating ang mga bagay, madaling maramdaman na sobra na. Kahit alam kong kaya mo naman, parang ang bigat pa rin sa dibdib. Nandito lang ako para makinig.";
      }
    }

    ApiLogger.logResponse(
      apiName: 'Groq AI (Local Fallback Engine)',
      statusCode: 200,
      url: 'https://api.groq.com/openai/v1/chat/completions',
      body: {
        'id': 'chatcmpl-fallback-${DateTime.now().millisecondsSinceEpoch}',
        'model': EnvConfig.primaryAiModel,
        'choices': [
          {
            'message': {'role': 'assistant', 'content': reply}
          }
        ]
      },
    );

    ApiLogger.logRetrievedDataDisplayed(
      screenName: 'JournalEditorScreen / UnifiedEntriesScreen',
      componentName: '_buildAiReplyBox (MarkdownBody)',
      displayedData: reply,
      note: 'Rendered dynamically in UI with companion mascot theme',
    );

    return reply;
  }
}

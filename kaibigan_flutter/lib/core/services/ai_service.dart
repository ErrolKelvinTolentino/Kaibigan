import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/env_config.dart';

class AIService {
  static Future<String> generateCompanionResponse({
    required String userText,
    required String companionId, // 'kai', 'ann', 'bee'
    required String language,    // 'taglish', 'filipino', 'english'
    String? mood,
  }) async {
    final apiKey = EnvConfig.groqApiKey;

    if (apiKey.isEmpty || apiKey == 'gsk_your_groq_api_key_here') {
      return _getOfflineFallbackResponse(companionId, userText, language);
    }

    final systemPrompt = _getSystemPrompt(companionId, language);

    try {
      // Try primary model first
      return await _callGroq(
        apiKey: apiKey,
        model: EnvConfig.primaryAiModel,
        systemPrompt: systemPrompt,
        userText: userText,
      );
    } catch (e) {
      print("Primary AI model failed ($e). Attempting fallback model...");
      try {
        return await _callGroq(
          apiKey: apiKey,
          model: EnvConfig.fallbackAiModel,
          systemPrompt: systemPrompt,
          userText: userText,
        );
      } catch (fallbackErr) {
        print("Fallback AI model failed ($fallbackErr). Using empathetic local reflection.");
        return _getOfflineFallbackResponse(companionId, userText, language);
      }
    }
  }

  static Future<String> _callGroq({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userText,
  }) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userText},
        ],
        'temperature': 0.7,
        'max_tokens': 250,
      }),
    ).timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['choices'][0]['message']['content'];
      return text.toString().trim();
    } else {
      throw Exception('Groq API status ${response.statusCode}: ${response.body}');
    }
  }

  static String _getSystemPrompt(String companionId, String language) {
    String personaDetails = "";
    if (companionId == 'ann') {
      personaDetails = "You are Ann, a warm, empathetic, and nurturing female AI companion.";
    } else if (companionId == 'bee') {
      personaDetails = "You are Bee, a friendly, expressive, highly validating, and inclusive companion representing LGBTQIA+ warmth.";
    } else {
      personaDetails = "You are Kai, a calm, steady, and encouraging companion.";
    }

    String langDetails = "";
    if (language == 'filipino') {
      langDetails = "Respond in natural, gentle Filipino language.";
    } else if (language == 'english') {
      langDetails = "Respond in warm, clear English.";
    } else {
      langDetails = "Respond in natural Taglish (mix of Tagalog and English as used by young Filipinos).";
    }

    return '''
$personaDetails
You are Kaibigan, a mental wellness companion for Filipinos.
$langDetails

GUIDELINES:
1. Provide a short, compassionate 2-3 sentence reflection or gentle follow-up question.
2. DO NOT give medical or psychiatric advice or diagnoses.
3. Be deeply understanding, validating their feelings without judgment.
4. Keep the tone warm, soothing, and culturally empathetic (e.g. use caring Taglish/Filipino phrasing when appropriate).
''';
  }

  static String _getOfflineFallbackResponse(String companionId, String userText, String language) {
    if (companionId == 'ann') {
      if (language == 'english') {
        return "I hear you, and your feelings are completely valid. Take a deep breath—you don't have to carry all this pressure at once. How are you taking care of yourself today?";
      } else {
        return "Naiintindihan ko ang nararamdaman mo. Mahirap man ang mga pinagdadaanan mo ngayon, nandito lang ako para makinig. Huwag mong kalimutang magpahinga kahit sandali.";
      }
    } else if (companionId == 'bee') {
      if (language == 'english') {
        return "Thank you for sharing your heart with me! You are doing so much better than you give yourself credit for. What is one small gentle thing you can do for yourself right now?";
      } else {
        return "Ang galing mo kasi pinili mong mag-express ngayon! Valid na valid ang nararamdaman mo. Anong maliit na bagay ang pwedeng magpagaan ng dibdib mo ngayon?";
      }
    } else { // Kai
      if (language == 'english') {
        return "Naiintindihan ko. When everything feels heavy at once, it's okay to slow down. What do you think is causing the biggest pressure right now?";
      } else {
        return "Nalintindihan ho. Kapag sabay-sabay dumadating ang mga bagay, madaling maramdaman na sobra na. Kahit alam kong kaya mo naman, parang ang bigat pa rin sa dibdib. Mas yang pressure siguro. Parang kailangan kong tama lagi, kahit sa sarili ko.";
      }
    }
  }
}

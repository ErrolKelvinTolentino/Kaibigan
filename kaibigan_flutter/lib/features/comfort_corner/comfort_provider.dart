import 'package:flutter/material.dart';

class ComfortQuote {
  final String quote;
  final String author;
  final String language;

  const ComfortQuote({
    required this.quote,
    required this.author,
    this.language = 'taglish',
  });
}

class ComfortProvider extends ChangeNotifier {
  int _groundingStep = 0; // 0 to 4 (5 see, 4 feel, 3 hear, 2 smell, 1 taste)

  int get groundingStep => _groundingStep;

  final List<ComfortQuote> quotes = const [
    ComfortQuote(quote: 'Huminga ka nang malalim. Hindi mo kailangang ayusin ang lahat sa isang iglap lang.', author: 'Kaibigan', language: 'taglish'),
    ComfortQuote(quote: 'Your pace is your own. Healing and growth are never a sprint.', author: 'Gentle Reminder', language: 'english'),
    ComfortQuote(quote: 'Valid ang nararamdaman mo. Ang paghingi ng pahinga ay hindi nangangahulugang sumusuko ka.', author: 'Ann', language: 'filipino'),
    ComfortQuote(quote: 'Small steps every day build a quiet, unbreakable inner strength.', author: 'Kai', language: 'english'),
  ];

  final List<Map<String, String>> groundingStepsData = const [
    {'title': '5 Things You Can See', 'desc': 'Look around your room. Notice 5 distinct colors or shapes.'},
    {'title': '4 Things You Can Touch', 'desc': 'Feel your feet on the ground, your shirt fabric, or a cool surface.'},
    {'title': '3 Things You Can Hear', 'desc': 'Listen closely. A passing fan, distant birds, or gentle wind.'},
    {'title': '2 Things You Can Smell', 'desc': 'Breathe in deeply. Fresh coffee, clean air, or paper.'},
    {'title': '1 Thing You Can Taste', 'desc': 'Take a sip of water or notice the quiet taste on your tongue.'},
  ];

  void nextGroundingStep() {
    if (_groundingStep < groundingStepsData.length - 1) {
      _groundingStep++;
    } else {
      _groundingStep = 0;
    }
    notifyListeners();
  }

  void resetGrounding() {
    _groundingStep = 0;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';

class FutureLetter {
  final String id;
  final String title;
  final String content;
  final DateTime deliverAt;
  final bool isOpened;
  final DateTime createdAt;

  FutureLetter({
    required this.id,
    required this.title,
    required this.content,
    required this.deliverAt,
    this.isOpened = false,
    required this.createdAt,
  });

  bool get isReadyToUnlock => DateTime.now().isAfter(deliverAt);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'deliver_at': deliverAt.toIso8601String(),
      'is_opened': isOpened,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FutureLetter.fromMap(Map<String, dynamic> map) {
    return FutureLetter(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      deliverAt: map['deliver_at'] != null 
          ? DateTime.parse(map['deliver_at']) 
          : DateTime.now().add(const Duration(days: 7)),
      isOpened: map['is_opened'] ?? false,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
    );
  }
}

class LettersProvider extends ChangeNotifier {
  final List<FutureLetter> _letters = [];
  bool _isLoading = false;

  List<FutureLetter> get letters => List.unmodifiable(_letters);
  bool get isLoading => _isLoading;

  LettersProvider() {
    _initSampleData();
  }

  void _initSampleData() {
    final now = DateTime.now();
    _letters.addAll([
      FutureLetter(
        id: 'fl-1',
        title: 'Para sa akin sa susunod na buwan',
        content: 'Sana mas magaan na ang puso mo habang binabasa mo ito. Remember how hard you worked on your capstone project! I am so proud of you.',
        deliverAt: now.add(const Duration(days: 30)),
        isOpened: false,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      FutureLetter(
        id: 'fl-2',
        title: 'A note from last week',
        content: 'You felt stressed on Monday, but look—you made it through gracefully! Always trust your resilience.',
        deliverAt: now.subtract(const Duration(hours: 1)),
        isOpened: true,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
    ]);
  }

  Future<void> fetchLetters() async {
    if (!SupabaseService.isInitialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseService.client
          .from('future_letters')
          .select()
          .order('created_at', ascending: false);

      final List data = response as List;
      _letters.clear();
      _letters.addAll(data.map((e) => FutureLetter.fromMap(e)).toList());
    } catch (e) {
      print("Error fetching letters from Supabase: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<FutureLetter> createLetter({
    required String title,
    required String content,
    required DateTime deliverAt,
  }) async {
    _isLoading = true;
    notifyListeners();

    final newLetter = FutureLetter(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      deliverAt: deliverAt,
      isOpened: false,
      createdAt: DateTime.now(),
    );

    _letters.insert(0, newLetter);

    if (SupabaseService.isInitialized) {
      try {
        await SupabaseService.client
            .from('future_letters')
            .insert(newLetter.toMap());
      } catch (e) {
        print("Error saving letter to Supabase: $e");
      }
    }

    _isLoading = false;
    notifyListeners();
    return newLetter;
  }
}

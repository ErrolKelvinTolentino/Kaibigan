import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/api_logger.dart';
import '../../core/utils/uuid_helper.dart';

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

  Map<String, dynamic> toMap({String? userId}) {
    final validId = UuidHelper.isValidUuid(id) ? id : UuidHelper.generateV4();
    final map = <String, dynamic>{
      'id': validId,
      'title': title,
      'content': content,
      'deliver_at': deliverAt.toIso8601String(),
      'is_opened': isOpened,
      'created_at': createdAt.toIso8601String(),
    };
    if (userId != null && userId.isNotEmpty) {
      map['user_id'] = userId;
    }
    return map;
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
  String? _errorMessage;
  String? _activeUserId;

  List<FutureLetter> get letters => List.unmodifiable(_letters);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  LettersProvider() {
    syncForCurrentUser();
  }

  void syncForCurrentUser() {
    final userId = SupabaseService.isInitialized
        ? SupabaseService.client.auth.currentUser?.id
        : null;
    if (userId == _activeUserId) return;
    _activeUserId = userId;
    _letters.clear();
    _errorMessage = null;
    notifyListeners();
    if (userId != null) fetchLetters();
  }

  Future<void> fetchLetters() async {
    _errorMessage = null;
    if (!SupabaseService.isInitialized) {
      _errorMessage = 'Future Letter sync is unavailable.';
      notifyListeners();
      return;
    }
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final query = SupabaseService.client
          .from('future_letters')
          .select()
          .eq('user_id', userId);
      final response = await query.order('created_at', ascending: false);

      final List data = response as List;
      _letters.clear();
      _letters.addAll(data.map((e) => FutureLetter.fromMap(e)).toList());
    } catch (e) {
      _errorMessage = 'We could not refresh your Future Letters.';
      ApiLogger.logDatabase(
        operation: 'SELECT',
        table: 'future_letters',
        error: e.toString(),
      );
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
    _errorMessage = null;
    notifyListeners();

    final newLetter = FutureLetter(
      id: UuidHelper.generateV4(),
      title: title,
      content: content,
      deliverAt: deliverAt,
      isOpened: false,
      createdAt: DateTime.now(),
    );

    var saved = false;
    if (SupabaseService.isInitialized &&
        SupabaseService.client.auth.currentUser != null) {
      try {
        final userId = SupabaseService.client.auth.currentUser!.id;
        await SupabaseService.client
            .from('future_letters')
            .insert(newLetter.toMap(userId: userId));
        saved = true;
      } catch (e) {
        _errorMessage =
            'Your Future Letter could not be saved. Please try again.';
        ApiLogger.logDatabase(
          operation: 'INSERT',
          table: 'future_letters',
          error: e.toString(),
        );
      }
    } else {
      _errorMessage =
          'Your Future Letter could not be saved because sync is unavailable.';
    }

    if (saved) _letters.insert(0, newLetter);

    _isLoading = false;
    notifyListeners();
    return newLetter;
  }

  Future<void> deleteLetter(String id) async {
    _errorMessage = null;
    if (!SupabaseService.isInitialized ||
        SupabaseService.client.auth.currentUser == null) {
      _errorMessage =
          'The letter could not be deleted because sync is unavailable.';
      notifyListeners();
      return;
    }
    final index = _letters.indexWhere((letter) => letter.id == id);
    if (index == -1) return;
    final removed = _letters.removeAt(index);
    notifyListeners();

    if (SupabaseService.isInitialized && UuidHelper.isValidUuid(id)) {
      try {
        await SupabaseService.client
            .from('future_letters')
            .delete()
            .eq('id', id);
      } catch (e) {
        _letters.insert(index.clamp(0, _letters.length), removed);
        _errorMessage =
            'The letter could not be deleted. It has been restored.';
        ApiLogger.logDatabase(
          operation: 'DELETE',
          table: 'future_letters',
          error: e.toString(),
        );
      }
    }
    notifyListeners();
  }
}

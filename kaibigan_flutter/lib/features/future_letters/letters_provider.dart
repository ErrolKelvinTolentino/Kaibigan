import 'package:flutter/material.dart';
import '../../core/services/local_record_store.dart';
import '../../core/services/offline_mode.dart';
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

  FutureLetter copyWith({
    String? title,
    String? content,
    DateTime? deliverAt,
    bool? isOpened,
  }) {
    return FutureLetter(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      deliverAt: deliverAt ?? this.deliverAt,
      isOpened: isOpened ?? this.isOpened,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap({String? userId}) {
    final validId = UuidHelper.isValidUuid(id) ? id : UuidHelper.generateV4();
    final map = <String, dynamic>{
      'id': validId,
      'title': title,
      'content': content,
      'deliver_at': deliverAt.toUtc().toIso8601String(),
      'is_opened': isOpened,
      'created_at': createdAt.toUtc().toIso8601String(),
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
          ? DateTime.parse(map['deliver_at']).toLocal()
          : DateTime.now().add(const Duration(days: 7)),
      isOpened: map['is_opened'] ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at']).toLocal()
          : DateTime.now(),
    );
  }
}

class LettersProvider extends ChangeNotifier {
  final List<FutureLetter> _letters = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _activeUserId;

  List<FutureLetter> get letters => List.unmodifiable(
      List<FutureLetter>.of(_letters)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  LettersProvider() {
    syncForCurrentUser();
  }

  /// Offline letters are stored in the same shape the table uses.
  static final LocalRecordStore<FutureLetter> _local =
      LocalRecordStore<FutureLetter>(
    collection: 'future_letters',
    encode: (letter) => letter.toMap(),
    decode: FutureLetter.fromMap,
    idOf: (letter) => letter.id,
  );

  void syncForCurrentUser() {
    if (OfflineMode.storesLocally) {
      _activeUserId = null;
      _errorMessage = null;
      fetchLetters();
      return;
    }
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == _activeUserId) return;
    _activeUserId = userId;
    _letters.clear();
    _errorMessage = null;
    notifyListeners();
    if (userId != null) fetchLetters();
  }

  Future<void> fetchLetters() async {
    _errorMessage = null;
    if (OfflineMode.storesLocally) {
      final stored = await _local.load(OfflineMode.scope);
      _letters
        ..clear()
        ..addAll(stored)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _isLoading = false;
      notifyListeners();
      return;
    }
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
      _letters.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

  Future<FutureLetter?> createLetter({
    required String title,
    required String content,
    required DateTime deliverAt,
  }) async {
    final cleanTitle = title.trim();
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) {
      _errorMessage = 'Write a message before sealing your Future Letter.';
      notifyListeners();
      return null;
    }
    if (!deliverAt.isAfter(DateTime.now())) {
      _errorMessage = 'Choose a delivery date in the future.';
      notifyListeners();
      return null;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final newLetter = FutureLetter(
      id: UuidHelper.generateV4(),
      title: cleanTitle.isEmpty ? 'Letter to Future Self' : cleanTitle,
      content: cleanContent,
      deliverAt: deliverAt,
      isOpened: false,
      createdAt: DateTime.now(),
    );

    var saved = false;
    if (OfflineMode.storesLocally) {
      saved = await _local.upsert(OfflineMode.scope, newLetter);
      if (!saved) {
        _errorMessage =
            'Your Future Letter could not be saved to this device.';
      }
    } else if (SupabaseService.isInitialized &&
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

    if (saved) {
      _letters.removeWhere((item) => item.id == newLetter.id);
      _letters.insert(0, newLetter);
      _letters.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    _isLoading = false;
    notifyListeners();
    return saved ? newLetter : null;
  }

  Future<bool> updateLetter(FutureLetter updated) async {
    _errorMessage = null;
    if (updated.title.trim().isEmpty || updated.content.trim().isEmpty) {
      _errorMessage = 'A Future Letter needs both a title and a message.';
      notifyListeners();
      return false;
    }
    if (OfflineMode.storesLocally) {
      final index = _letters.indexWhere((letter) => letter.id == updated.id);
      if (index == -1) {
        _errorMessage = 'This letter is no longer available.';
        notifyListeners();
        return false;
      }
      final previous = _letters[index];
      _letters[index] = updated;
      final stored = await _local.upsert(OfflineMode.scope, updated);
      if (!stored) {
        _letters[index] = previous;
        _errorMessage = 'Your changes could not be saved to this device.';
      }
      notifyListeners();
      return stored;
    }
    final userId = SupabaseService.isInitialized
        ? SupabaseService.client.auth.currentUser?.id
        : null;
    if (userId == null || !UuidHelper.isValidUuid(updated.id)) {
      _errorMessage =
          'The letter could not be updated because sync is unavailable.';
      notifyListeners();
      return false;
    }
    final index = _letters.indexWhere((letter) => letter.id == updated.id);
    if (index == -1) {
      _errorMessage = 'This Future Letter is no longer available.';
      notifyListeners();
      return false;
    }

    final previous = _letters[index];
    _letters[index] = updated;
    _letters.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
    try {
      await SupabaseService.client
          .from('future_letters')
          .update(updated.toMap(userId: userId))
          .eq('id', updated.id)
          .eq('user_id', userId)
          .select()
          .single();
      return true;
    } catch (e) {
      _letters[index] = previous;
      _errorMessage = 'The letter could not be updated. Please try again.';
      ApiLogger.logDatabase(
        operation: 'UPDATE',
        table: 'future_letters',
        error: e.toString(),
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteLetter(String id) async {
    _errorMessage = null;
    if (OfflineMode.storesLocally) {
      final index = _letters.indexWhere((letter) => letter.id == id);
      if (index == -1) return true;
      final removed = _letters.removeAt(index);
      notifyListeners();
      final cleared = await _local.remove(OfflineMode.scope, id);
      if (!cleared) {
        _letters.insert(index.clamp(0, _letters.length), removed);
        _errorMessage =
            'The letter could not be deleted. It has been restored.';
        notifyListeners();
      }
      return cleared;
    }
    if (!SupabaseService.isInitialized ||
        SupabaseService.client.auth.currentUser == null) {
      _errorMessage =
          'The letter could not be deleted because sync is unavailable.';
      notifyListeners();
      return false;
    }
    final index = _letters.indexWhere((letter) => letter.id == id);
    if (index == -1) return true;
    final removed = _letters.removeAt(index);
    notifyListeners();

    if (SupabaseService.isInitialized && UuidHelper.isValidUuid(id)) {
      try {
        final userId = SupabaseService.client.auth.currentUser!.id;
        await SupabaseService.client
            .from('future_letters')
            .delete()
            .eq('id', id)
            .eq('user_id', userId)
            .select()
            .single();
      } catch (e) {
        _letters.insert(index.clamp(0, _letters.length), removed);
        _errorMessage =
            'The letter could not be deleted. It has been restored.';
        ApiLogger.logDatabase(
          operation: 'DELETE',
          table: 'future_letters',
          error: e.toString(),
        );
        notifyListeners();
        return false;
      }
    }
    notifyListeners();
    return true;
  }
}

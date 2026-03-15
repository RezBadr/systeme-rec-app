import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

/// A small auth/session cache that persists the JWT + preferences-loaded state.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _kTokenKey = 'auth_token';
  static const _kPreferencesCompleteKey = 'preferences_complete';
  static const _kUserIdKey = 'user_id';

  final ValueNotifier<bool> isReady = ValueNotifier(false);
  final ValueNotifier<bool> isLoggedInNotifier = ValueNotifier(false);
  final ValueNotifier<bool> preferencesCompleteNotifier = ValueNotifier(false);

  String? _token;
  int? _userId;
  bool _preferencesComplete = false;

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  bool get preferencesComplete => _preferencesComplete;
  String? get token => _token;
  int? get userId => _userId;

  bool _hasSavedPreferences(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      return false;
    }

    final preferredGenres = payload['preferredGenres'];
    if (preferredGenres is List && preferredGenres.isNotEmpty) {
      return true;
    }

    final genreIds = payload['genreIds'];
    if (genreIds is List && genreIds.isNotEmpty) {
      return true;
    }

    final genres = payload['genres'];
    if (genres is List && genres.isNotEmpty) {
      return true;
    }

    return false;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kTokenKey);
    _userId = prefs.getInt(_kUserIdKey);
    _preferencesComplete = prefs.getBool(_kPreferencesCompleteKey) ?? false;

    if (isLoggedIn && _userId != null) {
      // Check with backend if preferences exist
      try {
        final data = await ApiService.get('/users/$_userId/preferences', token: _token);
        _preferencesComplete = _hasSavedPreferences(data);
      } catch (_) {
        _preferencesComplete = false;
      }
    }

    isLoggedInNotifier.value = isLoggedIn;
    preferencesCompleteNotifier.value = _preferencesComplete;
    isReady.value = true;
  }

  Future<void> _saveToken(String token, int userId) async {
    _token = token;
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, token);
    await prefs.setInt(_kUserIdKey, userId);
    isLoggedInNotifier.value = isLoggedIn;
  }

  Future<void> _savePreferencesComplete(bool complete) async {
    _preferencesComplete = complete;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPreferencesCompleteKey, complete);
    preferencesCompleteNotifier.value = _preferencesComplete;
  }

  Future<void> login({required String email, required String password}) async {
    final response = await ApiService.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );

    final data = response as Map<String, dynamic>;
    final token = data['token'] as String?;
    final user = data['user'] as Map<String, dynamic>?;
    final userId = user?['id'] as int?;

    if (token == null || token.isEmpty || userId == null) {
      throw Exception('Le serveur n\'a pas renvoyé de données utilisateur valides.');
    }

    await _saveToken(token, userId);

    // Vérifier préférences existantes
    try {
      final prefData = await ApiService.get('/users/$userId/preferences', token: token);
      final complete = _hasSavedPreferences(prefData);
      await _savePreferencesComplete(complete);
    } catch (_) {
      await _savePreferencesComplete(false);
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _preferencesComplete = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
    await prefs.remove(_kUserIdKey);
    await prefs.remove(_kPreferencesCompleteKey);
    isLoggedInNotifier.value = false;
    preferencesCompleteNotifier.value = false;
    isReady.value = true;
  }

  Future<void> setPreferences(List<int> genreIds) async {
    if (!isLoggedIn || _userId == null) {
      throw Exception('Utilisateur non connecté');
    }

    await ApiService.post(
      '/users/$_userId/preferences',
      token: _token,
      body: {'genreIds': genreIds},
    );

    await _savePreferencesComplete(true);
  }
}

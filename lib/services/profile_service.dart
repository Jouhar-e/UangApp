import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uangapp/core/constants/app_constants.dart';
import 'package:uangapp/models/user_profile.dart';

class ProfileService extends ChangeNotifier {
  UserProfile? _memoryCache;

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<UserProfile> loadProfile() async {
    if (_memoryCache != null) return _memoryCache!;
    final prefs = await _prefs;
    final raw = prefs.getString(AppConstants.cacheProfileKey);
    if (raw == null || raw.isEmpty) {
      _memoryCache = const UserProfile();
      return _memoryCache!;
    }
    _memoryCache =
        UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return _memoryCache!;
  }

  Future<void> saveProfile(UserProfile profile) async {
    _memoryCache = profile;
    final prefs = await _prefs;
    await prefs.setString(
      AppConstants.cacheProfileKey,
      jsonEncode(profile.toJson()),
    );
    notifyListeners();
  }

  Future<UserProfile> refresh() async {
    _memoryCache = null;
    final profile = await loadProfile();
    notifyListeners();
    return profile;
  }
}

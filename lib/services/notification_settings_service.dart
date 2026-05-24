import 'package:shared_preferences/shared_preferences.dart';
import 'package:uangapp/core/constants/app_constants.dart';

class NotificationSettings {
  const NotificationSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final int hour;
  final int minute;
}

class NotificationSettingsService {
  Future<NotificationSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationSettings(
      enabled: prefs.getBool(AppConstants.notificationsEnabledKey) ?? true,
      hour: prefs.getInt(AppConstants.notificationHourKey) ?? 20,
      minute: prefs.getInt(AppConstants.notificationMinuteKey) ?? 0,
    );
  }

  Future<void> save(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      AppConstants.notificationsEnabledKey,
      settings.enabled,
    );
    await prefs.setInt(AppConstants.notificationHourKey, settings.hour);
    await prefs.setInt(AppConstants.notificationMinuteKey, settings.minute);
  }
}

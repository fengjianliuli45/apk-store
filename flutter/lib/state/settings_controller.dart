import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PostVisibility { public, friends, private }

extension PostVisibilityLabel on PostVisibility {
  String get label => switch (this) {
        PostVisibility.public => '所有人',
        PostVisibility.friends => '仅好友',
        PostVisibility.private => '仅自己',
      };
}

/// Settings, ported from the Compose SettingsScreen text groups. All state
/// is local (shared_preferences) — there's no account backend yet.
class SettingsController extends ChangeNotifier {
  bool trainingReminder = true;
  bool socialNotify = true;
  bool systemNotify = false;
  bool nearbyEnabled = true;
  bool metricUnits = true;
  String language = '简体中文';
  PostVisibility visibility = PostVisibility.friends;

  static const _kTrainingReminder = 'settings_training_reminder';
  static const _kSocialNotify = 'settings_social_notify';
  static const _kSystemNotify = 'settings_system_notify';
  static const _kNearbyEnabled = 'settings_nearby_enabled';
  static const _kMetricUnits = 'settings_metric_units';
  static const _kLanguage = 'settings_language';
  static const _kVisibility = 'settings_visibility';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    trainingReminder = prefs.getBool(_kTrainingReminder) ?? true;
    socialNotify = prefs.getBool(_kSocialNotify) ?? true;
    systemNotify = prefs.getBool(_kSystemNotify) ?? false;
    nearbyEnabled = prefs.getBool(_kNearbyEnabled) ?? true;
    metricUnits = prefs.getBool(_kMetricUnits) ?? true;
    language = prefs.getString(_kLanguage) ?? '简体中文';
    visibility = PostVisibility.values.byName(prefs.getString(_kVisibility) ?? PostVisibility.friends.name);
    notifyListeners();
  }

  Future<void> _save(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  void setTrainingReminder(bool value) {
    trainingReminder = value;
    notifyListeners();
    _save(_kTrainingReminder, value);
  }

  void setSocialNotify(bool value) {
    socialNotify = value;
    notifyListeners();
    _save(_kSocialNotify, value);
  }

  void setSystemNotify(bool value) {
    systemNotify = value;
    notifyListeners();
    _save(_kSystemNotify, value);
  }

  void setNearbyEnabled(bool value) {
    nearbyEnabled = value;
    notifyListeners();
    _save(_kNearbyEnabled, value);
  }

  void setMetricUnits(bool value) {
    metricUnits = value;
    notifyListeners();
    _save(_kMetricUnits, value);
  }

  void setLanguage(String value) {
    language = value;
    notifyListeners();
    _save(_kLanguage, value);
  }

  void setVisibility(PostVisibility value) {
    visibility = value;
    notifyListeners();
    _save(_kVisibility, value.name);
  }
}

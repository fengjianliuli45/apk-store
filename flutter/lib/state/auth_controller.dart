import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only auth flow. There's no configured SMS/Firebase project, so this
/// stays a debug-only stand-in: any phone number, fixed OTP "123456". Do NOT
/// wire this to a real backend without also removing the fixed code.
class AuthController extends ChangeNotifier {
  static const debugOtp = '123456';
  static const _kLoggedIn = 'auth_logged_in';
  static const _kPhone = 'auth_phone';

  bool loggedIn = false;
  String? phone;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    loggedIn = prefs.getBool(_kLoggedIn) ?? false;
    phone = prefs.getString(_kPhone);
    notifyListeners();
  }

  Future<bool> verifyOtp(String phoneNumber, String code) async {
    if (code != debugOtp) return false;
    loggedIn = true;
    phone = phoneNumber;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, true);
    await prefs.setString(_kPhone, phoneNumber);
    return true;
  }

  Future<void> skip() async {
    loggedIn = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, true);
  }

  Future<void> logout() async {
    loggedIn = false;
    phone = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, false);
  }
}

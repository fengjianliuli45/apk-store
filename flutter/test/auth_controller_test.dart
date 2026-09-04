import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/state/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('skipping local auth persists across controller recreation', () async {
    SharedPreferences.setMockInitialValues({});

    final first = AuthController();
    await first.skip();
    expect(first.loggedIn, isTrue);

    final restored = AuthController();
    await restored.load();
    expect(restored.loggedIn, isTrue);

    await restored.logout();
    final loggedOut = AuthController();
    await loggedOut.load();
    expect(loggedOut.loggedIn, isFalse);
  });
}

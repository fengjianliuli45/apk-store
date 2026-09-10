import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/screens/app_update_screen.dart';

void main() {
  test('release accepts only versioned HTTPS APKs on the configured host', () {
    final data = {
      'version': '1.0.1',
      'build': 2,
      'url': 'https://mainleaf.top/apk/stopwatch-1.0.1-2.apk',
    };
    expect(AppRelease.parse(data).build, 2);
    for (final url in [
      'http://mainleaf.top/apk/a.apk',
      'https://evil.example/apk/a.apk',
      'https://mainleaf.top/a.apk',
      'https://user@mainleaf.top/apk/a.apk',
      'https://mainleaf.top:8443/apk/a.apk',
    ]) {
      expect(
        () => AppRelease.parse({...data, 'url': url}),
        throwsFormatException,
      );
    }
    expect(
      () => AppRelease.parse({...data, 'build': '2'}),
      throwsFormatException,
    );
  });
}

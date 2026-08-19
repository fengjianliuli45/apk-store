import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/root_shell.dart';
import 'state/auth_controller.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';

void main() {
  runApp(const RestPodApp());
}

class RestPodApp extends StatelessWidget {
  const RestPodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rest Pod HUD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: AppFonts.inter,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.brandGreen,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.gradientTop,
      ),
      home: const _AppGate(),
    );
  }
}

/// Loads auth state, then shows the phone-login flow or the app shell.
/// "跳过" on login bypasses this entirely for local testing/demo builds.
class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  final _auth = AuthController();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChanged);
    _auth.load().then((_) => setState(() => _ready = true));
  }

  void _onAuthChanged() => setState(() {});

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_auth.loggedIn) {
      return LoginScreen(auth: _auth);
    }
    return RootShell(onLogout: _auth.logout);
  }
}

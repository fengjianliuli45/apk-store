import 'package:flutter/material.dart';

import 'screens/generating_plan_screen.dart';
import 'screens/goal_survey_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_survey_screen.dart';
import 'screens/root_shell.dart';
import 'screens/welcome_animation_screen.dart';
import 'state/auth_controller.dart';
import 'state/goal_controller.dart';
import 'state/plan_controller.dart';
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
  final _goal = GoalController();
  final _plan = PlanController();
  bool _ready = false;
  bool _welcomeShown = false;
  Map<String, dynamic>? _pendingProfileFields;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onChanged);
    _goal.addListener(_onChanged);
    _plan.addListener(_onChanged);
    Future.wait([_auth.load(), _goal.load(), _plan.load()]).then((_) => setState(() => _ready = true));
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _auth.removeListener(_onChanged);
    _goal.removeListener(_onChanged);
    _plan.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_auth.loggedIn) {
      _welcomeShown = false;
      _pendingProfileFields = null;
      return LoginScreen(auth: _auth);
    }
    if (!_goal.hasChosen) {
      return GoalSurveyScreen(goalController: _goal);
    }
    if (!_plan.hasPlan) {
      final pending = _pendingProfileFields;
      if (pending == null) {
        return ProfileSurveyScreen(
          onSubmit: (fields) => setState(() => _pendingProfileFields = fields),
        );
      }
      return GeneratingPlanScreen(
        goal: _goal.goal!,
        profileFields: pending,
        planController: _plan,
        onDone: () {},
      );
    }
    if (!_welcomeShown) {
      return WelcomeAnimationScreen(
        goal: _goal.goal!,
        onDone: () => setState(() => _welcomeShown = true),
      );
    }
    return RootShell(onLogout: _auth.logout, plan: _plan, goal: _goal, auth: _auth);
  }
}

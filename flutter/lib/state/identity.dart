import '../state/auth_controller.dart';
import 'goal_controller.dart';

/// Display helpers for the local (no-backend) account. Phone is whatever the
/// user typed at login; skip-login leaves it empty.
extension AuthIdentity on AuthController {
  String get digits => (phone ?? '').replaceAll(RegExp(r'\D'), '');

  String get maskedPhone {
    if (digits.length < 7) return '未绑定';
    return '+86 ${digits.substring(0, 3)} **** ${digits.substring(digits.length - 4)}';
  }

  String displayName(FitnessGoal? goal) {
    if (digits.length >= 4) return '训练者 ${digits.substring(digits.length - 4)}';
    return '${goal?.label ?? '训练'}学员';
  }

  String avatarGlyph(FitnessGoal? goal) {
    if (digits.length >= 2) return digits.substring(digits.length - 2);
    final label = goal?.label ?? '练';
    return label.charactersFirst;
  }
}

extension on String {
  String get charactersFirst => isEmpty ? '练' : substring(0, 1);
}

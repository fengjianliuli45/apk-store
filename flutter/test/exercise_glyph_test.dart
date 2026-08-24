import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/widgets/exercise_glyph.dart';

void main() {
  test('common training moves resolve to distinct poses, not one dumbbell', () {
    expect(resolveExerciseGlyph(id: 'bodyweight_squat', name: '徒手深蹲'), ExercisePose.squat);
    expect(resolveExerciseGlyph(id: 'barbell_bench_press', name: '杠铃卧推'), ExercisePose.benchPress);
    expect(resolveExerciseGlyph(id: 'pull_up', name: '引体向上'), ExercisePose.pullUp);
    expect(resolveExerciseGlyph(id: 'plank', name: '平板支撑'), ExercisePose.plank);
    expect(resolveExerciseGlyph(id: 'barbell_row', name: '杠铃划船'), ExercisePose.row);
    expect(resolveExerciseGlyph(id: 'dumbbell_shoulder_press', name: '哑铃推举'), ExercisePose.overheadPress);
    expect(resolveExerciseGlyph(id: 'dumbbell_curl', name: '哑铃弯举'), ExercisePose.curl);
    expect(resolveExerciseGlyph(name: '跳绳'), ExercisePose.jumpRope);
    expect(resolveExerciseGlyph(name: '慢跑'), ExercisePose.run);
  });

  test('catalog names without ids still pick a matching pose', () {
    expect(resolveExerciseGlyph(name: '深蹲'), ExercisePose.squat);
    expect(resolveExerciseGlyph(name: '保加利亚分腿蹲'), ExercisePose.lunge);
    expect(resolveExerciseGlyph(name: '硬拉'), ExercisePose.deadlift);
    expect(resolveExerciseGlyph(name: '侧平举'), ExercisePose.lateralRaise);
  });

  test('incline and decline presses stay on a bench, not overhead', () {
    expect(
      resolveExerciseGlyph(id: 'incline_barbell_press', name: '上斜杠铃推举'),
      ExercisePose.benchPress,
    );
    expect(
      resolveExerciseGlyph(id: 'decline_dumbbell_press', name: '下斜哑铃推举'),
      ExercisePose.benchPress,
    );
  });
}

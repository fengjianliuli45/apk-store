import 'exercise_library.dart';
import 'injury_planner.dart';
import 'load_planner.dart';
import 'models.dart';

/// Port of fitness-planner's `session_builder.py` (2026-08-30 容量↔课时重构).
///
/// - 周目标按「实际训练频率」整除铺到每次暴露，前重后轻，各次封顶到单次上限。
/// - 课时预算：先扣显式热身时间，再按「按动作类型区分的单组真实耗时」两遍填充
///   （先每个主肌群保底 1 个动作，再补深度，最后补次要肌群）。
/// - 时间/频率不够兑现周目标时不静默截断——由 [analyzeVolume] 产出诚实对账。
/// 基准表 = 增肌目标。其他目标按 [goalVolumeScale] 缩放。
const _baseWeeklyVolume = {
  'beginner': {
    'chest': 10, 'back': 12, 'quads': 10, 'hamstrings': 6, 'shoulders': 8,
    'biceps': 6, 'triceps': 6, 'calves': 4, 'core': 4,
  },
  'intermediate': {
    'chest': 14, 'back': 16, 'quads': 14, 'hamstrings': 8, 'shoulders': 12,
    'biceps': 8, 'triceps': 8, 'calves': 6, 'core': 6,
  },
  'advanced': {
    'chest': 16, 'back': 18, 'quads': 16, 'hamstrings': 10, 'shoulders': 14,
    'biceps': 10, 'triceps': 10, 'calves': 8, 'core': 8,
  },
};

const goalVolumeScale = {
  'hypertrophy': 1.0,
  'recomposition': 0.9,
  'fat_loss': 0.85,
  'strength': 0.85,
};

/// 兼容旧引用：增肌基准表
const weeklyVolume = _baseWeeklyVolume;

/// 最低有效量（MEV）：每个肌群 ≥ 这个，计划就是科学完整的（一定长肌肉）。
const mevWeekly = {
  'chest': 8, 'back': 10, 'quads': 8, 'hamstrings': 6, 'shoulders': 8,
  'biceps': 6, 'triceps': 6, 'calves': 6, 'core': 4,
};

/// 按 level + goal 返回「最优训练量」(MAV) —— 每周每肌群组数的上限目标。
Map<String, int> weeklyVolumeFor(String level, String goal, [int cycleOffset = 0]) {
  final base = _baseWeeklyVolume[level] ?? _baseWeeklyVolume['beginner']!;
  final scale = goalVolumeScale[goal] ?? 1.0;
  final off = (1.0 + 0.08 * cycleOffset).clamp(0.8, 1.25);
  return {
    for (final e in base.entries)
      e.key: (e.value * scale * off).round() < 2 ? 2 : (e.value * scale * off).round(),
  };
}

/// 单次训练单肌群组数上限（证据：每肌群每次 6–8 组最优，>10–12 收益骤降）。
const maxSetsPerMuscleSession = {
  'beginner': 6,
  'intermediate': 9,
  'advanced': 12,
};

const _trainingVars = {
  'hypertrophy': {'load_pct': '65-80% 1RM', 'load_pct_mid': 0.72, 'reps': '8-12', 'sets_range': [3, 4], 'rest_sec': 90, 'rpe': 7.5, 'tempo': '3-1-2-0', 'rir': '1-3'},
  'strength': {'load_pct': '≥80% 1RM', 'load_pct_mid': 0.85, 'reps': '3-6', 'sets_range': [3, 5], 'rest_sec': 150, 'rpe': 8.0, 'tempo': '受控', 'rir': '1-2'},
  'fat_loss': {'load_pct': '60-75% 1RM', 'load_pct_mid': 0.68, 'reps': '10-15', 'sets_range': [3, 4], 'rest_sec': 45, 'rpe': 7.0, 'tempo': '3-1-2-0', 'rir': '2-3'},
  'recomposition': {'load_pct': '65-80% 1RM', 'load_pct_mid': 0.72, 'reps': '8-12', 'sets_range': [3, 4], 'rest_sec': 90, 'rpe': 7.5, 'tempo': '3-1-2-0', 'rir': '1-3'},
};

// 时间估算常量（只用于估时，不改动作的处方参数）。
const _workSecCompound = 55;
const _workSecIsolation = 35;
const _restMultCompound = 1.4;
const _warmupSecPerBigMuscle = 90;
const _warmupCapSec = 8 * 60;
const _bigMuscles = {'chest', 'back', 'quads', 'hamstrings', 'shoulders'};

// 负重器械：拥有其一即视为"有器械"，纯自重动作在选池里降权
const _loadedEquipment = {
  'barbell', 'dumbbell', 'cable', 'machine', 'kettlebell', 'trap_bar'
};

const sessionMuscles = {
  'push': ['chest', 'shoulders', 'triceps'],
  'pull': ['back', 'biceps', 'rear_delt'],
  'legs': ['quads', 'hamstrings', 'glutes', 'calves'],
  'upper': ['chest', 'back', 'shoulders', 'biceps', 'triceps'],
  'lower': ['quads', 'hamstrings', 'glutes', 'calves'],
  'full_body': ['chest', 'back', 'quads', 'hamstrings', 'shoulders'],
  'core': ['core', 'abs'],
};

/// Kept for docs/compat; volume math now uses [_actualMuscleFrequency].
const splitFrequency = {
  'full_body': {'chest': 2, 'back': 2, 'quads': 2, 'hamstrings': 2, 'shoulders': 2, 'biceps': 2, 'triceps': 2, 'calves': 1, 'core': 2},
  'upper_lower': {'chest': 2, 'back': 2, 'quads': 2, 'hamstrings': 2, 'shoulders': 2, 'biceps': 2, 'triceps': 2, 'calves': 2, 'core': 1},
  'push_pull_legs': {'chest': 1.5, 'back': 1.5, 'quads': 1.5, 'hamstrings': 1, 'shoulders': 1.5, 'biceps': 1.5, 'triceps': 1.5, 'calves': 1, 'core': 1},
  'ppl_upper_lower': {'chest': 2, 'back': 2, 'quads': 2, 'hamstrings': 1.5, 'shoulders': 2.5, 'biceps': 2, 'triceps': 2, 'calves': 1, 'core': 1},
  'ppl_ppl': {'chest': 2, 'back': 2, 'quads': 2, 'hamstrings': 2, 'shoulders': 2.5, 'biceps': 2, 'triceps': 2, 'calves': 2, 'core': 1},
};

const _accessorySets = {'glutes': 3, 'rear_delt': 3};

/// 某些分肢日里把小肌群当「次要」：主肌群吃饱后才用余量补，封顶更低。
const _secondaryMusclesByType = {
  'upper': {'biceps', 'triceps'},
};
const _secondarySessionCap = 3;

const _muscleCn = {
  'chest': '胸', 'back': '背', 'quads': '股四头', 'hamstrings': '腘绳',
  'shoulders': '肩', 'biceps': '二头', 'triceps': '三头', 'calves': '小腿', 'core': '核心',
};

Map<String, int> _actualMuscleFrequency(
  List<ScheduleDay> schedule, {
  bool primaryOnly = false,
}) {
  final freq = <String, int>{};
  for (final dayInfo in schedule) {
    if (dayInfo.type == 'rest') continue;
    final secondary = primaryOnly
        ? (_secondaryMusclesByType[dayInfo.type] ?? const <String>{})
        : const <String>{};
    for (final muscle in sessionMuscles[dayInfo.type] ?? const <String>[]) {
      if (secondary.contains(muscle)) continue;
      freq[muscle] = (freq[muscle] ?? 0) + 1;
    }
  }
  return freq;
}

int _setSeconds(int prescribedRest, bool compound) {
  if (compound) {
    return _workSecCompound + (prescribedRest * _restMultCompound).round();
  }
  return _workSecIsolation + prescribedRest;
}

/// 周目标铺成每次暴露的组数序列，前重后轻，各次封顶到 cap，每次 ≥2 组。
/// 周目标小的时候宁可少练几次、每次 ≥2 组。5/3 → [3,2,0]。
List<int> _distributeWeekly(int weeklyTarget, int frequency, int cap) {
  final freq = frequency < 1 ? 1 : frequency;
  final byTwo = weeklyTarget ~/ 2;
  final effFreq = (freq < byTwo ? freq : byTwo).clamp(1, freq);
  final base = weeklyTarget ~/ effFreq;
  final rem = weeklyTarget % effFreq;
  return [
    for (var i = 0; i < effFreq; i++)
      (base + (i < rem ? 1 : 0)).clamp(0, cap).toInt(),
    for (var i = 0; i < freq - effFreq; i++) 0,
  ];
}

List<SessionResult> buildSessions(
  UserProfile profile,
  SplitResult split,
  ExerciseLibrary library,
) {
  final level = profile.level;
  final goal = profile.goal;
  final vars_ = _trainingVars[goal] ?? _trainingVars['hypertrophy']!;
  final volume = weeklyVolumeFor(level, goal, profile.volumeCycleOffset);
  final exerciseOffset =
      profile.exerciseCycleOffset < 0 ? 0 : profile.exerciseCycleOffset;
  final bwProgress = profile.bodyweightProgress;
  final cap = maxSetsPerMuscleSession[level] ?? 8;
  final frequency = _actualMuscleFrequency(split.weeklySchedule);
  final prescribedRest = vars_['rest_sec'] as int;
  final setsRange = (vars_['sets_range'] as List).cast<int>();
  final oneRmMap = buildOneRmMap(profile.strengthBaseline);
  final loadMid = (vars_['load_pct_mid'] as num?)?.toDouble() ?? 0.72;
  final loadLabel = vars_['load_pct'] as String;

  final totalBudgetSec =
      (profile.minutesPerSession * 60).clamp(15 * 60, 1 << 30).toInt();

  final distribution = <String, List<int>>{
    for (final e in volume.entries)
      e.key: _distributeWeekly(e.value, frequency[e.key] ?? 0, cap),
  };
  final exposure = <String, int>{};

  final sessions = <SessionResult>[];
  for (final dayInfo in split.weeklySchedule) {
    final dayName = dayInfo.day;
    final sessionType = dayInfo.type;

    if (sessionType == 'rest') {
      sessions.add(SessionResult(
        day: dayName, type: 'rest', durationMin: 0,
        exercises: const [], totalSets: 0,
      ));
      continue;
    }

    final targetMuscles = sessionMuscles[sessionType] ?? const <String>[];
    final secondary =
        _secondaryMusclesByType[sessionType] ?? const <String>{};
    final primaryMusclesToday =
        targetMuscles.where((m) => !secondary.contains(m)).toList();
    final secondaryMusclesToday =
        targetMuscles.where((m) => secondary.contains(m)).toList();

    final sessionTargets = <String, int>{};
    final sessionExposure = <String, int>{}; // 本周该肌群第几次练（0 起）
    for (final muscle in targetMuscles) {
      if (!volume.containsKey(muscle)) {
        sessionTargets[muscle] = _accessorySets[muscle] ?? 0;
        continue;
      }
      final k = exposure[muscle] ?? 0;
      sessionExposure[muscle] = k;
      final seq = distribution[muscle] ?? const <int>[];
      var tgt = k < seq.length ? seq[k] : 0;
      if (secondary.contains(muscle) && tgt > _secondarySessionCap) {
        tgt = _secondarySessionCap;
      }
      sessionTargets[muscle] = tgt;
      exposure[muscle] = k + 1;
    }

    final nBig = targetMuscles.where(_bigMuscles.contains).length;
    final warmupSec =
        (_warmupSecPerBigMuscle * (nBig > 4 ? 4 : nBig)).clamp(0, _warmupCapSec).toInt();
    final workBudgetSec = (totalBudgetSec - warmupSec) < 8 * 60
        ? 8 * 60
        : totalBudgetSec - warmupSec;

    var exercises = library.query(
      exerciseType: sessionType,
      equipment: profile.equipment,
      injuries: profile.injuries,
      level: level,
    );
    // 有负重器械的用户，纯自重动作排到后面（否则轮换会给他轮到俯卧撑）。
    final hasLoadedGear =
        profile.equipment.any(_loadedEquipment.contains);
    int bwDemoted(Exercise e) => (hasLoadedGear &&
            e.equipmentRequired.length == 1 &&
            e.equipmentRequired.first == 'bodyweight')
        ? 1
        : 0;
    // 伤病"软提示"动作排到最后：有干净替代就不用它。
    final inj = normalizeInjuries(profile.injuries);
    int injCautioned(Exercise e) =>
        (inj.isNotEmpty && isCautioned(e, inj)) ? 1 : 0;
    // Stable sort (Dart's List.sort is not stable — break ties by original
    // index to stay identical to Python's list.sort()).
    final indexed = exercises.indexed.toList()
      ..sort((a, b) {
        final aKey = (
          injCautioned(a.$2),
          bwDemoted(a.$2),
          a.$2.compound ? 0 : 1,
          a.$2.skillLevel != 'beginner' ? 1 : 0
        );
        final bKey = (
          injCautioned(b.$2),
          bwDemoted(b.$2),
          b.$2.compound ? 0 : 1,
          b.$2.skillLevel != 'beginner' ? 1 : 0
        );
        final c0 = aKey.$1.compareTo(bKey.$1);
        if (c0 != 0) return c0;
        final cB = aKey.$2.compareTo(bKey.$2);
        if (cB != 0) return cB;
        final c1 = aKey.$3.compareTo(bKey.$3);
        if (c1 != 0) return c1;
        final c2 = aKey.$4.compareTo(bKey.$4);
        if (c2 != 0) return c2;
        return a.$1.compareTo(b.$1);
      });
    exercises = indexed.map((e) => e.$2).toList();

    final sessionExercises = <ExerciseEntry>[];
    final usedIds = <String>{};
    var order = 1;
    var usedSec = 0;
    final deliveredSession = <String, int>{};

    // 徒手进阶：同 movement_pattern 的自重变式按 progressionRank 排成阶梯（稳定排序）
    List<Exercise> bwLadder(String pattern) {
      final rungs = exercises.indexed
          .where((e) =>
              e.$2.equipmentRequired.length == 1 &&
              e.$2.equipmentRequired.first == 'bodyweight' &&
              e.$2.movementPattern == pattern &&
              e.$2.progressionRank != null)
          .toList()
        ..sort((a, b) {
          final c = a.$2.progressionRank!.compareTo(b.$2.progressionRank!);
          return c != 0 ? c : a.$1.compareTo(b.$1);
        });
      return rungs.map((e) => e.$2).toList();
    }

    (Exercise, String) bwPick(Exercise ex, Set<String> used) {
      if (!(ex.equipmentRequired.length == 1 &&
              ex.equipmentRequired.first == 'bodyweight') ||
          ex.progressionRank == null) {
        return (ex, '');
      }
      final step = bwProgress[ex.movementPattern] ?? 0;
      final ladder = bwLadder(ex.movementPattern);
      if (ladder.isEmpty) return (ex, '');
      final target = ex.progressionRank! + step;
      final avail =
          ladder.where((e) => !used.contains(e.id) || e.id == ex.id).toList();
      final pickFrom = avail.isEmpty ? ladder : avail;
      final chosen = pickFrom.reduce((a, b) {
        final da = ((a.progressionRank! - target).abs(), a.progressionRank!);
        final db = ((b.progressionRank! - target).abs(), b.progressionRank!);
        if (da.$1 != db.$1) return da.$1 < db.$1 ? a : b;
        return da.$2 <= db.$2 ? a : b;
      });
      final harder =
          ladder.where((e) => e.progressionRank! > chosen.progressionRank!).toList();
      final hint = harder.isNotEmpty
          ? '做满次数上限×全组且有余力 → 进阶「${harder.first.name}」'
          : '已是最难变式，加次数 / 放慢离心';
      return (chosen, hint);
    }

    List<Exercise> pool(String muscle) {
      var p = exercises
          .where((e) => e.primaryMuscles.contains(muscle) && !usedIds.contains(e.id))
          .toList();
      if (p.isEmpty) {
        p = exercises
            .where((e) => e.secondaryMuscles.contains(muscle) && !usedIds.contains(e.id))
            .toList();
      }
      return p;
    }

    int tryAdd(String muscle, int want) {
      if (want < 2) return 0;
      final p = pool(muscle);
      if (p.isEmpty) return 0;
      // 锚定动作（该肌群本节课第一个动作）永远取 p.first，保证双进阶 / 1RM 追踪；
      // 之后的辅助动作按「跨中周期档位 + 本周该肌群第几次练」轮换到兄弟动作。
      Exercise ex;
      if (deliveredSession.containsKey(muscle)) {
        final rot = exerciseOffset + (sessionExposure[muscle] ?? 0);
        ex = p[rot % p.length];
      } else {
        ex = p.first;
      }
      // 徒手动作：按已挣得的进阶档换成对应难度的变式
      final (bwEx, bwHint) = bwPick(ex, usedIds);
      ex = bwEx;
      final cost = _setSeconds(prescribedRest, ex.compound);
      final fitSets = (workBudgetSec - usedSec) ~/ cost;
      if (fitSets < 2) return 0;
      var sets = want;
      if (sets > setsRange[1]) sets = setsRange[1];
      if (sets > fitSets) sets = fitSets;
      if (sets < 2) return 0;
      var (loadText, loadKg) =
          suggestLoad(ex, oneRmMap, loadMid, loadLabel);
      if (bwHint.isNotEmpty &&
          ex.equipmentRequired.length == 1 &&
          ex.equipmentRequired.first == 'bodyweight') {
        loadText = '自重 · $bwHint';
      }
      sessionExercises.add(ExerciseEntry(
        name: ex.name,
        nameEn: ex.nameEn,
        exerciseId: ex.id,
        sets: sets,
        reps: vars_['reps'] as String,
        load: loadText,
        loadKg: loadKg == 0 ? null : loadKg,
        restSec: vars_['rest_sec'] as int,
        rpe: vars_['rpe'] as double,
        tempo: vars_['tempo'] as String,
        notes: 'RIR ${vars_['rir']}',
        order: order,
        primaryMuscles: ex.primaryMuscles,
        compound: ex.compound,
        formCues: ex.formCues,
        targetMuscle: muscle,
      ));
      usedIds.add(ex.id);
      order++;
      usedSec += sets * cost;
      deliveredSession[muscle] = (deliveredSession[muscle] ?? 0) + sets;
      return sets;
    }

    // 第 1 遍（广度）：主肌群各上 1 个动作
    for (final muscle in primaryMusclesToday) {
      final tgt = sessionTargets[muscle] ?? 0;
      if (tgt >= 2) {
        tryAdd(muscle, tgt < setsRange[1] ? tgt : setsRange[1]);
      }
    }

    // 第 2 遍（深度）：主肌群补足到 session 目标，单肌群最多 3 个动作
    for (var round = 0; round < 2; round++) {
      var progressed = false;
      for (final muscle in primaryMusclesToday) {
        final tgt = sessionTargets[muscle] ?? 0;
        final got = deliveredSession[muscle] ?? 0;
        if (got == 0 || got >= tgt) continue;
        final n = sessionExercises.where((e) => e.targetMuscle == muscle).length;
        if (n >= 3) continue;
        if (tryAdd(muscle, tgt - got) > 0) progressed = true;
      }
      if (!progressed) break;
    }

    // 第 3 遍：次要肌群只用余量补
    for (final muscle in secondaryMusclesToday) {
      final tgt = sessionTargets[muscle] ?? 0;
      if (tgt >= 2) tryAdd(muscle, tgt);
    }

    sessionExercises.sort((a, b) => a.order.compareTo(b.order));
    final totalSets = sessionExercises.fold<int>(0, (s, e) => s + e.sets);
    var estMin = profile.minutesPerSession;
    if (totalSets > 0) {
      estMin = ((warmupSec + usedSec) / 60).round();
      if (estMin < 1) estMin = 1;
      if (estMin > profile.minutesPerSession) estMin = profile.minutesPerSession;
    }
    sessions.add(SessionResult(
      day: dayName,
      type: sessionType,
      durationMin: estMin,
      exercises: sessionExercises,
      totalSets: totalSets,
    ));
  }

  return sessions;
}

/// B 方案软提示：容量为锚，反推完整兑现目标训练量需要的时间/频率（可选、不拦截）。
Map<String, dynamic> _recommendCapacity(UserProfile profile, int coveragePct) {
  if (coveragePct >= 90) return const {};
  final ratio = 100 / (coveragePct < 1 ? 1 : coveragePct);
  var recMinutes = ((profile.minutesPerSession * ratio) / 5).round() * 5;
  if (recMinutes > 120) recMinutes = 120;
  final recDays = (profile.daysPerWeek ?? 3) + 1 > 6 ? 6 : (profile.daysPerWeek ?? 3) + 1;
  final options = <String>[];
  if (recMinutes > profile.minutesPerSession) {
    options.add('每节练到约 $recMinutes 分钟');
  }
  if (recDays > (profile.daysPerWeek ?? 3)) {
    options.add('训练日加到 $recDays 天');
  }
  if (options.isEmpty) return const {};
  return {
    'coverage_pct': coveragePct,
    'suggestion': options.join('，或'),
    'text': '按你选的目标训练量，当前时间/频率约能兑现 $coveragePct%。'
        '想完整拿到：${options.join('，或')}。（可选，不影响现在开练）',
  };
}

/// 诚实层：周目标 vs 实际排出容量的对账。
/// 返回 {target, delivered, frequency, coverage_pct, notes, recommendation}。
Map<String, dynamic> analyzeVolume(
  UserProfile profile,
  SplitResult split,
  List<SessionResult> sessions,
) {
  final level = profile.level;
  final optimal = weeklyVolumeFor(level, profile.goal, profile.volumeCycleOffset); // MAV 上限
  final frequency = _actualMuscleFrequency(split.weeklySchedule);
  final primaryFrequency =
      _actualMuscleFrequency(split.weeklySchedule, primaryOnly: true);

  final delivered = <String, int>{for (final m in optimal.keys) m: 0};
  for (final s in sessions) {
    for (final ex in s.exercises) {
      if (delivered.containsKey(ex.targetMuscle)) {
        delivered[ex.targetMuscle] = delivered[ex.targetMuscle]! + ex.sets;
      }
    }
  }

  final target = <String, int>{};
  final indirect = <String>[];
  final belowMev = <String>[];
  var coveredT = 0, coveredD = 0, optT = 0, optD = 0;
  optimal.forEach((muscle, hi) {
    final got = delivered[muscle] ?? 0;
    final mevRaw = mevWeekly[muscle] ?? 6;
    final mev = mevRaw < hi ? mevRaw : hi;
    final freq = frequency[muscle] ?? 0;
    final pfreq = primaryFrequency[muscle] ?? 0;
    final cn = _muscleCn[muscle] ?? muscle;
    final gotClampedHi = got < hi ? got : hi;
    final tgt = mev > gotClampedHi ? mev : gotClampedHi;
    target[muscle] = tgt;
    if (freq == 0 || pfreq == 0) {
      indirect.add(cn);
      return;
    }
    coveredT += tgt;
    coveredD += got < tgt ? got : tgt;
    optT += hi;
    optD += gotClampedHi;
    if (got < mev) belowMev.add(cn);
  });

  final coveragePct =
      coveredT == 0 ? 100 : (100 * coveredD / coveredT).round();
  final vsOptimalPct = optT == 0 ? 100 : (100 * optD / optT).round();

  final notes = <String>[];
  var recommendation = <String, dynamic>{};
  if (belowMev.isNotEmpty) {
    recommendation = _recommendCapacity(profile, coveragePct);
    final opts = (recommendation['suggestion'] as String?) ?? '每次加长时间';
    notes.add('${belowMev.join('/')}：每周训练量还没到最低有效量。$opts 可补上。');
  } else if (vsOptimalPct < 90) {
    notes.add('训练量已达标（相当于最优的 $vsOptimalPct%）。想冲最大增速：每次加约 15 分钟。');
  }
  if (indirect.isNotEmpty) {
    notes.add('${indirect.join('/')}：当前分肢不单独安排，靠复合动作间接带到；'
        '想直接练需加训练日或换分肢。');
  }

  return {
    'target': target,
    'optimal': optimal,
    'delivered': delivered,
    'frequency': frequency,
    'coverage_pct': coveragePct,
    'vs_optimal_pct': vsOptimalPct,
    'notes': notes,
    'recommendation': recommendation,
  };
}

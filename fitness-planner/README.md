# fitness-planner（Python 权威源）

本目录是 [fengjianliuli45/fitness-planner](https://github.com/fengjianliuli45/fitness-planner) 引擎在 apk-store 的镜像，供对照与回归。

App 运行时用的是 `flutter/lib/planner/`（Dart 移植）。**改算法时先改本目录 Python，再同步 Dart。**

## 2026-08-30 伤病处理（任务 P0 #3）

原来：伤病词跟动作 `injury_contraindications` 做子串匹配，命中就把整个动作删掉——
容易漏 / 误伤，还可能把整块肌肉练空。改成规范化 + 分级：

- 新增 `engine/injury_planner.py` + `.dart`：
  - `normalize_injuries()`：中英自由文本（"左膝盖疼" / "shoulder impingement" / "跟腱炎"）
    → 规范键（knee / shoulder / lower_back / wrist / elbow / hip / ankle / neck）
  - `INJURY_RULES`：每个伤病一张「硬禁动作模式 / 具体动作」表 + 一句给用户的说明。
    循证（PMC12591260、训练修改指南）：肩→不做过顶推举 / 直立划船 / 侧平举过肩 / 双杠；
    下背→不做大重量轴向负荷和负重脊柱屈曲 / 旋转；膝→不做弓步 / 跳跃 / 单腿蹲、深蹲控幅度；等。
  - `is_contraindicated`（硬禁，从选池剔除）vs `is_cautioned`（动作自带禁忌 → 保留但
    `session_builder` 排到最后，有干净替代就不用它）。
- `exercise_library.query` / `query_by_muscle`：按上面规则过滤（不再子串匹配）。
- `plan_output.training.injury_accommodations`：`{injuries, notes, under_covered_muscles
  （本来能练、被伤病挤空的肌群）, pain_free_range_exercises（计划里要"无痛幅度"做的动作）}`。
- 效果：肩伤用户仍拿到哑铃推举 / 卧推（标注无痛幅度）+ 面拉，不做 OHP；膝伤用户腿日换成
  腿举 + 髋主导，不做弓步。计划不被删空。
- Python 183 / Flutter 82；demo + 3 种伤病计划 Python↔Dart 逐字一致。

## 2026-08-30 徒手力量估算（补 P0 #2 的坑）

用户提议：徒手动作按「一次做多少个」推算力量。查了成熟做法（自重动作举起体重的固定
比例，研究实测）：

- `load_planner._BODYMASS_FRACTION`：每个自重动作的体重占比——标准俯卧撑 0.64、
  脚高 0.75、引体/反手 1.0、双杠 0.40（三头）、徒手深蹲 0.68、分腿蹲 0.85、
  单腿臀推 0.75 …（JSCR / Suprak 2011 PMID 20179649、ExRx）。兜底按 movement_pattern。
- `bodyweight_e1rm(体重, 动作, 次数) = 体重 × 占比 × (1 + min(次数,20)/30)`（Epley，
  次数上限放宽到 20，因为徒手常做高次数，相对追踪仍成立）。
- `progress_tracker._lift_series`：徒手基准动作的 `best_e1rm` 不再是 None，用上式算。
  → 闭环里所有现成逻辑（`performance_improvement_pct`、`e1rm_declining` → 减载、
  达成判定）**对徒手用户自动生效**，补掉了「徒手用户老被判 deload_then_retry」的坑。
  `aggregate_evidence` / `aggregate_observation` / `per_exercise_progress` /
  `_lift_series` 增 `library` 参数（Python 走模块级单例，Dart 显式传）。
- 实测：居家新手俯卧撑次数 8 → 14（4 周）→ e1RM +15% → verdict `advance`（原为 deload）。
- Python 179 / Flutter 81；居家用户次数进步 check-in Python↔Dart 逐字一致。

## 2026-08-30 徒手进阶模型（任务 P0 #2）

自重动作不再只写「按次数 / 难度递进」，而是走明确的变式阶梯，由闭环驱动。

- `Exercise.progression_rank`：同 movement_pattern 内自重变式的难度序号（俯卧撑：
  上斜1 → 标准2 → 窄距/宽距3 → 钻石4 → 脚高5 → 弓箭手6）。
- `session_builder._bw_pick`：挑到自重动作时，按用户已挣得的 `bodyweight_progress
  [movement_pattern]` 档数，换成对应难度的变式（取阶梯里 rank 最接近 base+step 的一档，
  受 level 过滤——新手轮不到 advanced 变式）。`load` 文案改成「自重 · 做满次数上限×
  全组有余力 → 进阶「下一级动作」」。
- `check_in_engine._bodyweight_changes`：徒手基准动作做满次数上限×全组 & RIR≤1
  → 该 pattern +1 档；连续 2 次未达下限 → -1 档。`CycleReview.bodyweight_changes`；
  `next_raw.bodyweight_progress` 在上一周期基础上累加（钳 -3..6）。
  `review_cycle` / `run_check_in` 现在收 `library` 参数。
- `profile_validator` + `plan_output`：新增 `bodyweight_progress`（只收合法 movement_pattern）。
- `load_planner`：弹力带动作文案「弹力带 · 选阻力做到目标次数、末组留 1-2 次；
  变强了换更粗的带或缩短带长」。
- Python 178 / Flutter 80；demo / 轮换 / 居家用户 / 徒手进阶 check-in 计划 Python↔Dart 逐字一致。
- 已知：徒手用户在 `assess_stage` 里因无 e1RM 常被判 `deload_then_retry`（少 10% 容量），
  变式进阶仍照常——后续让阶段评估看得到"次数进步"。

## 2026-08-30 动作库扩充：居家 / 弹力带（任务 P0 #1）

证据：Kassiano 2022 系统综述 + 自重/弹力带接近力竭肥大等效（Nunes 2019, ISJC 2024）。

- `data/exercises.json` 108 → 154：新增 46 个居家动作（21 自重 + 22 弹力带 + 3 单杠）。
  合并后每个引擎会查的肌群（chest/back/shoulders/biceps/triceps/rear_delt/quads/
  hamstrings/glutes/calves）纯自重都 ≥3 个可选。肩 0→3、腘绳肌居家 0→4、臀 2→8。
- 新器械词：`band`（弹力带）、`pull_up_bar`（单杠）。
  `pull_up` / `chin_up` / 悬垂类从误标的 `bodyweight` 改成 `pull_up_bar`。
  `_expand_equipment()`：`rack` / `machine` → 也有 `pull_up_bar`（商业健身房自带）。
- `session_builder`：有负重器械的用户，纯自重动作在选池里降权（`_LOADED_EQUIPMENT`），
  避免轮换把俯卧撑 / 徒手深蹲轮给有杠铃的人。
- `Exercise` 新增可选字段 `progression_rank`（同 movement_pattern 内 1,2,3…），
  ~15 个自重动作已标，喂后续「徒手进阶模型」（P0 #2）。老数据为 None。
- Python 174 / Flutter 79 测试；demo / 轮换 offset 0-2 / 居家用户 计划 Python↔Dart 逐字一致。
- Unity 3D 教练按 15 个 `movement_pattern` 1:1 映射，引擎不加动画字段；GIF 只是降级素材。

## 2026-08-30 动作轮换（任务 D）

证据：Kassiano 2022 系统综述（PMID 35438660）—— 有计划的轮换促进区域性增长 + 减关节劳损，
随机 / 频繁轮换反而伤增肌（打断负荷进阶、没法追踪、疲劳堆积）。RP：主项固定，轮换辅助。

- `session_builder`：每个肌群本节课的**第一个动作 = 锚定**，永远取 `pool[0]`，
  保证双进阶 / 1RM 追踪；之后的辅助动作按 `exercise_offset + 本周该肌群第几次练`
  轮换到 `pool[rot % len]`（同 `library.query` 池，按 movement_pattern + 肌群，非随机）。
  · 同周内某肌群练 2 次 → 第 2 次辅助动作换变式
  · 跨中周期 → `exercise_cycle_offset` 推进
- `profile_validator` + `plan_output`：新增 `exercise_cycle_offset`（钳 0–12）。
- `check_in_engine`：只在 `up_one_step`（= 阶段达成 advance）时 `exercise_cycle_offset += 1`；
  `extend` / `deload_then_retry` 保持同一批动作再冲。
- Python 167 / Flutter 78 测试；offset 0/1/2 三档 Python↔Dart 逐字一致。
- 已知：动作库对零器械用户仍会轮到自重动作（池质量问题，非轮换引入）。

## 2026-08-30 深饮食：饮食进闭环 + 减脂 diet break（任务 E4）

- `check_in_engine`：中周期边界按体重周变化率调热量 ±150 kcal（`_diet_adjust`）。
  目标带：fat_loss −1.1~−0.3 %/周（Helms 2014）、hypertrophy +0.1~+0.6 %/周、
  recomp/strength 只纠明显偏离。体重比目标带低→加热量、高→减。需 ≥3 次称重、
  跨度 ≥14 天（`progress_tracker.weekly_weight_pct`，回归斜率）。
  `CycleReview` 新增 `kcal_change` / `diet_note`；`next_raw.kcal_adjust` 在上一周期
  基础上累加、钳 ±500。
- `macro_allocator`：`profile.kcal_adjust` 直接加到 `daily_kcal`。
- `mesocycle_planner`：fat_loss 的减载周 = diet break，热量提到维持量
  （`diet_break` / `diet_kcal_delta = -surplus`；MATADOR / Byrne 2018 间歇性能量平衡
  减少代谢适应、保肌）。`plan_mesocycle(..., surplus_kcal=)` 新参数。
- `profile_validator` + `plan_output`：新增 `kcal_adjust`；profile 块补齐
  `dietary_restrictions` / `cooking_access` / `meals_per_day` / `target_weight_kg`，
  让闭环不再丢失这些字段。Dart 端 `meta.evidence_basis` 补上 → 整份计划 Python↔Dart
  逐字一致（含 check-in 后重新生成的 next_plan）。
- Python 163 / Flutter 76 测试。

## 2026-08-30 深饮食：具体吃法 + 饮食限制真正生效（任务 E1–E3）

- 新增 `engine/food_db.py`：~45 项中式食物库（kind + 过敏原两属性推导限制），
  外加两套业界做法——
  · 食物交换份法（ADA / 美国营养学会 1950 起）：`suggest_meal()` 按每餐目标克数
    组「蛋白 + 主食 + 蔬菜 + 脂肪」，2 个备选，按餐次 `rotate` 错开选材。
  · 手掌法（Precision Nutrition，PMC4976119）：`hand_portion_text()` 给不称重 / 在外吃。
- `macro_allocator`：`dietary_restrictions` 含 vegan → 蛋白 +0.3 g/kg，vegetarian → +0.2 g/kg
  （植物蛋白消化率 / 亮氨酸偏低，PMC11281145）；`MacroResult.notes` 带说明。
- `meal_distributor`：每餐带 `options`（精确吃法）+ `hand_portions`；`MealPlan` 新增
  `fiber_g`（14g/1000kcal）、`water_ml_rest` / `water_ml_training`（33ml/kg，训练日 +500）、
  `diet_notes`（每餐蛋白 ≥0.3g/kg 检查、蛋白定时、纤维、饮水、纯素微量营养素）。
  移除静态 `FOOD_EXAMPLES`。
- `supplement_advisor`：纯素追加 B12（必补）+ 铁（按化验）；限制词归一走 `food_db`。
- JSON 版本仍 1.7（`nutrition.meals` 字段扩展，非破坏）。Python↔Dart 营养块逐字对齐。

## 2026-08-23 容量修复

- `session_builder`：按真实周日程肌群频次回算组数 + 单次肌群上限 + 课时预算
- `progression_planner`：每 4 周减载（容量 60%）

## 2026-08-30 闭环：训练日志 → 评估 → 调整（任务 A）

- 新增 `engine/progress_tracker.py`：训练日志聚合成 `stage_assessor` / `response_profiler` 的输入。
  - 日志契约：`LoggedSession{date, plan_day, session_type, planned_sets, exercises:[{exercise_id, planned_sets, sets:[{reps, weight_kg?, rir?}]}], aborted, pain_flag}` + `BodyEntry{date, weight_kg, waist_cm?}`。
  - e1RM = Epley + RIR 修正（`w×(1+(reps+rir)/30)`，只信 RIR≤3 的组）；基准动作首末中位数 ≥2.5% = 提升。
  - 身体趋势：减脂 ≥3 次称重、斜率为负且累计降 ≥0.5% 或腰围 −1cm；增肌 体重斜率 ≥0 且 +0.25%/周。
  - 疼痛：最近 3 次训练有 `pain_flag` → 未解决。
- 新增 `engine/check_in_engine.py`：`review_cycle(plan, workout_log, body_log, completed_cycles) -> CycleReview`。
  - 判定：`address_safety`（疼痛）/ `advance`（达成）/ `extend`（缺勤 + 补训场次）/
    `deload_then_retry`（出勤够但表现停滞）/ `extend`（接近达成）。
  - 逐动作双进阶：所有组到次数上限 & RIR≤2 → +2.5/5kg；连续 2 次未达下限 或 e1RM 连降 → −10%。
  - 产 `next_raw`：按主项比例更新 `strength_baseline`（估算 1RM）+ `volume_cycle_offset`
    （`advance` +1 往 MRV 推、`deload_then_retry` −1）。
- `session_builder.weekly_volume_for(level, goal, cycle_offset)`：offset 每档 ±8%，夹在 [0.8×, 1.25×MAV≈MRV]。
- `pipeline.run_check_in(plan_json, workout_log, ...)` → `{review, next_plan}`；
  Flutter `PlannerGateway.runCheckIn(...)`。
- 规则层确定性：垂直大模型可解释 / 陪伴，但不改写这里的结果。

## 2026-08-30 中周期结构（任务 A / ④ 第 1 步）

- 新增 `engine/mesocycle_planner.py`：把「一份周计划」展开成 4–6 周中周期。
  - 积累期若干周（= `progression.next_check_week`）：容量系数 0.7 → 1.0 线性爬到 MAV，
    RIR 目标 3 → 0；末周减载（组数 ×`deload_volume_pct`、保持重量、RIR 放松）。
  - 组数小的时候靠 RIR 递减承接强度递进（RP 做法：组数持平则 RIR 加码）。
  - 每周只产「对基准 session 的组数覆盖」`set_overrides = {day: {exercise_id: sets}}` +
    `rir_target`；动作、重量、时长仍来自 `session_builder`（基准 = MAV 那一周）。
- 计划 JSON `1.6 → 1.7`：`training.mesocycle`（`length_weeks` / `current_week` / `weeks[]`）。
- 组间负荷进阶（双进阶）在中周期边界由 check-in 按实际表现处理——下一步（progress_tracker + check_in_engine）。

## 2026-08-30 起始重量 / 1RM（任务 ②）

- 新增 `engine/load_planner.py`：把「65-80% 1RM」转成具体重量。
  - onboarding 混合采集：`strength_baseline = {squat|bench|hinge|row: {weight_kg, reps} 或 {one_rm_kg}}`。
    有器械填一组估测 → Epley 反推 1RM；做不了/不确定/徒手 → 留空，首周按 RPE 找重量。
  - 每个动作标「基准 + 系数」（`_PATTERN_BASIS` + `_EXERCISE_COEF`，哑铃按每只手）：
    建议重量 = 基准 1RM × 系数 × 目标 %1RM，取整 2.5kg。
  - `ExerciseEntry.load` 从「65-80% 1RM」变「52.5 kg（65-80% 1RM）」/「27.5 kg/只（…）」/
    「首周按 RPE 找重量」/「自重（按次数 / 难度递进）」；新增数值字段 `load_kg`。
- `profile.strength_baseline` + `profile.one_rm_estimates`（Epley 结果）进 JSON。
- `stage_goal.baseline_lifts`：挑计划里前几个复合动作作为「标准化测试动作」，
  带首周基线负荷，供阶段达成对比。
- 徒手用户的渐进（加次数 → 换更难变式）是单独子任务，本次未做。
- 计划 JSON `1.5 → 1.6`。

## 2026-08-30 自适应训练量 + 按恢复排日历（交付 2b）

- **训练量目标自适应**（`analyze_volume`）：目标不再是固定表，而是「用户这个时长/天数
  排得满的量」，夹在 [MEV, MAV] 之间。只要每个肌群 ≥ MEV（`MEV_WEEKLY`），计划就
  科学完整（一定长肌肉）→ `volume_coverage_pct` 通常 100。另给 `vs_optimal_pct`
  （相当于最优训练量 MAV 的百分比），是「还能更好，加时间往上推」的提示。
- `_distribute_weekly`：周目标小的时候宁可少练几次、每次 ≥2 组（`5/3 → [3,2,0]`），
  不排「1 组」的无效暴露。
- **频率决策**改为优化 `vs_optimal_pct`：给定时长，挑「最少的、能到最优」的天数；
  没有能到最优的选最接近的。`min_session_minutes` 仍以「每个肌群 ≥ MEV」为门槛
  （= 保证训练量完成的最短课时）。
- 新增 `engine/schedule_planner.py`：`split_selector` 只定训练日**类型序列**，
  schedule_planner 按肌群恢复窗口（`RECOVERY_MIN_GAP`：大肌群绝不连续两天）
  枚举所有摆法，挑间隔最均匀、周末最轻的。删掉 `full_body_4` 模板；新手锁 3 天。
- `recovery_planner`：完全休息天数按水平（新手 2 / 中高级 1），但让位给减脂的有氧日
  和增肌欠量的泵感课日。
- 计划 JSON `1.4 → 1.5`：`training` 下 `weekly_volume_target`（自适应）/
  `weekly_volume_optimal`（MAV）/ `vs_optimal_pct`；`frequency_plan` 增 `vs_optimal_pct`。

## 2026-08-30 休息日轻日 / 补练（交付 2）

- 新增 `engine/recovery_planner.py`：把日程里的 rest 日填成有内容的「轻日」，
  原则是**不抢主课的恢复**：
  - 减脂 → 补低强度有氧（Zone2）：减脂靠热量缺口，有氧直接补。
  - 增肌 / 增肌减脂 且主课覆盖 < 96% 且非新手 → 补 1 天「快恢复肌群泵感课」
    （二头/三头/小腿/核心，20 分钟，24 小时恢复，不影响第二天大动作）。
  - 新手 → rest 日只给主动恢复（拉伸 + 走路）。
  - rest 日 ≥ 2 或硬练 ≥ 5 天 → 保留 1 天完全休息。
  - 其余 rest 日 → 主动恢复。每天都有内容 → 服务「每天开 App / 连续天数 / 宠物」。
- 计划 JSON `1.3 → 1.4`：`training.recovery_days`（`kind` = rest/mobility/cardio/pump，
  `duration_min` / `title` / `focus` / `items`）。`schedule` 仍是 7 天（rest 保持 rest），
  App 按 `day` 把两者对起来渲染。
- 泵感课不计入 `volume_coverage_pct`（覆盖率只反映主课）；泵感课的 `focus` 文案
  会说明它在补哪部分缺口。
- 7 天训练 = 硬练（3–6 天）+ 轻日填满剩余天，不做 7 天硬练同肌群。

## 2026-08-30 引擎决定训练频率（任务 ①.5）

- `days_per_week` 不再是必填输入。用户只填「每次能练多久」，频率是结果：
  `frequency_planner.plan_frequency()` 在该水平允许的天数范围内（新手 3–4、
  中级 3–5、高级 3–6），挑**最少的、覆盖率 ≥ 92% 的天数**。
- 低于「最低训练时长」→ 自动上调时长（科学优先：先保证周训练量）。
  最低时长按 (水平, 目标, 器械) 用真实引擎搜索得出，例：增肌 新手 ~50–65 / 中级 ~65–70 分钟。
- `WEEKLY_VOLUME` 按目标缩放（`weekly_volume_for(level, goal)`）：
  增肌 1.0 / 增肌减脂 0.9 / 减脂 0.85 / 力量 0.85。高级基准容量下调一档，
  高级单次上限 10→12，力量 `sets_range` (4,5)→(3,5)。
- 新增 `split_selector` 的 `full_body_4` 模板：新手 4 天仍走全身。
- 新增 `engine/pipeline.generate_plan(raw, library)` 一站式编排入口，
  内含 `frequency_planner.resolve`。测试与 Flutter `PlannerGateway` 对齐此顺序。
- 计划 JSON `1.2 → 1.3`：`training.frequency_plan`（天数 / 上调后的时长 /
  最低时长 / 覆盖率 / 说明）。`profile.days_per_week` 可为 null（未解析时）。

## 2026-08-30 容量↔课时一致性（任务 ①：科学健身优先）

- `session_builder` 重写容量与排课：
  - 单组耗时改真实估计（复合 55s + 处方休息×1.4，孤立 35s + 处方休息，另按大肌群数扣热身时间）。`duration_min` 现在是诚实值。
  - 周目标按「实际训练频率」整除铺到每次暴露，前重后轻，各次封顶到单次上限（`MAX_SETS_PER_MUSCLE_SESSION` 调整为 6 / 9 / 10）。
  - 两遍排课：先每个主肌群保底 1 个动作，再补深度，最后补次要肌群。`upper` 日把二头/三头降为次要肌群（`SECONDARY_MUSCLES_BY_TYPE`），复合动作间接带到。
  - 每个 `ExerciseEntry` 记 `target_muscle`，容量统计不再被复合动作多肌群标签灌水。
- `session_builder.analyze_volume()`（新）：对比周目标 vs 实际排出容量，输出 `coverage_pct` + 差额提示 + B 方案软提示（可选、不拦截）。
- `split_selector`：3 天训练一律全身分肢（各水平），比 3 天 PPL（每肌群 1 次/周）显著更能兑现周容量。
- 计划 JSON 升级为 `1.2`：`training` 下新增 `weekly_volume_delivered` / `volume_coverage_pct` / `volume_notes` / `capacity_recommendation`。Dart `PlannerGateway` 同步（Python↔Dart 逐画像输出已对拍一致）。
- 训练量不达标的「补训 / 延长训练周期」联动属确定性规则，接入闭环时在 `stage_assessor` / check-in 落地（任务 A）。

## 2026-08-25 第一阶段适应期

- `stage_goal_planner`：把现有 4 周复评周期转成可验证的首阶段目标，默认要求 80% 场次、至少 3 个有效周和可比较测量。
- `stage_assessor`：以执行、数据质量、能力/身体趋势和安全四项规则判定 `achieved` 或延长 2 周。
- `response_profiler`：为后续宠物谱系积累训练响应；少于 2 个周期时，代谢、增肌和减脂响应强制保持 `unknown`。
- 计划 JSON 升级为 `1.1`，新增 `stage_goal`；Flutter `PlannerGateway` 同步生成相同结构。

阶段达成属于确定性规则层。后续垂直领域大模型可以负责问答、解释、语音陪伴和候选建议，但不能直接改写阶段结果；任何模型建议都必须转成可审计规则或由用户确认后再进入计划。

首发采用低阻力采集策略：训练表现数据由训练流程自动产生；体重、腰围、照片、体脂率和设备数据均为可选。阶段评估支持仅凭合格的执行数据与可复测训练表现达成，不得把身体测量作为隐性必填条件；数据不足时延长观察，不把用户标记为失败。

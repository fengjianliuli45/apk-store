# Fitness Planner — 代码质量与架构审查报告

> 审查日期: 2026-08-02  
> 审查范围: `engine/` 10 个模块 + `tests/` 11 个测试文件 + `data/exercises.json` (108 动作)  
> 测试状态: 77 passed, 0 failed  
> 审查人: Code (coder subagent)

---

## 一、架构总览

### 1.1 模块依赖图

```
profile_validator  ← 核心数据类型 UserProfile
    ↑
    ├── tdee_calculator     (UserProfile → TDEEResult)
    ├── macro_allocator     (UserProfile + TDEEResult → MacroResult)
    ├── meal_distributor    (UserProfile + MacroResult → MealPlan)
    ├── split_selector      (UserProfile → SplitResult)
    ├── progression_planner (UserProfile → ProgressionResult)
    ├── supplement_advisor  (UserProfile + MacroResult → SupplementResult)
    ├── exercise_library    (独立，从 JSON 加载)
    ├── session_builder     (UserProfile + SplitResult + ExerciseLibrary → [SessionResult])
    ├── explain_generator   (全链路结果 → str)
    └── plan_output         (全链路结果 → JSON dict)
```

### 1.2 架构评价

**优点:**
- **单向依赖管线**: `validate → calculate → allocate → distribute / select / build / plan / advise → output`，无循环依赖。
- **数据类封装**: 每个模块用 `@dataclass` 定义输入/输出类型，接口清晰。
- **关注点分离**: 校验、计算、编排、输出各自独立，单一职责。
- **论文溯源**: 营养素/训练变量均标注 PMID，可追溯证据。
- **中英双语**: 动作库含中英文名称，解释层全中文，适合目标用户。

**不足:**
- 无统一入口（`__init__.py` 为空），调用方需手动串联 10 个模块。
- 缺少类型导出（`__all__`），IDE 自动补全体验差。
- 无 `Pipeline`/`Orchestrator` 类封装全链路调用。

---

## 二、三个"修过"的点 — 根因分析

### 2.1 `profile_validator.py` — days_per_week/minutes_per_session 边界值

**现状**: `0 <= days_per_week <= 7`，`0 <= minutes_per_session <= 180`

**根因分析**:  
原始设计将 `≥1` / `≥15` 作为下限，意图是"用户必须训练才有意义"。但 `TDEECalculator._select_activity_level` 需要处理 `days_per_week=0`（sedentary）的情况——如果 validator 拒绝 0，则无法生成"久坐不动"用户的计划。改为 `≥0` 是正确的，因为：
1. TDEE 计算逻辑已对 `d==0` 做了 `1.20` sedentary 分支。
2. `split_selector` 对 `d==0` 会走到 `else` 分支返回 `full_body`（但不会有训练日）。
3. `session_builder` 对 rest 日生成空 session。

**残留风险**: ⚠️ `days_per_week=0` 时 `split_selector` 仍返回 `full_body` 模板（前 2 天训练 + 5 天休息），但用户实际不想训练。应增加 `d==0` 的特殊处理或警告。

**判定**: 修复方向正确，但 `split_selector` 缺少 `d==0` 的显式分支。

### 2.2 `meal_distributor.py` — 练后餐倾斜后的总量回正

**现状代码逻辑**:
1. 均分每餐蛋白/碳水
2. 练后餐 ×1.2（蛋白和碳水）
3. 缩放回正：`p_scale = daily_protein / total_p`，`c_scale = daily_carbs / total_c`

**根因分析**:  
原始代码在练后餐 ×1.2 后没有缩放，导致总量超出日目标。修复加入了比例缩放，使蛋白和碳水总量精确回正。

**当前实现评价**: ✅ 正确。缩放逻辑对 protein 和 carbs 分别处理，fat 不参与练后倾斜所以无需缩放。缩放后重算 kcal。

**残留风险**:
- 缩放是全局比例缩放，练后餐缩放后仍比其他餐高 20%（因为原增量被等比压缩），效果符合预期。
- 但脂肪没有缩放，总量等于 `daily_fat`（因为 fat 没被倾斜），这是正确的。
- ⚠️ 当 `meals_per_day <= 3` 且无"练后加餐"时，所有餐均等，没有倾斜效果——这是合理的（3 餐无法安排练后餐）。

**判定**: 修复正确且完整。

### 2.3 `progression_planner.py` — 双进阶中文标签

**现状**: `double_progression="双进阶：当无法再加重量时：先+1次→达到上限次数后降次加重循环"`

**根因分析**:  
原始代码只输出英文 `"double_progression"` 字符串，对中文用户不友好。修复后加入了完整中文说明。

**当前实现评价**: ✅ 字符串清晰，描述了双进阶的核心逻辑（先加次数，再加重量）。测试 `test_double_progression_described` 验证了 `"双进阶"` 关键词存在。

**残留风险**: 无。纯展示层修复，不影响逻辑。

**判定**: 修复正确。

---

## 三、潜在缺陷与风险点

### 3.1 🔴 `profile_validator.py` — ValidationError 被用作 Exception 基类

```python
@dataclass
class ValidationError(Exception):
    errors: list[str]
```

`@dataclass` 装饰一个 `Exception` 子类时，`dataclass` 会生成 `__init__`，但 Exception 的 `args` 不会被正确设置。这意味着 `except ValidationError as e: print(e)` 可以工作（因为有自定义 `__str__`），但 `e.args` 为空，某些异常处理框架可能行为异常。

**建议**: 改用普通类继承 Exception，手动写 `__init__`。

### 3.2 🟡 `profile_validator.py` — errors 检查逻辑碎片化

validate() 中有 **三处** `if errors: raise ValidationError(errors)`：
1. 必填字段检查后（第 65 行附近）
2. 类型/范围校验后（第 110 行附近）
3. optional 字段校验后（第 140 行附近）

第三处检查实际上只会捕获 `body_fat_pct` 超范围的情况，因为其他 optional 字段超范围都是 warning 而非 error。这导致错误收集不是 batch 的——前两处会提前 raise，用户需要多次提交才能发现所有错误。

**建议**: 移除前两处提前 raise，统一在最后一次性报错。

### 3.3 🟡 `meal_distributor.py` — 无练后餐时的倾斜缺失

当 `meals_per_day=3` 时，使用 `MEAL_NAMES_3 = ["早餐", "午餐", "晚餐"]`，没有"练后加餐"。此时所有餐均等分配，没有训练后营养倾斜。

**影响**: 3 餐用户（可能是减脂期或时间紧张的用户）缺少练后营养优势。

**建议**: 对 3 餐场景，可将"午餐"或"晚餐"标记为练后餐并施加倾斜（取决于训练时间）。

### 3.4 🟡 `split_selector.py` — days_per_week 与模板天数不匹配

`split_selector` 直接返回 7 天模板，但模板的训练日数量可能与 `days_per_week` 不一致。例如：
- `days_per_week=3` + `intermediate` → `push_pull_legs`，模板 = `["push", "pull", "legs", "rest", "push", "pull", "rest"]`，实际训练 5 天而非 3 天。

**影响**: 用户指定 3 天/周但实际被安排 5 天训练，与预期不符。

**建议**: 根据 `days_per_week` 截取或自定义模板，确保训练日数量与用户输入一致。

### 3.5 🟡 `tdee_calculator.py` — 活动乘数选择有覆盖盲区

```python
if d <= 2 or m <= 30:
    return 1.375, "light"
if 3 <= d <= 4:
    return 1.55, "moderate"
if 5 <= d <= 6 and m >= 60:
    return 1.725, "active"
```

当 `d=5, m=45` 时，不满足 `m >= 60`，会 fall through 到 `d==7` 检查（不满足），最终落到默认 `1.55, "moderate"`。但 `d=5` 训练 45 分钟应该是 active 而非 moderate。

**建议**: 调整条件为 `d >= 5 and m >= 40` 或使用综合评分。

### 3.6 🟢 `macro_allocator.py` — 碳水为负时的热量修正

```python
if carbs_g < 0:
    carbs_g = 0.0
    daily_kcal = protein_kcal + fat_kcal
```

处理了极端情况（蛋白+脂肪已超总热量），但此时 `daily_kcal` 被降低，可能与 TDEE+surplus 目标偏差很大。应该发出警告。

**建议**: 添加 warning 通知用户热量目标无法满足。

### 3.7 🟢 `session_builder.py` — 肌群组数分配的 round 误差

```python
per_session = max(2, round(total_sets / freq))
```

`round()` 对 .5 的行为是银行家舍入（round half to even）。例如 `round(2.5) = 2`，`round(3.5) = 4`。这可能导致某些肌群周容量比目标多/少 1-2 组。

**影响**: 轻微，实际训练中 1 组差异可接受。

### 3.8 🟢 `exercise_library.py` — 伤病过滤的模糊匹配

```python
if inj.lower() in contraind.lower() or contraind.lower() in inj.lower():
```

双向子串匹配过于宽泛。例如用户伤病为 `"膝"` 会匹配 `"膝盖疼痛"`（正确），但伤病为 `"肩"` 也会匹配 `"肩袖损伤"`（正确）——不过也可能产生误匹配。

**影响**: 低。当前动作库的 contraindication 字段比较规范。

### 3.9 🟢 `supplement_advisor.py` — 肌酸拒绝检测过于简单

```python
explicitly_rejected = any("no" in s or "不" in s or "拒绝" in s for s in user_supps)
```

如果用户写 `"不需要肌酸"`，`"不"` 会匹配。但如果写 `"none"`，也会匹配 `"no" in "none"`。整体可接受但不够健壮。

---

## 四、测试覆盖评估

### 4.1 覆盖矩阵

| 模块 | 测试文件 | 用例数 | 覆盖评价 |
|------|----------|--------|----------|
| profile_validator | test_profile_validator.py | 11 | ✅ 良好（边界值、缺失字段、警告） |
| tdee_calculator | test_tdee_calculator.py | 5 | ✅ 良好（两公式、5 个活动等级） |
| macro_allocator | test_macro_allocator.py | 7 | ✅ 良好（4 目标、蛋白/kg、kcal 一致性） |
| meal_distributor | test_meal_distributor.py | 7 | ✅ 良好（餐数、总量、练后倾斜） |
| split_selector | test_split_selector.py | 10 | ✅ 良好（1-7 天、警告、日名） |
| exercise_library | test_exercise_library.py | 10 | ✅ 良好（加载、查询、过滤、替代） |
| session_builder | test_session_builder.py | 7 | ⚠️ 中等（缺少 days_per_week=0 边界） |
| progression_planner | test_progression_planner.py | 6 | ✅ 良好（3 等级、触发器、双进阶） |
| supplement_advisor | test_supplement_advisor.py | 7 | ✅ 良好（肌酸、蛋白粉、VD、鱼油） |
| plan_output | test_plan_output.py | 7 | ✅ 良好（JSON 结构、序列化） |
| explain_generator | ❌ 无 | 0 | 🔴 未测试 |

### 4.2 测试缺口

1. **`explain_generator.py` 完全未测试** — 该模块生成用户可读文本，至少应有冒烟测试确保不崩溃。
2. **`days_per_week=0` 全链路测试缺失** — validator 允许 0 但后续模块的行为未验证。
3. **`minutes_per_session=0` 全链路测试缺失** — 同上。
4. **`session_builder` 的 `days_per_week` 与模板不匹配** — 未测试 3 天 intermediate 用户是否得到 3 天而非 5 天训练。
5. **`meal_distributor` 的 3 餐无练后餐场景** — 未测试倾斜缺失行为。
6. **`macro_allocator` 碳水为负的极端场景** — 未测试安全检查分支。
7. **并发/线程安全** — `ExerciseLibrary` 在 `load()` 中修改 `self._exercises` 和 `self._index`，非线程安全（单线程使用无问题，但如果未来做 API 服务需注意）。

---

## 五、模块耦合度评估

### 5.1 耦合度

| 模块 | 依赖数 | 被依赖数 | 评价 |
|------|--------|----------|------|
| profile_validator | 0 | 9 | 核心，被所有人依赖 |
| tdee_calculator | 1 | 2 | 低耦合 |
| macro_allocator | 2 | 2 | 低耦合 |
| exercise_library | 0 | 1 | 独立，仅被 session_builder 使用 |
| split_selector | 1 | 1 | 低耦合 |
| session_builder | 3 | 1 | 中等耦合（依赖最多） |
| meal_distributor | 2 | 1 | 低耦合 |
| progression_planner | 1 | 1 | 低耦合 |
| supplement_advisor | 2 | 1 | 低耦合 |
| plan_output | 8 | 0 | 汇聚点，依赖所有人 |
| explain_generator | 5 | 0 | 汇聚点 |

**总评**: 耦合结构健康。`profile_validator` 是唯一的中心依赖，其余模块间横向依赖很少。`plan_output` 和 `explain_generator` 作为输出层自然汇聚所有依赖。

### 5.2 内聚度

所有模块均为高内聚——每个文件只做一件事。没有发现"上帝类"或混合职责。

---

## 六、改进建议

### 6.1 🔴 高优先级

| # | 建议 | 原因 |
|---|------|------|
| 1 | **修复 `split_selector` 的天数不匹配问题** | 用户指定 3 天但可能得到 5 天训练，违反用户意图 |
| 2 | **为 `explain_generator` 添加测试** | 唯一无测试的模块，输出层不应有盲区 |
| 3 | **修复 `ValidationError` 的 dataclass+Exception 问题** | 可能导致异常框架行为异常 |

### 6.2 🟡 中优先级

| # | 建议 | 原因 |
|---|------|------|
| 4 | **统一 validate() 的错误收集策略** | 当前三处提前 raise，用户体验差 |
| 5 | **调整 TDEE 活动乘数条件覆盖盲区** | `d=5, m=45` 落入 moderate 不合理 |
| 6 | **添加 `Pipeline` 编排类** | 简化调用方代码，减少集成错误 |
| 7 | **`days_per_week=0` 全链路处理** | 添加警告或特殊路径 |
| 8 | **3 餐场景的练后餐倾斜** | 让 3 餐用户也有营养倾斜 |

### 6.3 🟢 低优先级

| # | 建议 | 原因 |
|---|------|------|
| 9 | **`macro_allocator` 碳水为负时添加警告** | 用户应知道热量目标无法满足 |
| 10 | **`__init__.py` 导出公共 API** | 改善开发体验 |
| 11 | **添加类型提示 `Protocol`** | 进一步增强类型安全 |
| 12 | **`session_builder` round 行为文档化** | 避免未来维护者困惑 |
| 13 | **补充边界值测试** | `d=0, m=0` 全链路、碳水为负、3 餐无练后餐 |

---

## 七、总结

### 整体评分: 7.5 / 10

| 维度 | 评分 | 说明 |
|------|------|------|
| 架构设计 | 8/10 | 单向依赖管线，职责清晰，数据类封装好 |
| 代码质量 | 7/10 | 可读性好，但有 dataclass+Exception、错误收集碎片化等问题 |
| 测试覆盖 | 7/10 | 77 测试覆盖率高，但 explain_generator 无测试、边界场景缺失 |
| 健壮性 | 7/10 | 核心路径健壮，但 split_selector 天数不匹配是显著缺陷 |
| 可维护性 | 8/10 | 模块独立、命名清晰、有论文溯源 |

### 三个修复点的判定

1. **profile_validator 边界值** — ✅ 修复方向正确，但 `split_selector` 缺少 `d==0` 分支
2. **meal_distributor 总量回正** — ✅ 修复正确且完整
3. **progression_planner 双进阶标签** — ✅ 修复正确

### 最大风险

**`split_selector` 天数不匹配**是当前最大的功能性缺陷。用户指定 `days_per_week=3`（intermediate）会得到 `push_pull_legs` 模板的 5 天训练，与用户意图不符。建议优先修复。

---

*审查完毕。报告已保存至 `~/fitness-planner/REVIEW.md`。*

# 引擎与 App 对齐审查（2026-09-10）

## 基准与范围

基于 apk-store 本地工作分支 `feat/exercise-closed-loop-v1`，修改前 HEAD `9771b2f`。完整阅读 `fitness-planner/engine/` 的 25 个非空 Python 模块，以及 README、历史 REVIEW；随后核对 Dart 网关、模型、执行队列、计划适配、资料问卷、饮食和 Unity 桥接。历史 REVIEW 不是当前实现规范。

本轮两次查询 GitHub main 失败（连接失败/连接被重置），**不能确认本地镜像就是远端最新版本**。没有改动 Python 算法，没有推送远端或发布 APK。

## 引擎链路及关键约束

| 模块组 | App 必须遵守的输出/规则 |
| --- | --- |
| profile_validator、frequency_planner | 4 类目标；可自动推导天数；保留伤病、饮食限制、器械、负重基线及进阶偏移 |
| exercise_library、split_selector、schedule_planner、session_builder | 依据器械/伤病筛选，按星期安排恢复间隔；sets/reps/load/rest_sec/rpe/tempo/form_cues 为处方 |
| load_planner、injury_planner | 没有基线不编造公斤数；哑铃可能是单手重量；伤病过滤与提示不可丢失 |
| mesocycle_planner、progression_planner | 每周 set_overrides、rir_target、减载；减脂减载周还有 diet_kcal_delta |
| recovery_planner | 非力量训练日可为完整休息、活动度、有氧或轻泵感；不能把文本建议捏造成已完成训练组 |
| stage_goal_planner、stage_assessor、check_in_engine、progress_tracker、response_profiler、cohort_compare | 以实际日志为评估证据；疼痛优先；未知重量/RIR不能当成真实值；缺数据不伪造达标 |
| tdee_calculator、macro_allocator、meal_distributor、food_db、supplement_advisor | 保留营养目标、餐次、饮食限制和烹饪条件；目录食谱不能冒充已通过限制校验 |
| pipeline、plan_output、explain_generator | 统一输出；说明文字不代替可执行处方 |

引擎**没有逐动作 work_seconds**。55 秒/35 秒是容量预算用的工作时间估算，复合动作休息倍率也是预算计算，不是额外的休息处方。数字 tempo `3-1-2-0` 可以推算一次 6 秒、12 次预计72秒；力量目标的“受控”不能这样换算。当前 reps 也不能自动解释成平板支撑等保持动作的秒数。

## 本轮已修改

1. `plan_adapter` 按当前中周期周次应用 set_overrides，训练队列和周计划适配结果使用真实覆盖组数，附带本周 RIR 提示；不覆盖保存的基准计划或在训快照。周期结束暂保持末周，等待复评，不自动回到第一周。duration_min 仍是引擎基准周估计，没有按比例伪造新时长。
2. 数字 tempo × 目标次数提供**预计本组倒计时**；非数字节奏保留实际用时并标注“引擎未规定秒数”。归零停在零，不自动完成、不写入虚构次数。移除目标次数强制裁剪为5–20的逻辑。
3. Unity 协议追加 estimatedWorkSeconds/remainingWorkSeconds；本地 Unity 不再把外部工作时间清零。Flutter 和 Unity 显示本动作的组序号，而非把全课组数当作该动作组数。
4. 编辑资料保留伤病、饮食限制、烹饪条件、补剂、力量基线、热量/容量/动作偏移与徒手进阶；未改变场景时保留精确器械列表。清空选填数据可真正删除。错误身体输入不再静默回退成默认年龄/身高/体重。
5. 只提供减脂/增肌/塑形/力量四类引擎目标。旧“体能/恢复”偏好需重新选择，避免静默生成塑形计划；历史计划与日志不删除。力量欢迎页暂复用增肌视频。
6. 首页休息提示显示 recovery_days 的具体建议。跨日或应用回前台时刷新今日计划；已开始/待开始的会话保留快照。
7. 多次加餐的营养目标求和。存在饮食限制时，不提供无校验元数据的静态推荐食谱，而显示引擎餐次建议；不声称实际食材已完成过敏原核验。

## 验证与回滚

- Python `unittest discover -s tests`：187 项通过。
- Flutter 全套：126 项通过，新增覆盖周次组数、RIR说明、基准不变、倒计时不自动完成、资料保留、目标迁移和加餐汇总；最终静态分析无问题，git diff --check通过。
- Unity 6000.5.4f1 Windows Development 构建成功，状态冒烟通过：准备/深蹲/暂停/休息/俯卧撑/完成、外部预计倒计时及归零不完成。
- Unity 隐藏运行截图是黑屏，**本轮视觉验收未通过**；不能将状态断言当成完整渲染或动作质量验收。
- Flutter 保留为可审查 Git diff，未重置用户文件、未改数据库架构。Unity 四个改动脚本的旧版在 `D:/Codex_pro/Stopwatch/.codex-backups/engine-alignment-20260910/`。
- Unity 本地工程：`D:/Codex_pro/Stopwatch/repo-main/stopwatch-main/unity/StopwatchUnity`。本轮可执行文件：`D:/Codex_pro/Stopwatch/outputs/coach-engine-alignment-20260910/StopwatchCoach.exe`；日志在 outputs/coach-engine-alignment-build.log、coach-engine-alignment-smoke.log。
- Unity 源工程和大资产仍不在 apk-store Git 工作树内；换机必须携带整个源工程的 Assets/Packages/ProjectSettings。本轮没有重新导出 Android Library。

## 仍未关闭的问题（不能宣称全量验收）

以下为首轮发现；第1、2项的后续落实见文末“第二轮”，不要把历史缺口误认为仍全部未做。

1. 引擎 diet_break/diet_kcal_delta 尚未应用到每日饮食执行目标；引擎没有同时输出该周新的餐次/三大营养素分配，不能在前端随意编造。需明确派生契约并双端验证。
2. 问卷尚未完整暴露伤病、饮食限制、烹饪条件、精确器械和力量基线的编辑控件，本轮先保证已保存信息不丢失。最低时长仍是水平/目标/器械探测值，不保证所有伤病及进阶状态都可达容量。
3. Unity 原生尚未完整显示重量/节奏/动作要点/本周 RIR，动作动画未按 tempo 同步。仅2个真实动作 FBX，不能声称整个动作库都能标准演示。
4. 未规定数值节奏的动作以及等长保持动作，需要引擎新增明确执行时长与来源字段后才能统一成规定倒计时。不要用预算常量顶替。
5. 本轮尚未安装新 Android 包到模拟器/真机；Flutter↔Android Unity 联调、页面布局和完整循环视觉验收仍待执行。服务器仍是旧发布版本。
6. 引擎自身待核实项：复评 next_raw 的目标体重/补剂保留、平均RIR为0时的分支、禁奶与补剂建议一致性。需与远端最新代码复核后修 Python+Dart，不单方面更改权威规则。

下一步优先：恢复远端比对 → 补齐输入及饮食减载执行契约 → 完成本机 Unity 可见渲染/动作循环验收 → 重导出 Android 并跑完整训练与恢复记录闭环。验收通过前不替换服务器 APK。

## 第二轮：输入与减载周饮食（2026-09-10）

已完成：

- 问卷增加实际器械多选，不再只能使用场景固定列表；增加引擎支持的8类伤病部位、10类饮食限制、3类烹饪条件及4类可选已知估算1RM。沿用现有页面样式，无额外强制步骤。
- 未编辑的旧重量/次数基线保留；新输入须为有限正数，清空可删除，非法值会阻止提交。返回上一步再进入时保留已编辑约束。
- 新增权威Python执行投影 `engine/weekly_nutrition.py` 及 Dart 镜像。契约：读取当周 diet_kcal_delta；在基准营养目标上加增量，保持蛋白/脂肪，按原分配器的剩余能量规则计算碳水，调用原有餐次分配器重新生成餐次、食物选项和手掌份量。零增量返回原基准；不改变profile.kcal_adjust，不保存为新计划，不重复累计。
- Flutter每日饮食目标通过统一周次选择应用投影；饮食分析页显示当周热量调整说明。Python提供同名语义的可调用执行函数，**未修改后端API响应结构或部署后端**。
- 不承诺加400一定精确等于TDEE：引擎保留的kcal_adjust仍在。前端明确描述“相对基准调整”，不假称恢复到绝对维持量。

验证：Python188项、Flutter128项通过，最终静态检查无问题。固定跨语言样例（80kg、减脂、纯素、kcal_adjust=100、6餐）：减载目标2855kcal、蛋白200g、脂肪64g、碳水369.8g（UI取整370g）；餐次合计与热量目标误差小于1kcal。控件测试覆盖已有基线保留、非法输入、修改与清空。

回滚补充：本轮开始时问卷与plan_sync快照在 `D:/Codex_pro/Stopwatch/.codex-backups/nutrition-input-before-20260910/`，其余新增文件均在Git diff可独立审查。本轮未修改Unity、未构建/安装新Android包、未替换服务器APK、未推送。GitHub远端重试仍被重置连接，最新基准待核实。

剩余：最低时长仍按目标/水平/器械探测，非完整伤病可行性保证；器械库自身的组合假设尚未修改。下一步完成本机Unity可见渲染、处方展示及动作循环验收，再重导出Android并验证新增问卷/饮食和训练闭环。

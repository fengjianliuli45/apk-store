# 待处理问题

> 状态：L3 待办与研究材料，不构成产品决策
> 现行入口：[`INDEX.md`](INDEX.md)；排期或实施前必须重新核实代码现状，并遵守首发冻结基线。

记录 2026-08-19 讨论中提出、还没动手做的三个问题，作为后续排期参考。

---

## 1. 训练引擎缺动作示范素材

`assets/data/exercises.json` 108 个动作，`video_url` 全部是 `null`——训练列表里每个动作只有一个统一的哑铃图标，没有任何示范画面（图/GIF/视频）。

108 个动作实际只对应 **15 种 `movement_pattern`**：

```
anti_extension, calf_raise, core, elbow_extension, elbow_flexion,
hip_extension, hip_hinge, horizontal_pull, horizontal_push, knee_flexion,
squat, trunk_flexion, trunk_rotation, vertical_pull, vertical_push
```

按 pattern 配一套通用示范即可覆盖大部分动作，缺口从 108 降到 15，不用给每个动作单独配素材。

**待定**：
- 素材形式——静态动作分解图 vs 短视频循环，两者成本/体积/观感取舍还没定（讨论中断，用户还没给出最终答案）。
- 素材来源——手头没有现成素材（0 个），需要生成；用户此前提到有 MiniMax（海螺）视频生成 API Key，可能会复用。

---

## 2. "数据"页文字太碎，想要图表

用户反馈某个页面"满屏是被打断的文字"，希望换成更直观的图表呈现。

现状：仓库里**还没有**一个独立的"数据"页面（`docs/Stopwatch-app-design-blueprint-v2.md` §6.12 提到的数据模块尚未实现）。最接近的候选：

- 训练 tab（`lib/screens/training_screen.dart`）顶部新加的营养摘要卡（`_NutritionSummaryCard`）
- 训练 tab / 计划 tab 里逐条列出的"动作名 · X 组 × X 次"文字列表

**待定**：需要用户确认具体是哪个页面/哪部分文字，才能对症下药（比如换成周训练量柱状图、宏量营养素占比图等）。

---

## 3. 社交圈 / 地图 / 饮食 / 消息 / 语音助手是空壳，没有真后端

当时是刻意的技术选型（见 `docs/FEATURE_PLAN.md`）：先把 UI 和本地状态跑通，不接付费云服务、不用未申请的地图/云视觉 Key。现状：

| 模块 | 现状 |
|---|---|
| 附近的人 | 地图是真的（`flutter_map` + OSM），人是写死的 mock 坐标 |
| 消息 | 本地会话（`shared_preferences`），没有真实收发通道 |
| 语音助手 | 真的在用设备语音识别（`speech_to_text`），但只映射到几条写死的命令，不是 AI 对话 |
| 社交圈 / 饮食 | 数据存在本地，没有跨设备同步，别人看不到你发的内容 |

这条工作量最大，本质是要不要、以及用什么方式接一个真后端（自建 server + 数据库，还是 Firebase/Supabase 这类 BaaS）。会决定后续架构方向，需要单独讨论：

- 先挑一两个模块做深，还是先定好整体后端方案再铺开？
- 自建 vs BaaS？
- 地图 API Key、推送、实时消息通道等外部依赖谁来申请/付费？

**待定**：讨论未完成，用户还没给出优先级方向。

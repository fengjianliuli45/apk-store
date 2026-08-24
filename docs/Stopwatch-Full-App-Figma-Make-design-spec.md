# Stopwatch 完整 App UI · Figma Make 生成规范

> 日期：2026-08-24  
> 用途：在同一个 Figma Make 项目中分阶段生成 Stopwatch 全部 App UI  
> 设计范围：完整产品；开发范围仍可保持 P0 训练闭环  
> 基准设备：390 × 844 手机竖屏  
> 默认语言：简体中文

---

## 0. 为什么必须使用这份新文档

`Stopwatch-Unity-P0-Figma-Make-design-spec.md` 只描述 Unity 两动作训练闭环，所以 Make 只生成训练模块是正确结果。

本文件负责完整 App，覆盖：

- 登录、注册和入门资料。
- AI 计划生成与计划解释。
- 极简训练首页和开舱过场。
- 3D 肌肉计划与动作组合。
- Unity 训练、休息、鼓励和完成。
- 独立数据中心。
- 饮食识别、日记和建议。
- 地图、训练地点与约练。
- 社区、用户资料和一对一聊天。
- 个人主页、侧边设置、设备和隐私。
- 每日角色开场、段位和系统状态。
- 轻量装备推荐。

完整 UI 设计与当前开发优先级是两件事。Figma 可以先覆盖整个产品，代码仍优先完成训练闭环。

---

## 1. Figma Make 正确使用方法

不要把 70 多个页面一次性要求 Make 全部生成。单次输出容易截断、复用错误或只完成前几个模块。

在同一个 Figma Make 项目中依次执行：

1. Prompt 0：全局基础、组件库与导航壳。
2. Prompt 1：登录注册与入门资料。
3. Prompt 2：首页、每日开场与计划概览。
4. Prompt 3：完整 Unity 训练闭环。
5. Prompt 4：完成总结、段位与数据中心。
6. Prompt 5：饮食模块。
7. Prompt 6：附近地图与约练。
8. Prompt 7：同道社区、资料和聊天。
9. Prompt 8：个人中心、设置、设备、商城与全局连线。

每次都在同一个 Make 会话继续输入。后续 Prompt 明确要求“保留已有页面和组件，只追加新模块”。

---

## 2. 产品定义

### 2.1 一句话

Stopwatch 是一个像秒表一样简单的 AI 健身教练：打开 App，按下开始，查看身体与今日训练，跟随 3D 教练完成动作和恢复，并在训练之后查看数据、饮食建议和同道反馈。

### 2.2 默认用户

- 没有健身基础的新手。
- 时间有限，只想训练某个部位的用户。
- 有自己的训练安排，需要动作筛选和强度建议的进阶用户。

产品默认引导新手，但不能强迫所有用户接受不可修改的 AI 计划。

### 2.3 产品原则

1. 主行为永远是开始训练。
2. 首页不做数据 dashboard。
3. 详细数据集中到独立数据模块。
4. AI 建议可解释、可修改、可跳过。
5. 社交只在合适节点出现，不干扰训练。
6. 训练页人物和动作是视觉主体。
7. 饮食、地图和商城为训练服务，不制造焦虑。
8. 所有核心操作支持单手和运动状态下点击。

---

## 3. 完整信息架构

### 3.1 一级导航

完整版本使用四个一级 Tab：

| Tab | 名称 | 职责 |
|---|---|---|
| T1 | 练 | 极简首页、计划入口、开始训练 |
| T2 | 附近 | 地图、训练地点、收藏、约练 |
| T3 | 同道 | 动态、搭子、约练广场、消息 |
| T4 | 我的 | 个人资料、数据、饮食、历史、设置 |

约束：

- 默认进入“练”。
- 首页中央始终只有圆形“开始”主操作。
- Unity 训练、首次入门、拍照、聊天详情等沉浸流程隐藏底部导航。
- 数据是独立完整模块，从首页两项数据和“我的”进入，不在首页铺卡片。
- 饮食从完成页和“我的”进入，不成为首发一级 Tab。

### 3.2 首次使用

```text
启动 -> 登录方式 -> 手机/第三方登录 -> 入门资料
-> 安全与限制 -> 生成计划 -> 首页
```

### 3.3 日常训练

```text
首页 -> 每日角色开场（按频率出现） -> 开始 -> 开舱过场
-> 3D 肌肉计划 -> 调整动作 -> Unity 训练
-> 休息 / 鼓励 -> 完成总结 -> 首页
```

### 3.4 特定肌肉或时间受限

不显示“AI / 指定部位 / 自定义”三个大入口。

```text
开始 -> 默认 AI 今日计划 -> 点击肌肉 -> 下半屏显示动作
-> 修改时间或动作组合 -> 确认训练
```

### 3.5 已有训练安排评估

```text
我的计划 -> 今日状态检查 -> 系统给出
照常 / 补充 / 降低强度 / 休息建议 -> 用户确认或忽略
```

---

## 4. 全局视觉系统

### 4.1 视觉方向

关键词：简洁、有个性、轻科技、有训练动力、纯净 3D、克制高对比。

核心视觉：

- 冷白和浅灰背景。
- 黑色主文字。
- 电光青柠 `#BAFF00` 作为主交互色。
- 训练页像纯净的 3D 展示棚，人物完整、有地面接触和空间感。
- 浅色半透明面板只用于必要工具和底部操作。
- 数据页比首页更密，但仍保持清晰分层。

禁止：

- 旧版纯黑休息舱、琥珀科幻 HUD。
- 海报式超大标题抢占主要空间。
- 大量卡片嵌套、霓虹光球和装饰性渐变。
- 首页多图表、多指标、多课程列表。
- 把 3D 模型装进圆角预览卡片。

### 4.2 Color Variables

| Variable | Value | 用途 |
|---|---|---|
| `color/canvas` | `#EEF1ED` | 主背景 |
| `color/canvas-deep` | `#E4E8E3` | 地图与舞台层次 |
| `color/surface` | `rgba(250,251,248,.84)` | 玻璃工具面板 |
| `color/surface-strong` | `#F8FAF6` | 实体表面 |
| `color/ink` | `#0D1112` | 主文字、图标 |
| `color/secondary` | `#667071` | 次级文字 |
| `color/muted` | `#9AA3A1` | 禁用和说明 |
| `color/hairline` | `rgba(13,17,18,.12)` | 分隔线 |
| `color/lime` | `#BAFF00` | 主 CTA、当前状态 |
| `color/lime-pressed` | `#A6E600` | 按压态 |
| `color/success` | `#55C98A` | 成功、完成 |
| `color/warning` | `#F2A63C` | 警告、结束训练 |
| `color/error` | `#D85D56` | 错误、危险 |
| `color/scrim` | `rgba(13,17,18,.24)` | 弹层背景 |

### 4.3 Typography

- 中文与正文：Noto Sans SC 或系统无衬线。
- 数字：JetBrains Mono 或系统等宽数字，启用 tabular nums。
- 页面标题：28–32px / 700。
- 区块标题：20–22px / 700。
- 正文：15–16px / 400–500。
- 标签：10–11px / 600。
- 主指标：48–64px / 400–500。
- 不使用随屏幕宽度变化的字体尺寸。

### 4.4 Layout

- 基准：390 × 844。
- 顶部安全区参考 47px，底部安全区参考 34px。
- 页面左右边距 16–20px。
- 主按钮高度 56px，触控区域不小于 48 × 48px。
- 主内容支持纵向滚动；固定操作不能超出安全区。
- 卡片圆角 12–20px，底部弹层 24px；不嵌套卡片。
- 列表优先使用分隔线和整行交互，不把每一行做成浮卡。

### 4.5 Motion

- 页面转场 220–320ms。
- 底部弹层 280ms ease-out。
- 3D 镜头聚焦 350–500ms。
- 按钮按压缩放 0.98，120ms。
- 支持 Reduce Motion，复杂过场降级为 180ms 淡入淡出。

---

## 5. 全局组件库

Figma Make 必须先创建组件和 Variant，再搭页面：

### Navigation

- `AppBottomNav`: Training / Nearby / Community / Profile。
- `TopBar`: Back / Title / Action。
- `ImmersiveHeader`: 无背景的返回、状态和计时。
- `SettingsDrawer`: Closed / Open。

### Actions

- `PrimaryButton`: Default / Pressed / Disabled / Loading。
- `SecondaryButton`: Default / Pressed / Disabled。
- `IconButton`: Default / Pressed / Selected / Disabled。
- `CircularStart`: Idle / Pressed / Running。
- `HoldToConfirm`: Idle / Holding / Complete。
- `Stepper`: Minus / Value / Plus。

### Inputs

- `TextField`: Default / Focus / Filled / Error / Disabled。
- `PhoneField`。
- `OtpCell`: Empty / Filled / Error。
- `ChoiceRow`: Default / Selected。
- `ChoiceBottomSheet`。
- `SliderField`。
- `ToggleRow`。
- `SearchField`。

### Training

- `UnityMuscleViewport`: FullBody / Focused / Loading / Error。
- `CoachViewport`: Standing / Floor / Recovery / Preview / Frozen / Error。
- `ExerciseRow`: Default / Selected / Disabled / MissingAsset。
- `SetProgressRail`。
- `SpatialCountdown`。
- `EncouragementCard`: Idle / Liked。
- `WorkoutSummaryMetric`。

### Data and Content

- `MetricRow`。
- `TrendChart`。
- `EmptyChartState`。
- `MealRow`。
- `PlaceRow`。
- `PartnerRow`。
- `PostItem`。
- `ChatBubble`: Incoming / Outgoing / System。
- `ProfileHeader`。
- `RankBadge`。
- `ProductRecommendationRow`。

### Feedback

- `Toast`: Success / Info / Error。
- `InlineError`。
- `PermissionSheet`。
- `EmptyState`。
- `OfflineBanner`。
- `LoadingState`。

---

## 6. 完整页面清单

### 6.1 启动、账号与入门（A）

| ID | Frame 名称 | 页面 |
|---|---|---|
| A00 | `App / Launch` | 品牌启动 |
| A01 | `Auth / Methods` | 登录方式 |
| A02 | `Auth / Phone` | 手机号 |
| A03 | `Auth / OTP` | 验证码 |
| A04 | `Auth / Account` | 邮箱密码备用 |
| A05 | `Auth / Error` | 登录错误 |
| A06 | `Onboarding / Goal` | 目标 |
| A07 | `Onboarding / Experience` | 经验 |
| A08 | `Onboarding / Scene` | 场景 |
| A09 | `Onboarding / Equipment` | 器械 |
| A10 | `Onboarding / Session Time` | 单次时长 |
| A11 | `Onboarding / Weekly Days` | 每周天数 |
| A12 | `Onboarding / Body` | 身体数据 |
| A13 | `Onboarding / Safety` | 伤病限制 |
| A14 | `Plan / Generating` | 生成计划 |
| A15 | `Plan / Generate Error` | 生成失败 |

### 6.2 首页与计划（H/P）

| ID | Frame 名称 | 页面 |
|---|---|---|
| H00 | `Home / Daily Intro` | 每日角色开场 |
| H01 | `Home / Main` | 圆形开始首页 |
| H02 | `Home / Running` | 首页计时状态 |
| H03 | `Home / Hatch` | 开舱过场关键帧 |
| P00 | `Plan / Overview` | 3D 肌肉计划 |
| P01 | `Plan / Muscle Focus` | 肌肉聚焦 |
| P02 | `Plan / Exercise Picker` | 动作组合 |
| P03 | `Plan / Exercise Detail` | 动作详情 |
| P04 | `Plan / Time Adjust` | 今日时间调整 |
| P05 | `Plan / Existing Check` | 已有安排评估 |
| P06 | `Plan / Download Required` | 动作资源提示 |

### 6.3 Unity 训练（U）

| ID | Frame 名称 | 页面 |
|---|---|---|
| U00 | `Unity / Loading` | Unity 加载 |
| U01 | `Unity / Ready` | 准备 |
| U02 | `Unity / Active Standing` | 站立动作 |
| U03 | `Unity / Active Floor` | 地面动作 |
| U04 | `Unity / Paused` | 暂停 |
| U05 | `Unity / Rest` | 普通休息 |
| U06 | `Unity / Rest Last Five` | 最后五秒 |
| U07 | `Unity / Encouragement` | 动作完成鼓励 |
| U08 | `Unity / Hold End` | 长按结束 |
| U09 | `Unity / Completed` | Unity 完成 |
| U10 | `Unity / Early End` | 中途结束 |
| U11 | `Unity / Motion Error` | 动作异常 |

详细规格引用同仓库 `Stopwatch-Unity-P0-Figma-Make-design-spec.md`，完整 App 文件中必须保留这些 Frame，不能只放链接或文字占位。

### 6.4 完成、段位与数据（C/D）

| ID | Frame 名称 | 页面 |
|---|---|---|
| C00 | `Completion / Summary` | 正常完成总结 |
| C01 | `Completion / Early Summary` | 中途结束总结 |
| C02 | `Completion / AI Feedback` | 建议解释 |
| C03 | `Rank / Progress` | 段位进度 |
| C04 | `Rank / Upgrade` | 升段反馈 |
| D00 | `Data / Overview` | 数据总览 |
| D01 | `Data / Training` | 训练数据 |
| D02 | `Data / Muscle` | 肌群分布 |
| D03 | `Data / Body` | 身体数据 |
| D04 | `Data / Recovery` | 恢复数据 |
| D05 | `Data / Nutrition` | 营养数据 |
| D06 | `Data / Metric Detail` | 单指标详情 |
| D07 | `Data / Empty` | 数据不足 |
| D08 | `History / List` | 训练历史 |
| D09 | `History / Detail` | 单次训练详情 |

### 6.5 饮食（N）

| ID | Frame 名称 | 页面 |
|---|---|---|
| N00 | `Nutrition / Home` | 当日饮食 |
| N01 | `Nutrition / Camera` | 食物相机 |
| N02 | `Nutrition / Barcode` | 条码扫描 |
| N03 | `Nutrition / Analyzing` | 分析中 |
| N04 | `Nutrition / Result` | 识别结果 |
| N05 | `Nutrition / Edit` | 食物与份量修改 |
| N06 | `Nutrition / Saved` | 保存成功 |
| N07 | `Nutrition / History` | 饮食历史 |
| N08 | `Nutrition / Meal Detail` | 单餐详情 |
| N09 | `Nutrition / Next Meal` | 下一餐建议 |
| N10 | `Nutrition / Recipes` | 食谱列表 |
| N11 | `Nutrition / Recipe Detail` | 食谱详情 |

### 6.6 附近与约练（M）

| ID | Frame 名称 | 页面 |
|---|---|---|
| M00 | `Nearby / Permission` | 定位授权 |
| M01 | `Nearby / Map` | 附近地图 |
| M02 | `Nearby / Search` | 搜索与筛选 |
| M03 | `Nearby / Place Sheet` | 地点底部信息 |
| M04 | `Nearby / Place Detail` | 地点详情 |
| M05 | `Nearby / Saved` | 收藏地点 |
| M06 | `Meetup / Create` | 发起约练 |
| M07 | `Meetup / Detail` | 约练详情 |
| M08 | `Meetup / Joined` | 参加成功 |

### 6.7 同道、搭子与聊天（S/X）

| ID | Frame 名称 | 页面 |
|---|---|---|
| S00 | `Community / Feed` | 动态流 |
| S01 | `Community / Post Detail` | 动态详情 |
| S02 | `Community / Comments` | 评论 |
| S03 | `Community / Compose` | 发布动态 |
| S04 | `Community / Partner Match` | 搭子推荐 |
| S05 | `Community / Meetup Board` | 约练广场 |
| S06 | `Community / User Preview` | 用户小资料 |
| S07 | `Community / User Profile` | 用户主页 |
| S08 | `Community / Following` | 关注列表 |
| X00 | `Chat / List` | 消息列表 |
| X01 | `Chat / Thread` | 单聊 |
| X02 | `Chat / Actions` | 会话操作 |
| X03 | `Chat / Report` | 举报 |
| X04 | `Chat / Blocked` | 拉黑结果 |

### 6.8 我的、设置、设备与装备（R/E/G）

| ID | Frame 名称 | 页面 |
|---|---|---|
| R00 | `Profile / Home` | 我的 |
| R01 | `Profile / Edit` | 编辑资料 |
| R02 | `Profile / Goal` | 当前目标 |
| R03 | `Profile / Settings Drawer` | 设置侧栏 |
| R04 | `Settings / Training` | 训练偏好 |
| R05 | `Settings / Health` | 身体与健康 |
| R06 | `Settings / Notifications` | 通知 |
| R07 | `Settings / Privacy` | 隐私 |
| R08 | `Settings / Account` | 账号与登录方式 |
| R09 | `Settings / Data` | 导出与删除 |
| E00 | `Devices / Home` | 设备中心 |
| E01 | `Devices / Connect` | 搜索设备 |
| E02 | `Devices / Permission` | 蓝牙/相机授权 |
| E03 | `Devices / Calibration` | 校准 |
| E04 | `Devices / Posture Report` | 姿态报告 |
| G00 | `Gear / Recommendations` | 装备推荐 |
| G01 | `Gear / Detail` | 装备详情 |

### 6.9 系统状态（Z）

| ID | Frame 名称 | 页面 |
|---|---|---|
| Z00 | `System / Offline` | 离线提示 |
| Z01 | `System / Empty` | 通用空状态 |
| Z02 | `System / Loading` | 通用加载 |
| Z03 | `System / Error` | 通用错误 |
| Z04 | `System / Camera Permission` | 相机权限 |
| Z05 | `System / Location Permission` | 定位权限 |
| Z06 | `System / Notification Permission` | 通知权限 |
| Z07 | `System / Delete Account` | 删除账号确认 |

---

## 7. 模块详细规范

### 7.1 登录与入门

- 登录首屏不使用巨大表单卡。
- 首选手机号；微信、Google 使用图标按钮；iOS 增加 Apple。
- 邮箱密码放在“其他登录方式”。
- 每个入门步骤只问一个主题。
- 目标、场景和器械点击后弹出选择层，不把所有选项平铺成大片文字。
- 底部“下一步”固定在安全区域内。
- 身体数据使用步进器、滑杆或数字输入。
- 伤病限制需要“无”和具体部位，选择后显示简短安全说明。
- 顶部显示轻量步骤进度，不显示繁重表单标题。

### 7.2 计划生成

- 中央使用人体或教练轻量动态，不使用技术日志。
- 显示三个过程项：匹配目标、筛选动作、估算休息。
- 超过 8 秒显示“先使用默认计划”。
- 失败允许重试或使用安全默认计划。

### 7.3 首页

- 中央圆形“开始”是绝对主角。
- 圆周只显示运动天数和累计消耗能量。
- 点击两项数据进入独立数据模块。
- 顶部只显示状态、品牌或个人入口。
- 底部最多一行今日计划摘要。
- 不显示课程列表、饮食卡、社区动态或趋势图。

### 7.4 每日角色开场

- 5–8 秒完整版，普通训练日 3–5 秒短版。
- 角色是支持用户的 AI 前辈，不羞辱、不持续说话。
- 可立即跳过。
- 最后收束到圆形“开始”。
- 连续第 7 天、升段前和久未回归时提高出现频率。

### 7.5 开舱过场

- 点击开始后播放，再进入计划概览。
- 保留“从中心缝隙打开”的概念。
- 颜色和材质适配当前浅色 Figma，不复用旧深黑休息舱。
- 必须有完整闭合首帧、可读的解锁节奏和清晰目标页揭示。
- Reduce Motion 时改为短淡入淡出。

### 7.6 3D 肌肉计划

- 上半屏为全身 3D 肌肉模型，下半屏为计划摘要。
- 今日肌群在模型上清晰但自然地高亮。
- 点击肌肉后镜头聚焦，其他区域弱化。
- 下半屏切换为该肌肉动作列表。
- 动作行包含选择、名称、器械、难度、组数、次数和替换。
- 用户可以调整今天可用时间，系统自动裁剪动作和组数。
- 不显示三个大模式入口。

### 7.7 Unity 训练

- 训练全屏隐藏底部导航。
- Ready 显示动作、组数、教练和开始。
- Active 显示当前动作、组数、次数/时间、进度侧栏、暂停和完成本组。
- 不显示左上退出箭头；长按 1.2 秒结束。
- Rest 以 3D 角色和头顶倒计时为主体，底部保留跳过与 `+30 秒`。
- Last Five 先显示下一动作名称，再切换动作预演。
- 鼓励卡只在同一动作全部组数完成后出现。
- 鼓励卡双击点赞、点击外部跳过、点击头像进入用户资料；P0 可以先用本地占位。
- 动作缺失不能拿其他动作冒充。

### 7.8 完成与段位

- 一个主数字：总训练时长。
- 摘要：动作数、组数、消耗估算。
- 一句具体 AI 反馈。
- 段位进度是次级身份信息，不替代训练结果。
- 正常完成可显示饮食入口；不强迫分享。
- 升段反馈 6–8 秒，可跳过。

### 7.9 数据中心

顶部使用分段控件：总览、训练、身体、恢复、营养。

- 单屏最多一个主数字和一个趋势图。
- 其余指标使用可点击行。
- 训练页展示频率、总训练量、肌群分布。
- 身体页展示体重、体脂和围度。
- 恢复页展示疲劳、自评、睡眠和心率。
- 营养页展示摄入、消耗和宏量营养。
- 数据不足时说明需要完成几次记录，不生成空图表。

### 7.10 饮食

- 相机页只保留取景、拍摄、相册、条码入口。
- 识别结果明确标记“估算”，允许修改食物和份量。
- 保存后进入当日时间线。
- 下一餐建议结合训练和剩余能量，可“换一个”。
- 不使用羞辱、补偿或极端节食文案。
- 食谱详情包含食材、步骤、营养和替换建议。

### 7.11 附近地图

- 进入附近页后再申请定位。
- 拒绝后可手动选择城市。
- 地图使用低饱和浅灰样式，训练地点标记使用 Lime。
- 地点底部信息包含名称、距离、类型、设施、可练动作和活跃度。
- 主要操作：在这里练、收藏、约搭子。
- 不显示用户精确实时位置。

### 7.12 社区与聊天

- 社区分为动态、搭子和约练。
- 动态突出训练结果和鼓励，不做无限娱乐流。
- 发布前预览照片和可见范围。
- 用户小资料显示昵称、段位、最近训练、共同目标和关注。
- 一对一聊天支持文字、照片、训练地点卡和约练卡。
- 会话操作包含静音、举报、拉黑和清空记录。
- 陌生人消息需要清晰限制与安全提示。

### 7.13 我的与设置

- 首屏只突出昵称、训练天数和当前目标。
- 数据、历史、饮食、设备和设置为清晰入口。
- 侧边设置栏从右侧打开，内容可滚动。
- 分组：训练、身体健康、设备、通知、隐私、账号和数据。
- 删除账号使用二次确认并说明影响。

### 7.14 设备与姿态

- 未来能力，不影响当前无设备训练。
- 设备中心显示连接状态、电量和最后同步。
- 校准使用分步图形指导，不用长文字。
- 姿态报告只显示高置信度问题、受影响关节和改进建议。
- 低置信度结果明确标注，不中断训练。

### 7.15 装备推荐

- 只推荐与当前计划相关的装备。
- 每项必须解释“为什么适合你”。
- 不做购物车、支付和物流。
- 不使用焦虑式倒计时和虚假折扣。

---

## 8. 分阶段 Figma Make Prompts

### Prompt 0：Foundation 与 App Shell

```text
创建 Stopwatch 完整健身 App 的移动端设计基础。只生成 390×844 手机竖屏，不生成桌面或营销页。默认中文。视觉为冷白浅灰背景、黑色文字、电光青柠 #BAFF00 主强调、浅色玻璃工具面板、纯净 3D 运动展示感；禁止旧版纯黑休息舱、琥珀科幻 HUD、海报式大标题和卡片嵌套。

建立 Color、Typography、Spacing、Radius 和 Motion Variables；建立本规范第 5 章全部核心组件与 Variant。创建四 Tab AppBottomNav：练、附近、同道、我的。训练、首次入门、相机、聊天详情等沉浸页面可以隐藏导航。

创建 Page：Foundations、Components、Auth & Onboarding、Training & Plan、Unity Session、Completion & Data、Nutrition、Nearby、Community & Chat、Profile & Settings、Prototype Map。所有组件使用 Auto Layout 和 Component Properties，Frame 以模块 ID 命名。现在只建立基础和空 Section，不生成业务页面。
```

### Prompt 1：登录注册与入门

```text
保留现有 Foundations、Components 和页面，只在 Auth & Onboarding Section 追加 A00–A15。

生成品牌启动、登录方式、手机号、验证码、邮箱密码备用、登录错误，以及目标、经验、场景、器械、单次时长、每周天数、身体数据、伤病限制、计划生成和生成失败。

登录首屏不要巨大表单卡。手机号为主，微信、Google 为快捷图标按钮，Apple 作为 iOS Variant，邮箱密码放入其他方式。每个入门步骤只问一个主题，顶部轻量进度，底部下一步永远在安全区。目标、场景和器械点击后使用底部选择层。所有界面为中文并建立完整 Prototype 连接：注册成功 -> 入门 -> 生成 -> Home 占位出口；老用户登录 -> Home 占位出口。
```

### Prompt 2：首页、开场与计划

```text
保留已有所有页面和组件，只在 Training & Plan Section 追加 H00–H03、P00–P06。

H01 首页中央只有圆形“开始”，圆周显示运动天数与累计消耗能量，顶部为轻量状态和个人入口，底部最多一行今日计划摘要。不要放课程列表、饮食卡、社区流或多图表。加入 H00 每日 AI 前辈短开场、H02 计时状态和 H03 开舱关键状态。

计划页上半屏为无卡片边框的 3D 肌肉模型视口，下半屏为训练摘要。点击肌肉进入 P01 聚焦并显示动作列表；动作可勾选、替换、调组数和次数。加入动作详情、今日时间调整、已有安排评估、动作资源下载提示。不显示“AI / 指定部位 / 自定义”三个大入口。连接：Home 开始 -> Hatch -> Plan Overview -> Muscle Focus / Picker -> Unity Loading 占位出口。
```

### Prompt 3：Unity 完整训练闭环

```text
保留已有所有页面和组件，只在 Unity Session Section 追加 U00–U11。严格按照 Stopwatch-Unity-P0-Figma-Make-design-spec.md 的页面、组件、中文文案和交互生成真实 Frame，不能只放文字链接或灰色占位。

包含 Loading、Ready、站立训练、地面训练、Paused、Rest、Rest Last Five、Encouragement、Hold End、Completed、Early End、Motion Error。3D 人物舞台全屏无卡片边框，UI 不遮挡关节。休息保留跳过和 +30 秒。鼓励卡双击点赞、点击外部跳过。长按结束 1.2 秒可取消。连接深蹲 -> 休息 -> 鼓励 -> 俯卧撑 -> 完成，并连接返回 Completion Summary 占位出口。
```

### Prompt 4：完成、段位与数据

```text
保留已有所有页面和组件，只在 Completion & Data Section 追加 C00–C04、D00–D09。

完成总结只有一个主数字，总时长优先，摘要显示动作数、组数和消耗估算，再给一句具体 AI 反馈和段位进度。中途结束使用中性文案并保存已完成内容。升段 6–8 秒可跳过。

数据中心是独立完整模块，分段为总览、训练、身体、恢复、营养。每屏最多一个主数字和一个真正有价值的趋势图，其余用指标行。加入数据不足状态、训练历史列表和详情。连接首页运动天数/能量、我的数据入口、完成总结到数据或首页。
```

### Prompt 5：饮食

```text
保留已有所有页面和组件，只在 Nutrition Section 追加 N00–N11。

生成当日饮食首页、食物相机、条码扫描、分析中、识别结果、食物和份量修改、保存成功、饮食历史、单餐详情、下一餐建议、食谱列表和食谱详情。识别结果标记“估算”并允许修改。相机页只保留拍摄、相册和条码。下一餐建议结合当天训练，可换一个。不要使用减肥羞辱、补偿性运动或极端节食文案。连接完成页饮食入口和我的饮食入口。
```

### Prompt 6：附近地图与约练

```text
保留已有所有页面和组件，只在 Nearby Section 追加 M00–M08。

先设计定位授权与手动选城市，再设计低饱和浅灰地图，使用 Lime 标记公园、跑道、户外器械和健身房。地点底部信息展示名称、距离、设施、适合动作和今日活跃度。加入地点详情、收藏、发起约练、约练详情和参加成功。主要操作为“在这里练”“收藏”“约搭子”。不公开用户精确实时位置。Nearby Tab 的完整流程必须可点击。
```

### Prompt 7：同道、用户资料与聊天

```text
保留已有所有页面和组件，只在 Community & Chat Section 追加 S00–S08、X00–X04。

社区包含动态、搭子推荐和约练广场。生成动态流、详情、评论、发布、搭子匹配、约练广场、用户小资料、用户主页和关注列表。用户小资料显示昵称、段位、最近训练、共同目标和关注。

正式支持一对一聊天：消息列表、单聊、会话操作、举报和拉黑结果。聊天支持文字、照片、训练地点卡和约练卡。必须有静音、举报、拉黑和陌生人消息限制。保持训练社区气质，不做娱乐化无限流。连接鼓励卡头像 -> User Preview -> Profile / Follow / Chat。
```

### Prompt 8：我的、设置、设备、装备和总连线

```text
保留已有所有页面和组件，只在 Profile & Settings Section 追加 R00–R09、E00–E04、G00–G01，以及 Z00–Z07 系统状态。

我的首屏突出昵称、训练天数和当前目标，提供数据、历史、饮食、设备和设置入口。设计右侧设置抽屉及训练、健康、通知、隐私、账号、数据子页。设备模块包含连接、权限、校准和姿态报告，但无设备时不阻塞训练。装备推荐只解释与计划的关系，不做购物车和支付。

补齐离线、空、加载、错误、相机/定位/通知权限和删除账号状态。最后在 Prototype Map 连接全部模块：首次使用、日常训练、指定肌肉、已有安排评估、训练完成、数据、饮食、地图约练、社区关注聊天、个人设置。检查所有 Frame 都是 390×844，没有死路、没有桌面页面、没有重复组件、没有中文截断。生成一个从登录到完成训练再进入数据/社区的演示起点。
```

---

## 9. Prototype 主流程连线

### 首次使用

`A00 -> A01 -> A02/A03 -> A06...A13 -> A14 -> H01`

### 日常训练

`H00/H01 -> H03 -> P00 -> P01/P02 -> U00 -> U01 -> U02/U03 -> U05/U06/U07 -> U09 -> C00 -> H01`

### 数据

`H01 运动天数/能量 -> D00 -> D01...D06 -> D09`

### 饮食

`C00 或 R00 -> N00 -> N01/N02 -> N03 -> N04/N05 -> N06 -> N00`

### 地图约练

`T2 -> M00/M01 -> M03/M04 -> M06/M07 -> M08`

### 社区聊天

`T3 -> S00/S04/S05 -> S06/S07 -> X01`，消息入口 `X00 -> X01 -> X02/X03/X04`。

### 我的与设置

`T4 -> R00 -> R03 -> R04...R09`，设备 `R00 -> E00 -> E01/E02 -> E03 -> E04`。

---

## 10. 内容语气

简短、具体、支持用户，不油腻、不羞辱。

推荐：

- `开始`
- `今天练上半身`
- `点击肌肉查看动作`
- `第 2 / 4 组`
- `休息 28`
- `下一组：俯卧撑 · 5`
- `已完成的内容会保留`
- `今天腿部完成度很好，下次可以把休息缩短 5 秒。`

避免：

- `燃爆全场`
- `马上逆袭`
- `你太弱了`
- `不练就废了`
- 长篇 AI 技术解释。

---

## 11. 全局无障碍与适配

- 触控区域不小于 48 × 48px。
- 正文和背景达到 WCAG AA。
- 颜色不是唯一状态信号。
- 支持系统字体缩放，主要操作文字不能截断。
- 倒计时和数据使用固定宽度，跳秒不抖动。
- 所有底部按钮位于 Safe Area 内。
- 地图、图片、模型和图表有可访问标签。
- 支持 Reduce Motion。
- 相机、定位、通知和蓝牙权限都解释用途并允许拒绝。
- 无网时仍能完成已下载训练。

---

## 12. 完整产出验收

### 覆盖

- A、H、P、U、C、D、N、M、S、X、R、E、G、Z 全部 Section 有真实页面。
- 至少覆盖本规范页面清单中的所有 ID。
- Unity 训练不是唯一模块。
- 数据、饮食、地图、社区、聊天和设置均可从主导航或明确入口到达。

### 视觉

- 全部是 390 × 844 手机界面。
- 视觉统一为冷白、黑字、Lime 强调。
- 首页保持极简；数据页承担密集信息。
- 没有旧版深黑舱体风格和海报式大标题。
- 3D 舞台无卡片边框，人物完整可见。

### 组件

- 使用 Variables、Auto Layout、Component Properties 和 Variants。
- 相同按钮、导航、输入和列表不重复绘制。
- 组件命名语义清晰。

### 交互

- 首次使用、训练、数据、饮食、地图、社区聊天和设置都有完整路径。
- 页面没有死路。
- 弹层可关闭，权限可拒绝，错误可恢复。
- 训练中暂停、休息、长按结束和完成均可演示。

### 内容

- 默认中文。
- 不使用无意义 Lorem Ipsum。
- 不宣称未实现的真实 AI、真实附近用户或医疗能力。
- 不使用羞辱和焦虑式文案。

---

## 13. 交付说明

Figma Make 完成九段 Prompt 后：

1. 在 `Prototype Map` 检查完整流程。
2. 导出页面 ID 与功能清单。
3. Unity 页面单独交给 Unity 实现。
4. 其余页面交给 Flutter/原生层实现。
5. 当前代码开发仍以 P0 训练闭环为第一优先，不因为完整 UI 已生成而同时开发全部模块。

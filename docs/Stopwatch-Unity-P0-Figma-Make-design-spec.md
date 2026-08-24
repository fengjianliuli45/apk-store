# Stopwatch Unity P0 训练闭环 UI 设计文档

> 用途：直接作为 Figma Make 生成移动端 UI 和交互原型的设计输入  
> 日期：2026-08-24  
> 状态：P0 实施规范  
> 输出目标：一套 390 × 844 的中文手机训练闭环，不生成平板或桌面界面  
> 最终运行环境：全屏 Unity 训练会话；Android 负责启动、结果接收和最小总结

---

## 1. 可直接复制到 Figma Make 的总 Prompt

```text
为 Stopwatch AI 健身教练设计并生成一套可交互的中文手机训练闭环原型。

产品目标：
用户点击 App 首页的“开始”后进入全屏 3D 教练训练。P0 只包含男性教练、徒手深蹲和标准俯卧撑两个动作。用户必须能够从训练准备开始，完成动作、组间休息、最后 5 秒下一动作预告、暂停、继续、跳过休息、增加 30 秒、长按结束，最后看到训练完成结果。

设备与页面：
- 只生成移动端竖屏，基准尺寸 390 × 844。
- 遵守顶部状态栏和底部 Home Indicator 安全区域。
- 不生成桌面、平板、网站 Hero 或营销落地页。
- 不生成底部 Tab，不展示地图、社区、饮食、聊天或复杂数据。
- 所有界面文字默认中文。

视觉方向：
- 简洁、有个性、有训练动力的浅色 3D 运动展示界面。
- 背景为冷白或极浅灰的纯净训练棚，人物像汽车游戏的车辆展示页一样成为绝对主体。
- UI 参考当前 Stopwatch Figma 的黑色文字、电光青柠强调和浅色玻璃面板，不使用旧版深黑休息舱、琥珀科幻 HUD 或海报式大标题。
- 3D 人物区域必须宽阔、无卡片边框、无装饰性容器；模型从头到脚完整可见，并带自然接触阴影。
- 数据和控制贴近屏幕边缘，不能遮挡教练的膝盖、髋、肩、肘和手脚。
- 单屏只保留当前动作最重要的信息，不做仪表盘。

颜色变量：
- Canvas / #EEF1ED
- Surface / rgba(250, 251, 248, 0.82)
- SurfaceStrong / #F8FAF6
- Ink / #0D1112
- Secondary / #667071
- Hairline / rgba(13, 17, 18, 0.12)
- Lime / #BAFF00
- LimePressed / #A6E600
- Warning / #F2A63C，仅用于长按结束和错误
- Success / #55C98A

字体：
- 中文和正文使用 Noto Sans SC 或系统无衬线字体。
- 动作标题使用 28–32px、700 字重，不做超大海报字。
- 计时和次数使用 JetBrains Mono 或等宽数字，tabular nums。
- 小标签 10px、600 字重、uppercase 英文或简短中文，字距适中，不使用夸张宽字距。

通用布局：
- 页面左右安全边距 16px，主要文字左边距 20px。
- 顶部 HUD 从安全区下方 16px 开始。
- 底部操作面板距离 Home Indicator 16px，高度按状态为 116–184px。
- 主按钮高度 56px，圆角 28px，最小触控区域 48 × 48px。
- 浅色玻璃面板允许 20–24px 圆角，但不得在面板内继续嵌套卡片。
- 3D 教练舞台占屏幕高度约 58%–66%。
- 倒计时、次数跳变不能引发布局位移。

创建以下组件和 Variant：
1. CoachViewport：Standing、Floor、Recovery、NextPreview、Frozen、Error。
2. TrainingTopHud：Ready、Active、Paused、Rest、LastFive、Completed。
3. SetProgressRail：1/4、2/4、3/4、4/4。
4. PrimaryAction：Default、Pressed、Disabled、Loading。
5. IconControl：Pause、Resume、Camera、Sound。
6. HoldToEnd：Idle、Holding25、Holding50、Holding75、Complete。
7. RestControls：Default、Extended、LastFive。
8. EncouragementCard：Idle、Liked。
9. StatusMessage：MotionReady、MotionMissing、Loading、Error。

创建并连接以下页面：

00 Unity Loading
- 冷白训练棚背景。
- 中央只显示很轻的教练轮廓和短状态“正在准备教练”。
- 底部显示细进度条。
- 1 秒后自动进入 Ready；加载失败进入 Motion Error。

01 Ready / 徒手深蹲
- 顶部小标签“训练准备”，主标题“徒手深蹲”。
- 次级信息“动作 1/2 · 4 组 × 12 次”。
- 中央展示完整站立男性 3D 教练，脚下有接触阴影和轻舞台环。
- 底部浅色玻璃面板：标题“动作示范”，说明“正面视角 · 保持核心收紧”。
- 左侧为切换视角图标按钮，右侧为青柠主按钮“开始训练”。
- 不显示返回箭头和教练性别切换。

02 Active / 深蹲第 1 组
- 顶部显示“徒手深蹲”、右侧计时 00:08。
- 左边缘显示 4 段纵向组数进度，当前第 1 组高亮。
- 中央 3D 教练循环演示深蹲。
- 姿态提示位于右上或人物旁边：“保持膝盖朝向脚尖”，不能遮挡身体。
- 底部面板显示“第 1/4 组”和“0 / 12 次”。
- 底部主要操作“完成本组”；旁边为暂停图标。
- “长按结束训练”是低强调控制，带 1.2 秒填充反馈。

03 Paused
- 保留并冻结 Active 的人物、计时和进度，不切换背景。
- 画面加入极轻半透明遮罩，标题“训练已暂停”。
- 主按钮“继续训练”。
- 次级控制“长按结束训练”。
- 不使用大弹窗，不显示数据图表。

04 Rest / 深蹲组间
- 只突出 3D 教练和头顶空间倒计时。
- 教练演示站立呼吸或肩颈放松。
- 头顶文字“休息 30”，数字使用等宽字体。
- 底部只保留两个低干扰操作：“跳过休息”和“+30 秒”。
- 不显示动作卡片、详细数据或下一组大面板。
- 倒计时到 0 自动回到 Active 的下一组。

05 Encouragement / 深蹲全部完成
- 背景保留并轻度压暗 Unity 教练舞台。
- 中央放置最大宽度 312px 的单张鼓励卡，四周必须留出明显可点击空白。
- 本地示例内容：“这一整个动作完成得很稳。继续保持自己的节奏。”
- 双击卡片任意位置切换点赞状态。
- 点击卡片外跳过并进入下一动作前休息。
- P0 不打开头像资料、不关注、不联网；不要显示不可用按钮。
- 连续跳过逻辑不需要在本原型中展示。

06 Rest / 下一动作准备
- 头顶仍显示“休息 12”。
- 教练进行轻恢复动作。
- 底部保留“跳过休息”和“+30 秒”。
- 进入最后 5 秒后自动切换到 Last Five。

07 Rest Last Five / 俯卧撑预告
- 先把头顶文字切换为“下一组：俯卧撑 · 5”。
- 80–120ms 后教练切换为俯卧撑起始姿势或短预演。
- 镜头平滑降低并拉远，确保地面动作头、手和脚完整可见。
- 只保留“+30 秒”，点击后回到普通休息；隐藏跳过按钮。
- 倒计时结束自动进入俯卧撑 Active。

08 Active / 俯卧撑第 1 组
- 复用 Active 组件，但使用 Floor 镜头构图。
- 标题“标准俯卧撑”，信息“动作 2/2 · 第 1/4 组”。
- 人物完整显示，手掌、肩、髋、膝和脚均不能出画。
- 姿态提示“头、背、髋保持一条直线”。
- 底部显示次数、完成本组、暂停和长按结束。

09 Hold To End
- 从任意 Active 或 Paused 状态进入。
- 长按时按钮内部从左到右填充 Warning 色，文案依次为“继续按住 1.2 秒”“松开取消”“正在保存”。
- 中途松开回到原状态。
- 填满后直接进入 Early Completed，不再弹二次确认框。

10 Completed
- 教练回到稳定站姿，播放短而克制的完成动作。
- 顶部显示“训练完成”。
- 底部单层浅色面板只展示：总时长 08:42、完成动作 2、完成组数 8。
- 一句反馈“深蹲与俯卧撑训练已完成”。
- 主按钮“返回应用”。
- 不显示趋势图、分享、社区、饮食或排行榜。

11 Early Completed
- 标题“本次训练已结束”。
- 显示实际完成的时间、动作和组数。
- 文案“已完成的内容会保留”。
- 主按钮“返回应用”。
- 不使用失败或羞辱语气。

12 Motion Error
- 保留训练舞台结构，不出现空白黑屏。
- 文案“动作演示暂时无法加载”。
- 两个操作：“重新加载”和“跳过这个动作”。
- 错误详情折叠，不在默认页面显示技术堆栈。

13 Android Minimal Summary
- 这是退出 Unity 后的原生总结参考页。
- 只显示主数字“08:42”、完成 2 个动作、8 组，以及“记录已保存”。
- 主按钮“完成”返回 App 首页。
- 外观延续 Unity 页面，但不显示 3D 舞台。

原型连接：
- Loading 自动到 Ready。
- Ready 点击开始到 Active Squat。
- Active 点击暂停到 Paused；Paused 点击继续返回原 Active。
- Active 点击完成本组到 Rest；Rest 倒计时后进入下一组。
- 深蹲第 4 组完成到 Encouragement；双击卡片留在 Liked，点击外部到 Rest Next Exercise。
- Rest Next Exercise 自动到 Last Five，再自动到 Active Push-up。
- 俯卧撑第 4 组完成到 Completed。
- 任意 Active/Paused 长按结束到 Early Completed。
- Completed 或 Early Completed 点击返回应用到 Android Minimal Summary。
- Loading 或动作加载异常到 Motion Error。

动效：
- 页面状态切换 220–320ms，使用 ease-out，不做夸张弹跳。
- 人物镜头切换 350–500ms。
- Rest Last Five 先换文字，再延迟 80–120ms 换动作。
- 长按结束持续 1.2 秒，填充过程连续可见。
- 点击、暂停、完成本组和长按完成使用不同强度的触觉反馈。
- 支持 Reduce Motion：镜头切换降级为 180ms 淡入淡出。

输出要求：
- 使用 Auto Layout、Variables 和 Component Properties。
- 每个状态建立独立 Frame，并用清晰英文层级名。
- 组件层级不能使用 Group 代替 Auto Layout。
- 3D 区域命名为 UnityViewport，保持可替换和透明边界。
- 不把 3D 区域做成圆角卡片。
- 所有文字都必须装入容器，不允许截断或超出按钮。
- 创建可点击 Prototype，能够完整走完深蹲到俯卧撑再到总结。
```

---

## 2. 设计目标与范围

### 2.1 本轮必须证明

用户不离开训练上下文，就能理解当前动作、当前组、下一步操作和剩余休息时间，并能在临时有事时暂停或安全结束。

### 2.2 P0 包含

- 男性 3D 教练。
- 徒手深蹲与标准俯卧撑。
- Ready、Active、Paused、Rest、Last Five、Completed。
- 完成本组、暂停、继续、跳过休息、增加 30 秒、长按结束。
- 本地鼓励占位状态。
- 动作缺失和 Unity 加载异常。
- 最小结果回传和原生总结。

### 2.3 P0 不包含

- 3D 肌肉选择。
- AI 动态生成计划。
- 女性教练。
- 实时摄像头和姿态识别。
- 真实用户头像、资料、关注和聊天。
- 社区、地图、饮食和数据趋势。
- 动作包下载和存储管理。
- 分享、排行榜和复杂段位升级。

---

## 3. 页面与状态编号

| ID | Frame 名称 | 触发 | 退出 |
|---|---|---|---|
| U00 | `Unity / Loading` | Android 启动 Unity | 自动到 U01 |
| U01 | `Unity / Ready / Squat` | Unity 就绪 | 开始到 U02 |
| U02 | `Unity / Active / Squat` | 开始动作 | 暂停、休息、结束 |
| U03 | `Unity / Paused` | 点击暂停 | 继续或结束 |
| U04 | `Unity / Rest / Set` | 完成本组 | 自动回训练 |
| U05 | `Unity / Encouragement / Local` | 深蹲全部组完成 | 跳过到 U06 |
| U06 | `Unity / Rest / Next Exercise` | 鼓励结束 | 自动到 U07 |
| U07 | `Unity / Rest / Last Five` | 剩余 5 秒 | 自动到 U08 |
| U08 | `Unity / Active / Push Up` | 休息结束 | 休息、完成、结束 |
| U09 | `Unity / Hold To End` | 长按结束 | 取消或 U11 |
| U10 | `Unity / Completed` | 全计划完成 | 返回原生 A01 |
| U11 | `Unity / Early Completed` | 中途结束 | 返回原生 A01 |
| U12 | `Unity / Motion Error` | 加载失败 | 重试或跳过 |
| A01 | `Android / Minimal Summary` | Unity 返回结果 | 完成到首页 |

---

## 4. 全局视觉系统

### 4.1 设计气质

关键词：纯净、轻科技、运动陈列、空间感、克制、有冲劲。

不要出现：

- 纯黑大面积背景。
- 旧版琥珀色休息舱 HUD。
- 大量网格线、扫描线、机械编号和科幻装饰文字。
- 大字海报排版。
- 数据仪表盘和多层卡片。
- 霓虹渐变球、光斑和无意义装饰。

### 4.2 Variables

#### Color

| Variable | Value | 用途 |
|---|---|---|
| `color/canvas` | `#EEF1ED` | 页面与 3D 棚背景 |
| `color/surface` | `rgba(250,251,248,.82)` | 底部玻璃面板 |
| `color/surface-strong` | `#F8FAF6` | 强实体控件 |
| `color/ink` | `#0D1112` | 主文字与图标 |
| `color/secondary` | `#667071` | 次要文字 |
| `color/hairline` | `rgba(13,17,18,.12)` | 分隔线 |
| `color/lime` | `#BAFF00` | 主交互与当前进度 |
| `color/lime-pressed` | `#A6E600` | 按压态 |
| `color/warning` | `#F2A63C` | 长按结束与错误 |
| `color/success` | `#55C98A` | 已完成状态 |
| `color/scrim` | `rgba(13,17,18,.20)` | 暂停与鼓励背景 |

#### Spacing

`4, 8, 12, 16, 20, 24, 32, 40`。

#### Radius

- 小控件：12。
- 图标按钮：24。
- 主按钮：28。
- 底部面板：24。
- 鼓励卡：20。

#### Type

| Style | Size / Line | Weight |
|---|---|---|
| `type/label` | 10 / 14 | 600 |
| `type/caption` | 12 / 18 | 500 |
| `type/body` | 15 / 22 | 400 |
| `type/action` | 16 / 22 | 700 |
| `type/title` | 30 / 36 | 700 |
| `type/metric` | 48 / 52 | 500 mono |
| `type/rest-countdown` | 64 / 68 | 400 mono |

---

## 5. 固定布局框架

### 5.1 Frame

- 尺寸：390 × 844。
- 顶部安全区参考：47px。
- 底部安全区参考：34px。
- 左右主要边距：16px。
- 画面禁止横向滚动。

### 5.2 Top HUD

- Y：安全区下 14–18px。
- 左侧：状态标签、动作标题、动作/组摘要。
- 右侧：计时或状态图标。
- 最大高度：86px。
- 不使用顶栏背景卡片。

### 5.3 UnityViewport

- X：0，W：390。
- 建议 Y：112，底部到 208–226。
- 必须完整显示角色和地面接触关系。
- 允许 UI 元素沿边缘悬浮，但不能遮挡动作关节。
- Standing 和 Floor 使用不同摄像机预设。

### 5.4 Bottom Controls

- X：16，W：358。
- Bottom：安全区上方 16px。
- 高度：Ready 170；Active 180；Rest 控制 56；Completed 194。
- 一层面板，不在里面嵌套第二张卡片。

---

## 6. 核心组件规格

### 6.1 `CoachViewport`

属性：

- `pose`: standing / floor / recovery / nextPreview / frozen。
- `camera`: front / side / floorWide。
- `status`: loading / ready / missing / error。

Figma 中使用静态 Unity 截图或占位渲染，但保留统一替换区域。不要绘制假的肌肉线或姿态骨架。

### 6.2 `SetProgressRail`

- 位于左边缘 X 12–24。
- 四段，每段至少 36px 高，间距 6px。
- 完成：Ink 20% 或 Success。
- 当前：Lime，宽度略增加。
- 未完成：Hairline。
- 底部显示 `1/4`，12px 等宽数字。

### 6.3 `PrimaryAction`

- 高度 56px。
- Lime 背景、Ink 文字。
- 按压缩放 0.98，120ms。
- Disabled 使用 Hairline 背景和 Secondary 文字。
- 文案不超过 8 个汉字。

### 6.4 `IconControl`

- 48–56px 正方形。
- 使用熟悉图标，不用文字胶囊代替暂停、继续和视角。
- 每个图标有 Tooltip 名称，但移动端不显示常驻说明。

### 6.5 `HoldToEnd`

- 高度 48–52px。
- 默认低对比，不与完成本组竞争。
- Pointer Down 开始 1.2 秒填充。
- Pointer Up / Exit 立即取消并回弹。
- 填满后触觉确认并锁定，防止重复触发。

### 6.6 `SpatialCountdown`

- 锚定角色头部上方，不是顶部卡片。
- 普通休息：`休息 30`。
- 最后五秒：`下一组：俯卧撑 · 5`。
- 背景仅允许轻微可读性底，不做大胶囊。
- 角色下蹲或地面动作时自动调整锚点，不能出屏。

### 6.7 `RestControls`

- 屏幕底部两个操作。
- `跳过休息`：次级文字按钮或低对比胶囊。
- `+30 秒`：描边按钮。
- Last Five 隐藏跳过，只保留 `+30 秒`。

### 6.8 `EncouragementCard`

- 最大宽度 312px。
- 高度随内容，建议 176–212px。
- 单卡，不嵌套。
- 双击整卡点赞，Liked 状态给出短触觉和小型图标反馈。
- 卡片外区域承担跳过，至少保留 56px 可点击空间。
- P0 不显示关注按钮和头像详情入口。

---

## 7. 逐状态详细说明

### U00 Loading

信息优先级：加载是否正常 > 品牌氛围。

- 文案：`正在准备教练`。
- 超过 5 秒补充：`动作资源加载中`。
- 超过 10 秒进入 U12，不无限等待。

### U01 Ready

用户问题：我要练什么，怎么开始？

- 标题：`徒手深蹲`。
- 摘要：`动作 1/2 · 4 组 × 12 次`。
- 提示：`站到舒适位置，观察教练动作`。
- 主操作：`开始训练`。
- 次操作：切换视角。

### U02/U08 Active

用户问题：现在做什么，做到什么程度，怎么暂停？

- 标题和组数始终可见。
- 次数或倒计时为单一主数字。
- 姿态提示一次只显示一句。
- “完成本组”始终位于拇指可达区。
- 长按结束不可隐藏到菜单中。

### U03 Paused

用户问题：训练是否真的停了，怎么继续？

- 计时和动画都冻结。
- “继续训练”成为唯一高强调操作。
- 长按结束保留。
- 不重置动作或组进度。

### U04/U06 Rest

用户问题：还要休息多久，临时有事怎么办？

- 头顶倒计时是唯一主信息。
- 角色持续做恢复动作。
- 跳过和延长始终可触达。
- 不在休息时展示社区内容流。

### U07 Last Five

用户问题：下一组做什么，身体怎么准备？

- 先更新文字，再换动作。
- 镜头必须适应俯卧撑地面构图。
- 倒计时结束无需再次点击开始。

### U05 Encouragement

用户问题：如何快速回应或跳过？

- 双击点赞。
- 点击外部跳过。
- 不显示传统点赞按钮。
- P0 使用本地固定内容，不请求网络。

### U09 Hold To End

用户问题：当前长按是否有效，松开会怎样？

- 按住时连续显示进度。
- 松开立即取消。
- 完成后保存已做内容。
- 不出现第二层确认弹窗。

### U10/U11 Completed

用户问题：刚才完成了什么，记录是否保存？

- 主结果：总时长。
- 摘要：动作数、组数。
- 明确显示：`记录已保存`。
- 正常完成与中途结束使用不同标题，但都不使用失败语气。

### U12 Motion Error

用户问题：还能不能继续训练？

- 优先给重新加载。
- 允许跳过当前动作。
- 不能自动用深蹲动画替代俯卧撑。

---

## 8. 原型交互与变量

Figma Make 内建议使用以下变量：

```text
sessionPhase = loading | ready | active | paused | rest | encouragement | completed | earlyCompleted | error
exerciseIndex = 0 | 1
exerciseId = bodyweight_squat | push_up
setIndex = 1..4
targetReps = 12
currentReps = 0..12
restSeconds = 30
liked = false | true
holdProgress = 0..100
```

关键逻辑：

```text
完成本组：
  setIndex < 4 -> rest -> active(setIndex + 1)
  setIndex == 4 && exerciseIndex == 0 -> encouragement -> rest next exercise
  setIndex == 4 && exerciseIndex == 1 -> completed

休息：
  restSeconds > 5 -> Rest
  restSeconds <= 5 -> LastFive
  restSeconds == 0 -> Active

长按结束：
  holdProgress < 100 且松开 -> 返回原状态
  holdProgress == 100 -> EarlyCompleted
```

---

## 9. 动效和触觉

| 行为 | 动效 | 触觉 |
|---|---|---|
| 开始训练 | 控件淡出，人物进入循环，260ms | 轻 |
| 完成本组 | 主按钮压下，进度段点亮，220ms | 中 |
| 暂停 | 画面冻结，遮罩淡入，180ms | 轻 |
| 恢复训练 | 遮罩淡出，计时继续，180ms | 轻 |
| 进入休息 | 镜头回正，头顶倒计时出现，360ms | 中 |
| 最后 5 秒 | 文字先换、人物后换 | 每秒轻，最后一秒中 |
| 双击点赞 | 图标缩放 1 → 1.18 → 1 | 双轻击 |
| 长按结束完成 | 填充结束并锁定 | 重 |
| 完成训练 | 人物完成姿势，结果面板上浮，360ms | 成功节奏 |

所有动效应支持 Reduce Motion。

---

## 10. Unity 落地约束

- Figma 的 `UnityViewport` 不输出为普通卡片组件，实际由 Unity Camera 填充。
- 屏幕 UI 使用 Unity uGUI 完成 P0，参考分辨率 390 × 844。
- 必须应用 `Screen.safeArea`。
- 空间倒计时使用 World Space Canvas 或 TextMeshPro 并跟随角色锚点。
- Standing 与 Floor 使用独立镜头预设。
- 所有数字启用等宽或固定宽度容器。
- 动作切换时先恢复根节点，再切换 Clip，避免人物上蹿下跳。
- 动作资源缺失必须进入错误状态，不允许错误替代。
- Android 只传入训练计划并接收结果，不在 P0 覆盖第二套 Compose 训练 UI。

---

## 11. Figma 图层与组件命名

```text
Page / Unity P0 Training Loop
  Section / Foundations
  Section / Components
  Section / Flow / Happy Path
  Section / Flow / Pause And Exit
  Section / Flow / Error

Frame / U00 Loading
Frame / U01 Ready Squat
Frame / U02 Active Squat
Frame / U03 Paused
Frame / U04 Rest Set
Frame / U05 Encouragement Local
Frame / U06 Rest Next Exercise
Frame / U07 Rest Last Five
Frame / U08 Active Push Up
Frame / U09 Hold To End
Frame / U10 Completed
Frame / U11 Early Completed
Frame / U12 Motion Error
Frame / A01 Android Minimal Summary

Component / CoachViewport
Component / TrainingTopHud
Component / SetProgressRail
Component / PrimaryAction
Component / IconControl
Component / HoldToEnd
Component / SpatialCountdown
Component / RestControls
Component / EncouragementCard
Component / StatusMessage
```

---

## 12. Figma Make 产出验收

### 12.1 视觉

- 所有 Frame 为 390 × 844 手机竖屏。
- 人物在 Ready、Active、Rest 和 Floor 动作中均完整可见。
- UI 不遮挡动作关键关节。
- 没有底部 Tab、数据 dashboard 或旧版深色舱体风格。
- 中文没有截断、溢出或错误换行。

### 12.2 交互

- 可以从 Loading 完整点击到 Completed 和 Android Summary。
- 暂停后可以继续。
- 休息可以跳过和增加 30 秒。
- 最后 5 秒自动切换下一动作。
- 长按结束可以取消，也可以完成中途结束。
- 鼓励卡支持双击和点外跳过。
- 错误状态可以重试或跳过。

### 12.3 工程交付

- 使用 Variables、Auto Layout 和 Component Variants。
- Frame 与组件按第 11 章命名。
- 3D 区域可独立隐藏或替换。
- 所有交互热区不小于 48 × 48px。
- 原型不存在死路，Completed 和 Early Completed 都能回到原生总结。

# Rest Pod HUD 未实现功能规划（优先改造 GitHub 现成项目）

主线：`apk-store/flutter/`（Flutter 3.47，`com.restpod.hud`）。Unity 舱页由用户本机工程出，Flutter 只负责跳转/嵌入。饮食识别不接未提供的付费云 API。以下仓库均用 `gh search repos` 核过（2026-08-19）。

## 总路线

1. **首页真计时 + Figma HUD** — 不依赖新仓库，把 `archive/android-compose` 里已跑通的计时迁过来，产品立刻不像壳。
2. **社交圈补真评论** — 在现有 `SocialFeedController` 上加评论列表，改动面最小。
3. **饮食打卡（相机 + Open Food Facts 条码，本地目录兜底）** — 旧 Compose 有流程可抄，识别先别吹成视觉大模型。
4. **计划日历 / 训练 tab** — 套 `table_calendar`。
5. **设置** — 纯 Flutter 页，逻辑简单。
6. **登录 OTP** — 等有短信通道再接 FlutterFire；没通道就先本地账号占位。
7. **消息** — UI 用开源 chat UI，存储先本地；不要默认绑 Stream 付费云。
8. **附近的人** — `flutter_map` + OSM，避免 Google Maps Key。
9. **语音条** — `speech_to_text` 做输入，不做「智能教练」。
10. **Unity 嵌入** — 等你本机舱页可导出后再接 `flutter_unity_widget`。
11. **iOS 出包** — 只能在你 Mac + Xcode 上编。

---

## 1. Unity 训练舱接入

**目标：** 点「开始训练」打开你做的 Unity 舱，而不是 Flutter 占位页。Flutter 不重做 Ready/Active/Rest 四屏。

**优先改造：**

| 仓库 | stars | 许可 | 用途 |
|---|---|---|---|
| [juicycleff/flutter-unity-view-widget](https://github.com/juicycleff/flutter-unity-view-widget) | ~2300 | BSD-3 | 把 Unity 视图嵌进 Flutter（Android/iOS） |
| [juicycleff/flutter-unity-arkit-demo](https://github.com/juicycleff/flutter-unity-arkit-demo) | ~230 | — | 官方配套 demo，看导出/通信怎么接 |
| [AgrMayank/Flutter-With-Unity](https://github.com/AgrMayank/Flutter-With-Unity) | 8 | — | 最小示例，对照用 |

**改造步骤：**
1. 你本机 Unity 工程按 widget 文档导出为 `android`/`ios` 库（不是完整 APK）。
2. Flutter 把现在的 `UnityCoachPlaceholderScreen` 换成 `UnityWidget`。
3. 用 widget 的 `UnityWidgetController.postMessage` 把「开始 / 休息 / 跳过」从 Flutter 传进 Unity；计时仍可由 Flutter 管或 Unity 回传。
4. 先 Android 通，再 iOS（iOS 必须在 Mac 上编 Unity 库）。

**接法：** 只改 `placeholder_screens.dart` 和 `pubspec.yaml`，不要动社交。

**风险：** Unity 导出体积大；插件对 Unity 版本敏感；这台 Linux 中转机编不了 iOS Unity 库。

---

## 2. 首页真计时 + Figma HUD

**目标：** `00:00.00` 真走表；双环 + 哑铃「开始训练」贴近 `docs/figma-ref/home-with-fab.png`。

**优先改造：** 不新开仓库。参考本仓库 `archive/android-compose/` 里 `WorkoutSessionViewModel`（已有组间休息、+30s、长按结束）。计时器用 Dart `Stopwatch`。

圆环不要找随机 HUD 模板硬套（会对不上稿）。用 `CustomPainter` 画双环 + 周点，色值已有 `#BAFF00`。

**步骤：**
1. 抽 `WorkoutSessionController`（ChangeNotifier），把 Compose 的 session 状态机搬过来。
2. `HomeScreen` 订阅 elapsed；进舱仍走 Unity 占位直到第 1 项完成。
3. 按 Figma 重排：点阵底、READY 胶囊、哑铃大圆、语音条、相机/我的 FAB。底栏可与稿的 5 tab 并存（现在已经是 5 tab）。

**风险：** 首页视觉工作量大，但零新依赖。不要为了「像」去 fork 一个无关健身 App。

---

## 3. 饮食打卡（相机 / 识别 / 历史 / 食谱）

**目标：** 拍照或扫码记一餐；历史；简单食谱。识别先条码 + 本地目录，不承诺云视觉。

**优先改造：**

| 仓库 | stars | 许可 | 用途 |
|---|---|---|---|
| [openfoodfacts/openfoodfacts-dart](https://github.com/openfoodfacts/openfoodfacts-dart) | ~230 | Apache-2 | 条码查热量/成分，免自己的营养库 |
| 官方 `camera`（flutter/packages） | — | BSD | 拍照预览 |
| 旧逻辑 | — | — | `archive/android-compose` 的 `DietLogViewModel`：餐次、历史、食谱 tab |

条码扫可用 pub.dev `mobile_scanner`（基于 ML Kit）。食物照片分类若要上，再用 Google ML Kit 本地模型，准确率有限，UI 上必须标「估算」。

**步骤：**
1. 相机页替换 `CameraPlaceholderScreen`。
2. 有条码 → Open Food Facts；没有 → 沿用旧工程的时段目录（假识别升级成「手选食物」）。
3. 历史/食谱做成「我的」里两张卡片的真实路由（现在点了没反应）。
4. 本地 `shared_preferences` / `hive` 存餐次，不上云。

**风险：** OFF 对中文包装覆盖一般；不要把目录匹配说成「AI 识别」。

---

## 4. 训练 tab、计划 / 日历 tab

**目标：** 现在「训练计划开发中 / 训练日历开发中」换成能点的列表和日历。

**优先改造：**

| 仓库 | stars | 许可 | 用途 |
|---|---|---|---|
| [aleksanderwozniak/table_calendar](https://github.com/aleksanderwozniak/table_calendar) | ~2000 | Apache-2 | 计划 tab 日历 |

训练 tab 不要整 App fork。用本地「动作库 + 今日计划」列表，数据结构抄 Compose 的组/动作文案即可。

**步骤：** `TabPlaceholderScreen` 拆成 `TrainingScreen` / `PlanScreen`；日历标记有训练的日期；点日期看当天动作。先写死 1 套示例计划。

---

## 5. 消息 / 聊天

**目标：** 会话列表 + 单聊。先本地，以后再接真实后端。

**优先改造：**

| 仓库 | stars | 许可 | 用途 |
|---|---|---|---|
| [ArunBalajiR/Flutter-Chat-Application](https://github.com/ArunBalajiR/Flutter-Chat-Application) | ~50 | MIT | 看列表+气泡怎么铺，可抄 UI 不要绑他的 Firebase 结构 |
| [GetStream/stream-chat-flutter](https://github.com/GetStream/stream-chat-flutter) | ~1050 | Other（商业 SDK） | **不作为默认。** 要付费云，产品早期不合适 |
| [amsokol/flutter-grpc-tutorial](https://github.com/amsokol/flutter-grpc-tutorial) | ~200 | Apache-2 | 以后自建实时通道再看 |

**步骤：** 先做本地 `ChatController`（仿社交圈）；UI 参考 MIT 那个示例的气泡。等真有账号体系再换后端。

---

## 6. 登录 / OTP

**目标：** 手机号 + 验证码。现在 Flutter 壳直接进首页。

**优先改造：** FlutterFire（`firebase/flutterfire`）的 Phone Auth 是业界默认，Android/iOS 都有。没有 Firebase 项目和短信配额就不要接。

没有短信通道时：本地「验证码 123456」仅 debug，正式包关掉。

旧 Compose 的 OTP 页在 `archive/android-compose` 可当视觉参考，逻辑不要用假页面流。

---

## 7. 附近的人 / 运动地图

**目标：** 地图上几个点 + 「附近 N 人在练」。旧 Compose `WorkoutMapScreen` 是假色块。

**优先改造：** `fleaflet/flutter_map` + OpenStreetMap 瓦片（**不要默认 Google Maps**，要 Key）。定位用官方 `geolocator`。人物点先本地 mock，真附近需要账号+上传位置，涉及隐私，放到登录之后。

---

## 8. 设置

**目标：** 账号、提醒、谁可以看动态、单位/语言、退出。旧 Compose `SettingsScreen` 已有文案分组，直接迁。

不必 fork 设置框架。一页 `ListView` + `Switch` 即可。状态进 `shared_preferences`。

---

## 9. 语音助手条

**目标：** 「有什么可以帮你的？」能说话变成文字，映射到有限命令：开始训练 / 打开社交 / 打开饮食。

**优先改造：** pub.dev `speech_to_text`（常见封装仓库 csdcorp/speech_to_text）。不要接大模型对话。命令表写死。

---

## 10. 真评论列表

**目标：** 评论不只 `comments += 1`。点气泡进该帖评论，能发表、能看到列表。

**不新开仓库。** 扩 `SocialPost`：`List<Comment>`。弹层改成列表+输入框。仍本地内存。

---

## 11. iOS 出包

这台 Linux 没有 Xcode。`flutter/ios` 已在仓库里。

在你 Mac 上：装 Flutter 同版本 3.47 → `cd flutter && flutter build ios` 或打开 `flutter/ios/Runner.xcworkspace`。签名用你的 Apple 账号。Unity 库必须也在 Mac 用同一 Unity 版本导出。

---

## 明确不 fork 的东西

- 不要整仓换成本人无关的「Instagram clone / 健身市场 App」。社交圈已经按 Figma 铺了，只补数据层。
- 不要用 Stream Chat 当默认后端。
- 不要用未申请的 Google Maps / 云视觉 Key。

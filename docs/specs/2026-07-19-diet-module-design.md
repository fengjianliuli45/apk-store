# Stopwatch 饮食模块设计方案

> 2026-07-19 · 基于「吃一点」App 设计参考
> 状态：待 Cursor 实现

---

## 1. 设计目标

训练完成后，用户点击「🥗 解锁饮食」进入饮食模块。核心功能：

1. **主屏（DietDashboard）**：今日饮食概览 — 热量目标 vs 摄入进度、三餐入口
2. **拍照识别**：打开 CameraX 拍照，AI 识别食物 → 自动记录到对应餐别
3. **记录管理**：查看/修改已记录的食物
4. **设计风格**：跟随冷白金属主题 + 橙色健康感点缀（参考「吃一点」App）

---

## 2. 屏幕流

```
DoneScreen → [🥗 解锁饮食] → DietDashboard
                                   ├── 早餐 (拍照/手动)
                                   ├── 午餐 (拍照/手动)
                                   ├── 晚餐 (拍照/手动)
                                   ├── 加餐 (拍照/手动)
                                   └── ↻ 返回 MainScreen
```

---

## 3. 数据结构（新增）

### 3.1 FoodRecord（食物记录）

```kotlin
// 现有 Models.kt 追加

/**
 * 单条食物记录
 */
data class FoodRecord(
    val id: String = UUID.randomUUID().toString(),
    val mealType: MealType,          // 餐别
    val foodName: String,            // 食物名称
    val calories: Int,               // 热量(千卡)
    val protein: Int = 0,            // 蛋白质(g)
    val carbs: Int = 0,              // 碳水(g)
    val fat: Int = 0,                // 脂肪(g)
    val imagePath: String?,          // 拍照截图路径
    val timestamp: Long = System.currentTimeMillis(),
    val source: FoodSource,          // 识别来源
)

enum class MealType(val label: String, val emoji: String) {
    BREAKFAST("早餐", "🌅"),
    LUNCH("午餐", "🍱"),
    DINNER("晚餐", "🌆"),
    SNACK("加餐", "🍿"),
}

enum class FoodSource {
    AI_RECOGNITION,  // AI 拍照识别
    MANUAL_INPUT,    // 手动输入
}

/**
 * 每日饮食汇总
 */
data class DailyDiet(
    val date: LocalDate = LocalDate.now(),
    val records: List<FoodRecord> = emptyList(),
    val targetCalories: Int = 1500,   // 推荐热量
    val targetProtein: Int = 60,      // 推荐蛋白质
    val targetCarbs: Int = 200,       // 推荐碳水
    val targetFat: Int = 50,          // 推荐脂肪
) {
    val consumedCalories: Int get() = records.sumOf { it.calories }
    val consumedProtein: Int get() = records.sumOf { it.protein }
    val consumedCarbs: Int get() = records.sumOf { it.carbs }
    val consumedFat: Int get() = records.sumOf { it.fat }

    val remainingCalories: Int get() = targetCalories - consumedCalories

    fun recordsByMeal(meal: MealType): List<FoodRecord> =
        records.filter { it.mealType == meal }
}

/**
 * 饮食目标（可关联 UserProfile 动态计算）
 */
data class DietGoal(
    val targetCalories: Int,
    val targetProtein: Int,
    val targetCarbs: Int,
    val targetFat: Int,
) {
    companion object {
        fun defaultForProfile(profile: UserProfile): DietGoal {
            // 简化版：男性1800，女性1500
            val base = if (profile.gender == "男") 1800 else 1500
            val active = if (profile.goal.contains("增肌", ignoreCase = true)) 300
                else if (profile.goal.contains("减脂", ignoreCase = true)) -300
                else 0
            val calories = (base + active).coerceIn(1200, 3000)
            return DietGoal(
                targetCalories = calories,
                targetProtein = (calories * 0.25 / 4).toInt(),
                targetCarbs = (calories * 0.50 / 4).toInt(),
                targetFat = (calories * 0.25 / 9).toInt(),
            )
        }
    }
}
```

### 3.2 DietStore（本地持久化）

```kotlin
// data/DietStore.kt — 新增文件

/**
 * 饮食数据的本地持久化（SharedPreferences 或 Room）
 * v1 简化：用 SharedPreferences + Gson 序列化 DailyDiet
 */
class DietStore(context: Context) {
    private val prefs = context.getSharedPreferences("diet", Context.MODE_PRIVATE)
    private val gson = Gson()

    fun getToday(): DailyDiet {
        val key = LocalDate.now().toString()
        val json = prefs.getString(key, null) ?: return DailyDiet()
        return gson.fromJson(json, DailyDiet::class.java)
    }

    fun saveToday(diet: DailyDiet) {
        val key = LocalDate.now().toString()
        prefs.edit().putString(key, gson.toJson(diet)).apply()
    }

    fun addRecord(record: FoodRecord) {
        val today = getToday()
        val updated = today.copy(records = today.records + record)
        saveToday(updated)
    }
}
```

---

## 4. 页面设计

### 4.1 DietDashboard（主屏）

**布局**（参考「吃一点」首页）：

```
┌────────────────────────────────┐
│  ← 返回     饮食记录           │  标题栏
├────────────────────────────────┤
│  7月19日                       │  日期
│  周一  周二  周三  周四  周五  周六  周日  │  周日期选择器（横向滑动）
├────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐   │
│  │ 🔥 推荐   │  │ ✅ 已摄入  │   │  四格热量看板
│  │  1500kcal │  │   890kcal │   │
│  ├──────────┤  ├──────────┤   │
│  │ 🏃 消耗   │  │ 🍽️ 还可吃  │   │
│  │   320kcal │  │   610kcal │   │
│  └──────────┘  └──────────┘   │
├────────────────────────────────┤
│                                │
│  ┌──────┐  ┌──────┐           │
│  │ 🌅   │  │ 🍱   │           │  四餐入口（2×2 宫格）
│  │早餐  │  │午餐  │           │  每个显示：已记录条数/热量
│  └──────┘  └──────┘           │
│  ┌──────┐  ┌──────┐           │
│  │ 🌆   │  │ 🍿   │           │
│  │晚餐  │  │加餐  │           │
│  └──────┘  └──────┘           │
│                                │
├────────────────────────────────┤
│  📷 [拍照识别]                  │  拍照入口按钮
└────────────────────────────────┘
```

**色彩**：
- 日期选中：`EncourageOrange`（`#FF6B35`）
- 热量看板：白底卡片，数值用 `TextPrimary`
- 四餐按钮：`SurfaceWhite` 背景，emoji 居中，文字下方
- 拍照按钮：`AccentGreen` 全宽 PillButton

**交互**：
- 日期选择 = `LazyRow` + 横向滑动
- 四餐按钮 → 跳转到 `MealDetailScreen(mealType)`
- 拍照按钮 → `DietCameraScreen`
- 消耗热量= `TrainingPlan.estimatedKcal`（本次训练）+ 后台累计

### 4.2 MealDetailScreen（餐别详情）

```
┌────────────────────────────────┐
│  ← 早餐                         │  标题：餐别名
├────────────────────────────────┤
│  今日早餐  🔥 320/450kcal       │  该餐热量汇总
├────────────────────────────────┤
│  ┌───────────────────────┐     │
│  │  🥚 煮鸡蛋  60kcal     │     │  已记录食物列表
│  │  蛋白质 6g · 碳水 1g   │     │
│  └───────────────────────┘     │
│  ┌───────────────────────┐     │
│  │  🥛 牛奶  120kcal     │     │
│  │  蛋白质 8g · 碳水 9g   │     │
│  └───────────────────────┘     │
│                                │
│  [📷 拍照添加]  [✏️ 手动输入]   │  操作按钮
└────────────────────────────────┘
```

- 每条食物记录可滑动删除（`SwipeToDismiss`）
- 点击记录可编辑（修改名称/热量/营养素）
- 右上角可切换餐别

### 4.3 DietCameraScreen（拍照识别 — 现有改造）

**现有 `DietCameraScreen.kt` 已有布局**：
- 冷白金属背景 + CameraX 全屏预览
- 底部圆形快门按钮（`AccentGreen`）
- 拍照完成 → 显示"已拍摄"结果卡片

**需要新增的功能**：
1. 拍照完成后，弹出餐别选择：早餐/午餐/晚餐/加餐
2. AI 识别结果展示卡片（食物名 + 营养素 + 热量）
3. 确认/更正/重拍
4. ~~保存记录到 DietStore~~

### 4.4 AI 营养识别（模拟层 — v1 占位）

```kotlin
/**
 * AI 营养识别接口（v1 模拟版）
 * v1.1+ 接入豆包视觉理解 / 智谱 GLM-4V 真实 API
 */
object NutritionAI {
    fun recognize(imageFile: File): FoodRecord? {
        // v1 模拟：返回占位数据
        return FoodRecord(
            mealType = MealType.LUNCH,
            foodName = "未知食物",
            calories = 0,
            imagePath = imageFile.absolutePath,
            source = FoodSource.AI_RECOGNITION,
        )
    }

    // v1.1 真实实现
    // fun recognizeAsync(imageFile: File, callback: (FoodRecord?) -> Unit)
}
```

---

## 5. UI 组件新增

### 5.1 CalorieStatCard（热量统计卡片）

```kotlin
@Composable
fun CalorieStatCard(
    label: String,        // "推荐" / "已摄入" / "消耗" / "还可吃"
    value: Int,           // 热量值
    unit: String = "kcal",
    emoji: String,        // "🔥" / "✅" / "🏃" / "🍽️"
    color: Color,         // 主题色
    modifier: Modifier = Modifier,
)
```

- 2×2 网格布局
- 白底 RoundedCornerShape(16.dp)
- emoji + label + 数值

### 5.2 MealEntryButton（餐别入口）

```kotlin
@Composable
fun MealEntryButton(
    mealType: MealType,
    recordCount: Int,
    totalCalories: Int,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
)
```

- 2×2 宫格布局
- 大 emoji 图标
- 下方显示记录数 + 热量

### 5.3 FoodRecordCard（食物记录卡片）

```kotlin
@Composable
fun FoodRecordCard(
    record: FoodRecord,
    onDelete: () -> Unit,
    onEdit: () -> Unit,
    modifier: Modifier = Modifier,
)
```

- 左侧小缩略图（如有）
- 右侧：食物名 + 热量
- 副行：营养素（蛋白质/碳水/脂肪）
- 左右滑动删除（`SwipeToDismiss`）

---

## 6. MainActivity 集成

### 6.1 Screen 枚举追加

```kotlin
private enum class Screen {
    Login, Onboard, Generating, BeltPromo, Main, Plan,
    Training, Encourage, Rest, Done, Diet,
    DietDashboard,          // ← 新增
    MealDetail,             // ← 新增
}
```

### 6.2 Navigation 接入

```kotlin
// 在 StopwatchApp() 中新增状态
var selectedMeal by remember { mutableStateOf<MealType?>(null) }
val dietStore = remember { DietStore(context.applicationContext) }

// DoneScreen → DietDashboard
Screen.Done -> {
    // ...
    onUnlockDiet = { go(Screen.DietDashboard) },
}

// DietDashboard → 各子页面
Screen.DietDashboard -> {
    DietDashboardScreen(
        diet = dietStore.getToday(),
        onMealClick = { meal ->
            selectedMeal = meal
            go(Screen.MealDetail)
        },
        onCamera = { go(Screen.Diet) },  // 复用现有 DietCameraScreen
        onBack = { go(Screen.Main) },
    )
}

// MealDetail → 拍照/返回
Screen.MealDetail -> {
    val meal = selectedMeal ?: return@when
    MealDetailScreen(
        mealType = meal,
        records = dietStore.getToday().recordsByMeal(meal),
        onCamera = { go(Screen.Diet) },
        onDelete = { record ->
            // 删除并保存
            val today = dietStore.getToday()
            val updated = today.copy(records = today.records - record)
            dietStore.saveToday(updated)
        },
        onBack = { go(Screen.DietDashboard) },
    )
}
```

---

## 7. 新增文件清单

| 文件路径 | 说明 |
|----------|------|
| `data/FoodRecord.kt` | 食物数据模型（或追加到 Models.kt） |
| `data/DietStore.kt` | 饮食数据本地持久化 |
| `data/DietGoal.kt` | 饮食目标计算 |
| `ui/screen/DietDashboardScreen.kt` | 饮食主屏 |
| `ui/screen/MealDetailScreen.kt` | 餐别详情 |
| `ui/components/CalorieStatCard.kt` | 热量统计卡片 |
| `ui/components/MealEntryButton.kt` | 餐别入口按钮 |
| `ui/components/FoodRecordCard.kt` | 食物记录卡片 |
| `service/NutritionAI.kt` | AI 营养识别抽象层 |

---

## 8. 色彩方案（对齐现有 Theme）

| 用途 | 色值 | 现有 Token |
|------|------|-----------|
| 饮食主色 | `#FF6B35` | `EncourageOrange` |
| 热量目标环 | `#FF6B35` | `EncourageOrange` |
| 已摄入 | `#27AE60` | `AccentGreen` |
| 剩余热量 | `#8E8E93` | `TextSecondary` |
| 卡片背景 | `0xF2FFFFFF` | `SurfaceWhite` |
| 背景 | `#EDEFF2` | `MetallicLight` |
| 文字 | `#1A1A1A` | `TextPrimary` |
| 辅文 | `#8E8E93` | `TextSecondary` |

---

## 9. 实现优先级

| 优先级 | 内容 | 说明 |
|--------|------|------|
| **P0** | DietDashboardScreen | 主屏：日期选择 + 热量看板 + 四餐入口 |
| **P0** | Data model + DietStore | FoodRecord、DailyDiet、本地持久化 |
| **P1** | MealDetailScreen | 餐别详情 + 食物列表 |
| **P1** | UI 组件 | CalorieStatCard、MealEntryButton、FoodRecordCard |
| **P1** | Navigation 接入 | Screen 枚举 + 状态传递 |
| **P2** | DietCameraScreen 改造 | 拍照后弹出餐别选择 + 营养素卡片 |
| **P2** | NutritionAI 模拟 | 识别结果的 UI 展示 |
| **P3** | 手动录入 | 搜索/自定义食物 |
| **P3** | AI 真实接入 | GLM-4V / 豆包视觉理解 API |

---

## 10. 依赖新增

```kotlin
// build.gradle.kts (app)
dependencies {
    // CameraX（已有）
    // Gson 用于 DietStore 序列化
    implementation("com.google.code.gson:gson:2.10.1")
}
```

---

## 11. 参考截图

「吃一点」App 设计参考（GLM-4V Plus 识别结果）：

- **主页**：周日期选择器 + 四格热量看板（推荐/已摄入/消耗/还可吃）+ 四餐入口按钮（早/午/晚/加餐）
- **色彩**：橙色主调（`#FF6B35`）+ 白底卡片 + 绿色辅助
- **风格**：简洁现代，卡片式布局，图标+文字信息展示
- **交互**：拍照识物 → 弹出结果 + 营养素拆解

---

## 12. Cursor 实现提示

```
项目路径：~/stopwatch/android/
架构：Kotlin + Jetpack Compose + CameraX + SharedPreferences(Gson)
现有 Theme：冷白金属（Color.kt）+ 橙绿点缀

关键约束：
1. 不要改动现有 TrainingScreen/RestScreen 的 3D 教练逻辑
2. DietCameraScreen.kt 有 CameraX 基础，在此基础上做 UI 改造
3. 饮食数据当前只做本地持久化（SharedPreferences + Gson），不涉及 Firebase
4. 所有新增 Composable 使用现有的 Color.kt / Theme.kt / Typography.kt 设计 token
5. AI 营养识别先做模拟层（返回占位数据），接口预留
```

package com.restpod.hud.session

import android.graphics.Bitmap
import androidx.lifecycle.ViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import java.util.Calendar
import java.util.Locale
import java.util.concurrent.atomic.AtomicLong

enum class TimeOfDay(val label: String) {
    Breakfast("早餐"),
    Lunch("午餐"),
    Dinner("晚餐"),
    Snack("加餐"),
}

enum class MacroLevel(val label: String) {
    Low("偏低"),
    Ok("达标"),
    High("偏高"),
}

enum class RecipeGoal(val tab: String) {
    Recommend("推荐"),
    Cut("减脂"),
    Bulk("增肌"),
    Maintain("维持"),
}

data class MealTemplate(
    val name: String,
    val kcal: Int,
    val items: List<String>,
    val proteinG: Int,
    val carbG: Int,
    val fatG: Int,
    val slot: TimeOfDay,
    val tip: String,
    val advice: List<String>,
)

data class RecipeItem(
    val name: String,
    val kcal: Int,
    val goal: RecipeGoal,
    val items: List<String>,
    val proteinG: Int,
    val carbG: Int,
    val fatG: Int,
    val blurb: String,
)

data class LoggedMeal(
    val id: Long,
    val name: String,
    val kcal: Int,
    val items: List<String>,
    val proteinG: Int,
    val carbG: Int,
    val fatG: Int,
    val calorieLevel: MacroLevel,
    val protein: MacroLevel,
    val carb: MacroLevel,
    val fat: MacroLevel,
    val slot: TimeOfDay,
    val timestampMs: Long,
    val dayKey: String,
    val tip: String,
    val advice: List<String>,
    val photo: Bitmap? = null,
) {
    val statusLine: String
        get() = "热量${calorieLevel.label} · 蛋白质${protein.label} · 碳水${carb.label}"
}

data class PendingScan(
    val template: MealTemplate,
    val photo: Bitmap?,
    val confidence: Int,
)

data class DayChip(
    val key: String,
    val dayOfMonth: Int,
    val isToday: Boolean,
)

data class DietUiState(
    val meals: List<LoggedMeal> = emptyList(),
    val pending: PendingScan? = null,
    val lastSaved: LoggedMeal? = null,
) {
    fun mealsOn(dayKey: String): List<LoggedMeal> = meals.filter { it.dayKey == dayKey }

    fun kcalOn(dayKey: String): Int = mealsOn(dayKey).sumOf { it.kcal }

    fun proteinOn(dayKey: String): Int = mealsOn(dayKey).sumOf { it.proteinG }

    fun carbOn(dayKey: String): Int = mealsOn(dayKey).sumOf { it.carbG }

    fun fatOn(dayKey: String): Int = mealsOn(dayKey).sumOf { it.fatG }

    fun todayMeals(): List<LoggedMeal> = mealsOn(DietLogViewModel.currentDayKey())

    fun todayKcal(): Int = kcalOn(DietLogViewModel.currentDayKey())

    fun projectedKcal(): Int = todayKcal() + (pending?.template?.kcal ?: 0)

    fun progressOf(dayKey: String): Float =
        (kcalOn(dayKey).toFloat() / DietLogViewModel.GOAL_KCAL).coerceIn(0f, 1f)
}

class DietLogViewModel : ViewModel() {

    private val _uiState = MutableStateFlow(DietUiState())
    val uiState: StateFlow<DietUiState> = _uiState.asStateFlow()

    private val ids = AtomicLong(1L)
    private val pickCursor = mutableMapOf<TimeOfDay, Int>()

    fun beginAnalysis(photo: Bitmap?) {
        val slot = slotForHour()
        val pool = CATALOG.filter { it.slot == slot }.ifEmpty { CATALOG }
        val index = pickCursor[slot] ?: 0
        pickCursor[slot] = index + 1
        val template = pool[index % pool.size]
        val confidence = 86 + (index * 7 + template.kcal) % 13
        _uiState.update {
            it.copy(pending = PendingScan(template, photo, confidence.coerceIn(86, 98)))
        }
    }

    fun confirmPending(): LoggedMeal? {
        val pending = _uiState.value.pending ?: return null
        val meal = toLoggedMeal(
            name = pending.template.name,
            kcal = pending.template.kcal,
            items = pending.template.items,
            proteinG = pending.template.proteinG,
            carbG = pending.template.carbG,
            fatG = pending.template.fatG,
            slot = pending.template.slot,
            tip = pending.template.tip,
            advice = pending.template.advice,
            photo = pending.photo,
        )
        _uiState.update {
            it.copy(
                meals = it.meals + meal,
                pending = null,
                lastSaved = meal,
            )
        }
        return meal
    }

    fun logRecipe(recipe: RecipeItem): LoggedMeal {
        val meal = toLoggedMeal(
            name = recipe.name,
            kcal = recipe.kcal,
            items = recipe.items,
            proteinG = recipe.proteinG,
            carbG = recipe.carbG,
            fatG = recipe.fatG,
            slot = slotForHour(),
            tip = recipe.blurb,
            advice = listOf(recipe.blurb),
            photo = null,
        )
        _uiState.update {
            it.copy(
                meals = it.meals + meal,
                lastSaved = meal,
            )
        }
        return meal
    }

    fun clearPending() {
        _uiState.update { it.copy(pending = null) }
    }

    private fun toLoggedMeal(
        name: String,
        kcal: Int,
        items: List<String>,
        proteinG: Int,
        carbG: Int,
        fatG: Int,
        slot: TimeOfDay,
        tip: String,
        advice: List<String>,
        photo: Bitmap?,
    ): LoggedMeal {
        val day = currentDayKey()
        val state = _uiState.value
        val kcalTotal = state.kcalOn(day) + kcal
        val proteinTotal = state.proteinOn(day) + proteinG
        val carbTotal = state.carbOn(day) + carbG
        val fatTotal = state.fatOn(day) + fatG
        return LoggedMeal(
            id = ids.getAndIncrement(),
            name = name,
            kcal = kcal,
            items = items,
            proteinG = proteinG,
            carbG = carbG,
            fatG = fatG,
            calorieLevel = level(kcalTotal, GOAL_KCAL),
            protein = level(proteinTotal, PROTEIN_GOAL),
            carb = level(carbTotal, CARB_GOAL),
            fat = level(fatTotal, FAT_GOAL),
            slot = slot,
            timestampMs = System.currentTimeMillis(),
            dayKey = day,
            tip = tip,
            advice = advice,
            photo = photo,
        )
    }

    companion object {
        const val GOAL_KCAL = 2000
        const val PROTEIN_GOAL = 150
        const val CARB_GOAL = 220
        const val FAT_GOAL = 65

        val CATALOG = listOf(
            MealTemplate(
                name = "燕麦酸奶碗",
                kcal = 420,
                items = listOf("燕麦 80g", "希腊酸奶 150g", "蓝莓 40g"),
                proteinG = 24,
                carbG = 58,
                fatG = 10,
                slot = TimeOfDay.Breakfast,
                tip = "早餐蛋白质不错，上午不易饿。",
                advice = listOf("蛋白质开局充足，有利于上午训练", "可再加一小把坚果补充优质脂肪"),
            ),
            MealTemplate(
                name = "全麦蛋吐司",
                kcal = 380,
                items = listOf("全麦吐司 2 片", "水煮蛋 2 个", "牛油果 40g"),
                proteinG = 22,
                carbG = 36,
                fatG = 16,
                slot = TimeOfDay.Breakfast,
                tip = "脂肪来自牛油果，属于优质来源。",
                advice = listOf("全麦碳水释放较慢", "配一杯无糖豆浆更好吸收"),
            ),
            MealTemplate(
                name = "香蕉花生酱吐司",
                kcal = 450,
                items = listOf("全麦吐司 2 片", "香蕉 1 根", "花生酱 15g"),
                proteinG = 14,
                carbG = 68,
                fatG = 14,
                slot = TimeOfDay.Breakfast,
                tip = "训练日前的快碳早餐。",
                advice = listOf("碳水偏高，适合今天有训练", "蛋白质略少，午餐记得补鸡胸或豆腐"),
            ),
            MealTemplate(
                name = "鸡胸糙米碗",
                kcal = 520,
                items = listOf("鸡胸肉 150g", "糙米饭 180g", "西兰花 80g"),
                proteinG = 48,
                carbG = 62,
                fatG = 8,
                slot = TimeOfDay.Lunch,
                tip = "经典减脂午餐，蛋白质密度高。",
                advice = listOf("蛋白质摄入充足，有利于肌肉合成", "建议搭配一份柑橘类水果，补充维生素 C"),
            ),
            MealTemplate(
                name = "牛肉番茄意面",
                kcal = 610,
                items = listOf("瘦牛肉 120g", "全麦意面 100g", "番茄酱汁 80g"),
                proteinG = 38,
                carbG = 72,
                fatG = 16,
                slot = TimeOfDay.Lunch,
                tip = "午后碳水偏高，适合有训练的日子。",
                advice = listOf("碳水偏高，傍晚训练会用得上", "可把意面减到 70g 以控制总量"),
            ),
            MealTemplate(
                name = "三文鱼藜麦碗",
                kcal = 530,
                items = listOf("三文鱼 120g", "藜麦 100g", "菠菜 60g"),
                proteinG = 36,
                carbG = 42,
                fatG = 22,
                slot = TimeOfDay.Lunch,
                tip = "优质脂肪来自三文鱼，对恢复友好。",
                advice = listOf("Omega-3 有助于抗炎恢复", "盐分略高，晚上少喝汤会更稳"),
            ),
            MealTemplate(
                name = "日式定食",
                kcal = 480,
                items = listOf("烤鯖鱼 100g", "米饭 150g", "味增汤 + 渍物"),
                proteinG = 32,
                carbG = 55,
                fatG = 14,
                slot = TimeOfDay.Lunch,
                tip = "清淡但碳水足够撑过下午。",
                advice = listOf("鱼类蛋白好吸收", "渍物偏咸，记得多喝水"),
            ),
            MealTemplate(
                name = "清蒸鲈鱼配时蔬",
                kcal = 390,
                items = listOf("鲈鱼 180g", "西兰花 100g", "胡萝卜 60g"),
                proteinG = 42,
                carbG = 18,
                fatG = 12,
                slot = TimeOfDay.Dinner,
                tip = "低碳晚餐，晚上负担小。",
                advice = listOf("蛋白质足够，碳水偏低", "若明天有晨练，睡前可加一片全麦"),
            ),
            MealTemplate(
                name = "豆腐蔬菜汤面",
                kcal = 410,
                items = listOf("北豆腐 120g", "荞麦面 80g", "青菜 100g"),
                proteinG = 22,
                carbG = 54,
                fatG = 10,
                slot = TimeOfDay.Dinner,
                tip = "植物蛋白为主，好消化。",
                advice = listOf("晚餐热量适中", "可加一个鸡蛋把蛋白质补上"),
            ),
            MealTemplate(
                name = "虾仁沙拉",
                kcal = 320,
                items = listOf("虾仁 120g", "混合生菜 80g", "橄榄油醋汁 10g"),
                proteinG = 28,
                carbG = 12,
                fatG = 14,
                slot = TimeOfDay.Dinner,
                tip = "轻食晚餐，脂肪来自油醋汁。",
                advice = listOf("热量偏低，适合减脂日", "碳水很少，若还没训练建议加红薯"),
            ),
            MealTemplate(
                name = "鸡胸时蔬烩",
                kcal = 360,
                items = listOf("鸡胸 120g", "彩椒 80g", "蘑菇 60g"),
                proteinG = 40,
                carbG = 16,
                fatG = 8,
                slot = TimeOfDay.Dinner,
                tip = "高蛋白低碳水的收官餐。",
                advice = listOf("蛋白质达标对夜间恢复有帮助", "可配一小碗杂粮饭以免睡前过饿"),
            ),
            MealTemplate(
                name = "希腊酸奶杯",
                kcal = 180,
                items = listOf("希腊酸奶 150g", "蜂蜜 8g", "核桃 10g"),
                proteinG = 16,
                carbG = 18,
                fatG = 6,
                slot = TimeOfDay.Snack,
                tip = "加餐蛋白质友好。",
                advice = listOf("比饼干更抗饿", "蜂蜜可换成浆果进一步降糖"),
            ),
            MealTemplate(
                name = "苹果杏仁",
                kcal = 160,
                items = listOf("苹果 1 个", "杏仁 12g"),
                proteinG = 4,
                carbG = 22,
                fatG = 8,
                slot = TimeOfDay.Snack,
                tip = "纤维加一点优质脂肪。",
                advice = listOf("维生素 C 有助于铁吸收", "蛋白质很少，正餐记得补"),
            ),
            MealTemplate(
                name = "坚果能量棒",
                kcal = 220,
                items = listOf("燕麦棒 1 根", "混合坚果 15g"),
                proteinG = 8,
                carbG = 24,
                fatG = 12,
                slot = TimeOfDay.Snack,
                tip = "训练间隙的快能量。",
                advice = listOf("脂肪偏高，一天一根即可", "搭配无糖茶比配奶茶更合适"),
            ),
        )

        val RECIPES = listOf(
            RecipeItem("低脂鸡胸肉沙拉", 350, RecipeGoal.Cut, listOf("鸡胸 120g", "生菜", "小番茄"), 38, 14, 10, "高蛋白低脂，减脂日首选。"),
            RecipeItem("牛油果鸡胸", 290, RecipeGoal.Cut, listOf("鸡胸 100g", "牛油果 40g", "黄瓜"), 32, 10, 12, "优质脂肪控量，饱腹感强。"),
            RecipeItem("虾仁时蔬", 310, RecipeGoal.Cut, listOf("虾仁 120g", "西兰花", "彩椒"), 30, 16, 8, "低碳水海鲜餐。"),
            RecipeItem("三文鱼藜麦", 530, RecipeGoal.Recommend, listOf("三文鱼 120g", "藜麦 100g", "菠菜"), 36, 42, 22, "均衡推荐，恢复友好。"),
            RecipeItem("希腊酸奶碗", 280, RecipeGoal.Recommend, listOf("希腊酸奶", "燕麦", "浆果"), 20, 32, 8, "正餐或加餐都可以。"),
            RecipeItem("日式定食", 480, RecipeGoal.Maintain, listOf("烤鱼", "米饭", "味增汤"), 32, 55, 14, "维持体重的清淡套餐。"),
            RecipeItem("豆腐蔬菜汤", 320, RecipeGoal.Maintain, listOf("北豆腐", "青菜", "菌菇"), 18, 28, 10, "植物蛋白，好消化。"),
            RecipeItem("杂粮饭配蛋", 430, RecipeGoal.Maintain, listOf("杂粮饭 150g", "茶叶蛋 2 个", "青菜"), 22, 58, 12, "碳水稳定，适合休息日。"),
            RecipeItem("牛肉红薯碗", 620, RecipeGoal.Bulk, listOf("瘦牛肉 150g", "红薯 200g", "西兰花"), 42, 70, 14, "增肌日的碳蛋白组合。"),
            RecipeItem("鸡胸西兰花饭", 560, RecipeGoal.Bulk, listOf("鸡胸 180g", "米饭 200g", "西兰花"), 52, 64, 8, "蛋白质拉满。"),
            RecipeItem("乳清燕麦", 480, RecipeGoal.Bulk, listOf("燕麦 80g", "乳清 1 勺", "香蕉"), 32, 62, 8, "训练后窗口的快碳+蛋白。"),
        )

        fun slotForHour(hour: Int = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)): TimeOfDay = when (hour) {
            in 5..10 -> TimeOfDay.Breakfast
            in 11..15 -> TimeOfDay.Lunch
            in 16..20 -> TimeOfDay.Dinner
            else -> TimeOfDay.Snack
        }

        fun currentDayKey(now: Long = System.currentTimeMillis()): String {
            val c = Calendar.getInstance().apply { timeInMillis = now }
            return "%04d-%02d-%02d".format(
                Locale.US,
                c.get(Calendar.YEAR),
                c.get(Calendar.MONTH) + 1,
                c.get(Calendar.DAY_OF_MONTH),
            )
        }

        fun weekChips(): List<DayChip> {
            val todayKey = currentDayKey()
            return (6 downTo 0).map { offset ->
                val c = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, -offset) }
                val key = "%04d-%02d-%02d".format(
                    Locale.US,
                    c.get(Calendar.YEAR),
                    c.get(Calendar.MONTH) + 1,
                    c.get(Calendar.DAY_OF_MONTH),
                )
                DayChip(key, c.get(Calendar.DAY_OF_MONTH), key == todayKey)
            }
        }

        fun level(total: Int, goal: Int): MacroLevel {
            val ratio = total.toFloat() / goal.coerceAtLeast(1)
            return when {
                ratio < 0.55f -> MacroLevel.Low
                ratio > 1.08f -> MacroLevel.High
                else -> MacroLevel.Ok
            }
        }

        fun kcalText(value: Int): String = "%,d".format(Locale.US, value)
    }
}

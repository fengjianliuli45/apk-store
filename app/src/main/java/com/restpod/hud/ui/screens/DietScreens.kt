package com.restpod.hud.ui.screens

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Shader
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.restpod.hud.session.DietLogViewModel
import com.restpod.hud.session.DietUiState
import com.restpod.hud.session.LoggedMeal
import com.restpod.hud.session.MacroLevel
import com.restpod.hud.session.RecipeGoal
import com.restpod.hud.session.RecipeItem
import com.restpod.hud.ui.components.GradientScreen
import com.restpod.hud.ui.components.PillPrimaryButton
import com.restpod.hud.ui.components.PillSecondaryButton
import com.restpod.hud.ui.components.SectionCard
import com.restpod.hud.ui.components.pressable
import com.restpod.hud.ui.theme.BrandGreen
import com.restpod.hud.ui.theme.BrandTeal
import com.restpod.hud.ui.theme.InkDark
import com.restpod.hud.ui.theme.TextMuted
import com.restpod.hud.ui.theme.WarnAmber
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun CameraScreen(
    onCaptured: (Bitmap) -> Unit,
    onBack: () -> Unit,
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var scanning by remember { mutableStateOf(false) }
    var preview by remember { mutableStateOf<Bitmap?>(null) }

    fun finishWith(bitmap: Bitmap) {
        preview = bitmap
        scanning = true
        scope.launch {
            delay(600)
            onCaptured(bitmap)
        }
    }

    val takePicture = rememberLauncherForActivityResult(
        ActivityResultContracts.TakePicturePreview(),
    ) { bitmap ->
        if (scanning) return@rememberLauncherForActivityResult
        if (bitmap != null) {
            finishWith(bitmap)
        }
    }

    val requestPermission = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) { granted ->
        if (scanning) return@rememberLauncherForActivityResult
        if (granted) {
            takePicture.launch(null)
        } else {
            finishWith(placeholderMealBitmap())
        }
    }

    fun shutter() {
        if (scanning) return
        val granted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.CAMERA,
        ) == PackageManager.PERMISSION_GRANTED
        if (granted) {
            takePicture.launch(null)
        } else {
            requestPermission.launch(Manifest.permission.CAMERA)
        }
    }

    Box(Modifier.fillMaxSize().background(InkDark).statusBarsPadding().navigationBarsPadding()) {
        preview?.let { bmp ->
            Image(
                bitmap = bmp.asImageBitmap(),
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop,
            )
            Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.35f)))
        }

        Icon(
            Icons.Filled.ArrowBack,
            contentDescription = "返回",
            tint = Color.White,
            modifier = Modifier
                .padding(16.dp)
                .size(40.dp)
                .clip(CircleShape)
                .pressable(onClick = onBack)
                .padding(8.dp)
                .align(Alignment.TopStart),
        )

        Column(Modifier.fillMaxSize()) {
            Spacer(Modifier.weight(1f))
            Text(
                if (scanning) "正在识别餐点…" else "拍一张你的餐点吧",
                color = Color.White,
                fontWeight = FontWeight.SemiBold,
                fontSize = 16.sp,
                modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp),
                textAlign = TextAlign.Center,
            )
            Text(
                if (scanning) "扫描中" else "对准食物按拍照键",
                color = Color.White.copy(alpha = 0.6f),
                fontSize = 12.sp,
                modifier = Modifier.fillMaxWidth().padding(bottom = 24.dp),
                textAlign = TextAlign.Center,
            )
            Box(Modifier.fillMaxWidth().padding(bottom = 40.dp), contentAlignment = Alignment.Center) {
                if (scanning) {
                    CircularProgressIndicator(color = BrandGreen, modifier = Modifier.size(48.dp))
                } else {
                    Box(
                        modifier = Modifier
                            .size(72.dp)
                            .clip(CircleShape)
                            .background(Color.White)
                            .pressable(onClick = { shutter() }),
                        contentAlignment = Alignment.Center,
                    ) {
                        Box(
                            Modifier
                                .size(60.dp)
                                .clip(CircleShape)
                                .border(2.dp, InkDark.copy(alpha = 0.2f), CircleShape),
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun DietAnalysisScreen(
    state: DietUiState,
    onConfirm: () -> Unit,
    onBack: () -> Unit,
    onOpenHistory: () -> Unit,
    onOpenRecipes: () -> Unit,
) {
    val pending = state.pending
    val template = pending?.template ?: DietLogViewModel.CATALOG.first()
    val photo = pending?.photo
    val confidence = pending?.confidence ?: 90
    val projected = state.todayKcal() + template.kcal
    val progress = (projected.toFloat() / DietLogViewModel.GOAL_KCAL).coerceIn(0f, 1.15f).coerceAtMost(1f)
    val calorieLevel = DietLogViewModel.level(projected, DietLogViewModel.GOAL_KCAL)
    val proteinLevel = DietLogViewModel.level(state.todayMeals().sumOf { it.proteinG } + template.proteinG, DietLogViewModel.PROTEIN_GOAL)
    val carbLevel = DietLogViewModel.level(state.todayMeals().sumOf { it.carbG } + template.carbG, DietLogViewModel.CARB_GOAL)
    val fatLevel = DietLogViewModel.level(state.todayMeals().sumOf { it.fatG } + template.fatG, DietLogViewModel.FAT_GOAL)

    GradientScreen {
        Column(Modifier.fillMaxSize()) {
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Filled.ArrowBack,
                        contentDescription = "返回",
                        tint = InkDark,
                        modifier = Modifier
                            .size(36.dp)
                            .clip(CircleShape)
                            .pressable(onClick = onBack)
                            .padding(6.dp),
                    )
                    Spacer(Modifier.width(4.dp))
                    Text("饮食分析", fontWeight = FontWeight.Bold, fontSize = 22.sp, color = InkDark)
                }
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text(
                        "食谱",
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 14.sp,
                        color = InkDark,
                        modifier = Modifier.pressable(onClick = onOpenRecipes).padding(4.dp),
                    )
                    Icon(
                        Icons.Filled.CalendarToday,
                        contentDescription = "饮食记录",
                        tint = InkDark,
                        modifier = Modifier
                            .size(28.dp)
                            .pressable(onClick = onOpenHistory)
                            .padding(2.dp),
                    )
                }
            }
            LazyColumn(modifier = Modifier.weight(1f).padding(horizontal = 24.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                item {
                    Box(
                        Modifier.fillMaxWidth().height(160.dp).clip(RoundedCornerShape(20.dp)).background(InkDark.copy(alpha = 0.85f)),
                        contentAlignment = Alignment.TopStart,
                    ) {
                        if (photo != null) {
                            Image(
                                bitmap = photo.asImageBitmap(),
                                contentDescription = template.name,
                                modifier = Modifier.fillMaxSize(),
                                contentScale = ContentScale.Crop,
                            )
                        }
                        Box(
                            Modifier.padding(12.dp).clip(RoundedCornerShape(10.dp)).background(InkDark).padding(horizontal = 10.dp, vertical = 5.dp),
                        ) {
                            Text("AI SCANNING COMPLETE", color = BrandGreen, fontSize = 10.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                }
                item {
                    SectionCard(Modifier.fillMaxWidth()) {
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("AI 识别结果", fontWeight = FontWeight.Bold, color = InkDark)
                            Text("置信度 $confidence%", fontSize = 12.sp, color = TextMuted)
                        }
                        Spacer(Modifier.height(4.dp))
                        Text(template.name, fontWeight = FontWeight.SemiBold, color = InkDark, fontSize = 16.sp)
                        Text("${DietLogViewModel.kcalText(template.kcal)} kcal · ${template.slot.label}", fontSize = 12.sp, color = TextMuted)
                        Spacer(Modifier.height(12.dp))
                        template.items.forEach {
                            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(vertical = 3.dp)) {
                                Box(Modifier.size(6.dp).clip(CircleShape).background(BrandGreen))
                                Spacer(Modifier.width(8.dp))
                                Text(it, color = InkDark, fontSize = 14.sp)
                            }
                        }
                    }
                }
                item {
                    SectionCard(Modifier.fillMaxWidth()) {
                        Text("✦ AI 饮食建议", fontWeight = FontWeight.Bold, color = InkDark)
                        Spacer(Modifier.height(8.dp))
                        template.advice.forEach { line ->
                            Text("• $line", fontSize = 13.sp, color = InkDark)
                        }
                    }
                }
                item {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        MacroPill("热量", calorieLevel, Modifier.weight(1f))
                        MacroPill("蛋白质", proteinLevel, Modifier.weight(1f))
                        MacroPill("碳水", carbLevel, Modifier.weight(1f))
                        MacroPill("脂肪", fatLevel, Modifier.weight(1f))
                    }
                }
                item {
                    SectionCard(Modifier.fillMaxWidth()) {
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("今日摄入进度", fontWeight = FontWeight.SemiBold, color = InkDark)
                            Row {
                                Text(DietLogViewModel.kcalText(projected), fontWeight = FontWeight.Bold, color = InkDark)
                                Text(" / ${DietLogViewModel.kcalText(DietLogViewModel.GOAL_KCAL)} kcal", fontSize = 12.sp, color = TextMuted)
                            }
                        }
                        Spacer(Modifier.height(10.dp))
                        ProgressTrack(progress)
                    }
                }
                item { Spacer(Modifier.height(8.dp)) }
            }
            PillPrimaryButton(
                "确认记录",
                modifier = Modifier.fillMaxWidth().padding(24.dp),
                onClick = onConfirm,
            )
        }
    }
}

@Composable
private fun MacroPill(label: String, level: MacroLevel, modifier: Modifier = Modifier) {
    SectionCard(modifier) {
        Text(label, fontSize = 11.sp, color = TextMuted)
        Text(
            level.label,
            fontWeight = FontWeight.Bold,
            color = if (level == MacroLevel.Ok) BrandGreen else WarnAmber,
            fontSize = 15.sp,
        )
    }
}

@Composable
private fun ProgressTrack(progress: Float) {
    Box(Modifier.fillMaxWidth().height(8.dp).clip(RoundedCornerShape(100.dp)).background(Color(0xFFF2F5F4))) {
        Box(
            Modifier
                .fillMaxWidth(progress.coerceIn(0f, 1f))
                .height(8.dp)
                .clip(RoundedCornerShape(100.dp))
                .background(BrandGreen),
        )
    }
}

@Composable
fun ConfirmSuccessScreen(
    meal: LoggedMeal?,
    onContinueScanning: () -> Unit,
    onViewHistory: () -> Unit,
) {
    val shown = meal
    GradientScreen {
        Column(Modifier.fillMaxSize(), verticalArrangement = Arrangement.Bottom) {
            Column(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp)).background(Color.White).padding(24.dp),
            ) {
                Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                    Box(Modifier.size(96.dp).clip(CircleShape).background(BrandGreen.copy(alpha = 0.2f)), contentAlignment = Alignment.Center) {
                        Icon(Icons.Filled.CheckCircle, contentDescription = null, tint = BrandGreen, modifier = Modifier.size(48.dp))
                    }
                }
                Spacer(Modifier.height(12.dp))
                Text("记录成功！", fontWeight = FontWeight.Bold, fontSize = 20.sp, color = InkDark, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
                Text(
                    "已记录至今日${shown?.slot?.label ?: ""}",
                    fontSize = 13.sp,
                    color = TextMuted,
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Center,
                )
                Spacer(Modifier.height(20.dp))
                SectionCard(Modifier.fillMaxWidth()) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        if (shown?.photo != null) {
                            Image(
                                bitmap = shown.photo.asImageBitmap(),
                                contentDescription = shown.name,
                                modifier = Modifier.size(56.dp).clip(RoundedCornerShape(14.dp)),
                                contentScale = ContentScale.Crop,
                            )
                        } else {
                            Box(Modifier.size(56.dp).clip(RoundedCornerShape(14.dp)).background(BrandTeal.copy(alpha = 0.3f)))
                        }
                        Spacer(Modifier.width(12.dp))
                        Column {
                            Text(shown?.name ?: "已记录", fontWeight = FontWeight.Bold, color = InkDark)
                            Text(
                                "${DietLogViewModel.kcalText(shown?.kcal ?: 0)} kcal",
                                fontWeight = FontWeight.Bold,
                                color = InkDark,
                                fontSize = 13.sp,
                            )
                            Text(shown?.statusLine ?: "", fontSize = 11.sp, color = TextMuted)
                        }
                    }
                }
                Spacer(Modifier.height(12.dp))
                SectionCard(Modifier.fillMaxWidth()) {
                    Text("💡 AI 饮食助手建议", fontWeight = FontWeight.SemiBold, color = InkDark, fontSize = 13.sp)
                    Spacer(Modifier.height(6.dp))
                    Text(
                        shown?.tip ?: "记录成功。",
                        fontSize = 12.sp,
                        color = TextMuted,
                    )
                }
                Spacer(Modifier.height(16.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    PillSecondaryButton("继续拍照", modifier = Modifier.weight(1f), onClick = onContinueScanning)
                    PillPrimaryButton("查看记录", modifier = Modifier.weight(1f), onClick = onViewHistory)
                }
            }
        }
    }
}

@Composable
fun DietHistoryScreen(
    state: DietUiState,
    onAddMeal: () -> Unit,
    onOpenRecipes: () -> Unit,
    onBack: () -> Unit,
) {
    val chips = remember { DietLogViewModel.weekChips() }
    var selectedKey by remember { mutableStateOf(chips.lastOrNull { it.isToday }?.key ?: chips.last().key) }
    val meals = state.mealsOn(selectedKey)
    val total = state.kcalOn(selectedKey)
    val progress = (total.toFloat() / DietLogViewModel.GOAL_KCAL).coerceIn(0f, 1f)
    val isToday = selectedKey == DietLogViewModel.currentDayKey()

    GradientScreen {
        Column(Modifier.fillMaxSize()) {
            Row(
                Modifier.fillMaxWidth().padding(start = 16.dp, end = 24.dp, top = 16.dp, bottom = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Filled.ArrowBack,
                        contentDescription = "返回",
                        tint = InkDark,
                        modifier = Modifier
                            .size(36.dp)
                            .clip(CircleShape)
                            .pressable(onClick = onBack)
                            .padding(6.dp),
                    )
                    Spacer(Modifier.width(4.dp))
                    Text("饮食记录", fontWeight = FontWeight.Bold, fontSize = 22.sp, color = InkDark)
                }
                Text(
                    "食谱",
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 14.sp,
                    color = InkDark,
                    modifier = Modifier.pressable(onClick = onOpenRecipes).padding(4.dp),
                )
            }
            LazyRow(modifier = Modifier.padding(horizontal = 24.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                items(chips, key = { it.key }) { day ->
                    val selected = day.key == selectedKey
                    Box(
                        Modifier
                            .size(40.dp)
                            .clip(CircleShape)
                            .background(if (selected) BrandGreen else Color.White)
                            .pressable(onClick = { selectedKey = day.key }),
                        contentAlignment = Alignment.Center,
                    ) { Text("${day.dayOfMonth}", fontWeight = FontWeight.SemiBold, color = InkDark) }
                }
            }
            Spacer(Modifier.height(16.dp))
            SectionCard(Modifier.fillMaxWidth().padding(horizontal = 24.dp)) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text(if (isToday) "今日总量" else "当日总量", color = InkDark)
                    Text(
                        "${DietLogViewModel.kcalText(total)} / ${DietLogViewModel.kcalText(DietLogViewModel.GOAL_KCAL)} kcal",
                        fontWeight = FontWeight.Bold,
                        color = InkDark,
                    )
                }
                Spacer(Modifier.height(8.dp))
                ProgressTrack(progress)
            }
            Spacer(Modifier.height(16.dp))
            if (meals.isEmpty()) {
                Column(
                    Modifier.fillMaxWidth().weight(1f).padding(horizontal = 24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                ) {
                    Text("这一天还没有记录", fontWeight = FontWeight.SemiBold, color = InkDark)
                    Spacer(Modifier.height(6.dp))
                    Text("拍一张餐点，或从食谱添加", fontSize = 13.sp, color = TextMuted)
                }
            } else {
                LazyColumn(modifier = Modifier.weight(1f).padding(horizontal = 24.dp)) {
                    items(meals, key = { it.id }) { meal ->
                        MealRow(meal)
                    }
                }
            }
            PillSecondaryButton(
                "+ 添加餐次",
                modifier = Modifier.fillMaxWidth().padding(24.dp),
                onClick = onAddMeal,
            )
        }
    }
}

@Composable
private fun MealRow(meal: LoggedMeal) {
    Row(
        Modifier.fillMaxWidth().padding(vertical = 10.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Text("${meal.slot.label} · ${meal.name}", color = InkDark, fontWeight = FontWeight.SemiBold)
            Text(meal.items.take(2).joinToString(" / "), fontSize = 11.sp, color = TextMuted)
        }
        Text("${DietLogViewModel.kcalText(meal.kcal)} kcal", color = TextMuted)
    }
}

@Composable
fun RecipeScreen(
    onBack: () -> Unit,
    onLogRecipe: (RecipeItem) -> Unit,
) {
    val tabs = RecipeGoal.entries
    var selected by remember { mutableStateOf(RecipeGoal.Recommend) }
    var pending by remember { mutableStateOf<RecipeItem?>(null) }
    val recipes = remember(selected) {
        DietLogViewModel.RECIPES.filter { it.goal == selected }
    }
    val featured = recipes.firstOrNull()

    GradientScreen {
        Column(Modifier.fillMaxSize()) {
            Row(
                Modifier.fillMaxWidth().padding(start = 16.dp, end = 24.dp, top = 16.dp, bottom = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    Icons.Filled.ArrowBack,
                    contentDescription = "返回",
                    tint = InkDark,
                    modifier = Modifier
                        .size(36.dp)
                        .clip(CircleShape)
                        .pressable(onClick = onBack)
                        .padding(6.dp),
                )
                Spacer(Modifier.width(4.dp))
                Text("健康食谱", fontWeight = FontWeight.Bold, fontSize = 22.sp, color = InkDark)
            }
            Row(Modifier.padding(horizontal = 24.dp), horizontalArrangement = Arrangement.spacedBy(20.dp)) {
                tabs.forEach { tab ->
                    val on = tab == selected
                    Text(
                        tab.tab,
                        fontWeight = if (on) FontWeight.Bold else FontWeight.Medium,
                        color = if (on) InkDark else TextMuted,
                        modifier = Modifier.pressable(onClick = { selected = tab }).padding(vertical = 4.dp),
                    )
                }
            }
            Spacer(Modifier.height(16.dp))
            LazyColumn(modifier = Modifier.weight(1f)) {
                if (featured != null) {
                    item {
                        Box(
                            Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 24.dp)
                                .aspectRatio(2f)
                                .clip(RoundedCornerShape(20.dp))
                                .background(BrandTeal.copy(alpha = 0.25f))
                                .pressable(onClick = { pending = featured }),
                            contentAlignment = Alignment.BottomStart,
                        ) {
                            Column(Modifier.padding(16.dp)) {
                                Text(featured.name, fontWeight = FontWeight.Bold, color = InkDark)
                                Text("${DietLogViewModel.kcalText(featured.kcal)} kcal · 点击记录", fontSize = 12.sp, color = TextMuted)
                            }
                        }
                    }
                }
                item {
                    Spacer(Modifier.height(16.dp))
                    Text(
                        if (selected == RecipeGoal.Recommend) "热门食谱" else "${selected.tab}食谱",
                        fontWeight = FontWeight.SemiBold,
                        color = InkDark,
                        modifier = Modifier.padding(horizontal = 24.dp),
                    )
                    Spacer(Modifier.height(8.dp))
                }
                items(recipes.drop(if (featured != null) 1 else 0)) { recipe ->
                    SectionCard(
                        Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 24.dp, vertical = 6.dp)
                            .pressable(onClick = { pending = recipe }),
                    ) {
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Column(Modifier.weight(1f)) {
                                Text(recipe.name, fontWeight = FontWeight.SemiBold, color = InkDark, fontSize = 15.sp)
                                Text(recipe.blurb, fontSize = 12.sp, color = TextMuted)
                            }
                            Text("${DietLogViewModel.kcalText(recipe.kcal)} kcal", fontSize = 12.sp, color = TextMuted)
                        }
                    }
                }
                item { Spacer(Modifier.height(24.dp)) }
            }
        }
    }

    pending?.let { recipe ->
        AlertDialog(
            onDismissRequest = { pending = null },
            title = { Text("记录到今日？") },
            text = { Text("${recipe.name} · ${DietLogViewModel.kcalText(recipe.kcal)} kcal") },
            confirmButton = {
                TextButton(onClick = {
                    onLogRecipe(recipe)
                    pending = null
                }) { Text("确认记录") }
            },
            dismissButton = {
                TextButton(onClick = { pending = null }) { Text("取消") }
            },
        )
    }
}

internal fun placeholderMealBitmap(): Bitmap {
    val width = 720
    val height = 960
    val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bmp)
    val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    paint.shader = LinearGradient(
        0f,
        0f,
        width.toFloat(),
        height.toFloat(),
        intArrayOf(0xFF0D1112.toInt(), 0xFF73D6CE.toInt(), 0xFFC7FF00.toInt()),
        floatArrayOf(0f, 0.55f, 1f),
        Shader.TileMode.CLAMP,
    )
    canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
    paint.shader = null
    paint.color = 0x66FFFFFF
    canvas.drawCircle(width / 2f, height / 2.2f, 180f, paint)
    paint.color = 0x33C7FF00
    canvas.drawCircle(width / 2f, height / 2.2f, 110f, paint)
    return bmp
}


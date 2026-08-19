package com.restpod.hud.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.restpod.hud.ui.components.GradientScreen
import com.restpod.hud.ui.components.pressable
import com.restpod.hud.ui.components.PillPrimaryButton
import com.restpod.hud.ui.components.PillSecondaryButton
import com.restpod.hud.ui.components.SectionCard
import com.restpod.hud.ui.theme.BrandGreen
import com.restpod.hud.ui.theme.BrandTeal
import com.restpod.hud.ui.theme.InkDark
import com.restpod.hud.ui.theme.TextMuted

@Composable
fun CameraScreen(onCaptured: () -> Unit) {
    Box(Modifier.fillMaxSize().background(InkDark).statusBarsPadding().navigationBarsPadding()) {
        Column(Modifier.fillMaxSize()) {
            Spacer(Modifier.weight(1f))
            Text(
                "拍一张你的餐点吧",
                color = Color.White,
                fontWeight = FontWeight.SemiBold,
                fontSize = 16.sp,
                modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
            )
            Text(
                "对准食物按拍照键",
                color = Color.White.copy(alpha = 0.6f),
                fontSize = 12.sp,
                modifier = Modifier.fillMaxWidth().padding(bottom = 24.dp),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
            )
            Box(Modifier.fillMaxWidth().padding(bottom = 40.dp), contentAlignment = Alignment.Center) {
                Box(
                    modifier = Modifier
                        .size(72.dp)
                        .clip(CircleShape)
                        .background(Color.White)
                        .pressable(onClick = onCaptured),
                    contentAlignment = Alignment.Center,
                ) {
                    Box(Modifier.size(60.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.001f)))
                }
            }
        }
    }
}

@Composable
fun DietAnalysisScreen(onConfirm: () -> Unit) {
    GradientScreen {
        Column(Modifier.fillMaxSize()) {
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("饮食分析", fontWeight = FontWeight.Bold, fontSize = 22.sp, color = InkDark)
                Icon(Icons.Filled.CalendarToday, contentDescription = null, tint = InkDark)
            }
            LazyColumn(modifier = Modifier.weight(1f).padding(horizontal = 24.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                item {
                    Box(
                        Modifier.fillMaxWidth().height(160.dp).clip(RoundedCornerShape(20.dp)).background(InkDark.copy(alpha = 0.85f)),
                        contentAlignment = Alignment.TopStart,
                    ) {
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
                            Text("置信度 98%", fontSize = 12.sp, color = TextMuted)
                        }
                        Spacer(Modifier.height(12.dp))
                        listOf("鸡胸肉 150g", "糙米饭 200g", "西兰花 80g").forEach {
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
                        Text("• 蛋白质摄入充足，有利于肌肉合成", fontSize = 13.sp, color = InkDark)
                        Text("• 建议搭配一份柑橘类水果，补充维生素 C", fontSize = 13.sp, color = InkDark)
                    }
                }
                item {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        MacroPill("热量", "达标", BrandGreen, Modifier.weight(1f))
                        MacroPill("蛋白质", "达标", BrandGreen, Modifier.weight(1f))
                        MacroPill("碳水", "偏高", Color(0xFFF2A63C), Modifier.weight(1f))
                        MacroPill("脂肪", "达标", BrandGreen, Modifier.weight(1f))
                    }
                }
                item {
                    SectionCard(Modifier.fillMaxWidth()) {
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("今日摄入进度", fontWeight = FontWeight.SemiBold, color = InkDark)
                            Row {
                                Text("1,650", fontWeight = FontWeight.Bold, color = InkDark)
                                Text(" / 2,000 kcal", fontSize = 12.sp, color = TextMuted)
                            }
                        }
                        Spacer(Modifier.height(10.dp))
                        Box(Modifier.fillMaxWidth().height(8.dp).clip(RoundedCornerShape(100.dp)).background(Color(0xFFF2F5F4))) {
                            Box(Modifier.fillMaxWidth(0.825f).height(8.dp).clip(RoundedCornerShape(100.dp)).background(BrandGreen))
                        }
                    }
                }
            }
            // Bottom: replaced the original tab bar with a single confirm CTA (see design review).
            PillPrimaryButton(
                "确认记录",
                modifier = Modifier.fillMaxWidth().padding(24.dp),
                onClick = onConfirm,
            )
        }
    }
}

@Composable
private fun MacroPill(label: String, value: String, valueColor: Color, modifier: Modifier = Modifier) {
    SectionCard(modifier) {
        Text(label, fontSize = 11.sp, color = TextMuted)
        Text(value, fontWeight = FontWeight.Bold, color = valueColor, fontSize = 15.sp)
    }
}

@Composable
fun ConfirmSuccessScreen(onContinueScanning: () -> Unit, onBackToAnalysis: () -> Unit) {
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
                Text("记录成功！", fontWeight = FontWeight.Bold, fontSize = 20.sp, color = InkDark, modifier = Modifier.fillMaxWidth(), textAlign = androidx.compose.ui.text.style.TextAlign.Center)
                Text("已记录至今日午餐", fontSize = 13.sp, color = TextMuted, modifier = Modifier.fillMaxWidth(), textAlign = androidx.compose.ui.text.style.TextAlign.Center)
                Spacer(Modifier.height(20.dp))
                SectionCard(Modifier.fillMaxWidth()) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(Modifier.size(56.dp).clip(RoundedCornerShape(14.dp)).background(BrandTeal.copy(alpha = 0.3f)))
                        Spacer(Modifier.width(12.dp))
                        Column {
                            Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                                Text("鸡胸肉沙拉", fontWeight = FontWeight.Bold, color = InkDark)
                            }
                            Text("428 kcal", fontWeight = FontWeight.Bold, color = InkDark, fontSize = 13.sp)
                            Text("热量达标 · 蛋白质达标 · 碳水偏高", fontSize = 11.sp, color = TextMuted)
                        }
                    }
                }
                Spacer(Modifier.height(12.dp))
                SectionCard(Modifier.fillMaxWidth()) {
                    Text("💡 AI 饮食助手建议", fontWeight = FontWeight.SemiBold, color = InkDark, fontSize = 13.sp)
                    Spacer(Modifier.height(6.dp))
                    Text("小贴士：下午可以吃一份水果补充维生素 C，推荐苹果或橙子，帮助今日营养更好地吸收。", fontSize = 12.sp, color = TextMuted)
                }
                Spacer(Modifier.height(16.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    PillSecondaryButton("继续拍照", modifier = Modifier.weight(1f), onClick = onContinueScanning)
                    PillPrimaryButton("返回饮食分析", modifier = Modifier.weight(1f), onClick = onBackToAnalysis)
                }
            }
        }
    }
}

@Composable
fun DietHistoryScreen() {
    val days = listOf("24", "25", "26", "27", "28", "29", "30")
    GradientScreen {
        Column(Modifier.fillMaxSize()) {
            Text("饮食记录", fontWeight = FontWeight.Bold, fontSize = 22.sp, color = InkDark, modifier = Modifier.padding(24.dp))
            LazyRow(modifier = Modifier.padding(horizontal = 24.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                items(days) { day ->
                    Box(
                        Modifier.size(40.dp).clip(CircleShape).background(if (day == "27") BrandGreen else Color.White),
                        contentAlignment = Alignment.Center,
                    ) { Text(day, fontWeight = FontWeight.SemiBold, color = InkDark) }
                }
            }
            Spacer(Modifier.height(16.dp))
            SectionCard(Modifier.fillMaxWidth().padding(horizontal = 24.dp)) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text("今日总量已", color = InkDark)
                    Text("1,650 / 2,000 kcal", fontWeight = FontWeight.Bold, color = InkDark)
                }
                Spacer(Modifier.height(8.dp))
                Box(Modifier.fillMaxWidth().height(6.dp).clip(RoundedCornerShape(100.dp)).background(Color(0xFFF2F5F4))) {
                    Box(Modifier.fillMaxWidth(0.825f).height(6.dp).clip(RoundedCornerShape(100.dp)).background(BrandGreen))
                }
            }
            Spacer(Modifier.height(16.dp))
            Column(Modifier.padding(horizontal = 24.dp)) {
                MealRow("早餐", "320 kcal")
                MealRow("午餐", "428 kcal")
            }
            Spacer(Modifier.weight(1f))
            PillSecondaryButton("+ 添加餐次", modifier = Modifier.fillMaxWidth().padding(24.dp))
        }
    }
}

@Composable
private fun MealRow(name: String, kcal: String) {
    Row(Modifier.fillMaxWidth().padding(vertical = 8.dp), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(name, color = InkDark, fontWeight = FontWeight.SemiBold)
        Text(kcal, color = TextMuted)
    }
}

@Composable
fun RecipeScreen() {
    val tabs = listOf("推荐", "减脂", "增肌", "维持")
    val recipes = listOf("三文鱼藜麦" to "530 kcal", "牛油果鸡胸" to "290 kcal")
    GradientScreen {
        Column(Modifier.fillMaxSize()) {
            Text("健康食谱", fontWeight = FontWeight.Bold, fontSize = 22.sp, color = InkDark, modifier = Modifier.padding(24.dp))
            Row(Modifier.padding(horizontal = 24.dp), horizontalArrangement = Arrangement.spacedBy(20.dp)) {
                tabs.forEachIndexed { i, tab ->
                    Text(tab, fontWeight = if (i == 0) FontWeight.Bold else FontWeight.Medium, color = if (i == 0) InkDark else TextMuted)
                }
            }
            Spacer(Modifier.height(16.dp))
            Box(
                Modifier.fillMaxWidth().padding(horizontal = 24.dp).aspectRatio(2f).clip(RoundedCornerShape(20.dp)).background(BrandTeal.copy(alpha = 0.25f)),
                contentAlignment = Alignment.BottomStart,
            ) {
                Text("低脂鸡胸肉沙拉", fontWeight = FontWeight.Bold, color = InkDark, modifier = Modifier.padding(16.dp))
            }
            Spacer(Modifier.height(16.dp))
            Text("热门食谱", fontWeight = FontWeight.SemiBold, color = InkDark, modifier = Modifier.padding(horizontal = 24.dp))
            LazyRow(modifier = Modifier.padding(24.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                items(recipes) { (title, kcal) ->
                    Column(Modifier.width(140.dp)) {
                        Box(Modifier.fillMaxWidth().aspectRatio(1.2f).clip(RoundedCornerShape(16.dp)).background(BrandGreen.copy(alpha = 0.25f)))
                        Spacer(Modifier.height(6.dp))
                        Text(title, fontWeight = FontWeight.SemiBold, color = InkDark, fontSize = 13.sp)
                        Text(kcal, fontSize = 11.sp, color = TextMuted)
                    }
                }
            }
        }
    }
}

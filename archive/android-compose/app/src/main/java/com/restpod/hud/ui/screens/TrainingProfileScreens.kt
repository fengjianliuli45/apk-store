package com.restpod.hud.ui.screens

import androidx.compose.foundation.background
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
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.restpod.hud.ui.components.BottomNavBar
import com.restpod.hud.ui.components.GradientScreen
import com.restpod.hud.ui.components.PillPrimaryButton
import com.restpod.hud.ui.components.pressable
import com.restpod.hud.ui.components.PillSecondaryButton
import com.restpod.hud.ui.components.SectionCard
import com.restpod.hud.ui.theme.BrandGreen
import com.restpod.hud.ui.theme.BrandTeal
import com.restpod.hud.ui.theme.InkDark
import com.restpod.hud.ui.theme.TextMuted

@Composable
fun WorkoutMapScreen(onNavigate: (Int) -> Unit) {
    GradientScreen {
        Column(Modifier.fillMaxSize()) {
            Text("附近的训练", fontWeight = FontWeight.Bold, fontSize = 22.sp, color = InkDark, modifier = Modifier.padding(24.dp))
            Column(Modifier.weight(1f).padding(horizontal = 24.dp)) {
                Box(
                    Modifier.fillMaxWidth().aspectRatio(1f).clip(RoundedCornerShape(20.dp)).background(BrandTeal.copy(alpha = 0.25f)),
                    contentAlignment = Alignment.Center,
                ) {
                    Box(Modifier.size(14.dp).clip(CircleShape).background(BrandGreen))
                }
                Spacer(Modifier.height(16.dp))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    StatBlock("5.2 km", "距离")
                    StatBlock("28:16", "时间")
                    StatBlock("6'12\"", "配速")
                    StatBlock("340 kcal", "消耗")
                }
                Spacer(Modifier.height(12.dp))
                Text("附近有 3 人在练", color = TextMuted, fontSize = 13.sp)
                Spacer(Modifier.height(16.dp))
                PillPrimaryButton("结伴训练", modifier = Modifier.fillMaxWidth())
                Spacer(Modifier.height(10.dp))
                PillSecondaryButton("分享到社交圈", modifier = Modifier.fillMaxWidth())
            }
            BottomNavBar(
                items = listOf("首页" to false, "社交" to false, "训练" to true, "我的" to false),
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp),
                onSelect = onNavigate,
            )
        }
    }
}

@Composable
private fun StatBlock(value: String, label: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, fontWeight = FontWeight.Bold, fontSize = 15.sp, color = InkDark)
        Text(label, fontSize = 11.sp, color = TextMuted)
    }
}

@Composable
fun ProfileScreen(
    onOpenSettings: () -> Unit,
    onNavigate: (Int) -> Unit,
    onOpenHistory: () -> Unit = {},
    onOpenRecipes: () -> Unit = {},
) {
    val recent = listOf("胸推 · 腿" to "42:59", "夜跑 · 5.2km" to "28:59", "深蹲" to "50:59")
    GradientScreen {
        Column(Modifier.fillMaxSize()) {
            Row(
                Modifier.fillMaxWidth().padding(24.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(56.dp).clip(CircleShape).background(BrandGreen))
                    Spacer(Modifier.width(12.dp))
                    Column {
                        Text("源雅女", fontWeight = FontWeight.Bold, fontSize = 18.sp, color = InkDark)
                        Text("坚持训练 128 天", fontSize = 12.sp, color = TextMuted)
                    }
                }
            }
            Row(Modifier.fillMaxWidth().padding(horizontal = 24.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                StatBlock("72 次", "训练")
                StatBlock("86 时", "时长")
                StatBlock("12.4k", "消耗")
            }
            Spacer(Modifier.height(20.dp))
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 24.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                SectionCard(
                    Modifier.weight(1f).pressable(onClick = onOpenHistory),
                ) {
                    Text("饮食记录", fontWeight = FontWeight.SemiBold, color = InkDark)
                    Text("查看今日餐次", fontSize = 11.sp, color = TextMuted)
                }
                SectionCard(
                    Modifier.weight(1f).pressable(onClick = onOpenRecipes),
                ) {
                    Text("健康食谱", fontWeight = FontWeight.SemiBold, color = InkDark)
                    Text("减脂 / 增肌 / 维持", fontSize = 11.sp, color = TextMuted)
                }
            }
            Spacer(Modifier.height(10.dp))
            SectionCard(
                Modifier.fillMaxWidth().padding(horizontal = 24.dp).pressable(onClick = { onNavigate(1) }),
            ) {
                Row(
                    Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column {
                        Text("社交圈", fontWeight = FontWeight.SemiBold, color = InkDark)
                        Text("看看好友的训练动态", fontSize = 11.sp, color = TextMuted)
                    }
                    Text("›", fontWeight = FontWeight.Bold, fontSize = 18.sp, color = TextMuted)
                }
            }
            Spacer(Modifier.height(16.dp))
            SectionCard(Modifier.fillMaxWidth().padding(horizontal = 24.dp)) {
                Text("体能进度雷达图", fontWeight = FontWeight.SemiBold, color = InkDark)
                Spacer(Modifier.height(8.dp))
                Box(Modifier.size(120.dp).clip(CircleShape).background(BrandTeal.copy(alpha = 0.2f)))
            }
            Spacer(Modifier.height(16.dp))
            Text("最近训练记录", fontWeight = FontWeight.SemiBold, color = InkDark, modifier = Modifier.padding(horizontal = 24.dp))
            LazyColumn(modifier = Modifier.weight(1f).padding(horizontal = 24.dp)) {
                items(recent) { (title, meta) ->
                    Row(Modifier.fillMaxWidth().padding(vertical = 8.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text(title, color = InkDark)
                        Text(meta, color = TextMuted)
                    }
                }
            }
            BottomNavBar(
                items = listOf("首页" to false, "社交" to false, "训练" to false, "我的" to true),
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp),
                onSelect = onNavigate,
            )
        }
    }
}

@Composable
fun SettingsScreen(onBack: () -> Unit) {
    val groups = listOf(
        "账号" to listOf("账号与安全", "固定推送", "手机号"),
        "训练" to listOf("训练提醒", "社交互动", "系统通知"),
        "隐私" to listOf("谁可以看我的动态", "附近的人"),
        "通用" to listOf("单位", "语言"),
    )
    GradientScreen {
        Column(Modifier.fillMaxSize()) {
            Text("设置", fontWeight = FontWeight.Bold, fontSize = 22.sp, color = InkDark, modifier = Modifier.padding(24.dp))
            LazyColumn(modifier = Modifier.weight(1f).padding(horizontal = 24.dp)) {
                items(groups) { (header, rows) ->
                    Text(header, fontSize = 12.sp, color = TextMuted, modifier = Modifier.padding(top = 12.dp, bottom = 4.dp))
                    SectionCard(Modifier.fillMaxWidth()) {
                        rows.forEach { row ->
                            Text(row, color = InkDark, modifier = Modifier.padding(vertical = 8.dp))
                        }
                    }
                }
                item {
                    Text("关于 Stopwatch", color = InkDark, modifier = Modifier.padding(vertical = 16.dp))
                    Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(BrandTeal.copy(alpha = 0.15f)).padding(14.dp)) {
                        Text("退出登录", color = androidx.compose.ui.graphics.Color(0xFFE5484D), fontWeight = FontWeight.SemiBold)
                    }
                }
            }
        }
    }
}

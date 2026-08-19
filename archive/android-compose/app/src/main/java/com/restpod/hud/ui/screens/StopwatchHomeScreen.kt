package com.restpod.hud.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.PersonOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.restpod.hud.ui.components.BottomNavBar
import com.restpod.hud.ui.components.GradientScreen
import com.restpod.hud.ui.components.pressable
import com.restpod.hud.ui.theme.BrandGreen
import com.restpod.hud.ui.theme.InkDark
import com.restpod.hud.ui.theme.TextMuted

@Composable
fun StopwatchHomeScreen(
    onStart: () -> Unit,
    onNavigate: (Int) -> Unit = {},
    onOpenCamera: () -> Unit = {},
) {
    GradientScreen {
        Column(modifier = Modifier.fillMaxSize()) {
                Column(modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 8.dp)) {
                    Text("STOPWATCH", fontWeight = FontWeight.Bold, letterSpacing = 2.sp, fontSize = 11.sp, color = TextMuted)
                    Text("READY", fontWeight = FontWeight.Bold, fontSize = 12.sp, color = BrandGreen)
                }

                Column(
                    modifier = Modifier.fillMaxWidth().padding(top = 32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Text(
                        "00:00.00",
                        fontWeight = FontWeight.Bold,
                        fontSize = 40.sp,
                        color = InkDark,
                        fontFamily = FontFamily.Monospace,
                    )
                    Spacer(Modifier.height(20.dp))
                    Box(
                        modifier = Modifier
                            .size(180.dp)
                            .clip(CircleShape)
                            .background(BrandGreen)
                            .pressable(onClick = onStart),
                        contentAlignment = Alignment.Center,
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text("开始训练", fontWeight = FontWeight.Bold, fontSize = 18.sp, color = InkDark)
                            Text("点击进入准备", fontSize = 11.sp, color = InkDark.copy(alpha = 0.6f))
                        }
                    }
                }

                Column(modifier = Modifier.fillMaxWidth().padding(24.dp)) {
                    Text("有什么可以帮你的？", color = TextMuted, fontSize = 14.sp)
                }

                Spacer(modifier = Modifier.weight(1f))

                Row(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(
                        Icons.Filled.CameraAlt,
                        contentDescription = "饮食打卡",
                        tint = InkDark,
                        modifier = Modifier
                            .size(40.dp)
                            .clip(CircleShape)
                            .pressable(onClick = onOpenCamera)
                            .padding(8.dp),
                    )
                    Box(
                        modifier = Modifier
                            .size(48.dp)
                            .clip(CircleShape)
                            .background(BrandGreen)
                            .pressable(onClick = { onNavigate(3) }),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(Icons.Filled.PersonOutline, contentDescription = "我的", tint = InkDark)
                    }
                }

                BottomNavBar(
                    items = listOf(
                        "首页" to true,
                        "社交" to false,
                        "训练" to false,
                        "我的" to false,
                    ),
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp),
                    onSelect = onNavigate,
                )
        }
    }
}

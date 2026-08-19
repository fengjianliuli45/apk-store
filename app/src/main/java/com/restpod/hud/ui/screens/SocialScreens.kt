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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.restpod.hud.ui.components.BottomNavBar
import com.restpod.hud.ui.components.GradientScreen
import com.restpod.hud.ui.components.SectionCard
import com.restpod.hud.ui.theme.BrandGreen
import com.restpod.hud.ui.theme.InkDark
import com.restpod.hud.ui.theme.TextMuted
import kotlinx.coroutines.launch

private data class Post(val author: String, val tag: String, val title: String, val meta: String)

@Composable
fun SocialFeedScreen(onNavigate: (Int) -> Unit) {
    val posts = listOf(
        Post("林晨", "STRENGTH", "完成胸推日", "4 组重量 · 36 分钟"),
        Post("陈可", "CARDIO", "夜跑收工", "5.2 km · 28:16"),
    )
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    GradientScreen {
        Box(Modifier.fillMaxSize()) {
        Column(Modifier.fillMaxSize()) {
            Text("社交圈", fontWeight = FontWeight.Bold, fontSize = 22.sp, color = InkDark, modifier = Modifier.padding(24.dp))
            LazyColumn(modifier = Modifier.weight(1f).padding(horizontal = 24.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                items(posts) { post ->
                    SectionCard(Modifier.fillMaxWidth()) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Box(Modifier.size(36.dp).clip(CircleShape).background(BrandGreen))
                                Spacer(Modifier.width(10.dp))
                                Text(post.author, fontWeight = FontWeight.SemiBold, color = InkDark)
                            }
                            Box(Modifier.clip(RoundedCornerShape(12.dp)).background(BrandGreen).padding(horizontal = 10.dp, vertical = 4.dp)) {
                                Text(post.tag, fontSize = 10.sp, fontWeight = FontWeight.Bold, color = InkDark)
                            }
                        }
                        Spacer(Modifier.height(10.dp))
                        Text(post.title, fontWeight = FontWeight.Bold, fontSize = 16.sp, color = InkDark)
                        Text(post.meta, fontSize = 13.sp, color = TextMuted)
                    }
                }
            }
            Box(Modifier.fillMaxWidth().padding(24.dp), contentAlignment = Alignment.CenterEnd) {
                FloatingActionButton(
                    onClick = { scope.launch { snackbarHostState.showSnackbar("发布动态下一版") } },
                    containerColor = BrandGreen,
                ) {
                    Icon(Icons.Filled.Add, contentDescription = null, tint = InkDark)
                }
            }
            BottomNavBar(
                items = listOf("首页" to false, "社交" to true, "训练" to false, "我的" to false),
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp),
                onSelect = onNavigate,
            )
        }
            SnackbarHost(
                hostState = snackbarHostState,
                modifier = Modifier.align(Alignment.BottomCenter).padding(bottom = 96.dp),
            )
        }
    }
}

private data class ChatRow(val name: String, val preview: String, val badge: Int)

@Composable
fun ChatListScreen(onNavigate: (Int) -> Unit) {
    val chats = listOf(
        ChatRow("林晨", "今天状态不错？", 2),
        ChatRow("陈可", "明天一起跑步？", 1),
        ChatRow("夜间跑步群", "系统通知：训练提醒已开启", 5),
        ChatRow("系统通知", "你的周报已生成", 0),
        ChatRow("附近同好", "3 位附近的人在训练", 3),
    )
    GradientScreen {
        Column(Modifier.fillMaxSize()) {
            Text("消息", fontWeight = FontWeight.Bold, fontSize = 22.sp, color = InkDark, modifier = Modifier.padding(24.dp))
            LazyColumn(modifier = Modifier.weight(1f).padding(horizontal = 24.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                items(chats) { chat ->
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween,
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(Modifier.size(40.dp).clip(CircleShape).background(BrandGreen))
                            Spacer(Modifier.width(12.dp))
                            Column {
                                Text(chat.name, fontWeight = FontWeight.SemiBold, color = InkDark)
                                Text(chat.preview, fontSize = 12.sp, color = TextMuted)
                            }
                        }
                        if (chat.badge > 0) {
                            Box(Modifier.size(20.dp).clip(CircleShape).background(InkDark), contentAlignment = Alignment.Center) {
                                Text(chat.badge.toString(), color = BrandGreen, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            }
            BottomNavBar(
                items = listOf("首页" to false, "消息" to true, "训练" to false, "我的" to false),
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp),
                onSelect = onNavigate,
            )
        }
    }
}

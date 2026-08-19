package com.restpod.hud.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.ChatBubbleOutline
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.School
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.restpod.hud.ui.components.BottomNavBar
import com.restpod.hud.ui.components.GradientScreen
import com.restpod.hud.ui.components.pressable
import com.restpod.hud.ui.theme.BrandGreen
import com.restpod.hud.ui.theme.HomeBrandGreen
import com.restpod.hud.ui.theme.HomeGradientBottom
import com.restpod.hud.ui.theme.HomeGradientMid
import com.restpod.hud.ui.theme.HomeGradientTop
import com.restpod.hud.ui.theme.HomeInk
import com.restpod.hud.ui.theme.HomeTextMuted
import com.restpod.hud.ui.theme.InkDark
import com.restpod.hud.ui.theme.InterFontFamily
import com.restpod.hud.ui.theme.JetBrainsMonoFontFamily
import com.restpod.hud.ui.theme.TextMuted

private val CardioBlue = Color(0xFFC1EAF5)

private class SocialPost(
    val authorName: String,
    val initials: String,
    val avatarColor: Color,
    val time: String,
    val tag: String,
    val tagColor: Color,
    val title: String,
    val meta: String,
    likes: Int,
    liked: Boolean = false,
    comments: Int = 0,
) {
    var likes by mutableStateOf(likes)
    var liked by mutableStateOf(liked)
    var comments by mutableStateOf(comments)
}

private fun defaultPosts() = mutableStateListOf(
    SocialPost(
        authorName = "林晨",
        initials = "LC",
        avatarColor = HomeBrandGreen,
        time = "今天 07:12",
        tag = "STRENGTH",
        tagColor = HomeBrandGreen,
        title = "完成胸推日",
        meta = "4 组卧推 · 36 分钟",
        likes = 24,
        comments = 6,
    ),
    SocialPost(
        authorName = "陈可",
        initials = "CK",
        avatarColor = CardioBlue,
        time = "昨天 21:40",
        tag = "CARDIO",
        tagColor = CardioBlue,
        title = "夜跑收工",
        meta = "5.2 km · 28:16",
        likes = 18,
        comments = 3,
    ),
)

@Composable
fun SocialFeedScreen(onNavigate: (Int) -> Unit) {
    val posts = remember { defaultPosts() }
    var showComposer by remember { mutableStateOf(false) }
    var commentTarget by remember { mutableStateOf<SocialPost?>(null) }

    Box(
        Modifier
            .fillMaxSize()
            .background(
                Brush.linearGradient(
                    colorStops = arrayOf(0f to HomeGradientTop, 0.5f to HomeGradientMid, 1f to HomeGradientBottom),
                    start = Offset(0f, 0f),
                    end = Offset(0f, Float.POSITIVE_INFINITY),
                ),
            ),
    ) {
        Column(
            Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding(),
        ) {
            SocialTopBar(onBack = { onNavigate(0) })
            LazyColumn(
                modifier = Modifier.weight(1f).fillMaxWidth().padding(horizontal = 20.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                items(posts) { post ->
                    SocialPostCard(
                        post = post,
                        onToggleLike = {
                            post.liked = !post.liked
                            post.likes += if (post.liked) 1 else -1
                        },
                        onComment = { commentTarget = post },
                    )
                }
                item { Spacer(Modifier.height(84.dp)) }
            }
            SocialBottomNav(onNavigate = onNavigate)
        }

        Box(
            Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding()
                .padding(end = 20.dp, bottom = 96.dp),
            contentAlignment = Alignment.BottomEnd,
        ) {
            Box(
                Modifier
                    .size(56.dp)
                    .clip(CircleShape)
                    .background(Color.White)
                    .border(1.5.dp, HomeBrandGreen, CircleShape)
                    .pressable(onClick = { showComposer = true }),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Filled.Add, contentDescription = "发布动态", tint = HomeInk)
            }
        }
    }

    if (showComposer) {
        var draftTitle by remember { mutableStateOf("") }
        var draftMeta by remember { mutableStateOf("") }
        var draftIsCardio by remember { mutableStateOf(false) }
        AlertDialog(
            onDismissRequest = { showComposer = false },
            title = { Text("发布动态", fontWeight = FontWeight.SemiBold) },
            text = {
                Column {
                    OutlinedTextField(
                        value = draftTitle,
                        onValueChange = { draftTitle = it },
                        label = { Text("标题") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                    )
                    Spacer(Modifier.height(8.dp))
                    OutlinedTextField(
                        value = draftMeta,
                        onValueChange = { draftMeta = it },
                        label = { Text("训练数据") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                    )
                    Spacer(Modifier.height(8.dp))
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("类型:", fontSize = 13.sp, color = TextMuted)
                        Spacer(Modifier.width(8.dp))
                        TagChip("STRENGTH", HomeBrandGreen, selected = !draftIsCardio) { draftIsCardio = false }
                        Spacer(Modifier.width(6.dp))
                        TagChip("CARDIO", CardioBlue, selected = draftIsCardio) { draftIsCardio = true }
                    }
                }
            },
            confirmButton = {
                TextButton(
                    enabled = draftTitle.isNotBlank(),
                    onClick = {
                        posts.add(
                            0,
                            SocialPost(
                                authorName = "我",
                                initials = "我",
                                avatarColor = BrandGreen,
                                time = "刚刚",
                                tag = if (draftIsCardio) "CARDIO" else "STRENGTH",
                                tagColor = if (draftIsCardio) CardioBlue else HomeBrandGreen,
                                title = draftTitle,
                                meta = draftMeta.ifBlank { "刚刚完成" },
                                likes = 0,
                            ),
                        )
                        showComposer = false
                    },
                ) { Text("发布") }
            },
            dismissButton = {
                TextButton(onClick = { showComposer = false }) { Text("取消") }
            },
        )
    }

    commentTarget?.let { target ->
        var draftComment by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = { commentTarget = null },
            title = { Text("回复 ${target.authorName}", fontWeight = FontWeight.SemiBold) },
            text = {
                OutlinedTextField(
                    value = draftComment,
                    onValueChange = { draftComment = it },
                    label = { Text("说点什么") },
                    modifier = Modifier.fillMaxWidth(),
                )
            },
            confirmButton = {
                TextButton(
                    enabled = draftComment.isNotBlank(),
                    onClick = {
                        target.comments += 1
                        commentTarget = null
                    },
                ) { Text("发送") }
            },
            dismissButton = {
                TextButton(onClick = { commentTarget = null }) { Text("取消") }
            },
        )
    }
}

@Composable
private fun TagChip(label: String, color: Color, selected: Boolean, onClick: () -> Unit) {
    Box(
        Modifier
            .clip(RoundedCornerShape(10.dp))
            .background(if (selected) color else color.copy(alpha = 0.25f))
            .pressable(onClick = onClick)
            .padding(horizontal = 10.dp, vertical = 6.dp),
    ) {
        Text(label, fontSize = 11.sp, fontWeight = FontWeight.Bold, color = HomeInk)
    }
}

@Composable
private fun SocialTopBar(onBack: () -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(Color.White.copy(alpha = 0.6f))
                    .pressable(onClick = onBack),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Filled.ArrowBack, contentDescription = "返回", tint = HomeInk)
            }
            Spacer(Modifier.width(14.dp))
            Text(
                "社交圈",
                fontFamily = InterFontFamily,
                fontWeight = FontWeight.SemiBold,
                fontSize = 20.sp,
                color = HomeInk,
            )
        }
        Box(
            Modifier
                .clip(RoundedCornerShape(20.dp))
                .background(Color.White.copy(alpha = 0.55f))
                .padding(horizontal = 12.dp, vertical = 6.dp),
        ) {
            Text(
                "SOCIAL",
                fontFamily = JetBrainsMonoFontFamily,
                fontSize = 10.sp,
                letterSpacing = 1.sp,
                color = HomeInk.copy(alpha = 0.56f),
            )
        }
    }
}

@Composable
private fun SocialPostCard(post: SocialPost, onToggleLike: () -> Unit, onComment: () -> Unit) {
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(24.dp))
            .background(Color.White)
            .padding(18.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    Modifier.size(38.dp).clip(CircleShape).background(post.avatarColor),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(post.initials, fontSize = 12.sp, fontWeight = FontWeight.Bold, color = HomeInk, textAlign = TextAlign.Center)
                }
                Spacer(Modifier.width(10.dp))
                Column {
                    Text(post.authorName, fontFamily = InterFontFamily, fontWeight = FontWeight.SemiBold, fontSize = 15.sp, color = HomeInk)
                    Text(post.time, fontFamily = JetBrainsMonoFontFamily, fontSize = 12.sp, color = HomeTextMuted)
                }
            }
            Box(Modifier.clip(RoundedCornerShape(10.dp)).background(post.tagColor).padding(horizontal = 10.dp, vertical = 5.dp)) {
                Text(post.tag, fontSize = 10.sp, fontWeight = FontWeight.Bold, letterSpacing = 0.5.sp, color = HomeInk)
            }
        }
        Spacer(Modifier.height(14.dp))
        Text(post.title, fontFamily = InterFontFamily, fontWeight = FontWeight.Bold, fontSize = 17.sp, color = HomeInk)
        Spacer(Modifier.height(4.dp))
        Text(post.meta, fontFamily = JetBrainsMonoFontFamily, fontSize = 13.sp, color = HomeTextMuted)
        Spacer(Modifier.height(14.dp))
        HorizontalDivider(color = HomeInk.copy(alpha = 0.08f))
        Spacer(Modifier.height(10.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.pressable(onClick = onToggleLike),
            ) {
                Icon(
                    if (post.liked) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder,
                    contentDescription = "点赞",
                    tint = if (post.liked) Color(0xFFE5484D) else HomeTextMuted,
                    modifier = Modifier.size(18.dp),
                )
                Spacer(Modifier.width(6.dp))
                Text(post.likes.toString(), fontFamily = JetBrainsMonoFontFamily, fontSize = 13.sp, color = HomeTextMuted)
            }
            Spacer(Modifier.width(20.dp))
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.pressable(onClick = onComment),
            ) {
                Icon(Icons.Filled.ChatBubbleOutline, contentDescription = "评论", tint = HomeTextMuted, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(6.dp))
                Text(post.comments.toString(), fontFamily = JetBrainsMonoFontFamily, fontSize = 13.sp, color = HomeTextMuted)
            }
        }
    }
}

@Composable
private fun SocialBottomNav(onNavigate: (Int) -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 12.dp)
            .clip(RoundedCornerShape(28.dp))
            .background(Color.White)
            .padding(vertical = 10.dp),
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        SocialNavTab(Icons.Filled.FitnessCenter, "训练", selected = false, modifier = Modifier.weight(1f)) { onNavigate(2) }
        SocialNavTab(Icons.Filled.CalendarToday, "计划", selected = false, modifier = Modifier.weight(1f)) { }
        Box(Modifier.weight(1f), contentAlignment = Alignment.Center) {
            Box(
                Modifier
                    .size(46.dp)
                    .clip(CircleShape)
                    .background(HomeBrandGreen)
                    .pressable(onClick = { onNavigate(0) }),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Filled.School, contentDescription = "首页", tint = HomeInk)
            }
        }
        SocialNavTab(Icons.Filled.Groups, "社交", selected = true, modifier = Modifier.weight(1f)) { onNavigate(1) }
        SocialNavTab(Icons.Filled.Person, "我的", selected = false, modifier = Modifier.weight(1f)) { onNavigate(3) }
    }
}

@Composable
private fun SocialNavTab(icon: androidx.compose.ui.graphics.vector.ImageVector, label: String, selected: Boolean, modifier: Modifier = Modifier, onClick: () -> Unit) {
    val color = if (selected) HomeInk else HomeInk.copy(alpha = 0.56f)
    Column(
        modifier = modifier.pressable(onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(icon, contentDescription = label, tint = color, modifier = Modifier.size(20.dp))
        Spacer(Modifier.height(3.dp))
        Text(label, fontSize = 11.sp, fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium, color = color)
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

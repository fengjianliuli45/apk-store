package com.restpod.hud.ui.screens

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.restpod.hud.session.WorkoutUiState
import com.restpod.hud.ui.components.CoachStage
import com.restpod.hud.ui.components.GradientScreen
import com.restpod.hud.ui.components.HudBreath
import com.restpod.hud.ui.components.PillDashedHoldButton
import com.restpod.hud.ui.components.PillPrimaryButton
import com.restpod.hud.ui.components.PillSecondaryButton
import com.restpod.hud.ui.components.SectionCard
import com.restpod.hud.ui.components.pressable
import com.restpod.hud.ui.theme.BrandGreen
import com.restpod.hud.ui.theme.BrandTeal
import com.restpod.hud.ui.theme.InkDark
import com.restpod.hud.ui.theme.TextMuted

@Composable
private fun Breadcrumb(text: String) {
    Text(text, fontWeight = FontWeight.Bold, letterSpacing = 1.5.sp, fontSize = 11.sp, color = TextMuted)
}

@Composable
private fun GenderToggle(isMale: Boolean, onSelectMale: (Boolean) -> Unit) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(21.dp))
            .background(BrandGreen.copy(alpha = 0.55f))
            .padding(4.dp),
    ) {
        GenderChip(label = "男", selected = isMale, onClick = { onSelectMale(true) })
        GenderChip(label = "女", selected = !isMale, onClick = { onSelectMale(false) })
    }
}

@Composable
private fun GenderChip(label: String, selected: Boolean, onClick: () -> Unit) {
    Text(
        text = label,
        fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium,
        fontSize = 12.sp,
        color = if (selected) InkDark else InkDark.copy(alpha = 0.5f),
        modifier = Modifier
            .clip(RoundedCornerShape(17.dp))
            .then(
                if (selected) Modifier.background(Color.White.copy(alpha = 0.6f))
                else Modifier
            )
            .pressable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 8.dp),
    )
}

@Composable
fun CoachReadyScreen(
    state: WorkoutUiState,
    onStart: () -> Unit,
    onToggleGender: (Boolean) -> Unit,
    onCycleAngle: () -> Unit,
) {
    GradientScreen {
        Column(Modifier.fillMaxSize().padding(horizontal = 24.dp, vertical = 20.dp)) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Column {
                    Breadcrumb("TRAINING / READY")
                    Text(state.exerciseName, fontWeight = FontWeight.Bold, fontSize = 28.sp, color = InkDark)
                    Text("第 ${state.currentSet} 组 / 共 ${state.totalSets} 组", fontSize = 13.sp, color = TextMuted)
                }
                GenderToggle(isMale = state.isMale, onSelectMale = onToggleGender)
            }
            Spacer(Modifier.height(16.dp))
            Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp)).background(Color.White.copy(alpha = 0.7f)).padding(14.dp)) {
                Text(
                    "站到标记内，观察教练动作",
                    color = InkDark,
                    fontSize = 13.sp,
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Center,
                )
            }
            CoachStage(modifier = Modifier.weight(1f), ringColor = BrandGreen, angleLabel = state.cameraAngle)
            SectionCard(Modifier.fillMaxWidth()) {
                Text("动作示范", fontWeight = FontWeight.Bold, fontSize = 18.sp, color = InkDark)
                Text(state.angleCaption, fontSize = 12.sp, color = TextMuted)
                Spacer(Modifier.height(12.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    PillSecondaryButton("切换视角", modifier = Modifier.width(110.dp), onClick = onCycleAngle)
                    PillPrimaryButton("开始训练", modifier = Modifier.weight(1f), onClick = onStart)
                }
            }
        }
    }
}

@Composable
fun CoachActiveScreen(
    state: WorkoutUiState,
    onPauseToggle: () -> Unit,
    onCompleteSet: () -> Unit,
    onAbort: () -> Unit,
) {
    GradientScreen(breath = HudBreath.Active) {
        Column(Modifier.fillMaxSize().padding(horizontal = 24.dp, vertical = 20.dp)) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Column {
                    Breadcrumb("TRAINING / SET ${state.currentSet}")
                    Text(state.exerciseName, fontWeight = FontWeight.Bold, fontSize = 28.sp, color = InkDark)
                }
                Text(
                    state.setTimerText,
                    fontWeight = FontWeight.Medium,
                    fontSize = 24.sp,
                    color = InkDark,
                    fontFamily = FontFamily.Monospace,
                )
            }
            Box(Modifier.fillMaxWidth().padding(top = 8.dp), contentAlignment = Alignment.CenterEnd) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .clip(RoundedCornerShape(20.dp))
                        .background(Color.White.copy(alpha = 0.85f))
                        .padding(horizontal = 14.dp, vertical = 8.dp),
                ) {
                    Icon(Icons.Filled.Check, contentDescription = null, tint = InkDark, modifier = Modifier.size(14.dp))
                    Spacer(Modifier.width(6.dp))
                    Text(
                        if (state.isPaused) "已暂停" else "姿态良好",
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 13.sp,
                        color = InkDark,
                    )
                }
            }
            CoachStage(modifier = Modifier.weight(1f), ringColor = BrandGreen, angleLabel = state.cameraAngle)
            SectionCard(Modifier.fillMaxWidth()) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Column {
                        Text("第 ${state.currentSet} 组 / 共 ${state.totalSets} 组", fontWeight = FontWeight.SemiBold, color = InkDark, fontSize = 14.sp)
                        Text(if (state.isPaused) "计时已冻结，点播放继续" else "保持核心收紧", color = TextMuted, fontSize = 13.sp)
                    }
                    Row(verticalAlignment = Alignment.Bottom) {
                        Text("${state.completedReps}", fontWeight = FontWeight.Bold, fontSize = 30.sp, color = InkDark)
                        Text("/${state.targetReps}", fontSize = 14.sp, color = TextMuted)
                    }
                }
                Spacer(Modifier.height(10.dp))
                Box(Modifier.fillMaxWidth().height(4.dp).clip(RoundedCornerShape(100.dp)).background(InkDark.copy(alpha = 0.12f))) {
                    Box(Modifier.fillMaxWidth(state.repsProgress).height(4.dp).clip(RoundedCornerShape(100.dp)).background(BrandGreen))
                }
                Spacer(Modifier.height(14.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(56.dp)
                            .clip(CircleShape)
                            .background(BrandTeal)
                            .pressable(onClick = onPauseToggle),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(
                            imageVector = if (state.isPaused) Icons.Filled.PlayArrow else Icons.Filled.Pause,
                            contentDescription = if (state.isPaused) "继续" else "暂停",
                            tint = Color.White,
                        )
                    }
                    PillPrimaryButton("完成本组", modifier = Modifier.weight(1f), onClick = onCompleteSet)
                }
                Spacer(Modifier.height(10.dp))
                PillDashedHoldButton("长按结束训练", modifier = Modifier.fillMaxWidth(), onLongPress = onAbort)
            }
        }
    }
}

@Composable
fun CoachRestScreen(
    state: WorkoutUiState,
    onSkip: () -> Unit,
    onAddThirty: () -> Unit,
) {
    GradientScreen(breath = HudBreath.Recover) {
        Column(Modifier.fillMaxSize().padding(horizontal = 24.dp, vertical = 20.dp)) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.Top) {
                Breadcrumb("RECOVERY")
                PillSecondaryButton("跳过休息", modifier = Modifier.height(40.dp), onClick = onSkip)
            }
            Row(verticalAlignment = Alignment.Bottom) {
                Text("${state.restSecondsDisplay}", fontWeight = FontWeight.Light, fontSize = 72.sp, color = InkDark)
                Text(" 秒", fontSize = 16.sp, color = TextMuted, modifier = Modifier.padding(bottom = 14.dp))
            }
            Box(Modifier.clip(RoundedCornerShape(12.dp)).background(Color.White.copy(alpha = 0.55f)).padding(horizontal = 10.dp, vertical = 4.dp)) {
                Text("放松肩颈，跟随教练呼吸", color = InkDark, fontSize = 14.sp)
            }
            CoachStage(
                modifier = Modifier.weight(1f),
                ringColor = BrandTeal,
                ringProgress = state.restRingProgress,
                angleLabel = state.cameraAngle,
            )
            SectionCard(Modifier.fillMaxWidth()) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                    Column {
                        Text("下一组", fontSize = 12.sp, color = TextMuted)
                        Text("${state.nextExerciseName} · 第 ${state.nextSetNumber} 组", fontWeight = FontWeight.Bold, color = InkDark)
                    }
                    PillSecondaryButton("+30 秒", modifier = Modifier.width(100.dp).height(44.dp), onClick = onAddThirty)
                }
            }
        }
    }
}

@Composable
fun CoachRestLast5sScreen(
    state: WorkoutUiState,
    onStartNow: () -> Unit,
) {
    val pulse = rememberInfiniteTransition(label = "last5pulse")
    val scale by pulse.animateFloat(
        initialValue = 0.94f,
        targetValue = 1.08f,
        animationSpec = infiniteRepeatable(tween(520), RepeatMode.Reverse),
        label = "last5scale",
    )
    GradientScreen(breath = HudBreath.Recover) {
        Column(Modifier.fillMaxSize().padding(horizontal = 24.dp, vertical = 20.dp)) {
            Breadcrumb("NEXT SET")
            Row(verticalAlignment = Alignment.Bottom) {
                Text(
                    "${state.restSecondsDisplay.coerceAtMost(5)}",
                    fontWeight = FontWeight.Light,
                    fontSize = 72.sp,
                    color = BrandGreen,
                    modifier = Modifier.graphicsLayer {
                        scaleX = scale
                        scaleY = scale
                    },
                )
                Text(" 秒", fontSize = 16.sp, color = TextMuted, modifier = Modifier.padding(bottom = 14.dp))
            }
            Text("保持呼吸，准备就绪", color = InkDark, fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
            CoachStage(
                modifier = Modifier.weight(1f),
                ringColor = BrandTeal,
                ringProgress = state.restRingProgress,
                angleLabel = state.cameraAngle,
            )
            SectionCard(Modifier.fillMaxWidth()) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                    Column {
                        Text("教练正在预演下一动作", fontSize = 12.sp, color = TextMuted)
                        Text("${state.nextExerciseName} · 第 ${state.nextSetNumber} 组", fontWeight = FontWeight.Bold, color = InkDark)
                    }
                    PillPrimaryButton("立即开始", modifier = Modifier.width(120.dp).height(44.dp), onClick = onStartNow)
                }
            }
        }
    }
}

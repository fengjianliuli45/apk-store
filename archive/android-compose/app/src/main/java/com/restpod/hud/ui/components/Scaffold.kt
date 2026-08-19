package com.restpod.hud.ui.components

import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.restpod.hud.ui.theme.BrandGreen
import com.restpod.hud.ui.theme.BrandTeal
import com.restpod.hud.ui.theme.InkDark
import com.restpod.hud.ui.theme.SurfaceBackgroundBottom
import com.restpod.hud.ui.theme.SurfaceBackgroundTop
import com.restpod.hud.ui.theme.TextMuted

/** How strongly the shared HUD backdrop inhales/exhales. */
enum class HudBreath(val strength: Float) {
    /** Home / Ready / tabs — living but quiet. */
    Calm(0.48f),
    /** Active set — a little more present. */
    Active(0.68f),
    /** Rest / last-5s — recovery cue, still readable. */
    Recover(1f),
}

private val BreathEasing = CubicBezierEasing(0.42f, 0.0f, 0.58f, 1.0f)
private const val BreathHalfCycleMs = 2500
private val InhaleLime = Color(0xFFE5F4C4)
private val InhaleTeal = Color(0xFFD4EBE6)

/**
 * Full-bleed gradient backdrop used by every screen. A slow inhale/exhale shifts luminance,
 * gradient focus, and a soft lime/teal glow so the HUD feels alive without washing out text.
 */
@Composable
fun GradientScreen(
    modifier: Modifier = Modifier,
    topBrightColor: Color = SurfaceBackgroundTop,
    bottomWarmColor: Color = SurfaceBackgroundBottom,
    breath: HudBreath = HudBreath.Calm,
    content: @Composable BoxScope.() -> Unit,
) {
    val infinite = rememberInfiniteTransition(label = "hudBreath")
    val inhale by infinite.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = BreathHalfCycleMs, easing = BreathEasing),
            repeatMode = RepeatMode.Reverse,
        ),
        label = "hudInhale",
    )
    val amp = breath.strength
    val phase = inhale * amp
    val top = lerp(topBrightColor, InhaleLime, 0.28f * phase)
    val bottom = lerp(bottomWarmColor, InhaleTeal, 0.32f * phase)

    Box(modifier = modifier.fillMaxSize()) {
        Canvas(Modifier.fillMaxSize()) {
            val start = Offset(size.width * (0.18f + 0.10f * phase), 0f)
            val end = Offset(size.width * (0.82f - 0.08f * phase), size.height)
            drawRect(brush = Brush.linearGradient(colors = listOf(top, bottom), start = start, end = end))

            val glowCenter = Offset(
                x = size.width * 0.5f,
                y = size.height * (0.40f - 0.05f * phase),
            )
            val glowRadius = size.minDimension * (0.46f + 0.18f * phase)
            drawCircle(
                brush = Brush.radialGradient(
                    colorStops = arrayOf(
                        0f to BrandGreen.copy(alpha = 0.055f * amp + 0.070f * phase),
                        0.42f to BrandTeal.copy(alpha = 0.028f * amp + 0.050f * phase),
                        1f to Color.Transparent,
                    ),
                    center = glowCenter,
                    radius = glowRadius,
                ),
                center = glowCenter,
                radius = glowRadius,
            )
            drawRect(Color.White.copy(alpha = 0.035f * phase))
        }
        Box(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding(),
            content = content,
        )
    }
}

data class BottomNavItem(val label: String, val icon: @Composable () -> Unit = {})

@Composable
fun BottomNavBar(
    items: List<Pair<String, Boolean>>,
    modifier: Modifier = Modifier,
    onSelect: (Int) -> Unit = {},
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(28.dp))
            .background(Color.White)
            .padding(vertical = 10.dp),
        horizontalArrangement = Arrangement.SpaceEvenly,
    ) {
        items.forEachIndexed { index, (label, selected) ->
            NavTab(label = label, selected = selected, modifier = Modifier.weight(1f)) { onSelect(index) }
        }
    }
}

@Composable
private fun RowScope.NavTab(label: String, selected: Boolean, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Box(
        modifier = modifier
            .pressable(onClick = onClick)
            .padding(vertical = 8.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = label,
            color = if (selected) InkDark else TextMuted,
            fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium,
            fontSize = 13.sp,
        )
    }
}

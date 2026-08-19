package com.restpod.hud.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.LocalIndication
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameMillis
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.restpod.hud.ui.theme.BrandGreen
import com.restpod.hud.ui.theme.InkDark

private const val PressScale = 0.96f
private const val HoldDurationMs = 700

/** Press-scale (~0.96) for custom tappable chrome. Pair with the same [interactionSource] on clickable. */
@Composable
fun Modifier.pressScale(
    interactionSource: MutableInteractionSource,
    pressedScale: Float = PressScale,
): Modifier {
    val pressed by interactionSource.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = if (pressed) pressedScale else 1f,
        animationSpec = tween(90),
        label = "pressScale",
    )
    return graphicsLayer {
        scaleX = scale
        scaleY = scale
    }
}

/** Ripple + press-scale for non-Material tappable surfaces. */
fun Modifier.pressable(
    enabled: Boolean = true,
    pressedScale: Float = PressScale,
    onClick: () -> Unit,
): Modifier = composed {
    val interactionSource = remember { MutableInteractionSource() }
    pressScale(interactionSource, pressedScale)
        .clickable(
            interactionSource = interactionSource,
            indication = LocalIndication.current,
            enabled = enabled,
            onClick = onClick,
        )
}

@Composable
fun PillPrimaryButton(text: String, modifier: Modifier = Modifier, onClick: () -> Unit = {}) {
    val interactionSource = remember { MutableInteractionSource() }
    Button(
        onClick = onClick,
        modifier = modifier
            .pressScale(interactionSource)
            .height(56.dp),
        shape = RoundedCornerShape(28.dp),
        colors = ButtonDefaults.buttonColors(containerColor = BrandGreen, contentColor = InkDark),
        interactionSource = interactionSource,
    ) {
        Text(text, fontWeight = FontWeight.Bold, fontSize = 16.sp)
    }
}

@Composable
fun PillSecondaryButton(
    text: String,
    modifier: Modifier = Modifier,
    onClick: () -> Unit = {},
) {
    val interactionSource = remember { MutableInteractionSource() }
    OutlinedButton(
        onClick = onClick,
        modifier = modifier
            .pressScale(interactionSource)
            .height(56.dp),
        shape = RoundedCornerShape(28.dp),
        border = BorderStroke(1.dp, InkDark.copy(alpha = 0.28f)),
        colors = ButtonDefaults.outlinedButtonColors(containerColor = Color.White.copy(alpha = 0.36f), contentColor = InkDark),
        interactionSource = interactionSource,
    ) {
        Text(text, fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
    }
}

/** Long-press-only action. Dashed stroke + hold-progress fill so the hold is obvious. */
@Composable
fun PillDashedHoldButton(
    text: String,
    modifier: Modifier = Modifier,
    onLongPress: () -> Unit = {},
) {
    val shape = RoundedCornerShape(28.dp)
    val interactionSource = remember { MutableInteractionSource() }
    val pressed by interactionSource.collectIsPressedAsState()
    var progress by remember { mutableFloatStateOf(0f) }

    LaunchedEffect(pressed) {
        if (pressed) {
            val start = withFrameMillis { it }
            while (true) {
                val frame = withFrameMillis { it }
                val p = ((frame - start).toFloat() / HoldDurationMs).coerceIn(0f, 1f)
                progress = p
                if (p >= 1f) {
                    onLongPress()
                    break
                }
            }
        } else {
            progress = 0f
        }
    }

    Box(
        modifier = modifier
            .pressScale(interactionSource)
            .height(56.dp)
            .clip(shape)
            .drawBehind {
                drawRoundRect(
                    color = Color.White.copy(alpha = 0.3f),
                    cornerRadius = CornerRadius(28.dp.toPx(), 28.dp.toPx()),
                )
                if (progress > 0f) {
                    drawRoundRect(
                        color = BrandGreen.copy(alpha = 0.55f),
                        size = Size(size.width * progress, size.height),
                        cornerRadius = CornerRadius(28.dp.toPx(), 28.dp.toPx()),
                    )
                }
                drawRoundRect(
                    color = InkDark.copy(alpha = 0.5f),
                    cornerRadius = CornerRadius(28.dp.toPx(), 28.dp.toPx()),
                    style = Stroke(
                        width = 1.5.dp.toPx(),
                        pathEffect = PathEffect.dashPathEffect(floatArrayOf(14f, 10f), 0f),
                    ),
                )
            }
            .clickable(
                interactionSource = interactionSource,
                indication = LocalIndication.current,
                onClick = {},
            ),
        contentAlignment = Alignment.Center,
    ) {
        Text(text, fontWeight = FontWeight.SemiBold, fontSize = 15.sp, color = InkDark)
    }
}

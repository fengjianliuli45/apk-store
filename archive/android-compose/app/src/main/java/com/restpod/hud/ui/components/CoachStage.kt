package com.restpod.hud.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.restpod.hud.ui.theme.BrandGreen
import com.restpod.hud.ui.theme.InkDark
import com.restpod.hud.ui.theme.TextMuted

/**
 * Mocks the "Unity / Coach Model Slot" from the Figma file. A real 3D coach avatar needs the
 * Unity engine, which can't be produced via the Android CLI toolchain — this stands in with a
 * silhouette capsule + floor ring, matching the mockup's own placeholder aesthetic.
 *
 * [ringProgress] (0f..1f), when non-null, draws the recovery countdown arc we added to the
 * Figma file's Rest/Rest-Last-5s states, so the floor ring doubles as a glanceable timer.
 *
 * [angleLabel] is the live "切换视角" caption (3D itself stays a drawn placeholder).
 */
@Composable
fun CoachStage(
    modifier: Modifier = Modifier,
    ringColor: androidx.compose.ui.graphics.Color = BrandGreen,
    ringProgress: Float? = null,
    angleLabel: String? = null,
) {
    Box(modifier = modifier.fillMaxWidth().height(420.dp), contentAlignment = Alignment.BottomCenter) {
        Canvas(modifier = Modifier.fillMaxWidth().height(420.dp)) {
            val capsuleWidth = size.width * 0.56f
            val capsuleLeft = (size.width - capsuleWidth) / 2f
            val capsuleTop = size.height * 0.04f
            val capsuleHeight = size.height * 0.78f

            drawRoundRect(
                brush = Brush.verticalGradient(listOf(InkDark.copy(alpha = 0.08f), InkDark.copy(alpha = 0.02f))),
                topLeft = Offset(capsuleLeft, capsuleTop),
                size = Size(capsuleWidth, capsuleHeight),
                cornerRadius = androidx.compose.ui.geometry.CornerRadius(capsuleWidth / 2f, capsuleWidth / 2f),
                style = Stroke(width = 1.5.dp.toPx()),
            )

            val ringWidth = size.width * 0.64f
            val ringHeight = ringWidth * 0.25f
            val ringLeft = (size.width - ringWidth) / 2f
            val ringTop = capsuleTop + capsuleHeight - ringHeight / 2f

            drawOval(
                color = ringColor.copy(alpha = 0.3f),
                topLeft = Offset(ringLeft, ringTop),
                size = Size(ringWidth, ringHeight),
                style = Stroke(width = 2.dp.toPx()),
            )

            if (ringProgress != null) {
                drawArc(
                    color = ringColor,
                    startAngle = -90f,
                    sweepAngle = 360f * ringProgress,
                    useCenter = false,
                    topLeft = Offset(ringLeft, ringTop),
                    size = Size(ringWidth, ringHeight),
                    style = Stroke(width = 6.dp.toPx()),
                )
            }
        }
        if (!angleLabel.isNullOrBlank()) {
            Text(
                text = angleLabel,
                color = TextMuted,
                fontWeight = FontWeight.SemiBold,
                fontSize = 12.sp,
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .padding(top = 12.dp),
            )
        }
    }
}

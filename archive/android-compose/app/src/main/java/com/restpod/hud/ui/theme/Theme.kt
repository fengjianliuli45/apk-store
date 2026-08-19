package com.restpod.hud.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val AppColorScheme = lightColorScheme(
    primary = InkDark,
    onPrimary = BrandGreen,
    secondary = BrandTeal,
    background = SurfaceBackgroundTop,
    surface = SurfaceCard,
    onBackground = InkDark,
    onSurface = InkDark,
)

@Composable
fun RestPodHudTheme(content: @Composable () -> Unit) {
    // Design is a single light, gradient-driven look — dark mode isn't part of the source file.
    MaterialTheme(
        colorScheme = AppColorScheme,
        typography = AppTypography,
        content = content,
    )
}

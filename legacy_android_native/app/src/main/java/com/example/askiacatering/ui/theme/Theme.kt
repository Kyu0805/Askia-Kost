package com.example.askiacatering.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val DarkColorScheme = darkColorScheme(
    primary = ClayOrange,
    secondary = HerbGreen,
    tertiary = RiverBlue,
    background = Ink,
    surface = Color(0xFF24313C),
    surfaceVariant = Color(0xFF32414C),
    onPrimary = Color(0xFF2F170C),
    onSecondary = Color(0xFFF3FFF4),
    onTertiary = Color(0xFFF1F7FB),
    onBackground = Color(0xFFF6F1EC),
    onSurface = Color(0xFFF6F1EC),
    onSurfaceVariant = Color(0xFFD7DDD4),
    outline = Color(0xFF8796A1)
)

private val LightColorScheme = lightColorScheme(
    primary = SunsetTerracotta,
    secondary = HerbGreen,
    tertiary = RiverBlue,
    background = Cream,
    surface = Color.White,
    surfaceVariant = WarmSurface,
    onPrimary = Color.White,
    onSecondary = Color.White,
    onTertiary = Color.White,
    onBackground = Ink,
    onSurface = Ink,
    onSurfaceVariant = MutedInk,
    outline = SoftOutline,
    secondaryContainer = Color(0xFFD8E7D9),
    onSecondaryContainer = Ink,
    tertiaryContainer = Color(0xFFD7E7EF),
    onTertiaryContainer = Ink
)

@Composable
fun AskiaCateringTheme(
    darkTheme: Boolean = false,
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}

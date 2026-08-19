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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.restpod.hud.ui.components.GradientScreen
import com.restpod.hud.ui.components.PillPrimaryButton
import com.restpod.hud.ui.theme.BrandGreen
import com.restpod.hud.ui.theme.InkDark
import com.restpod.hud.ui.theme.TextMuted

@Composable
fun OnboardingPhoneScreen(onGetCode: () -> Unit) {
    GradientScreen {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 24.dp, vertical = 48.dp),
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                LogoBadge(InkDark, size = 64)
                Spacer(Modifier.height(12.dp))
                Text("STOPWATCH", fontWeight = FontWeight.Bold, letterSpacing = 2.sp, fontSize = 12.sp, color = InkDark)
                Spacer(Modifier.height(4.dp))
                Text("用手机号开始训练", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = InkDark)
            }
            Spacer(Modifier.weight(1f))
            Text("+86  请输入手机号", color = TextMuted, fontSize = 16.sp, modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(16.dp))
                .background(Color.White)
                .padding(16.dp))
            Spacer(Modifier.height(16.dp))
            PillPrimaryButton("获取验证码", modifier = Modifier.fillMaxWidth(), onClick = onGetCode)
            Spacer(Modifier.height(24.dp))
            Text(
                "继续即代表同意《用户协议》和《隐私政策》",
                color = TextMuted,
                fontSize = 11.sp,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }
}

@Composable
fun OnboardingOtpScreen(onVerified: () -> Unit) {
    GradientScreen {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 24.dp, vertical = 48.dp),
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                LogoBadge(InkDark, size = 64)
                Spacer(Modifier.height(12.dp))
                Text("STOPWATCH", fontWeight = FontWeight.Bold, letterSpacing = 2.sp, fontSize = 12.sp, color = InkDark)
                Spacer(Modifier.height(12.dp))
                Text("已发送至 +86 138 0013 0000", color = TextMuted, fontSize = 13.sp)
            }
            Spacer(Modifier.height(32.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                repeat(4) {
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .height(56.dp)
                            .clip(RoundedCornerShape(14.dp))
                            .background(Color.White),
                    )
                }
            }
            Spacer(Modifier.height(16.dp))
            Text("30s 后可重新获取", color = TextMuted, fontSize = 13.sp, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
            Spacer(Modifier.weight(1f))
            PillPrimaryButton("验证并继续", modifier = Modifier.fillMaxWidth(), onClick = onVerified)
        }
    }
}

@Composable
private fun LogoBadge(color: Color, size: Int) {
    Box(
        modifier = Modifier
            .size(size.dp)
            .clip(RoundedCornerShape(18.dp))
            .background(color),
        contentAlignment = Alignment.Center,
    ) {
        Icon(Icons.Filled.Bolt, contentDescription = null, tint = BrandGreen)
    }
}

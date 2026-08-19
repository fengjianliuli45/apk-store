# apk-store

Stopwatch 休息舱 HUD 的私有备份仓库。

- `app-debug.apk`：可安装的 debug 包
- 其余为 Android 源码（Kotlin + Jetpack Compose）

```bash
./gradlew assembleDebug
```

饮食打卡已接成可跑通的本地切片（拍照 → 分析 → 记录 → 历史 / 食谱），餐次存在内存 ViewModel，识别是按时段轮换的假 AI。教练仍是绘制占位，不是 Unity 3D。

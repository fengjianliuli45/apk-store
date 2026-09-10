# mainleaf.top APK 测试分发

## 当前状态

最新发布：1.0.2+3，下载 `https://mainleaf.top/apk/stopwatch-1.0.2-3.apk`。126546029 bytes，SHA256 `17d016d36e26e8658e765ab3d617a0e5f021095a1cacfd1c07b879b055259915`，服务端一致、HTTPS 200，latest.json 已切换 build 3。122 项测试通过，模拟器覆盖安装/问卷/休息日/演示降级验证完成。旧 APK 保留；旧清单和页面分别备份为 latest.1.0.1-2.json.bak、index.1.0.1-2.html.bak。仍待 ARM64 真机和浏览器下载安装完整升级链验收。以下 1.0.1 记录为历史发布记录。

验证：Flutter 119 项测试通过、静态检查无问题；通用 Debug APK 构建并覆盖安装模拟器成功，系统确认 versionName=1.0.1/versionCode=2。SHA256 `25997F261CFFB9786FD0C54E7CF60A2572F5604A1F69F7AA98D06ED76606C627`。线上清单/下载/升级尚待服务器认证后联合验收。

应用 1.0.1+2 增加「设置 → 检查更新」：从 `https://mainleaf.top/apk/latest.json` 检查更高 build，用户点击下载后在系统浏览器获取 APK 并确认安装。不是静默安装，也不是 Google Play 更新接口。下载 URL 只允许 HTTPS/mainleaf.top/apk/。请求超时、无网络和无效清单均提示重试。

已部署至 `root@39.97.248.129:/var/www/mainleaf/apk/`。用户提供共享目录 SSH 密钥后认证成功；由于原目录 ACL 过宽，部署使用当前用户专属临时副本，未改变原密钥。APK 服务端 SHA256 与上述本地值一致，文件大小 154554021 bytes；下载页、APK、latest.json 均 HTTPS 200。模拟器 1.0.1 实际检查线上清单显示“当前已是最新版本（1.0.1）”。尚未执行未来更高版本的浏览器下载/系统覆盖升级整链测试。

## 待上传文件

- `flutter/build/app/outputs/flutter-apk/app-debug.apk` → `/var/www/mainleaf/apk/stopwatch-1.0.1-2.apk`
- `deploy/apk/index.html` → `/var/www/mainleaf/apk/index.html`
- `deploy/apk/latest.json` → `/var/www/mainleaf/apk/latest.json`

发布顺序：先确认目标目录和现有文件；保留已有版本 APK，先上传新版本并核验 SHA256/HTTPS 下载，最后以临时文件重命名方式更新 latest.json。仅操作 apk 子目录，不覆盖网站主页。建议 latest.json 返回 Cache-Control: no-cache；APK 内容类型 application/vnd.android.package-archive。

已上线下载页面：https://mainleaf.top/apk/ ，APK：https://mainleaf.top/apk/stopwatch-1.0.1-2.apk 。网站原主页未修改，发布文件位于独立 apk 子目录。

## 后续发版

先递增 pubspec 的 build number，再构建测试、上传版本化 APK，最后修改 latest.json 的 version/build/url/notes。不得在 APK 上传完成前发布清单。旧版 1.0.0 无更新入口，需要先手动安装一次 1.0.1。

当前构建为内部 Debug 测试版。Android 覆盖升级要求相同 applicationId 与签名证书、合适的版本号；跨机器构建可能使用不同 Debug 密钥。正式分发前必须选择并安全备份稳定的签名密钥，不提交私钥或密码到仓库。参考：https://developer.android.com/google/play/app-updates 。

此次仅提供 APK 分发，不部署规划后端，不上传本地用户数据库、缓存或 Unity 源工程。

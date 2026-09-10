# mainleaf.top APK 测试分发

## 当前状态

验证：Flutter 119 项测试通过、静态检查无问题；通用 Debug APK 构建并覆盖安装模拟器成功，系统确认 versionName=1.0.1/versionCode=2。SHA256 `25997F261CFFB9786FD0C54E7CF60A2572F5604A1F69F7AA98D06ED76606C627`。线上清单/下载/升级尚待服务器认证后联合验收。

应用 1.0.1+2 增加「设置 → 检查更新」：从 `https://mainleaf.top/apk/latest.json` 检查更高 build，用户点击下载后在系统浏览器获取 APK 并确认安装。不是静默安装，也不是 Google Play 更新接口。下载 URL 只允许 HTTPS/mainleaf.top/apk/。请求超时、无网络和无效清单均提示重试。

服务器 `root@39.97.248.129` 已连通，但现有 SSH 身份返回 `Permission denied (publickey,gssapi-keyex,gssapi-with-mic)`；等待用户提供本机私钥路径。尚未上传、未验证 HTTPS 下载和线上更新闭环。

## 待上传文件

- `flutter/build/app/outputs/flutter-apk/app-debug.apk` → `/var/www/mainleaf/apk/stopwatch-1.0.1-2.apk`
- `deploy/apk/index.html` → `/var/www/mainleaf/apk/index.html`
- `deploy/apk/latest.json` → `/var/www/mainleaf/apk/latest.json`

发布顺序：先确认目标目录和现有文件；保留已有版本 APK，先上传新版本并核验 SHA256/HTTPS 下载，最后以临时文件重命名方式更新 latest.json。仅操作 apk 子目录，不覆盖网站主页。建议 latest.json 返回 Cache-Control: no-cache；APK 内容类型 application/vnd.android.package-archive。

预期下载页面：https://mainleaf.top/apk/ ，预期 APK：https://mainleaf.top/apk/stopwatch-1.0.1-2.apk 。地址未部署前不可视为可用。

## 后续发版

先递增 pubspec 的 build number，再构建测试、上传版本化 APK，最后修改 latest.json 的 version/build/url/notes。不得在 APK 上传完成前发布清单。旧版 1.0.0 无更新入口，需要先手动安装一次 1.0.1。

当前构建为内部 Debug 测试版。Android 覆盖升级要求相同 applicationId 与签名证书、合适的版本号；跨机器构建可能使用不同 Debug 密钥。正式分发前必须选择并安全备份稳定的签名密钥，不提交私钥或密码到仓库。参考：https://developer.android.com/google/play/app-updates 。

此次仅提供 APK 分发，不部署规划后端，不上传本地用户数据库、缓存或 Unity 源工程。

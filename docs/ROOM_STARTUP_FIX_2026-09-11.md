# 1.0.4+5 启动崩溃修复

1.0.3 的匹配 R8 映射 c47eef 对应 usage.txt 明确列出 WorkDatabase_Impl 的 public void <init>() 被裁剪；旧 DEX 无该构造方法。Room 用反射创建数据库实现类，现有 consumer rule 仅保留类，未显式保留构造方法。

在 android/app/proguard-rules.pro 增加 RoomDatabase 子类与公开无参构造方法保留规则，并由 release.proguardFiles 引用，保持其他 R8 优化。版本递增 1.0.4+5。

验证：修复 ARM64 APK DEX 中 WorkDatabase_Impl 包含 PUBLIC CONSTRUCTOR <init>()V，usage 不再列出该构造方法。另构建含 ARM64/x64 Flutter 的最终 Release APK，本机 Stopwatch_API_35 模拟器通过 adb install -r 保留数据覆盖安装，冷启动 Status ok，进程存活，日志显示 WorkManager 初始化，UI 层级包含 STOPWATCH、READY、开始训练及原有 11 组计划。无连接真机，未完成荣耀手机或 Unity 真机训练验证。

最终 APK outputs/room-fix-1.0.4-5/stopwatch-1.0.4-5.apk，58916986 bytes，SHA256 CA2E1212A25FE9FEBC825995492211D4DF998DC57E1519CB91DB965D6C5A10CC。对应 mapping/configuration/usage 已归档至同目录 r8。与旧版签名相同：271d3a901e82ae13378621155e665b1e69b862ee05ed49f1226b31a8a2608c46。

按既有服务器分发授权发布 https://mainleaf.top/apk/stopwatch-1.0.4-5.apk，服务器哈希一致、公网 HTTPS 200、latest.json build 5。旧 APK 保留，更新清单和下载页备份 latest.before-1.0.4-5.json.bak、index.before-1.0.4-5.html.bak。因 1.0.3 无法进入更新页，用户需浏览器下载覆盖安装，无需卸载或清除数据。未推送 Git 远端。

下一步：荣耀手机确认冷启动后，再继续 ARM64 Unity 完整训练验收。

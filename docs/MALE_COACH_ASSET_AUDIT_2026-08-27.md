# 男性教练资产可用性审计（2026-08-27）

> 层级：L2 现行实施说明
> 范围：Unity P0 两动作训练闭环
> 结论：**可用于 P0 工程验证。** 授权口径已于 2026-08-30 澄清：Mixamo 官方允许把动作嵌入商业游戏成品，无需另购授权；男性模型由用户用 Neural4D 自生成，商用取决于生成时是否为付费档。缺的是条款/生成记录归档，不是另买一份商业授权。Unity 真机复验仍待完成。

## 1. 核实范围

交接文档给出的目录已在本机找到，实际路径为：

`D:\Codex_pro\Stopwatch\repo-main\stopwatch-main\assets\body-model\mixamo\male-coach-v1`

正式 Unity 工程位于：

`D:\Codex_pro\Stopwatch\repo-main\stopwatch-main\unity\StopwatchUnity`

## 2. 可用性清单

| 检查项 | 状态 | 证据与说明 |
| --- | --- | --- |
| 原始角色模型 | 通过 | `stopwatch-male-coach-mixamo-rigged-v1.fbx` 存在，11,634,288 bytes。 |
| 可编辑源文件 | 通过 | Blender 主文件与 `.blend1` 备份均存在。 |
| 骨骼结构 | 通过 | 原始 FBX 可检出 66 个 Mixamo 命名节点；Unity 正式版 `StopwatchMaleCoach_MixamoRigged_v2.fbx` 可检出 65 个 Mixamo 命名节点，包含 Hips、Spine、头部、四肢、手指和脚趾链。 |
| Unity Humanoid 导入 | 通过（静态证据） | 模型 `.meta` 为 `animationType: 3`、`avatarSetup: 1`，自动生成人形 Avatar。 |
| 正式场景引用 | 通过 | `SquatTraining.unity` 通过 GUID `494bd517e4c4faf48ad23d73aa9127d8` 引用 65 骨新版角色。 |
| 深蹲动作 | 通过（静态证据） | `bodyweight_squat.fbx` 已进入动作目录和 Motion Catalog，循环开启。 |
| 俯卧撑动作 | 通过（静态证据） | `push_up.fbx` 已进入动作目录和 Motion Catalog，循环开启并使用地面展示模式。 |
| 根运动约束 | 部分通过 | 两个动作均保留 XZ 原位置；Y 设置与生成器目标存在差异，需 Unity 复验是否仍会漂移或离地。运行时已有 grounding 逻辑兜底。 |
| 材质与贴图 | 通过（工程存在性） | Unity Coach 目录包含基础色、金属度、粗糙度和两张 JPG 贴图；尚未做真机渲染和内存审计。 |
| 视觉姿态 | 通过（有限证据） | `mixamo-squat-test-frame20.png` 显示角色可完成深蹲姿态，未见明显骨骼爆裂；该截图不能代替全周期动作检查。 |
| 角色切换接口 | 通过 | `CoachAvatarSwitcher` 已支持男/女 prefab、身高归一化、控制器/HUD 重绑定和缺失女性模型时回退男性。 |
| 女性角色 prefab | 未完成 | 工程中未发现女性教练模型或 prefab，`femaleCoachPrefab` 尚无资产可绑定。 |
| 授权与来源 | **已澄清（2026-08-30）** | 男性模型：用户 Neural4D 自生成。动作：Mixamo 免费库。Adobe Mixamo FAQ 允许免版税用于个人/商用/游戏成品，禁止把原始 FBX 当素材包再卖。Neural4D：付费订阅（Pro/Enterprise）生成可商用且无需署名；免费档仅限自用；Trial 与社区 Showcase 另论。目录里尚无订阅/生成页或条款快照，建议补进 `docs/licenses/`，**不再把「缺少商业授权」当作发布硬阻塞**。 |
| Unity 编辑器复验 | 部分通过 | 项目要求 Unity `6000.5.4f1`，本机版本匹配；Unity Personal 已激活，Activity 入口版 Android Library 已由 Editor 成功导出。Humanoid Avatar、两动作完整循环、接地和材质仍缺真机目视复验。 |

## 3. 文件指纹

- 正式男性模型：`F445E1A4D5B37D1B966709D943756322541E831251654085ACB05D5D5106BF67`
- 深蹲动作：`AD13BF4DEC339C68B31A72203EA37C8293557EADC55C8ED12DA211878FBC46ED`
- 俯卧撑动作：`F1C4C271EA41454381853751FF35F742C3837F68B00DCC21B9B5B385FFAD9EC6`

以上均为 SHA-256，可用于后续复制、导入和交接一致性核对。

## 4. P0 决定

1. 继续使用 `StopwatchMaleCoach_MixamoRigged_v2.fbx`，禁止回退到旧 23 骨模型。
2. P0 仅开放 `bodyweight_squat` 与 `push_up`；Motion Catalog 其余缺失动作不扩大当前范围。
3. 不再因「未购买商业授权」禁止应用商店或外部分发。发布前确认 Neural4D 生成时为付费档（非 Free/Trial），并把 Neural4D 订阅/生成记录与 Mixamo 条款快照存入 `docs/licenses/`。
4. Unity Personal 已激活且 Android Library 已导出；仍必须完成 Humanoid Avatar 有效性、两动作完整循环、脚底贴地、材质和 Android 真机性能复验。

## 5. 女性教练补齐方案

当前不直接采购或生成资产。候选女性角色必须同时满足以下门槛后才能进入工程：

- 来源可追溯，并保存生成/下载记录与当时适用的使用条款（Neural4D 记套餐档位，Mixamo 记官方 FAQ 快照）。
- 中性 A/T Pose，全身无遮挡；与男性角色使用同一 65 骨 Mixamo 兼容命名或可稳定映射到 Unity Humanoid。
- 独立角色 FBX，不内嵌动作；材质采用与男性角色一致的移动端预算与 PBR 通道约定。
- 导入后直接复用现有 `bodyweight_squat`、`push_up`，不复制两套动作文件。
- 通过 1.72 m 归一化、正面/侧面轮廓、手脚接地、深蹲膝髋、俯卧撑肩腕和全周期穿模检查。
- 制作为独立 prefab 后绑定 `femaleCoachPrefab`；验证切换时训练状态、动作进度、HUD 和镜头不重置。
- Android 真机连续切换和两动作循环无异常，再决定是否解冻“女性教练首发”。

## 6. 下一步验收命令

在项目根目录执行：

```powershell
& 'C:\Program Files\Unity\Hub\Editor\6000.5.4f1\Editor\Unity.exe' `
  -batchmode -nographics -quit `
  -projectPath . `
  -executeMethod Stopwatch.Editor.ExerciseMotionCatalogBuilder.Validate `
  -logFile -
```

当前 `Validate` 只报告覆盖率，不会因缺失动作返回失败码。P0 验收应以两条必需绑定存在并完成目视/真机复验为准。

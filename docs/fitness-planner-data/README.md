# 健身规划引擎 · 动作 + GIF 数据

GIF 来源：`hasaneyldrm/exercises-dataset`（⭐20.4k，1324 动作）
本地数据集路径：`/tmp/exercises-dataset/videos/`（GIF 命名 `{id}-{media_id}.gif`）

## 文件说明

### base_actions.json — 精简基础动作表（77 动作）
每肌肉 × 居家/健身房两档，胸/腹已细分肌群。

字段：`grp`（肌肉）· `sub`（细分，无则 null）· `loc`（home/gym）· `name`（英文）· `equipment`（器械）· `gif`（数据集 GIF 文件名）

**胸细分**：上胸 / 中胸 / 下胸
**腹细分**：上腹 / 下腹 / 腹斜

各肌肉覆盖：
- ✅ 胸 / 背 / 肩 / 二头 / 三头 / 股四头 / 腘绳肌 / 小腿 / 核心 / 腹斜 / 斜方 / 下背 / 前臂
- ⚠️ 臀：仅健身房档（纯自重臀桥数据集收录少，居家可徒手臀桥/驴踢腿）

### exercises_108_gif_map.json — 现有 108 个手工库 → GIF 映射
现有引擎库（`fitness-planner/data/exercises.json`，108 动作）到数据集的 GIF 匹配结果。

**匹配率：95/108（88%）**
- ✅ 95 个已精确匹配到数据集 GIF（动作+器械对齐）
- ❌ 13 个数据集确实没有，需 minimax 生成或替代：
  cable_fly 绳索飞鸟 · pec_deck 蝴蝶机夹胸 · face_pull 面拉 · chest_supported_row 俯卧划船 · single_leg_glute_bridge 单腿臀桥 · dumbbell_curl 哑铃弯举 · french_press 仰卧臂屈伸 · bird_dog 鸟狗式 · cable_woodchop 绳索砍柴 · box_squat 箱式深蹲 · toes_to_bar 脚触杠 · kettlebell_clean 壶铃翻举 · suitcase_carry 手提箱行走

## GIF 跑 minimax-h3
每个动作的 GIF 文件名即生成入口，直接喂本地 minimax-h3：
`/tmp/exercises-dataset/videos/{id}-{media_id}.gif`
生成完后将新视频路径回填 gif 字段。

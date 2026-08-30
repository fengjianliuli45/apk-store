# base_actions.json 复核 + 优化建议（2026-08-30）

联网核对了循证依据（见文末来源）。结论：数据集自动抽取的这版有系统性问题，需要一次人工 + 证据过滤。

---

## 一、主要问题

1. **居家档混进了大量增强式（plyo）动作** —— 不是增肌动作，CNS 疲劳高、不适合按容量堆。
   - 股四头 home：`bodyweight drop jump squat`、`box jump down with one leg` ❌
   - 小腿 home：`jump rope`、`box jump down` ❌
   - 胸 home：`incline push up depth jump` ❌

2. **"居家"其实需要器械** —— 违背"零器械也能练"的初衷。
   - 肩 home：`exercise ball pike push up`（要健身球）
   - 腘绳肌 home：`barbell good morning`（要杠铃）
   - 前臂 home：`farmers walk [dumbbell]`（要哑铃）

3. **居家选项太少，轮换无池可选**（引擎需要每肌群 home ≥3 才能轮换）
   - 二头 home 1 · 下背 home 1 · 背 home 2 · 三头 home 2 · 腹斜 home 2

4. **臀完全没有居家档**（只有 gym），且 gym 档也偏（缺杠铃臀桥 / 臀推）。

5. **动作难度错配**：肩 home 给了 `handstand push-up`（倒立俯卧撑）—— 新手根本做不了。

6. **归错肌群**：腘绳肌 home 的 `glute bridge march` 其实主要练臀。

---

## 二、每肌群：删 / 加（居家档以「纯自重 + 弹力带 + 一根单杠(可选)」为界）

证据：自重 / 弹力带动作在**接近力竭**时，肌肉蛋白合成与负重训练等效（Nunes 2019；ISJC 2024）。
进阶靠：加次数 → 换更难变式 → 缩间歇（House of Hypertrophy / PlayThenics 综述）。

| 肌群 | 删（居家） | 加（居家，纯自重/弹力带） | gym 档补充 |
|---|---|---|---|
| **胸·上** | incline push up depth jump | 弹力带下上斜飞鸟、跪姿上斜俯卧撑 | — |
| **胸·中** | — | 弹力带卧推、钻石俯卧撑（也算三头） | machine chest press |
| **胸·下** | — | 双杠臂屈伸（也可 gym）、脚高俯卧撑 | — |
| **背** | — | 弹力带高位下拉、弹力带俯身划船、弹力带直臂下压、引体/反手引体（有单杠）、俯身 W 收缩 | chest-supported row、single-arm DB row |
| **肩** | exercise ball pike push up、handstand push-up | 弹力带过顶推举、弹力带侧平举、弹力带前平举、弹力带面拉/后束飞鸟、派克俯卧撑（前束，自重可进阶到倒立） | DB 后束飞鸟、machine shoulder press、cable 侧平举 |
| **二头** | — | 弹力带锤式弯举、反手引体（有单杠）、毛巾/背包弯举、等长靠墙弯举 | cable curl、incline DB curl |
| **三头** | — | 弹力带下压、弹力带过顶臂屈伸、窄距俯卧撑 | cable pushdown、DB 过顶臂屈伸 |
| **股四头** | drop jump squat、box jump down | 自重深蹲、分腿蹲、后撤步箭步、保加利亚分腿蹲（进阶）、靠墙静蹲、台阶登阶（有台阶/椅子） | hack squat、leg press、leg extension |
| **腘绳肌** | barbell good morning、glute bridge march（→归臀） | 单腿罗马尼亚硬拉（自重/背包）、滑毯/毛巾勾腿、北欧挺（离心，可扶物借力）、腘绳肌 walkout | 俯卧腿弯举机、坐姿腿弯举 |
| **臀** | （home 现在为空） | 臀桥、单腿臀桥、自重臀推（上背靠沙发）、弹力带臀推、蛙泵、弹力带外展（贝壳式/侧向走）、弹力带后踢 | 杠铃臀推、杠铃臀桥、cable kickback、髋外展机 |
| **小腿** | jump rope、box jump down | 站姿提踵（自重）、单腿站姿提踵、坐姿提踵（膝上压背包）、驴式提踵 | 站姿/坐姿提踵机 |
| **核心** | bridge - mountain climber（偏有氧） | 平板、侧平板、死虫、鸟狗、空心支撑（hollow hold）、悬垂举腿（有单杠）、腹轮（有腹轮） | cable crunch、悬垂举腿 |
| **腹斜** | — | 侧平板、俄罗斯转体、侧卷腹、Pallof press（弹力带）、伐木（弹力带） | cable 侧屈、cable 俄罗斯转体 |
| **斜方** | — | 弹力带耸肩、弹力带直立划船、弹力带 Y 字、弹力带面拉 | 杠铃/哑铃耸肩、直立划船 |
| **下背** | — | 超人静态保持、鸟狗、反向挺髋（沙发/床沿）、弹力带早安、自重背屈伸 | 罗马椅背屈伸、山羊挺身 |
| **前臂** | farmers walk [dumbbell] | 弹力带腕屈/腕伸、单杠悬垂、毛巾悬垂、书/盘捏握、背包农夫行走 | 杠铃/哑铃腕弯举、反向弯举、腕滚轮 |

---

## 三、徒手进阶阶梯（喂 P0 #2「徒手进阶模型」）

引擎对自重动作的进阶，不再只写"按次数递进"，改成明确阶梯：**次数达上限 & RIR≤1 → 换下一级变式，从下一级的次数下限重来。**

| 模式 | 阶梯（易 → 难） |
|---|---|
| 水平推（胸） | 上斜俯卧撑 → 跪姿俯卧撑 → 标准俯卧撑 → 宽距/钻石 → 脚高俯卧撑 → 弓箭手俯卧撑 → 单臂俯卧撑进阶 |
| 垂直推（肩） | 派克俯卧撑（浅） → 派克俯卧撑（深/脚高） → 靠墙倒立撑（部分幅度） → 倒立撑 |
| 垂直拉（背） | 斜身引体（高） → 斜身引体（低/脚高） → 离心引体 → 反手引体 → 正手引体 → 加重/弓箭手引体 |
| 水平拉（背） | 弹力带划船（低阻） → 弹力带划船（高阻） → 桌下反式划船（膝屈） → 反式划船（腿直） → 反式划船（脚高） |
| 深蹲（股四头） | 自重深蹲 → 分腿蹲 → 后撤步箭步 → 保加利亚分腿蹲 → 高抬保加利亚 → 手枪蹲进阶 |
| 髋铰链（腘绳/臀） | 臀桥 → 单腿臀桥 → 自重臀推 → 单腿罗马尼亚（自重） → 单腿罗马尼亚（背包） → 北欧挺（离心） |

每级"变式难度"= 我们 schema 里新增一个 `progression_rank`（同 movement_pattern 内 1,2,3…），引擎按它取下一级。

---

## 四、器械词表变更

`equipment_required` 词表新增：
- **`band`（弹力带）** —— 已同意
- （可选）`pull_up_bar`（单杠 / 门上引体杆）—— 现在自重拉类默认"任何人都能做"，其实需要单杠。加了它才能按"用户有没有单杠"过滤。建议加。

数据集里的 `body weight` → 我们的 `bodyweight`；`resistance band` / `band` → `band`；`stability ball` → 归 `gym`（或直接不收该动作的居家档）。

---

## 五、落地方式（等这份定稿后）

1. 按上表出一版修订的 `base_actions.json`（每肌群 home ≥3、gym ≥3，全部过 plyo / 真居家 / 难度 三道筛）。
2. 转成 `exercises.json` schema：中文名、`movement_pattern`、`compound`、`skill_level`、`primary/secondary_muscles`（引擎词表）、`form_cues`、`progression_rank`。
3. `exercises.json` 净增约 35–45 条；`equipment_required` 加 `band` / `pull_up_bar`。
4. `library.query` 加"有器械时降权纯自重动作"排序键（解决轮换轮到俯卧撑的问题）。
5. GIF 回填 `video_url`（用 `exercises_108_gif_map.json`，95 条；新增动作按名字再匹配一轮）。

---

## 来源

- Nunes et al. 2019 / ISJC Sep 2024 — 自重接近力竭 vs 负重，肥大等效
- Frontiers Physiol 2025 1542334 — 臀大肌肥大系统综述（髋推 / 髋铰链 + 带阻外展）
- House of Hypertrophy / PlayThenics — 自重训练肥大与进阶策略综述
- Sci Rep 2023 s41598-023-40319-x — 渐进自重深蹲 vs 杠铃深蹲，力量/肥大
- Kassiano 2022 (PMID 35438660) — 系统性动作变化（承接任务 D）

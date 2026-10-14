# 音频素材全量换源（三方可商用站点重新取材）设计

> 创建：2026-10-13
> 状态：已与用户对齐范围 / 来源池 / 兜底策略 / 执行方案
> 关联：`docs/audio-assets-license.md`（现有合规清单）、`docs/audio-resources-research.md`（来源调研）

---

## 一、背景与目标

声栖声音库共 **30 条** `Sound`（`snapp/lib/data/seed_data.dart`），当前资产状态：

| 类别 | 数量 | 明细 |
|---|---|---|
| Mixkit 真实录音（2026-10-12 批次） | 20 | rain, wind, stream, ocean-wave, campfire, forest, fan, drizzle, thunder, tide, waterfall, birdsong, cricket, mountain-brook, cafe, typewriter, sleeper-train, kitchen, valley-echo, radio-noise |
| 算法合成 WAV（`tool/gen_audio.dart`） | 5 | white-noise, pink-noise, brown-noise, red-noise, train |
| 无任何资产（SimulatedAudioEngine 静音模拟） | 5 | nightingale, floor-heating, blue-noise, violet-noise, grey-noise |

**目标**：全部 30 条逐条重新选音、换新素材文件，来源池限三方可商用站点；换源后声音库不再依赖项目自造的合成资产（除确认无法取得第三方素材的彩色噪音外）。

## 二、用户已确认的关键决策

1. **替换范围**：全部 30 条重新找源（含现有 20 条 Mixkit 录音，逐条换新文件）。
2. **来源池**：因不引入 Freesound（用户不注册 API Key），现实合规来源为：
   - **Mixkit**（主力，直链可批量下载，License 已验证）
   - **Wikimedia Commons**（补缺口，公开 API 按授权过滤，仅取 CC0/公有领域）
   - **FreePD / Kenney / OpenGameArt**（仅兜底）
   - 明确排除：Pixabay（无 Key 且页面爬取违反 ToS）、Freesound（无 Key 不可用）、BBC Sound Effects（授权不商用）。
3. **彩色噪音兜底**：蓝/紫/灰噪（及任何声音）找不到可商用第三方素材时，保留现状（合成 WAV 或静音模拟），并在合规清单登记原因。
4. **执行方案**：A（候选清单审批表 + 脚本化流水线）——先出 30 条候选表给用户审批，批准后才批量下载与替换。

## 三、来源与检索策略

### 3.1 Mixkit（主力）

- 通过网页检索枚举分类页（rain / wind / water / waves / fire / forest / birds / insect / train / kitchen / appliance / restaurant / typewriter / radio 等）建立候选池。
- 素材直链模式稳定：`https://assets.mixkit.co/active_storage/sfx/<sfx_id>/<sfx_id>.wav`，无需登录。
- 授权：Mixkit License（https://mixkit.co/license/#sfxFree）——可免费商用、免署名、允许修改后并入作品；**禁止**将原始文件作为独立素材再分发/转售。

### 3.2 Wikimedia Commons（补缺口）

- 公开 API（无需凭证）检索，仅取 `CC0 / Public domain` 授权文件；CC-BY 一律不用（保持免署名）。
- 预期承担：nightingale（夜莺）、彩色噪音信号文件（白/粉/褐/棕噪在声学条目有 PD 示例文件）、floor-heating（地暖→低频嗡鸣/暖气运转实录）。

### 3.3 选音标准（逐条执行）

1. **语义匹配**：与声音的中文名、描述、场景标签一致（如「潮汐」选礁石潮汐带而非沙滩海浪）。
2. **稳态可循环**：环境底噪类选稳态段，无突发事件（门响、人声特写、雷点除外——thunder 本身允许雷声事件）。
3. **原始时长 ≥30s 优先**（保证 20s 循环 + 2s 交叉淡化有余量）；不足则按素材实际长度收缩循环时长（先例：radio-noise 11s→10s）。
4. **授权免署名**：CC0 / Mixkit License / Public domain。
5. 每条准备 1 主选 + 备选，主选审批被拒或下载失败时顺延。

## 四、处理流水线（与现有 20 条完全一致）

```
下载原始文件
→ ffmpeg 截取 ≤20s 稳态段
→ 首尾 2s 交叉淡化（无缝循环）
→ 合并单声道
→ loudnorm 归一 -20 LUFS
→ 44.1kHz / 16bit / mono WAV
→ 覆写 snapp/assets/audio/<id>.wav
```

- 输出规格与现有资产一致，`audioAssetFor(id)` 映射逻辑不变。
- 处理后逐条 ffprobe 校验（采样率 / 位深 / 声道 / 时长）。

## 五、代码与文档接线

| 变更点 | 内容 |
|---|---|
| `snapp/lib/data/seed_data.dart` | 换成真实素材的 `train`、`white/pink/brown/red-noise` 从 `generatedAudioIds` 移入 `recordedAudioIds`；`nightingale`、`floor-heating` 补入 `recordedAudioIds`；蓝/紫/灰噪未取得素材则维持现状不动；`tool/gen_audio.dart` 保留（继续承担保留合成的彩噪） |
| `docs/audio-assets-license.md` | 30 条全部重新逐条登记：App 声音 id / 来源站点 / 素材名 / 素材 id / 授权类型 / 原始时长 / 循环时长 / 来源直链 / 下载日期 |
| `docs/audio-resources-research.md` | 更新状态节（全量换源完成、来源结构变化） |
| `AGENT.md` | 更新「已知待办」音频素材条目与「最后更新」日期 |

- `pubspec.yaml` 的 `assets/audio/` 为目录级声明，无需改动；OHOS rawfile 产物随构建重新生成。

## 六、合规留痕

- 每条素材在 `docs/audio-assets-license.md` 登记：来源站点、素材名、素材 id、授权类型、来源 URL、下载日期。
- Mixkit License 条款 URL、Commons 文件授权信息随表留档，供上架前备查。
- 应用内使用属于「修改后并入作品」，符合两家授权；不做原始文件再分发。

## 七、执行流（两阶段 + 门禁）

```
阶段一（取材与审批）
  1. 枚举来源分类页 / Commons API 检索，建立候选池
  2. 逐音选音，产出候选清单表（30 行：声音 id → 素材名/来源/授权/原始时长/试听或直链/循环时长预估）
  3. 【门禁】用户审批清单 → 有异议逐条换候选重出
阶段二（下载与替换）
  4. 脚本批量下载主选素材（失败自动回退备选并记录）
  5. ffmpeg 统一处理 → 覆写 assets/audio/<id>.wav
  6. 更新 seed_data.dart / 合规清单 / 调研报告 / AGENT.md
  7. 验证：flutter analyze 零错误 + flutter test 全绿 + ffprobe 抽检
  8. 输出结果报告（含：任何保留合成/静音的声音及原因）
```

## 八、验收口径

- [ ] 30 条候选清单经用户审批通过
- [ ] `snapp/assets/audio/` 下 WAV 与清单一致，ffprobe 校验全部 44.1kHz/16bit/mono
- [ ] `seed_data.dart` 的 `recordedAudioIds` 与实际文件一一对应（回归测试通过）
- [ ] `docs/audio-assets-license.md` 逐条可追溯（来源/授权/日期/直链）
- [ ] `flutter analyze` 零错误、`flutter test` 全绿
- [ ] 结果报告明确列出保留合成/静音的条目及原因

## 九、风险与对策

| 风险 | 对策 |
|---|---|
| 夜莺等自然音 Commons 录音音质参差 | loudnorm 统一响度；审批表阶段给出候选，用户可否决 |
| 地暖类素材极稀少 | 以低频嗡鸣/暖气运转实录替代；无合适素材则维持静音模拟并登记 |
| Mixkit 分类页无官方 API，枚举靠页面检索 | 仅做检索与直链下载（人工粒度），不做高频批量抓取；逐条登记来源，必要时改人工下载 |
| 彩噪网上无可商用「录音」 | 用户已批准：保留合成，登记原因（数学定义信号，合成即正解） |
| 个别素材下载失败/过短 | 备选顺延；仍失败则该条保留现状并列入报告 |

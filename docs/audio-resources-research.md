# 白噪音素材来源与授权调研报告

> 声栖 · 音频资源调研
> 创建：2026-09-28
> 状态：第一批已落地（2026-10-12，Mixkit 20 条真实采录音，逐条登记见 `docs/audio-assets-license.md`；缺口：nightingale 与蓝/紫/灰噪音）

---

## 一、背景与目标

优化声栖项目中的白噪音音频资源，并为「公开可商用的白噪音素材」调研可行的获取渠道与授权合规方案。

**项目声音资源现状**（Flutter 主工程 `snapp/`）：

- 声音库共约 40 条 `Sound`，但真正有音频资产（WAV）的仅 **12 条**，由 `snapp/tool/gen_audio.dart` 算法合成（44.1kHz / 16bit / mono，10s 循环，~882KB/条）：`white/pink/brown/red-noise`、`rain`、`wind`、`stream`、`ocean-wave`、`campfire`、`forest`、`fan`、`train`。
- 其余近 30 条**无声**，走 `SimulatedAudioEngine`（静音模拟），包括：

  - 自然类：`drizzle`(细雨)、`thunder`(雷雨)、`tide`(潮汐)、`waterfall`(瀑布)、`birdsong`(鸟鸣)、`cricket`(虫鸣)、`mountain-brook`(山涧)、`nightingale`(夜莺)
  - 城市/环境类：`cafe`(咖啡厅)、`typewriter`(打字机)、`sleeper-train`(火车卧铺)、`kitchen`(厨房)、`valley-echo`(空谷回响)
  - 合成类：`blue`/`violet`/`grey`/`radio-noise`

**优化点**：
1. 补齐上述真实采录音的音频；
2. 已合成的 12 条中，雨/风/溪流/海浪/篝火/森林/风扇/列车等「伪自然音」听感偏假，可用真实录音升级。

---

## 二、公开可商用来源清单

### A. CC0 / 公有领域（最省心：可商用、免署名、可自由修改）

| 站点 | 覆盖度 | 授权 | 获取方式 |
|---|---|---|---|
| [Freesound](https://freesound.org/) | 73 万+，自然/环境很全 | 逐条可选 **CC0 / CC-BY / CC-BY-NC** | 官方 **API v2**（search + OAuth2 下载）；筛 `license=Creative Commons 0` 即可商用免署名 |
| [FreePD](https://freepd.com/) | 音乐为主，自然音较少 | CC0 | 直接下载 |

> Freesound 是自然类白噪音（雨/溪流/鸟鸣/虫鸣/海浪）最匹配的 CC0 来源；`GET /apiv2/search/` 支持按授权与字段过滤，适合脚本化筛选下载。

### B. 站内许可证（免费可商用、免署名，无公开批量 API）

| 站点 | 覆盖度 | 授权要点 |
|---|---|---|
| [Pixabay](https://pixabay.com/) | 20 万+ 音效（含 1950s 打字机、鸟鸣、咖啡厅等稀有项） | **Pixabay Content License**：可商用、免署名；**禁止**原样把文件当独立素材再分发/出售 |
| [Mixkit](https://mixkit.co/free-sound-effects/) | 3000+，有 ocean/rain/wind/bird/insect 分类 | **Mixkit Free License**：个人+商用、免署名；禁止原样再售/再分发 |

### C. 需署名 / 有条件（可用但不推荐省心）

- **Freesound CC-BY**：可商用但必须署名作者，长期维护成本高。
- **Zapsplat / Sounds+ / Sample Focus / SoundJay**：免费档多为 MP3 或有下载额度、部分要求署名（Zapsplat 免费档需署名）。

---

## 三、授权对比与本项目推荐

| 需求音 | 首选来源 | 备选 |
|---|---|---|
| 鸟鸣 / 夜莺 / 虫鸣 | Freesound CC0（自然类极全） | Mixkit bird/insect |
| 细雨 / 雷雨 / 瀑布 / 潮汐 / 山涧 | Freesound CC0 | Pixabay |
| 咖啡厅 / 打字机 / 厨房 | **Pixabay**（稀有人声/机械类强） | Freesound CC0 |
| 火车卧铺 / 风扇 / 收音机 | Mixkit / Pixabay | Freesound CC0 |
| 蓝/紫/灰噪（本就该合成） | 保留算法合成（升级 `gen_audio.dart` 即可，免授权） | — |

---

## 四、「爬取」合规风险

1. **有合规接口的**：Freesound（官方 API v2）最适合批量、按 CC0 筛选、脚本化下载；**建议走 API 而非抓 HTML 页面**。
2. **无公开 API 的**：Pixabay / Mixkit 用 HTML 爬虫**批量**下文件通常违反其 ToS（尤其 Pixabay 明确限制自动化采集与再分发），有账号封禁/侵权风险。
3. **规避结论**：
   - 批量 / 脚本化 → 官方 **API**（Freesound）或开发者接口；
   - 站点无 API 且素材量少 → **人工手动下载**少量文件（几到几十条）在 ToS 允许范围内更稳妥；
   - **任何来源都须留存**：素材授权快照 / 下载链接 / 授权截图，供上架前合规备查。

---

## 五、落地建议（后续执行时验收口径）

1. **补齐真实录音**：从 Freesound CC0 + Pixabay 人工/API 获取约 14 条缺失音轨（`birdsong`、`cricket`、`cafe`、`typewriter`、`drizzle`、`thunder`、`tide`、`waterfall`、`sleeper-train`、`kitchen`、`valley-echo`、`mountain-brook`、`nightingale`、`radio-noise`）。
2. **升级伪自然音**：替换 `rain`/`wind`/`stream`/`ocean-wave`/`campfire`/`forest`/`fan` 为真实录音（CC0）。
3. **技术接线**：
   - 文件统一转 `44.1kHz / 16bit / mono WAV` 循环；
   - 写入 `snapp/assets/audio/`；
   - 扩展 `snapp/lib/data/seed_data.dart` 的 `generatedAudioIds`（或新增 `recordedAudioIds`）；
   - 同步 `pubspec.yaml` 的 `assets/audio/` 声明与 `ohos` 的 rawfile 构建产物。
4. **合规留存**：为每条素材单独登记来源 URL、作者、授权类型、获取日期。
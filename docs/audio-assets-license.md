# 音频素材合规清单（真实采录音）

> 生成日期：2026-10-12；来源：Mixkit（https://mixkit.co）
>
> **许可**：Mixkit License（https://mixkit.co/license/#sfxFree）——可免费商用、免署名、
> 允许修改后并入作品；**禁止**将原始文件作为独立素材再分发/转售。
> 本清单为上架前合规备查的逐条登记。

统一处理：下载原始 WAV → 截取 ≤20s → 尾部-头部 2s 交叉淡化（无缝循环）→ 单声道 →
响度归一（loudnorm -20 LUFS）→ 44.1kHz / 16bit / mono WAV，输出 snapp/assets/audio/<id>.wav。

| App 声音 id | Mixkit 素材 | sfx id | 分类页 | 原始时长 | 循环时长 | 文件直链 |
|---|---|---|---|---|---|---|
| drizzle | Light rain looping | 1249 | https://mixkit.co/free-sound-effects/rain/ | 96.0s | 20.0s | https://assets.mixkit.co/active_storage/sfx/1249/1249.wav |
| thunder | Thunderstorm and rain loop | 2402 | https://mixkit.co/free-sound-effects/rain/ | 52.8s | 20.0s | https://assets.mixkit.co/active_storage/sfx/2402/2402.wav |
| tide | Sea waves loop | 1196 | https://mixkit.co/free-sound-effects/waves/ | 48.2s | 20.0s | https://assets.mixkit.co/active_storage/sfx/1196/1196.wav |
| waterfall | Waterfall in the woods | 2517 | https://mixkit.co/free-sound-effects/water/ | 82.8s | 20.0s | https://assets.mixkit.co/active_storage/sfx/2517/2517.wav |
| birdsong | Morning birds singing | 2467 | https://mixkit.co/free-sound-effects/birds/ | 120.1s | 20.0s | https://assets.mixkit.co/active_storage/sfx/2467/2467.wav |
| cricket | Crickets and insects in the wild ambience | 39 | https://mixkit.co/free-sound-effects/insect/ | 26.0s | 20.0s | https://assets.mixkit.co/active_storage/sfx/39/39.wav |
| mountain-brook | River water flowing | 2454 | https://mixkit.co/free-sound-effects/water/ | 180.1s | 20.0s | https://assets.mixkit.co/active_storage/sfx/2454/2454.wav |
| typewriter | Old typewriter typing | 1372 | https://mixkit.co/free-sound-effects/typewriter/ | 24.4s | 20.0s | https://assets.mixkit.co/active_storage/sfx/1372/1372.wav |
| sleeper-train | Old train departure | 1628 | https://mixkit.co/free-sound-effects/train/ | 107.3s | 20.0s | https://assets.mixkit.co/active_storage/sfx/1628/1628.wav |
| kitchen | Kettle boiling | 1817 | https://mixkit.co/free-sound-effects/kitchen/ | 63.3s | 20.0s | https://assets.mixkit.co/active_storage/sfx/1817/1817.wav |
| valley-echo | Wind in the top of the mountain | 1267 | https://mixkit.co/free-sound-effects/wind/ | 31.8s | 20.0s | https://assets.mixkit.co/active_storage/sfx/1267/1267.wav |
| radio-noise | Radio noise static and crackles | 1446 | https://mixkit.co/free-sound-effects/radio/ | 11.0s | 10.0s | https://assets.mixkit.co/active_storage/sfx/1446/1446.wav |
| rain | Rain long loop | 2394 | https://mixkit.co/free-sound-effects/rain/ | 57.1s | 20.0s | https://assets.mixkit.co/active_storage/sfx/2394/2394.wav |
| wind | Wind blowing ambience | 2658 | https://mixkit.co/free-sound-effects/wind/ | 61.8s | 20.0s | https://assets.mixkit.co/active_storage/sfx/2658/2658.wav |
| stream | Water flowing ambience loop | 3126 | https://mixkit.co/free-sound-effects/water/ | 51.0s | 20.0s | https://assets.mixkit.co/active_storage/sfx/3126/3126.wav |
| ocean-wave | Sea coast breaking waves | 1206 | https://mixkit.co/free-sound-effects/waves/ | 120.1s | 20.0s | https://assets.mixkit.co/active_storage/sfx/1206/1206.wav |
| campfire | Campfire crackles | 1330 | https://mixkit.co/free-sound-effects/fire/ | 24.0s | 20.0s | https://assets.mixkit.co/active_storage/sfx/1330/1330.wav |
| forest | Quiet forest ambience | 1220 | https://mixkit.co/free-sound-effects/forest/ | 152.1s | 20.0s | https://assets.mixkit.co/active_storage/sfx/1220/1220.wav |
| cafe | Restaurant crowd talking ambience | 444 | https://mixkit.co/free-sound-effects/restaurant/ | 120.0s | 20.0s | https://assets.mixkit.co/active_storage/sfx/444/444.wav |
| fan | Small stove extractor fan | 1833 | https://mixkit.co/free-sound-effects/appliance/ | 20.6s | 20.0s | https://assets.mixkit.co/active_storage/sfx/1833/1833.wav |

## 缺口（暂无资产，走静音模拟）

- nightingale（夜莺）、blue-noise / violet-noise / grey-noise（蓝/紫/灰噪音，按调研结论保留算法合成路线，待升级 gen_audio.dart）

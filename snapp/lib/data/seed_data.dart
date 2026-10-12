/// 全量静态种子数据。
///
/// 唯一权威来源：`prototype/src/data/scenes.ts` 与 `prototype/src/data/sounds.ts`，
/// 所有 id/name/desc/gradient/image/soundIds 均逐条原样拷贝，禁止臆造。
/// 保证与 uni-app 原型数据一致。

import 'scene_models.dart';
import 'sound_models.dart';

/// 场景分类（key + label + icon），对应原型 `sceneCategories`。
const List<SceneCategoryItem> sceneCategories = [
  SceneCategoryItem('all', '全部', 'wave'),
  SceneCategoryItem('sleep', '助眠', 'moon'),
  SceneCategoryItem('focus', '专注', 'flame'),
  SceneCategoryItem('relax', '放松', 'forest'),
  SceneCategoryItem('nature', '自然', 'mountain'),
];

/// 首页/场景列表全量场景（11 条），对应原型 `homeScenes`。
const List<Scene> homeScenes = [
  // 助眠
  Scene(id: 'deep-sleep', name: '深度睡眠', category: 'sleep', desc: '雨声铺底、白噪衬静，一夜沉入深眠', iconName: 'moon', gradient: 'linear-gradient(135deg, #7E93A8, #4E7182)', image: '/static/scene/deep-sleep.png', soundIds: ['rain', 'white-noise', 'forest'], isPreset: true),
  Scene(id: 'rainy-night', name: '夜雨入眠', category: 'sleep', desc: '细雨夹着篝火，温暖安全地睡去', iconName: 'rain', gradient: 'linear-gradient(135deg, #5F7A92, #B97A48)', image: '/static/scene/rainy-night.png', soundIds: ['drizzle', 'thunder', 'campfire'], isPreset: true),
  Scene(id: 'ocean-sleep', name: '海浪催眠', category: 'sleep', desc: '潮起潮落，像摇篮一样晃进梦里', iconName: 'wave-ocean', gradient: 'linear-gradient(135deg, #5F8296, #4E7182)', image: '/static/scene/ocean-sleep.png', soundIds: ['ocean-wave', 'white-noise'], isPreset: true),
  // 专注
  Scene(id: 'focus-white-noise', name: '专注白噪', category: 'focus', desc: '纯净声墙，一键进入心流', iconName: 'white-noise', gradient: 'linear-gradient(135deg, #8296A8, #C49A92)', image: '/static/scene/focus-white-noise.png', soundIds: ['white-noise', 'pink-noise'], isPreset: true),
  Scene(id: 'coffee-time', name: '咖啡时光', category: 'focus', desc: '杯碟轻响，适合写字的角落', iconName: 'coffee', gradient: 'linear-gradient(135deg, #A89068, #9A886B)', image: '/static/scene/coffee-time.png', soundIds: ['cafe', 'typewriter'], isPreset: true),
  Scene(id: 'long-train', name: '长途列车', category: 'focus', desc: '车轮规律作响，思绪随轨道延伸', iconName: 'train', gradient: 'linear-gradient(135deg, #8E82A6, #746889)', image: '/static/scene/long-train.png', soundIds: ['train', 'white-noise'], isPreset: true),
  // 放松
  Scene(id: 'nature-relax', name: '自然放松', category: 'relax', desc: '把大海和森林搬进房间', iconName: 'forest', gradient: 'linear-gradient(135deg, #5F8296, #7E9A74)', image: '/static/scene/nature-relax.png', soundIds: ['ocean-wave', 'forest', 'stream', 'birdsong'], isPreset: true),
  Scene(id: 'forest-meditation', name: '森林冥想', category: 'relax', desc: '空谷幽林，让呼吸慢下来', iconName: 'mountain', gradient: 'linear-gradient(135deg, #7E9A74, #5F7A86)', image: '/static/scene/forest-meditation.png', soundIds: ['forest', 'stream', 'cricket'], isPreset: true),
  Scene(id: 'campfire-night', name: '篝火夜晚', category: 'relax', desc: '火光噼啪，虫鸣作伴的冬夜', iconName: 'fire', gradient: 'linear-gradient(135deg, #B97A48, #9C5F34)', image: '/static/scene/campfire-night.png', soundIds: ['campfire', 'cricket'], isPreset: true),
  // 自然
  Scene(id: 'forest-stream', name: '林间溪流', category: 'nature', desc: '泉水淌过青石，清亮又安定', iconName: 'stream', gradient: 'linear-gradient(135deg, #7F9AA6, #66818D)', image: '/static/scene/forest-stream.png', soundIds: ['stream', 'forest'], isPreset: true),
  Scene(id: 'morning-forest', name: '山野清晨', category: 'nature', desc: '鸟鸣与风拂过林梢的清晨', iconName: 'bird', gradient: 'linear-gradient(135deg, #7E9A74, #547E54)', image: '/static/scene/morning-forest.png', soundIds: ['forest', 'birdsong'], isPreset: true),
];

/// 内置白噪音音频库（30 个，覆盖 4 类），对应原型 `sounds`。
const List<Sound> sounds = [
  // 合成白噪音 synthetic
  Sound(id: 'white-noise', name: '白噪音', type: '合成白噪音', category: 'synthetic', iconName: 'white-noise', color: '#8296A8', gradient: 'linear-gradient(135deg, #9FB2C4, #6E8396)', duration: '60:00', sampleRate: '44.1kHz', quality: '无损', source: '算法合成 · 全频段均匀能量', desc: '全频段均匀覆盖的经典白噪音，持续稳定的声墙能有效隔绝环境杂音，适合入睡与深度专注。', scenes: ['助眠', '专注', '抗噪'], loopLength: '5min'),
  Sound(id: 'pink-noise', name: '粉红噪音', type: '合成白噪音', category: 'synthetic', iconName: 'pink-noise', color: '#C49A92', gradient: 'linear-gradient(135deg, #D9B4AC, #AE7C73)', duration: '45:00', sampleRate: '48kHz', quality: '高清', source: '算法合成 · 低频功率更强', desc: '低频更充沛的粉红噪音，听感比白噪音更温暖柔和，长时间聆听也不易疲劳，是公认的助眠首选。', scenes: ['助眠', '冥想', '放松'], loopLength: '3min'),
  Sound(id: 'brown-noise', name: '褐噪音', type: '合成白噪音', category: 'synthetic', iconName: 'brown-noise', color: '#B9A98A', gradient: 'linear-gradient(135deg, #CDBE9F, #A18F6E)', duration: '40:00', sampleRate: '44.1kHz', quality: '无损', source: '算法合成 · 能量集中于低频', desc: '能量高度集中于低频的褐噪音，声底深沉厚实，如同远处的低沉轰鸣，带来沉稳的安定感。', scenes: ['助眠', '专注', '深度睡眠'], loopLength: '4min'),
  Sound(id: 'red-noise', name: '棕噪音', type: '合成白噪音', category: 'synthetic', iconName: 'red-noise', color: '#AE8F66', gradient: 'linear-gradient(135deg, #C2A37C, #967850)', duration: '30:00', sampleRate: '48kHz', quality: '高清', source: '算法合成 · 红噪声低频延伸', desc: '比褐噪音更低沉的红噪音，低频向下延伸，营造被包裹的安全氛围，适合睡前彻底放松身心。', scenes: ['助眠', '深度睡眠', '冥想'], loopLength: '2min'),
  Sound(id: 'blue-noise', name: '蓝噪音', type: '合成白噪音', category: 'synthetic', iconName: 'white-noise', color: '#7E93A8', gradient: 'linear-gradient(135deg, #9AABC0, #667C91)', duration: '25:00', sampleRate: '44.1kHz', quality: '高清', source: '算法合成 · 高频能量突出', desc: '高频更清晰的蓝噪音，声音轻快明亮，适合需要保持清醒的场合，提神之余减少外界干扰。', scenes: ['专注', '学习', '办公'], loopLength: '2min'),
  Sound(id: 'violet-noise', name: '紫噪音', type: '合成白噪音', category: 'synthetic', iconName: 'pink-noise', color: '#8E82A6', gradient: 'linear-gradient(135deg, #A99EC2, #73668E)', duration: '20:00', sampleRate: '48kHz', quality: '无损', source: '算法合成 · 高频增益处理', desc: '紫噪音在中高频有所增益，听感细腻清脆，适合耳鸣掩蔽与轻度提神，让思绪保持敏捷。', scenes: ['专注', '耳鸣掩蔽', '办公'], loopLength: '1min'),
  Sound(id: 'grey-noise', name: '灰色噪音', type: '合成白噪音', category: 'synthetic', iconName: 'brown-noise', color: '#7E9390', gradient: 'linear-gradient(135deg, #98ACA9, #667C79)', duration: '35:00', sampleRate: '44.1kHz', quality: '高清', source: '算法合成 · 感知均衡优化', desc: '依据人耳等响曲线优化合成的灰色噪音，各频段听感更均衡，长时间佩戴依然舒适。', scenes: ['专注', '助眠', '放松'], loopLength: '3min'),
  Sound(id: 'radio-noise', name: '调频收音机噪音', type: '合成白噪音', category: 'synthetic', iconName: 'fan', color: '#9A886B', gradient: 'linear-gradient(135deg, #B0A085, #847354)', duration: '30:00', sampleRate: '44.1kHz', quality: '高清', source: '录音采集 · 调频波段底噪', desc: '介于纯噪声与机械声之间的收音机底噪，颗粒感十足，带来复古怀旧的安稳氛围。', scenes: ['放松', '复古', '助眠'], loopLength: '2min'),
  // 自然音 nature
  Sound(id: 'rain', name: '雨声', type: '自然音', category: 'nature', iconName: 'rain', color: '#7E93A8', gradient: 'linear-gradient(135deg, #9AABC0, #667C91)', duration: '60:00', sampleRate: '48kHz', quality: '无损', source: '实地录音 · 江南雨巷屋檐', desc: '雨滴敲打屋檐与地面的层次声响，细密而均匀，是无数人心中最治愈的入眠背景音。', scenes: ['助眠', '冥想', '雨天'], loopLength: '5min'),
  Sound(id: 'drizzle', name: '细雨', type: '自然音', category: 'nature', iconName: 'rain', color: '#8296A8', gradient: 'linear-gradient(135deg, #A2B4C6, #6C8194)', duration: '45:00', sampleRate: '44.1kHz', quality: '无损', source: '实地录音 · 林间蒙蒙细雨', desc: '细密轻柔的毛毛雨声，沙沙作响却不扰人，营造湿润朦胧的氛围，适合午后小憩与阅读。', scenes: ['助眠', '小憩', '阅读'], loopLength: '3min'),
  Sound(id: 'thunder', name: '雷雨', type: '自然音', category: 'nature', iconName: 'rain', color: '#5F7A92', gradient: 'linear-gradient(135deg, #7C97AF, #486078)', duration: '30:00', sampleRate: '48kHz', quality: '高清', source: '实地录音 · 山谷雷雨夜', desc: '雷声低沉滚过山谷，雨势随情绪起伏，带来戏剧化的沉浸感，是极具氛围的夜晚配乐。', scenes: ['氛围', '助眠', '雨天'], loopLength: '2min'),
  Sound(id: 'ocean-wave', name: '海浪', type: '自然音', category: 'nature', iconName: 'wave-ocean', color: '#5F8296', gradient: 'linear-gradient(135deg, #7EA2B6, #48657A)', duration: '55:00', sampleRate: '48kHz', quality: '无损', source: '实地录音 · 南半球海岸线', desc: '潮水一波波拍打沙滩的节奏声，白噪音般的均匀起伏，适合冥想与深度放松的片刻。', scenes: ['冥想', '放松', '助眠'], loopLength: '4min'),
  Sound(id: 'tide', name: '潮汐', type: '自然音', category: 'nature', iconName: 'wave-ocean', color: '#4E7182', gradient: 'linear-gradient(135deg, #6C8FA0, #38586A)', duration: '40:00', sampleRate: '44.1kHz', quality: '高清', source: '实地录音 · 礁石潮汐带', desc: '海水进退礁石的循环声响，节奏舒缓悠长，让人仿佛置身海边，感受呼吸般自然的律动。', scenes: ['放松', '冥想', '助眠'], loopLength: '3min'),
  Sound(id: 'forest', name: '森林', type: '自然音', category: 'nature', iconName: 'forest', color: '#7E9A74', gradient: 'linear-gradient(135deg, #9CB493, #64825C)', duration: '50:00', sampleRate: '48kHz', quality: '无损', source: '实地录音 · 温带针叶林', desc: '风吹树叶沙沙与林间细微声响交织，层次丰富的森林白噪音，让思绪在自然中沉静下来。', scenes: ['专注', '冥想', '放松'], loopLength: '4min'),
  Sound(id: 'stream', name: '溪流', type: '自然音', category: 'nature', iconName: 'stream', color: '#7F9AA6', gradient: 'linear-gradient(135deg, #9DB6C2, #66818D)', duration: '45:00', sampleRate: '44.1kHz', quality: '无损', source: '实地录音 · 山间清浅溪流', desc: '泉水冲刷卵石的清脆声响，清澈灵动，如同山涧的呼吸，带来清凉与安定的双重感受。', scenes: ['放松', '专注', '冥想'], loopLength: '3min'),
  Sound(id: 'campfire', name: '篝火', type: '自然音', category: 'nature', iconName: 'fire', color: '#B97A48', gradient: 'linear-gradient(135deg, #D39A68, #9C5F34)', duration: '35:00', sampleRate: '48kHz', quality: '高清', source: '实地录音 · 露营营地篝火', desc: '木柴燃烧噼啪作响，火焰摇曳的温暖声响，在寒冷的夜晚带来安心与归属感的陪伴。', scenes: ['放松', '冬夜', '氛围'], loopLength: '2min'),
  Sound(id: 'wind', name: '风声', type: '自然音', category: 'nature', iconName: 'stream', color: '#8E9E96', gradient: 'linear-gradient(135deg, #A9B8B0, #74867D)', duration: '30:00', sampleRate: '44.1kHz', quality: '高清', source: '实地录音 · 高原旷野之风', desc: '风掠过旷野与林梢的呼啸声，空旷悠远，带着自然的呼吸感，让内心随之开阔平静。', scenes: ['冥想', '放松', '自然'], loopLength: '2min'),
  Sound(id: 'waterfall', name: '瀑布', type: '自然音', category: 'nature', iconName: 'stream', color: '#5E8A9A', gradient: 'linear-gradient(135deg, #7EA6B6, #47707F)', duration: '40:00', sampleRate: '48kHz', quality: '无损', source: '实地录音 · 深山瀑布群', desc: '水流从高处倾泻的磅礴声浪，白噪音感极强，能迅速遮盖周遭杂音，沉浸感十足。', scenes: ['专注', '助眠', '自然'], loopLength: '3min'),
  Sound(id: 'birdsong', name: '鸟鸣', type: '自然音', category: 'nature', iconName: 'bird', color: '#6E9A6E', gradient: 'linear-gradient(135deg, #8CB48C, #547E54)', duration: '25:00', sampleRate: '44.1kHz', quality: '高清', source: '实地录音 · 清晨山林鸟鸣', desc: '清晨林间此起彼伏的鸟鸣，清脆悦耳，唤醒一天的生机，带来明亮而松弛的心情。', scenes: ['晨间', '唤醒', '自然'], loopLength: '2min'),
  Sound(id: 'cricket', name: '虫鸣', type: '自然音', category: 'nature', iconName: 'mountain', color: '#7E9A5E', gradient: 'linear-gradient(135deg, #9CB47D, #667F47)', duration: '30:00', sampleRate: '48kHz', quality: '高清', source: '实地录音 · 夏夜乡野虫鸣', desc: '夏夜里蟋蟀与夜虫的合奏，细碎而规律，仿佛回到童年乡间的夜晚，宁静又安心。', scenes: ['助眠', '夏夜', '怀旧'], loopLength: '2min'),
  // 城市音 urban
  Sound(id: 'cafe', name: '咖啡厅', type: '城市音', category: 'urban', iconName: 'coffee', color: '#A89068', gradient: 'linear-gradient(135deg, #C0AA84, #8C754F)', duration: '45:00', sampleRate: '44.1kHz', quality: '无损', source: '实录混音 · 街角精品咖啡店', desc: '杯碟碰撞、低语与咖啡机嗡鸣交织的咖啡馆氛围声，忙碌却松弛，是绝佳的写作背景音。', scenes: ['专注', '阅读', '社交'], loopLength: '3min'),
  Sound(id: 'train', name: '列车', type: '城市音', category: 'urban', iconName: 'train', color: '#8E82A6', gradient: 'linear-gradient(135deg, #AB9FC2, #746889)', duration: '40:00', sampleRate: '48kHz', quality: '高清', source: '实地录音 · 绿皮列车车厢', desc: '车轮与铁轨规律的碰撞声，伴随着轻微晃动感，最适合长途旅程中的放松与浅眠。', scenes: ['放松', '通勤', '助眠'], loopLength: '3min'),
  Sound(id: 'fan', name: '风扇', type: '城市音', category: 'urban', iconName: 'fan', color: '#7E9390', gradient: 'linear-gradient(135deg, #98ACA9, #667C79)', duration: '35:00', sampleRate: '44.1kHz', quality: '无损', source: '实地录音 · 老式落地风扇', desc: '扇叶匀速旋转的嗡嗡声，单调却莫名安心，是许多人夏季入眠不可或缺的背景音。', scenes: ['助眠', '夏夜', '专注'], loopLength: '3min'),
  Sound(id: 'sleeper-train', name: '火车卧铺', type: '城市音', category: 'urban', iconName: 'train', color: '#7A6E96', gradient: 'linear-gradient(135deg, #978CB2, #61567C)', duration: '30:00', sampleRate: '48kHz', quality: '高清', source: '实地录音 · 夜行卧铺车厢', desc: '夜间卧铺车厢的低沉背景声，车轮节奏缓慢稳定，像摇篮般哄人入睡的独特声响。', scenes: ['助眠', '深度睡眠', '旅途中'], loopLength: '2min'),
  Sound(id: 'kitchen', name: '厨房', type: '城市音', category: 'urban', iconName: 'fire', color: '#AE8F66', gradient: 'linear-gradient(135deg, #C2A37C, #967850)', duration: '20:00', sampleRate: '44.1kHz', quality: '高清', source: '实录混音 · 家常厨房烟火气', desc: '锅具叮当与烹饪的细碎声响，带着人间烟火气，温馨治愈，让独处的时光不再孤单。', scenes: ['温馨', '放松', '居家'], loopLength: '2min'),
  Sound(id: 'typewriter', name: '打字机', type: '城市音', category: 'urban', iconName: 'fan', color: '#9A886B', gradient: 'linear-gradient(135deg, #B0A085, #847354)', duration: '25:00', sampleRate: '48kHz', quality: '无损', source: '实录混音 · 复古机械打字机', desc: '机械按键哒哒的敲击声，节奏分明富有韵律，仿佛穿越回旧时光，激发写作灵感。', scenes: ['专注', '写作', '复古'], loopLength: '2min'),
  // 环境音 ambient
  Sound(id: 'valley-echo', name: '空谷回响', type: '环境音', category: 'ambient', iconName: 'mountain', color: '#5F7A86', gradient: 'linear-gradient(135deg, #7D98A4, #475F6C)', duration: '35:00', sampleRate: '44.1kHz', quality: '无损', source: '合成混响 · 幽谷空间感', desc: '空旷山谷中层层回荡的环境声，空间感极强，带来孤寂而辽阔的冥想体验。', scenes: ['冥想', '禅意', '放松'], loopLength: '3min'),
  Sound(id: 'mountain-brook', name: '山涧', type: '环境音', category: 'ambient', iconName: 'mountain', color: '#6E8296', gradient: 'linear-gradient(135deg, #8CA0B4, #56687C)', duration: '30:00', sampleRate: '48kHz', quality: '高清', source: '实地录音 · 云雾缭绕山涧', desc: '山涧溪水与雾气交织的湿润声响，清冷而空灵，仿佛置身仙境，抚平所有躁动。', scenes: ['冥想', '放松', '自然'], loopLength: '2min'),
  Sound(id: 'nightingale', name: '夜莺', type: '环境音', category: 'ambient', iconName: 'bird', color: '#7E8A9E', gradient: 'linear-gradient(135deg, #9CA8BC, #656F83)', duration: '25:00', sampleRate: '44.1kHz', quality: '无损', source: '实地录音 · 月夜林间夜莺', desc: '夜莺婉转啼鸣划破静谧夜空，清脆空灵，为夜色添上诗意，伴你安然入睡。', scenes: ['助眠', '夜晚', '诗意'], loopLength: '2min'),
  Sound(id: 'floor-heating', name: '地暖', type: '环境音', category: 'ambient', iconName: 'fire', color: '#A89068', gradient: 'linear-gradient(135deg, #C0AA84, #8C754F)', duration: '30:00', sampleRate: '48kHz', quality: '高清', source: '实地录音 · 室内地暖运转', desc: '地暖系统轻微运转的低频嗡鸣，均匀而温暖，在寒冬里提供熨帖的安心陪伴。', scenes: ['冬夜', '助眠', '居家'], loopLength: '3min'),
];

/// 声音分类（key + label + icon），对应原型 `soundCategories`。
const List<SoundCategoryItem> soundCategories = [
  SoundCategoryItem('all', '全部', 'wave'),
  SoundCategoryItem('synthetic', '合成白噪音', 'white-noise'),
  SoundCategoryItem('nature', '自然音', 'forest'),
  SoundCategoryItem('urban', '城市音', 'coffee'),
  SoundCategoryItem('ambient', '环境音', 'mountain'),
];

/// 模拟偏好标签（原型阶段写死：助眠 + 自然）。
const List<String> simulatedPrefs = ['sleep', 'nature'];

/// 发现页推荐场景（8 条），对应原型 `featuredScenes`。
const List<FeaturedScene> featuredScenes = [
  FeaturedScene(id: 'deep-sleep', name: '深度睡眠', desc: '雨声与白噪音叠加森林的层次声墙，低频充盈，帮助大脑快速进入深度睡眠。', iconName: 'moon', gradient: 'linear-gradient(135deg, #7E93A8, #4E7182)', tags: ['助眠', '深度睡眠'], soundIds: ['rain', 'white-noise', 'forest'], ratio: [40, 30, 30], playCount: '12.6万', duration: '60:00'),
  FeaturedScene(id: 'focus-white-noise', name: '专注白噪', desc: '白噪音与粉红噪音的中性叠加，持续而均匀，是屏蔽干扰、进入心流的利器。', iconName: 'white-noise', gradient: 'linear-gradient(135deg, #8296A8, #C49A92)', tags: ['专注', '工作'], soundIds: ['white-noise', 'pink-noise'], ratio: [60, 40], playCount: '9.8万', duration: '45:00'),
  FeaturedScene(id: 'nature-relax', name: '自然放松', desc: '海浪、森林、溪流与鸟鸣交织，把大自然搬进房间，身心随之彻底松弛。', iconName: 'forest', gradient: 'linear-gradient(135deg, #5F8296, #7E9A74)', tags: ['放松', '自然'], soundIds: ['ocean-wave', 'forest', 'stream', 'birdsong'], ratio: [25, 25, 25, 25], playCount: '8.4万', duration: '55:00'),
  FeaturedScene(id: 'urban-afternoon', name: '城市午后', desc: '咖啡厅、风扇与打字机的日常声响，忙碌而温暖，是都市人安放疲惫的角落。', iconName: 'coffee', gradient: 'linear-gradient(135deg, #A89068, #7E9390)', tags: ['氛围', '写作'], soundIds: ['cafe', 'fan', 'typewriter'], ratio: [40, 30, 30], playCount: '7.2万', duration: '45:00'),
  FeaturedScene(id: 'rainy-night', name: '雨夜入眠', desc: '细雨与雷雨交织，偶有篝火噼啪，营造温暖安全的雨夜，伴你安然入梦。', iconName: 'rain', gradient: 'linear-gradient(135deg, #5F7A92, #B97A48)', tags: ['助眠', '雨夜'], soundIds: ['drizzle', 'thunder', 'campfire'], ratio: [45, 30, 25], playCount: '6.9万', duration: '45:00'),
  FeaturedScene(id: 'forest-meditation', name: '森林冥想', desc: '森林为底、溪流轻淌、虫鸣点缀，空旷而通透，是每日冥想的最佳伴侣。', iconName: 'mountain', gradient: 'linear-gradient(135deg, #7E9A74, #5F7A86)', tags: ['冥想', '禅意'], soundIds: ['forest', 'stream', 'cricket'], ratio: [40, 30, 30], playCount: '6.1万', duration: '50:00'),
  FeaturedScene(id: 'seaside-sunset', name: '海边日落', desc: '海浪起伏、潮汐进退、晚风轻拂，把日落时分的海岸装进口袋慢慢听。', iconName: 'wave-ocean', gradient: 'linear-gradient(135deg, #4E7182, #8E9E96)', tags: ['放松', '日落'], soundIds: ['ocean-wave', 'tide', 'wind'], ratio: [40, 30, 30], playCount: '5.5万', duration: '55:00'),
  FeaturedScene(id: 'coffee-time', name: '咖啡时光', desc: '咖啡馆的松弛氛围搭配打字机的节奏，一杯咖啡、一段文字，享受独处时光。', iconName: 'coffee', gradient: 'linear-gradient(135deg, #A89068, #9A886B)', tags: ['阅读', '咖啡'], soundIds: ['cafe', 'typewriter'], ratio: [60, 40], playCount: '4.8万', duration: '45:00'),
];

/// 声音精选（发现页人气最高的 8 个），对应原型 `featuredSounds`。
final List<FeaturedSound> featuredSounds = [
  FeaturedSound(sound: _sound('white-noise'), hot: 98),
  FeaturedSound(sound: _sound('pink-noise'), hot: 95),
  FeaturedSound(sound: _sound('rain'), hot: 93),
  FeaturedSound(sound: _sound('ocean-wave'), hot: 92),
  FeaturedSound(sound: _sound('forest'), hot: 90),
  FeaturedSound(sound: _sound('brown-noise'), hot: 88),
  FeaturedSound(sound: _sound('campfire'), hot: 87),
  FeaturedSound(sound: _sound('stream'), hot: 85),
];

/// 从 [sounds] 中按 id 取声音；原型对应 findSound（丢失即抛错）。
Sound _sound(String id) {
  for (final s in sounds) {
    if (s.id == id) return s;
  }
  throw StateError('seed_data.dart: 未找到声音 $id');
}

/// 有合成 WAV 资产的声音 id（`assets/audio/<id>.wav`，由 `tool/gen_audio.dart`
/// 生成）：纯算法合成类（各色噪声音 + 列车节拍）。
const Set<String> generatedAudioIds = <String>{
  'white-noise', 'pink-noise', 'brown-noise', 'red-noise', 'train',
};

/// 有真实采录音资产的声音 id（Mixkit License：可商用、免署名；逐条登记见
/// `docs/audio-assets-license.md`），同样映射到 `assets/audio/<id>.wav`。
/// 夜莺/蓝/紫/灰噪音暂无资产，仍走 SimulatedAudioEngine 静音模拟。
const Set<String> recordedAudioIds = <String>{
  'rain', 'wind', 'stream', 'ocean-wave', 'campfire', 'forest', 'fan',
  'drizzle', 'thunder', 'tide', 'waterfall', 'birdsong', 'cricket',
  'mountain-brook', 'cafe', 'typewriter', 'sleeper-train', 'kitchen',
  'valley-echo', 'radio-noise',
};

/// 声音 id → WAV 资产路径；无资产返回 null（对应音轨走模拟引擎）。
String? audioAssetFor(String id) =>
    generatedAudioIds.contains(id) || recordedAudioIds.contains(id)
        ? 'assets/audio/$id.wav'
        : null;

/// 发现页热门精选相关（对应原型 `scenes.ts` 的 parsePlayCount / featuredSceneCategory / getHotScenes）。

/// featuredScenes 各 id → 场景分类 key（口径与 sceneCategories 一致，单一来源）。
const Map<String, String> featuredSceneCategory = <String, String>{
  'deep-sleep': 'sleep',
  'focus-white-noise': 'focus',
  'nature-relax': 'nature',
  'urban-afternoon': 'focus',
  'rainy-night': 'sleep',
  'forest-meditation': 'relax',
  'seaside-sunset': 'relax',
  'coffee-time': 'focus',
};

/// 解析播放量字符串（"12.6万" → 126000 / "9.8千" → 9800 / "5000" → 5000），用作热度排序；失败返回 0。
double parsePlayCount(String pc) {
  final m = RegExp(r'^([\d.]+)(万|千)?$').firstMatch(pc);
  if (m == null) return 0;
  final num = double.parse(m.group(1)!);
  final unit = m.group(2);
  if (unit == '万') return num * 10000;
  if (unit == '千') return num * 1000;
  return num;
}

/// 发现页热门精选：按分类过滤（'all' 不过滤），再按播放量降序，
/// 体现「大家都在听的热门」。excludeId 用于排除今日推荐 hero，避免重复展示。
List<FeaturedScene> getHotScenes(String category, {String excludeId = ''}) {
  final list = featuredScenes.where((FeaturedScene s) => s.id != excludeId).toList();
  final filtered = category == 'all'
      ? list
      : list.where((FeaturedScene s) => featuredSceneCategory[s.id] == category).toList();
  filtered.sort((FeaturedScene a, FeaturedScene b) =>
      parsePlayCount(b.playCount).compareTo(parsePlayCount(a.playCount)));
  return filtered;
}
// 声栖 · 合成 WAV 音频资产生成脚本。
//
// 用法：`dart run tool/gen_audio.dart`
//
// 为 sounds 库中「纯算法合成类」声音生成 44.1kHz / 16bit / mono PCM WAV
// （每条约 10s，用于循环播放），输出到 `assets/audio/<soundId>.wav`。
// 自然类声音（雨/风/溪流/海浪/篝火/森林/风扇）及真实采录音已改用 Mixkit
// 素材（登记见 `docs/audio-assets-license.md`），不在此合成，重跑本脚本
// 不会覆盖真实录音。
//
// 随机种子固定（Random(42)），产物可复现。
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int _sampleRate = 44100;
const double _durationSec = 10;
final int _totalSamples = (_sampleRate * _durationSec).round();
const String _outDir = 'assets/audio';

/// 每个 id 的合成器：输入 [rng]、输出幅度回调 `emit(int i, double v)`（[-1,1]）。
final Map<String, void Function(Random, void Function(int, double))> _synths = {
  'white-noise': _white,
  'pink-noise': _pink,
  'brown-noise': _brown,
  'red-noise': _red,
  'train': _train,
};

void main() {
  Directory(_outDir).createSync(recursive: true);
  for (final MapEntry<String, void Function(Random, void Function(int, double))>
      e in _synths.entries) {
    final rng = Random(42);
    final samples = Float64List(_totalSamples);
    e.value(rng, (int i, double v) {
      if (i >= 0 && i < _totalSamples) samples[i] = v.clamp(-1.0, 1.0);
    });
    final path = '$_outDir/${e.key}.wav';
    File(path).writeAsBytesSync(_wavOf(samples));
    stdout.writeln('wrote $path (${samples.length} samples)');
  }
}

/* ------------------------------ 合成器 ------------------------------ */

void _white(Random r, void Function(int, double) emit) {
  for (int i = 0; i < _totalSamples; i++) {
    emit(i, r.nextDouble() * 2 - 1);
  }
}

/// 粉红噪（Paul Kellet 一阶滤波近似，-3dB/oct）。
void _pink(Random r, void Function(int, double) emit) {
  double b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
  for (int i = 0; i < _totalSamples; i++) {
    final w = r.nextDouble() * 2 - 1;
    b0 = 0.99886 * b0 + w * 0.0555179;
    b1 = 0.99332 * b1 + w * 0.0750759;
    b2 = 0.969 * b2 + w * 0.153852;
    b3 = 0.8665 * b3 + w * 0.3104856;
    b4 = 0.55 * b4 + w * 0.5329522;
    b5 = -0.7616 * b5 - w * 0.016898;
    emit(i, (b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * 0.5362) * 0.11);
    b6 = w * 0.115926;
  }
}

/// 褐噪（积分白噪，-6dB/oct）。
void _brown(Random r, void Function(int, double) emit) {
  double last = 0;
  for (int i = 0; i < _totalSamples; i++) {
    final w = r.nextDouble() * 2 - 1;
    last = (last + 0.02 * w) / 1.02;
    emit(i, last * 3.5);
  }
}

/// 棕噪（比褐噪更重的低频积分）。
void _red(Random r, void Function(int, double) emit) {
  double last = 0;
  for (int i = 0; i < _totalSamples; i++) {
    final w = r.nextDouble() * 2 - 1;
    last = (last + 0.012 * w) / 1.012;
    emit(i, last * 4.2);
  }
}

/// 列车：规律节拍撞击（约 1.1Hz）+ 低沉底噪。
void _train(Random r, void Function(int, double) emit) {
  final int beat = (_sampleRate / 1.1).round();
  double low = 0;
  double beatEnv = 0;
  for (int i = 0; i < _totalSamples; i++) {
    final w = r.nextDouble() * 2 - 1;
    low = 0.99 * low + 0.01 * w;
    if (i % beat == 0) beatEnv = 1.0;
    beatEnv *= 0.9992;
    emit(i, low * 1.5 + (r.nextDouble() * 2 - 1) * beatEnv * 0.7);
  }
}

/* ------------------------------ WAV 编码 ------------------------------ */

/// 把采样数组编码为 16bit PCM WAV（44.1kHz mono）。
Uint8List _wavOf(Float64List samples) {
  final dataLen = samples.length * 2;
  final bytes = BytesBuilder(copy: false);
  void str(String s) => bytes.add(s.codeUnits);
  void u32(int v) => bytes.add(<int>[
        v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF,
      ]);
  void u16(int v) => bytes.add(<int>[v & 0xFF, (v >> 8) & 0xFF]);

  str('RIFF');
  u32(36 + dataLen);
  str('WAVE');
  str('fmt ');
  u32(16);
  u16(1); // PCM
  u16(1); // mono
  u32(_sampleRate);
  u32(_sampleRate * 2); // byte rate
  u16(2); // block align
  u16(16); // bits
  str('data');
  u32(dataLen);
  for (int i = 0; i < samples.length; i++) {
    final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    u16(v & 0xFFFF);
  }
  return bytes.toBytes();
}

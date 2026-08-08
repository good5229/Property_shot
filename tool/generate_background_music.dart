import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _sampleRate = 22050;
const _durationSeconds = 16;
const _twoPi = math.pi * 2;

void main() {
  final sampleCount = _sampleRate * _durationSeconds;
  final samples = Int16List(sampleCount);
  for (var index = 0; index < sampleCount; index++) {
    final time = index / _sampleRate;
    final value = (_pad(time) + _bell(time) + _pulse(time)).clamp(-0.92, 0.92);
    samples[index] = (value * 32767).round();
  }

  final output = File('assets/audio/property_shot_island_loop.wav');
  output.parent.createSync(recursive: true);
  output.writeAsBytesSync(_wav(samples), flush: true);
  stdout.writeln('배경 음악 생성: ${output.path} (${output.lengthSync()} bytes)');
}

double _pad(double time) {
  const chords = [
    [130.81, 164.81, 196.00, 246.94],
    [110.00, 130.81, 164.81, 196.00],
    [87.31, 130.81, 174.61, 220.00],
    [98.00, 123.47, 146.83, 196.00],
  ];
  final chordIndex = (time ~/ 4).clamp(0, chords.length - 1);
  final local = time % 4;
  final envelope = _smooth(local / 0.7) * _smooth((4 - local) / 0.7);
  var value = 0.0;
  for (final frequency in chords[chordIndex]) {
    value += math.sin(_twoPi * frequency * time) * 0.028;
    value += math.sin(_twoPi * frequency * 2 * time) * 0.006;
  }
  return value * envelope;
}

double _bell(double time) {
  const frequencies = [
    523.25,
    659.25,
    783.99,
    659.25,
    587.33,
    523.25,
    440.00,
    493.88,
    523.25,
    659.25,
    698.46,
    783.99,
    659.25,
    587.33,
    493.88,
    392.00,
  ];
  final noteIndex = (time ~/ 1).clamp(0, frequencies.length - 1);
  final local = time % 1;
  if (local > 0.72) return 0;
  final attack = _smooth(local / 0.025);
  final decay = math.exp(-4.8 * local);
  final frequency = frequencies[noteIndex];
  final phase = _twoPi * frequency * local;
  return attack *
      decay *
      (math.sin(phase) * 0.12 +
          math.sin(phase * 2) * 0.035 +
          math.sin(phase * 3) * 0.014);
}

double _pulse(double time) {
  final local = time % 2;
  if (local > 0.45) return 0;
  final envelope = _smooth(local / 0.02) * math.exp(-8 * local);
  final frequency = local < 0.16 ? 196.0 : 146.83;
  return math.sin(_twoPi * frequency * local) * envelope * 0.035;
}

double _smooth(double value) {
  final x = value.clamp(0.0, 1.0);
  return x * x * (3 - 2 * x);
}

Uint8List _wav(Int16List samples) {
  final dataSize = samples.lengthInBytes;
  final bytes = ByteData(44 + dataSize);
  void text(int offset, String value) {
    for (var index = 0; index < value.length; index++) {
      bytes.setUint8(offset + index, value.codeUnitAt(index));
    }
  }

  text(0, 'RIFF');
  bytes.setUint32(4, 36 + dataSize, Endian.little);
  text(8, 'WAVE');
  text(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, _sampleRate, Endian.little);
  bytes.setUint32(28, _sampleRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  text(36, 'data');
  bytes.setUint32(40, dataSize, Endian.little);
  for (var index = 0; index < samples.length; index++) {
    bytes.setInt16(44 + index * 2, samples[index], Endian.little);
  }
  return bytes.buffer.asUint8List();
}

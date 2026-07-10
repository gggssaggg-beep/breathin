import 'dart:typed_data';

/// Минимальный ввод-вывод WAV PCM 16 бит / моно. Чистый Dart (только
/// dart:typed_data) — тестируется без устройства и плагинов.
///
/// Умышленно узкий формат: ассеты синтезируются ровно таким (см.
/// tools/generate_audio.py, ПЛАН §10.1). Никакого ресемплинга/переканалки —
/// микс в таймлайн идёт сэмпл-в-сэмпл (ПЛАН §3.3).
class WavData {
  final int sampleRate;
  final Int16List samples;
  const WavData(this.sampleRate, this.samples);
}

class WavIo {
  /// Разобрать WAV из байтов. Бросает [FormatException], если это не
  /// PCM 16-бит моно.
  static WavData decode(Uint8List bytes) {
    final bd = ByteData.sublistView(bytes);
    if (bytes.length < 12 ||
        _tag(bytes, 0) != 'RIFF' ||
        _tag(bytes, 8) != 'WAVE') {
      throw const FormatException('Не RIFF/WAVE');
    }

    int? sampleRate;
    int? bitsPerSample;
    int? channels;
    int? audioFormat;
    int offset = 12;
    Int16List? samples;

    while (offset + 8 <= bytes.length) {
      final id = _tag(bytes, offset);
      final size = bd.getUint32(offset + 4, Endian.little);
      final body = offset + 8;
      if (id == 'fmt ') {
        audioFormat = bd.getUint16(body, Endian.little);
        channels = bd.getUint16(body + 2, Endian.little);
        sampleRate = bd.getUint32(body + 4, Endian.little);
        bitsPerSample = bd.getUint16(body + 14, Endian.little);
      } else if (id == 'data') {
        final n = size ~/ 2;
        final out = Int16List(n);
        for (var i = 0; i < n; i++) {
          out[i] = bd.getInt16(body + i * 2, Endian.little);
        }
        samples = out;
      }
      offset = body + size + (size & 1); // чанки выровнены по 2 байта
    }

    if (audioFormat != 1 || bitsPerSample != 16 || channels != 1) {
      throw FormatException(
        'Ожидался PCM/16/моно, получено fmt=$audioFormat '
        'bits=$bitsPerSample ch=$channels',
      );
    }
    if (sampleRate == null || samples == null) {
      throw const FormatException('Нет fmt/data чанка');
    }
    return WavData(sampleRate, samples);
  }

  /// Собрать WAV-байты из PCM 16-бит моно.
  static Uint8List encode(Int16List samples, int sampleRate) {
    final dataBytes = samples.length * 2;
    final out = ByteData(44 + dataBytes);
    _putTag(out, 0, 'RIFF');
    out.setUint32(4, 36 + dataBytes, Endian.little);
    _putTag(out, 8, 'WAVE');
    _putTag(out, 12, 'fmt ');
    out.setUint32(16, 16, Endian.little); // размер fmt
    out.setUint16(20, 1, Endian.little); // PCM
    out.setUint16(22, 1, Endian.little); // моно
    out.setUint32(24, sampleRate, Endian.little);
    out.setUint32(28, sampleRate * 2, Endian.little); // байт/с
    out.setUint16(32, 2, Endian.little); // выравнивание блока
    out.setUint16(34, 16, Endian.little); // бит/сэмпл
    _putTag(out, 36, 'data');
    out.setUint32(40, dataBytes, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      out.setInt16(44 + i * 2, samples[i], Endian.little);
    }
    return out.buffer.asUint8List();
  }

  static String _tag(Uint8List b, int o) => String.fromCharCodes(b, o, o + 4);
  static void _putTag(ByteData d, int o, String s) {
    for (var i = 0; i < 4; i++) {
      d.setUint8(o + i, s.codeUnitAt(i));
    }
  }
}

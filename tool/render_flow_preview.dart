// Рендер превью «Арфы» настоящим кодом приложения (harp_melody + renderer):
// два цикла бокса 4-4-4-4 из реальных ассетов лесенки →
// _sound_preview/11_arfa_iz_prilozheniya.wav (фон НЕ входит — он отдельный
// слой just_audio). Запуск: dart run tool/render_flow_preview.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:breathin/domain/catalog/techniques.dart';
import 'package:breathin/domain/engine/session_plan_compiler.dart';
import 'package:breathin/domain/models/session_config.dart';
import 'package:breathin/services/audio/harp_melody.dart';
import 'package:breathin/services/audio/timeline_renderer.dart';
import 'package:breathin/services/audio/wav_io.dart';

void main() {
  const cfg = SessionConfig(
    endMode: EndMode.cycles,
    cycles: 2,
    phaseSeconds: [4, 4, 4, 4],
    prepSeconds: 0,
  );
  final plan = const SessionPlanCompiler().compile(boxBreathing, cfg);
  Int16List load(String rel) =>
      WavIo.decode(File('assets/audio/$rel').readAsBytesSync()).samples;
  final bank = SoundBank(
    sampleRate: 44100,
    clips: {ClipId.gong: Int16List(1)},
    scale: [
      for (var i = 0; i < harpScaleSize; i++) load('sets/harp/note_$i.wav'),
    ],
  );
  final pcm = const TimelineRenderer().render(plan, bank);
  final out =
      File(r'C:\purba\breathin\_sound_preview\11_arfa_iz_prilozheniya.wav');
  out.createSync(recursive: true);
  out.writeAsBytesSync(WavIo.encode(pcm, 44100));
  stdout.writeln('✓ ${out.path} (${(pcm.length / 44100).toStringAsFixed(1)} c)');
}

import 'package:breathin/domain/models/technique.dart';
import 'package:breathin/features/catalog/technique_icons.dart';
import 'package:breathin/ui/icons/breathin_icon.dart';
import 'package:breathin/ui/icons/breathin_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_drawing/path_drawing.dart';

void main() {
  test('все иконки набора: пути непусты и парсятся без исключений', () {
    expect(BreathinIcons.all, hasLength(33));
    for (final icon in BreathinIcons.all) {
      expect(icon.paths, isNotEmpty);
      for (final d in icon.paths) {
        expect(() => parseSvgPathData(d), returnsNormally);
      }
    }
  });

  test('iconDataFor покрывает все значения TechniqueIcon', () {
    for (final semantic in TechniqueIcon.values) {
      expect(iconDataFor(semantic), isA<BreathinIconData>());
    }
  });

  testWidgets('BreathinIcon рендерится и уважает размер', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BreathinIcon(BreathinIcons.lungs, size: 48),
        ),
      ),
    );
    final box = tester.getSize(find.byType(BreathinIcon));
    expect(box, const Size(48, 48));
  });
}

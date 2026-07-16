import 'package:flutter_test/flutter_test.dart';

import 'package:breathin/domain/catalog/technique_groups.dart';
import 'package:breathin/domain/catalog/techniques.dart';

void main() {
  test('каждая техника каталога имеет группу (страховка новых техник)', () {
    for (final t in catalog) {
      expect(() => groupOf(t), returnsNormally, reason: t.id);
    }
  });

  test('группы непусты и вместе покрывают каталог', () {
    final byGroup = <TechniqueGroup, int>{};
    for (final t in catalog) {
      byGroup.update(groupOf(t), (n) => n + 1, ifAbsent: () => 1);
    }
    expect(byGroup.keys, containsAll(TechniqueGroup.values));
    expect(byGroup.values.fold(0, (a, b) => a + b), catalog.length);
  });
}

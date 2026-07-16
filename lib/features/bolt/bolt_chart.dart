import 'package:flutter/material.dart';

import '../../domain/models/bolt_result.dart';
import '../../ui/charts/sparkline_chart.dart';

/// Спарклайн динамики BOLT: тонкая обёртка над общим [SparklineChart]
/// (вынесен в ui/charts — ПЛАН П19). Показывает до [maxPoints] последних
/// замеров по секундам.
class BoltChart extends StatelessWidget {
  final List<BoltResult> results;
  final int maxPoints;

  const BoltChart({super.key, required this.results, this.maxPoints = 30});

  @override
  Widget build(BuildContext context) => SparklineChart(
        values: [for (final r in results) r.seconds],
        maxPoints: maxPoints,
      );
}

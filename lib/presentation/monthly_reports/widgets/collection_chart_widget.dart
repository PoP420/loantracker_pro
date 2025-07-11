import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class CollectionChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> chartData;

  const CollectionChartWidget({
    super.key,
    required this.chartData,
  });

  @override
  State<CollectionChartWidget> createState() => _CollectionChartWidgetState();
}

class _CollectionChartWidgetState extends State<CollectionChartWidget> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 300,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.lightTheme.colorScheme.shadow,
                  blurRadius: 4,
                  offset: Offset(0, 2)),
            ]),
        child: Column(children: [
          Row(children: [
            Text('Weekly Collection Trend',
                style: AppTheme.lightTheme.textTheme.titleSmall),
            Spacer(),
            Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color:
                        AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('This Week',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.primaryColor,
                        fontWeight: FontWeight.w500))),
          ]),
          SizedBox(height: 24),
          Expanded(
              child: BarChart(BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 30000,
                  barTouchData: BarTouchData(touchTooltipData:
                      BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final day =
                        widget.chartData[group.x.toInt()]["day"] as String;
                    final amount = rod.toY;
                    return BarTooltipItem(
                        '$day\n₱${amount.toStringAsFixed(0)}',
                        TextStyle(
                            color: AppTheme.lightTheme.colorScheme.surface,
                            fontWeight: FontWeight.bold,
                            fontSize: 12));
                  }), touchCallback: (FlTouchEvent event, barTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          barTouchResponse == null ||
                          barTouchResponse.spot == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          barTouchResponse.spot!.touchedBarGroupIndex;
                    });
                  }),
                  titlesData: FlTitlesData(
                      show: true,
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                if (value.toInt() >= 0 &&
                                    value.toInt() < widget.chartData.length) {
                                  return Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text(
                                          widget.chartData[value.toInt()]["day"]
                                              as String,
                                          style: AppTheme
                                              .lightTheme.textTheme.bodySmall));
                                }
                                return Text('');
                              },
                              reservedSize: 30)),
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              interval: 5000,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                return Text(
                                    '₱${(value / 1000).toStringAsFixed(0)}k',
                                    style: AppTheme
                                        .lightTheme.textTheme.bodySmall);
                              }))),
                  borderData: FlBorderData(show: false),
                  barGroups: widget.chartData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    final amount = data["amount"] as double;

                    return BarChartGroupData(x: index, barRods: [
                      BarChartRodData(
                          toY: amount,
                          color: touchedIndex == index
                              ? AppTheme.lightTheme.primaryColor
                              : AppTheme.lightTheme.primaryColor
                                  .withValues(alpha: 0.7),
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 30000,
                              color: AppTheme.lightTheme.colorScheme.outline
                                  .withValues(alpha: 0.1))),
                    ]);
                  }).toList(),
                  gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 5000,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                            color: AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.2),
                            strokeWidth: 1);
                      })))),
        ]));
  }
}

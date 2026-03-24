import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tam_an/services/analytics_service.dart';
import 'package:tam_an/providers/auth_provider.dart';
import 'package:tam_an/services/emotion_service.dart';
import 'package:tam_an/theme/app_theme.dart';
import 'package:tam_an/models/emotion_config.dart';
import 'package:intl/intl.dart';

class EmotionTrendsScreen extends StatefulWidget {
  const EmotionTrendsScreen({super.key});

  @override
  State<EmotionTrendsScreen> createState() => _EmotionTrendsScreenState();
}

class _EmotionTrendsScreenState extends State<EmotionTrendsScreen> {
  int _selectedDays = 7;
  List<EmotionTrend> _trends = [];
  bool _isLoading = true;

  // No longer needed: static map

  @override
  void initState() {
    super.initState();
    _loadTrends();
  }

  Future<void> _loadTrends() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final emotionService = context.read<EmotionService>();
    final analyticsService = AnalyticsService(emotionService);

    final trends = await analyticsService.calculateTrends(
      authProvider.user!.id,
      _selectedDays,
    );

    setState(() {
      _trends = trends;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Xu hướng cảm xúc'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector
                  _buildPeriodSelector(),
                  const SizedBox(height: 24),

                  // Chart
                  _buildChart(),
                  const SizedBox(height: 24),

                  // Legend
                  _buildLegend(),
                  const SizedBox(height: 24),

                  // Stats cards
                  _buildStatsCards(),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildPeriodButton('7 ngày', 7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPeriodButton('30 ngày', 30),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPeriodButton('90 ngày', 90),
        ),
      ],
    );
  }

  Widget _buildPeriodButton(String label, int days) {
    final isSelected = _selectedDays == days;

    return InkWell(
      onTap: () {
        setState(() => _selectedDays = days);
        _loadTrends();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryPurple
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryPurple
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (_trends.isEmpty) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        child: const Text('Chưa có dữ liệu'),
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Theme.of(context).dividerColor,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
                reservedSize: 30,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _selectedDays == 7 ? 1 : (_selectedDays == 30 ? 5 : 15),
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= _trends.length) return const SizedBox();
                  final date = _trends[value.toInt()].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('dd/MM').format(date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (_trends.length - 1).toDouble(),
          minY: 0,
          maxY: 10,
          lineBarsData: _buildLineBars(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  // This is a bit tricky since we don't have the emotion name directly in the spot
                  // But we can get it from the trends data if we know which bar it is
                  // For now, let's just use generic labels if names are not easily accessible
                  return LineTooltipItem(
                    'Cảm xúc\n${spot.y.toStringAsFixed(1)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  List<LineChartBarData> _buildLineBars() {
    final lineBars = <LineChartBarData>[];

    // For trends, we need to know WHICH emotions to show lines for.
    // Let's get them from the data itself.
    final trackedEmotions = <String>{};
    for (var trend in _trends) {
      trackedEmotions.addAll(trend.emotionIntensities.keys);
    }

    for (var emotionType in trackedEmotions) {
      final spots = <FlSpot>[];
      final color = EmotionConfig.getStyle(emotionType).color;

      for (var i = 0; i < _trends.length; i++) {
        final intensity = _trends[i].emotionIntensities[emotionType];
        if (intensity != null) {
          spots.add(FlSpot(i.toDouble(), intensity));
        }
      }

      if (spots.isNotEmpty) {
        lineBars.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: color,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.1),
            ),
          ),
        );
      }
    }

    return lineBars;
  }

  Widget _buildLegend() {
    final trackedEmotions = <String>{};
    for (var trend in _trends) {
      trackedEmotions.addAll(trend.emotionIntensities.keys);
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: trackedEmotions.map((emotion) {
        final color = EmotionConfig.getStyle(emotion).color;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              emotion,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStatsCards() {
    // Calculate some quick stats from trends
    var mostActiveEmotion = '';
    var maxCount = 0;

    final emotionCounts = <String, int>{};

    for (var trend in _trends) {
      for (var entry in trend.emotionIntensities.entries) {
        emotionCounts[entry.key] = (emotionCounts[entry.key] ?? 0) + 1;
      }
    }

    for (var entry in emotionCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostActiveEmotion = entry.key;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thống kê',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Số ngày',
                _trends.length.toString(),
                Icons.calendar_today_rounded,
                AppTheme.primaryPurple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Cảm xúc chủ đạo',
                mostActiveEmotion.isNotEmpty ? mostActiveEmotion : 'N/A',
                Icons.emoji_emotions_rounded,
                AppTheme.accentPink,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

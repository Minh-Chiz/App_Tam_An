import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tam_an/models/emotion_config.dart';
import 'package:tam_an/services/api_service.dart';
import 'package:tam_an/services/emotion_service.dart';
import 'package:tam_an/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:tam_an/models/daily_emotion.dart';
import 'package:tam_an/models/monthly_insights.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  EmotionService? _emotionService;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<DailyEmotion> _dailyEmotions = [];
  List<String> _datesWithEmotions = [];
  MonthlyInsights? _monthlyInsights;
  bool _isLoading = false;
  bool _showInsights = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final apiService = context.read<ApiService>();
      _emotionService = EmotionService(apiService);
      _initialized = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_emotionService == null) return;
    
    setState(() => _isLoading = true);
    
    await Future.wait([
      _loadCalendarDates(),
      _loadDailyEmotions(),
      _loadMonthlyInsights(),
    ]);

    setState(() => _isLoading = false);
  }

  Future<void> _loadCalendarDates() async {
    if (_emotionService == null) return;
    try {
      final dates = await _emotionService!.getCalendarDates(
        _focusedDay.year,
        _focusedDay.month,
      );
      setState(() => _datesWithEmotions = dates);
    } catch (e) {
      debugPrint('Error loading calendar dates: $e');
    }
  }

  Future<void> _loadDailyEmotions() async {
    if (_emotionService == null) return;
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
      final emotions = await _emotionService!.getEmotionsByDate(dateStr);
      setState(() => _dailyEmotions = emotions);
    } catch (e) {
      debugPrint('Error loading daily emotions: $e');
    }
  }

  Future<void> _loadMonthlyInsights() async {
    if (_emotionService == null) return;
    try {
      final insights = await _emotionService!.getMonthlyInsights(
        _focusedDay.year,
        _focusedDay.month,
      );
      setState(() => _monthlyInsights = insights);
    } catch (e) {
      debugPrint('Error loading monthly insights: $e');
    }
  }

  bool _hasEmotionOnDay(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    return _datesWithEmotions.contains(dateStr);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF7FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF2D3748);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Lịch sử',
          style: TextStyle(
            color: textColor,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primaryPurple,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      // Calendar
                      _buildCalendar(isDark),
                      const SizedBox(height: 24),

                      // Summary Card
                      _buildSummaryCard(),
                      const SizedBox(height: 24),

                      // Monthly Insights
                      if (_monthlyInsights != null) _buildMonthlyInsights(isDark),
                      if (_monthlyInsights != null) const SizedBox(height: 24),

                      // Timeline
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 16),
                        child: Text(
                          'Dòng thời gian',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                        ),
                      ),
                      _buildTimeline(isDark),
                      
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCalendar(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.03);
    final calendarTextColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF4A5568);
    final calendarHeadingColor = isDark ? Colors.white : const Color(0xFF2D3748);
    final outsideColor = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E0);
    final iconColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: calendarHeadingColor,
          ),
          leftChevronIcon: Icon(Icons.chevron_left_rounded, color: iconColor),
          rightChevronIcon: Icon(Icons.chevron_right_rounded, color: iconColor),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: iconColor, fontWeight: FontWeight.w600, fontSize: 13),
          weekendStyle: const TextStyle(color: Color(0xFFED8936), fontWeight: FontWeight.w600, fontSize: 13),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: TextStyle(fontWeight: FontWeight.w600, color: calendarTextColor),
          weekendTextStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFED8936)),
          outsideTextStyle: TextStyle(fontWeight: FontWeight.w500, color: outsideColor),
          todayDecoration: BoxDecoration(
            color: AppTheme.primaryPurple.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold),
          selectedDecoration: const BoxDecoration(
            color: AppTheme.primaryPurple,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x334F46E5),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (_hasEmotionOnDay(day)) {
              final isSelected = isSameDay(_selectedDay, day);
              return Positioned(
                bottom: 8,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : const Color(0xFF48BB78), // Green
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            return null;
          },
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _loadDailyEmotions();
        },
        onPageChanged: (focusedDay) {
          setState(() => _focusedDay = focusedDay);
          _loadCalendarDates();
          _loadMonthlyInsights();
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    final dateFormat = DateFormat('dd/MM/yyyy', 'vi');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)], // Blue shades
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.event_note_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormat.format(_selectedDay),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tổng quan ngày trong tháng',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_dailyEmotions.length} ghi nhận',
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(bool isDark) {
    if (_dailyEmotions.isEmpty) {
      final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
      final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.02);
      final emptyBg = isDark ? const Color(0xFF334155) : const Color(0xFFF7FAFC);
      final titleColor = isDark ? Colors.white : const Color(0xFF2D3748);
      final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: emptyBg,
                shape: BoxShape.circle,
              ),
              child: const Text('📭', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có dữ liệu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn chưa ghi nhận cảm xúc nào trong ngày này.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _dailyEmotions.map((emotion) => _buildTimelineItem(emotion, isDark)).toList(),
    );
  }

  Widget _buildTimelineItem(DailyEmotion emotion, bool isDark) {
    final style = EmotionConfig.getStyle(emotion.emotionType);
    final icon = style.icon;
    final color = style.color;
    final gradient = style.gradient;

    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.03);
    final timeColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096);
    final contextBg = isDark ? const Color(0xFF334155) : const Color(0xFFF7FAFC);
    final contextBorder = isDark ? const Color(0xFF475569) : const Color(0xFFEDF2F7);
    final contextText = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF4A5568);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time and Emoji
          Column(
            children: [
              Text(
                emotion.timeString,
                style: TextStyle(
                  color: timeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: gradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(width: 20),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emotion.emotionType,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                if (emotion.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: emotion.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (emotion.noteText != null && emotion.noteText!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: contextBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: contextBorder),
                    ),
                    child: Text(
                      emotion.noteText!,
                      style: TextStyle(
                        color: contextText,
                        height: 1.5,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyInsights(bool isDark) {
    final insights = _monthlyInsights!;

    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.03);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFEDF2F7);
    final titleColor = isDark ? Colors.white : const Color(0xFF2D3748);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096);
    final iconBgColor = isDark ? const Color(0xFF334155) : const Color(0xFFF7FAFC);
    final listLabelColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF4A5568);
    final insightTitleColor = isDark ? const Color(0xFF63B3ED) : const Color(0xFF2B6CB0); // Darker blue vs lighter blue for dark mode
    final insightBgColor = isDark ? const Color(0xFF2A4365) : const Color(0xFFEBF8FF);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Header — tap to expand
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() => _showInsights = !_showInsights);
              },
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  // Emotional Score Circle
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          _getScoreColor(insights.emotionalScore),
                          _getScoreColor(insights.emotionalScore).withAlpha(180),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getScoreColor(insights.emotionalScore).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${insights.emotionalScore}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đánh giá tháng ${insights.month}/${insights.year}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              insights.trendIcon,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${insights.trendText} • ${insights.totalEntries} lần',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _showInsights ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: subtitleColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_showInsights) ...[
            const SizedBox(height: 20),
            Divider(color: borderColor),
            const SizedBox(height: 20),
            
            // Emotion Breakdown with sleek bars
            if (insights.emotionBreakdown.isNotEmpty) ...[
              Text(
                'Phân bổ cảm xúc trong tháng',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 16),
              ...insights.emotionBreakdown.entries.map((entry) {
                final emotion = entry.key;
                final count = entry.value;
                final percentage = insights.totalEntries > 0
                    ? (count / insights.totalEntries * 100)
                    : 0.0;
                final style = EmotionConfig.getStyle(emotion);
                final gradient = style.gradient;
                final avgIntensity = insights.averageIntensity[emotion];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            emotion,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: listLabelColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$count lần (${percentage.toStringAsFixed(0)}%)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: subtitleColor,
                            ),
                          ),
                          if (avgIntensity != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: style.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '⚡${avgIntensity.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: style.color,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 6,
                          child: Stack(
                            children: [
                              Container(color: borderColor),
                              FractionallySizedBox(
                                widthFactor: percentage / 100,
                                child: Container(
                                  decoration: BoxDecoration(gradient: gradient),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],

            Divider(color: borderColor),
            const SizedBox(height: 16),

            // AI Suggestions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: insightBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('💡', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Text(
                  'Góc nhìn từ AI',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: insightTitleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...insights.suggestions.map((suggestion) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4299E1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: TextStyle(
                          color: listLabelColor,
                          height: 1.5,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInsightStat(
                    '${insights.totalEntries}',
                    'Ghi nhận',
                    Icons.edit_note_rounded,
                    titleColor,
                    subtitleColor,
                  ),
                  Container(width: 1, height: 40, color: borderColor),
                  _buildInsightStat(
                    '${insights.notesCount}',
                    'Ghi chú',
                    Icons.article_rounded,
                    titleColor,
                    subtitleColor,
                  ),
                  Container(width: 1, height: 40, color: borderColor),
                  _buildInsightStat(
                    '${insights.emotionalScore}',
                    'Điểm CX',
                    Icons.favorite_rounded,
                    titleColor,
                    subtitleColor,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 70) return const Color(0xFF48BB78); // Green
    if (score >= 50) return const Color(0xFFED8936); // Orange
    if (score >= 30) return const Color(0xFFF56565); // Red
    return const Color(0xFFE53E3E); // Darker red
  }

  Widget _buildInsightStat(String value, String label, IconData icon, Color titleColor, Color subtitleColor) {
    return Column(
      children: [
        Icon(icon, color: subtitleColor, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: subtitleColor,
          ),
        ),
      ],
    );
  }
}

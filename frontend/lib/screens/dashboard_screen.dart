import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tam_an/providers/emotion_provider.dart';
import 'package:tam_an/providers/auth_provider.dart';
import 'package:tam_an/theme/app_theme.dart';
import 'package:tam_an/screens/full_analysis_screen.dart';
import 'package:tam_an/screens/achievements_screen.dart';
import 'package:intl/intl.dart';
import 'package:tam_an/models/emotion_config.dart';
import 'package:tam_an/screens/monthly_wrapped_screen.dart';
import 'package:tam_an/services/api_service.dart';
import 'package:tam_an/services/emotion_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmotionProvider>().loadDashboardStats();
    });
  }

  Future<void> _refreshData() async {
    await context.read<EmotionProvider>().loadDashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF7FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF2D3748);

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppTheme.primaryPurple,
        child: Consumer<EmotionProvider>(
          builder: (context, emotionProvider, _) {
            if (emotionProvider.isLoading && emotionProvider.dashboardStats == null) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple));
            }

            final stats = emotionProvider.dashboardStats;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildSliverAppBar(context, isDark, bgColor),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Streak & Points Status Bar
                        _buildStatusBar(context, isDark),
                        const SizedBox(height: 24),

                        // Monthly Wrapped Banner
                        _buildMonthlyWrappedCard(context, isDark),
                        const SizedBox(height: 24),

                        if (stats == null || stats.totalEntries == 0)
                          _buildEmptyState(isDark)
                        else ...[
                          // Stats Overview Grid
                          _buildStatsOverview(stats, isDark),
                          const SizedBox(height: 24),

                          // Insight Card
                          _buildInsightCard(stats.insights.message, isDark),
                          const SizedBox(height: 32),

                          // Emotion Distribution Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Phân bổ cảm xúc',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Emotion Chart (Horizontal stacked bar)
                          _buildEmotionChart(stats.emotionDistribution, isDark),
                          const SizedBox(height: 20),

                          // Emotion Breakdown Details
                          stats.emotionDistribution.isNotEmpty
                              ? _buildEmotionDistribution(stats.emotionDistribution, isDark)
                              : const SizedBox.shrink(),
                          
                          const SizedBox(height: 40),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark, Color bgColor) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final now = DateTime.now();
    final hour = now.hour;
    
    String greeting;
    if (hour < 12) {
      greeting = 'Chào buổi sáng,';
    } else if (hour < 18) {
      greeting = 'Chào buổi chiều,';
    } else {
      greeting = 'Chào buổi tối,';
    }

    final dateColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096);
    final greetingColor = isDark ? Colors.white : const Color(0xFF2D3748);
    final avatarBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final avatarBorderColor = isDark ? const Color(0xFF334155) : Colors.grey.shade200;
    final avatarShadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05);

    return SliverAppBar(
      backgroundColor: bgColor,
      elevation: 0,
      expandedHeight: 140, // Tăng chiều cao để không bị cắt tên
      floating: true,
      pinned: false,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEEE, dd MMMM', 'vi').format(now),
                        style: TextStyle(
                          color: dateColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                          children: [
                            TextSpan(
                              text: greeting,
                              style: TextStyle(color: greetingColor),
                            ),
                            const TextSpan(text: '\n'), // Luôn xuống dòng để đẹp hơn
                            TextSpan(
                              text: user?.name ?? 'bạn',
                              style: const TextStyle(color: AppTheme.primaryPurple),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: avatarBgColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: avatarBorderColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: avatarShadowColor,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(Icons.person_outline_rounded, color: AppTheme.primaryPurple.withOpacity(0.8), size: 28),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(BuildContext context, bool isDark) {
    final emotionProvider = context.watch<EmotionProvider>();
    final streak = emotionProvider.streakData;

    if (streak == null) return const SizedBox.shrink();

    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.03);
    final dividerColor = isDark ? const Color(0xFF334155) : Colors.grey.shade200;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AchievementsScreen()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusItem(
                  icon: streak.currentStreak > 0 ? '🔥' : '💤',
                  label: 'Chuỗi ngày',
                  value: '${streak.currentStreak}',
                  isDark: isDark,
                ),
                Container(width: 1, height: 40, color: dividerColor),
                _buildStatusItem(
                  icon: '⭐',
                  label: 'Điểm tích lũy',
                  value: '${streak.points}',
                  isDark: isDark,
                ),
                Container(width: 1, height: 40, color: dividerColor),
                _buildStatusItem(
                  icon: '🏆',
                  label: 'Thành tựu',
                  value: '${streak.unlockedCount}',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem({required String icon, required String label, required String value, required bool isDark}) {
    final textColor = isDark ? Colors.white : const Color(0xFF2D3748);
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096);

    return Column(
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyWrappedCard(BuildContext context, bool isDark) {
    final now = DateTime.now();
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)], // Violet to Indigo
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
            );
            
            try {
              final apiService = context.read<ApiService>();
              final emotionService = EmotionService(apiService);
              final wrappedData = await emotionService.getMonthlyWrapped(now.year, now.month);
              
              if (!mounted) return;
              Navigator.pop(context); // close loading
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MonthlyWrappedScreen(data: wrappedData),
                ),
              );
            } catch (e) {
              if (!mounted) return;
              Navigator.pop(context); // close loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi tải dữ liệu: ${e.toString()}')),
              );
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tổng kết tháng',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nhìn lại hành trình cảm xúc',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_forward_ios, color: Color(0xFF4F46E5), size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview(stats, bool isDark) {
    String dominantEmotion = '😊';
    String dominantEmotionName = 'Vui';
    if (stats.emotionDistribution.isNotEmpty) {
      final sorted = List.from(stats.emotionDistribution)
        ..sort((a, b) => b.count.compareTo(a.count));
      dominantEmotionName = sorted.first.emotionType;
      dominantEmotion = _getEmotionEmoji(sorted.first.emotionType);
    }

    return Row(
      children: [
        Expanded(
          child: _buildSquareStatCard(
            icon: '📝',
            label: 'Tổng ghi nhận',
            value: '${stats.totalEntries}',
            color: const Color(0xFF3182CE),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSquareStatCard(
            icon: dominantEmotion,
            label: 'Cảm xúc chủ đạo',
            value: dominantEmotionName,
            color: const Color(0xFFD53F8C), // Pinkish
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSquareStatCard({
    required String icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.03);
    final valueColor = isDark ? Colors.white : const Color(0xFF2D3748);
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096);

    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getEmotionEmoji(String emotionType) {
    const emojiMap = {
      'Vui': '😊',
      'Vui vẻ': '😊',
      'Bình thường': '😌',
      'Buồn': '😔',
      'Căng thẳng': '😣',
      'Lo âu': '😰',
      'Giận dữ': '😡',
    };
    return emojiMap[emotionType] ?? '😊';
  }

  Widget _buildInsightCard(String message, bool isDark) {
    final bgColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4); // Dark Green vs Light Mint Green
    final borderColor = isDark ? const Color(0xFF065F46) : const Color(0xFFBBF7D0); 
    final iconBgColor = isDark ? const Color(0xFF047857) : const Color(0xFF86EFAC);
    final titleColor = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF166534);
    final textColor = isDark ? const Color(0xFF34D399) : const Color(0xFF14532D);
    final actionColor = isDark ? const Color(0xFF10B981) : const Color(0xFF15803D);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('✨', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Tóm tắt',
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: textColor,
              height: 1.6,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Action Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FullAnalysisScreen()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Xem phân tích chi tiết',
                    style: TextStyle(
                      color: actionColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: actionColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionChart(List<dynamic> distribution, bool isDark) {
    if (distribution.isEmpty) return const SizedBox.shrink();

    final totalCount = distribution.fold<int>(0, (sum, item) => sum + (item.count as int));
    if (totalCount == 0) return const SizedBox.shrink();

    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.03);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 16,
              child: Row(
                children: distribution.map<Widget>((item) {
                  final count = item.count as int;
                  final fraction = count / totalCount;
                  final style = EmotionConfig.getStyle(item.emotionType);
                  return Expanded(
                    flex: (fraction * 1000).round().clamp(1, 1000),
                    child: Container(color: style.color),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionDistribution(List<dynamic> distribution, bool isDark) {
    final totalCount = distribution.fold<int>(0, (sum, item) => sum + (item.count as int));

    return Column(
      children: distribution.map<Widget>((item) {
        final emotionType = item.emotionType;
        final count = item.count as int;
        final percentage = (count / totalCount * 100);
        final style = EmotionConfig.getStyle(emotionType);

        return _buildSleekEmotionBar(
          emotion: emotionType,
          icon: style.icon,
          count: count,
          percentage: percentage,
          gradient: style.gradient,
          isDark: isDark,
        );
      }).toList(),
    );
  }

  Widget _buildSleekEmotionBar({
    required String emotion,
    required IconData icon,
    required int count,
    required double percentage,
    required LinearGradient gradient,
    required bool isDark,
  }) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.02);
    final titleColor = isDark ? Colors.white : const Color(0xFF2D3748);
    final countColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096);
    final trackColor = isDark ? const Color(0xFF334155) : const Color(0xFFEDF2F7);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      emotion,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: titleColor,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 6,
                          child: Stack(
                            children: [
                              Container(color: trackColor), // Track color
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
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$count lần',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: countColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF2D3748);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096);
    final iconBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ]
              ),
              child: const Text('📊', style: TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 32),
            Text(
              'Chưa có dữ liệu',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: titleColor),
            ),
            const SizedBox(height: 12),
            Text(
              'Bắt đầu ghi nhật ký cảm xúc\nđể xem thống kê sinh động ở đây',
              textAlign: TextAlign.center,
              style: TextStyle(color: subtitleColor, fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

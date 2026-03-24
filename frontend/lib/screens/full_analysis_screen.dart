import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tam_an/providers/emotion_provider.dart';
import 'package:tam_an/models/full_analysis.dart';
import 'package:tam_an/models/emotion_config.dart';
import 'package:tam_an/theme/app_theme.dart';
import 'dart:math' as math;

class FullAnalysisScreen extends StatefulWidget {
  const FullAnalysisScreen({super.key});

  @override
  State<FullAnalysisScreen> createState() => _FullAnalysisScreenState();
}

class _FullAnalysisScreenState extends State<FullAnalysisScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreAnimator;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _scoreAnimator = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scoreAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scoreAnimator, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EmotionProvider>();
      provider.clearError(); // Clear any stale errors from other operations
      provider.loadFullAnalysis().then((_) {
        if (mounted) _scoreAnimator.forward();
      });
    });
  }

  @override
  void dispose() {
    _scoreAnimator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF7FAFC);
    final titleColor = isDark ? Colors.white : const Color(0xFF2D3748);
    final iconColor = isDark ? Colors.white : AppTheme.primaryPurple;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Phân tích toàn bộ',
          style: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: iconColor),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<EmotionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.fullAnalysis == null) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.primaryPurple),
            );
          }

          if (provider.error != null && provider.fullAnalysis == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Lỗi: ${provider.error}', style: TextStyle(color: titleColor)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => provider.loadFullAnalysis(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                    ),
                    child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          final analysis = provider.fullAnalysis;
          if (analysis == null || analysis.totalEntries == 0) {
            return _buildEmptyState(isDark);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadFullAnalysis();
              _scoreAnimator.reset();
              _scoreAnimator.forward();
            },
            color: const Color(0xFF8B5CF6),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildScoreCard(analysis, isDark),
                  const SizedBox(height: 20),
                  _buildQuickStats(analysis, isDark),
                  const SizedBox(height: 24),
                  _buildDistributionSection(analysis, isDark),
                  const SizedBox(height: 24),
                  _buildIntensitySection(analysis, isDark),
                  const SizedBox(height: 24),
                  _buildSuggestionsSection(analysis, isDark),
                  const SizedBox(height: 24),
                  if (analysis.topContexts.isNotEmpty) ...[
                    _buildContextsSection(analysis, isDark),
                    const SizedBox(height: 24),
                  ],
                  if (analysis.themes.isNotEmpty) ...[
                    _buildThemesSection(analysis, isDark),
                    const SizedBox(height: 24),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF2D3748);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📊', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Chưa có dữ liệu để phân tích',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy ghi nhận cảm xúc hàng ngày để nhận phân tích chi tiết',
              style: TextStyle(
                fontSize: 14,
                color: subtitleColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Emotional Score Card ──────────────────────────────────────────
  Widget _buildScoreCard(FullAnalysis analysis, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
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
      child: Column(
        children: [
          const Text(
            'Chỉ số cảm xúc tổng thể',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              final animatedScore =
                  (analysis.emotionalScore * _scoreAnimation.value).round();
              return SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(160, 160),
                      painter: _ScoreRingPainter(
                        progress: _scoreAnimation.value *
                            analysis.emotionalScore /
                            100,
                        color: _getScoreColor(analysis.emotionalScore),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$animatedScore',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          analysis.scoreLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Trend indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(analysis.trendIcon,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  analysis.trendText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF34D399); // Light green
    if (score >= 60) return const Color(0xFF60A5FA); // Light blue
    if (score >= 40) return const Color(0xFFFBBF24); // Light orange
    return const Color(0xFFF87171); // Light red
  }

  // ─── Quick Stats Row ──────────────────────────────────────────────
  Widget _buildQuickStats(FullAnalysis analysis, bool isDark) {
    final dominantEmotion = analysis.emotionDistribution.isNotEmpty
        ? analysis.emotionDistribution.first.emotionType
        : 'N/A';

    return Row(
      children: [
        Expanded(
          child: _buildQuickStatCard(
            icon: '📝',
            label: 'Tổng ghi nhận',
            value: '${analysis.totalEntries}',
            gradient: const LinearGradient(
              colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatCard(
            icon: _getEmotionEmoji(dominantEmotion),
            label: 'Chủ đạo',
            value: dominantEmotion,
            gradient: const LinearGradient(
              colors: [Color(0xFFC084FC), Color(0xFF9333EA)],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatCard(
            icon: '📖',
            label: 'Ghi chú',
            value: '${analysis.notesCount}',
            gradient: const LinearGradient(
              colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard({
    required String icon,
    required String label,
    required String value,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Emotion Distribution ─────────────────────────────────────────
  Widget _buildDistributionSection(FullAnalysis analysis, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04);
    final textColor = isDark ? Colors.white : const Color(0xFF2D3748);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600;
    final trackColor = isDark ? const Color(0xFF334155) : Colors.grey.shade200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Phân bổ cảm xúc', Icons.pie_chart_rounded, isDark),
        const SizedBox(height: 12),
        ...analysis.emotionDistribution.map((item) {
          final config = _getEmotionConfig(item.emotionType);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: config['gradient'] as LinearGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        config['icon'] as IconData,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item.emotionType,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    Text(
                      '${item.count} lần',
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${item.percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      children: [
                        Container(color: trackColor),
                        FractionallySizedBox(
                          widthFactor: item.percentage / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: config['gradient'] as LinearGradient,
                            ),
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
      ],
    );
  }

  // ─── Intensity Section ────────────────────────────────────────────
  Widget _buildIntensitySection(FullAnalysis analysis, bool isDark) {
    if (analysis.averageIntensity.isEmpty) return const SizedBox.shrink();

    final intensityEntries = analysis.averageIntensity.entries.toList();
    // Sort by intensity descending (highest impact first)
    intensityEntries.sort((a, b) => b.value.average.compareTo(a.value.average));

    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04);
    final textColor = isDark ? Colors.white : const Color(0xFF2D3748);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500;
    final trackColor = isDark ? const Color(0xFF334155) : Colors.grey.shade100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Cường độ trung bình', Icons.speed_rounded, isDark),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: intensityEntries.map((entry) {
              final intensityData = entry.value;
              final intensity = intensityData.average;
              // Use emotion-specific color for better "accuracy" to theme
              final emotionStyle = EmotionConfig.getStyle(entry.key);
              final color = emotionStyle.color;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _getEmotionEmoji(entry.key),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${intensityData.count} lần)',
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${intensity.toStringAsFixed(2)}/10',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              height: 8,
                              child: Stack(
                                children: [
                                  Container(color: trackColor),
                                  FractionallySizedBox(
                                    widthFactor: (intensity / 10).clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: emotionStyle.gradient,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Suggestions Section ──────────────────────────────────────────
  Widget _buildSuggestionsSection(FullAnalysis analysis, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF2D3748);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Nhận xét & Gợi ý', Icons.lightbulb_rounded, isDark),
        const SizedBox(height: 12),
        ...analysis.suggestions.asMap().entries.map((entry) {
          final index = entry.key;
          final suggestion = entry.value;

          final gradients = [
            [const Color(0xFF8B5CF6), const Color(0xFF6366F1)], // Purple - Indigo
            [const Color(0xFF34D399), const Color(0xFF10B981)], // Emerald
            [const Color(0xFFFBBF24), const Color(0xFFF59E0B)], // Amber
            [const Color(0xFFF472B6), const Color(0xFFEC4899)], // Pink
            [const Color(0xFF60A5FA), const Color(0xFF3B82F6)], // Blue
          ];

          final colors = gradients[index % gradients.length];
          final bgColor = isDark ? colors[0].withOpacity(0.1) : colors[0].withOpacity(0.05);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors[0].withOpacity(isDark ? 0.3 : 0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: colors,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      color: textColor,
                      height: 1.6,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── Contexts Section ─────────────────────────────────────────────
  Widget _buildContextsSection(FullAnalysis analysis, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04);
    final textColor = isDark ? Colors.white : const Color(0xFF2D3748);
    final accentBg = isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
            'Hoạt động & Địa điểm', Icons.place_rounded, isDark),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: analysis.topContexts.asMap().entries.map((entry) {
              final index = entry.key;
              final ctx = entry.value;
              final icons = ['📍', '🏃', '🏠', '☕', '🎯'];

              return Padding(
                padding: EdgeInsets.only(
                    bottom:
                        index < analysis.topContexts.length - 1 ? 16 : 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentBg,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        icons[index % icons.length],
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        ctx.context,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${ctx.count} lần',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Themes Section ───────────────────────────────────────────────
  Widget _buildThemesSection(FullAnalysis analysis, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Chủ đề nổi bật', Icons.tag_rounded, isDark),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: analysis.themes.map((theme) {
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withOpacity(isDark ? 0.2 : 0.1),
                    const Color(0xFFEC4899).withOpacity(isDark ? 0.2 : 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                ),
              ),
              child: Text(
                '🏷️ $theme',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF2D3748);
    return Row(
      children: [
        Icon(icon, size: 24, color: const Color(0xFF8B5CF6)),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
      ],
    );
  }

  String _getEmotionEmoji(String emotionType) {
    const emojiMap = {
      'Vui': '😊',
      'Vui vẻ': '😊',
      'Bình thường': '😌',
      'Buồn': '😔',
      'Lo âu': '😰',
      'Căng thẳng': '😣',
      'Giận dữ': '😤',
    };
    return emojiMap[emotionType] ?? '😐';
  }

  Map<String, dynamic> _getEmotionConfig(String emotionType) {
    final configs = {
      'Vui vẻ': {
        'icon': Icons.sentiment_very_satisfied_rounded,
        'gradient': const LinearGradient(
            colors: [Color(0xFFFDD835), Color(0xFFFBC02D)]),
      },
      'Vui': {
        'icon': Icons.sentiment_very_satisfied_rounded,
        'gradient': const LinearGradient(
            colors: [Color(0xFFFDD835), Color(0xFFFBC02D)]),
      },
      'Bình thường': {
        'icon': Icons.sentiment_neutral_rounded,
        'gradient': const LinearGradient(
            colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)]),
      },
      'Buồn': {
        'icon': Icons.sentiment_dissatisfied_rounded,
        'gradient': const LinearGradient(
            colors: [Color(0xFF757575), Color(0xFF616161)]),
      },
      'Lo âu': {
        'icon': Icons.psychology_rounded,
        'gradient': const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)]),
      },
      'Căng thẳng': {
        'icon': Icons.warning_amber_rounded,
        'gradient': const LinearGradient(
            colors: [Color(0xFFFF6F00), Color(0xFFE65100)]),
      },
      'Giận dữ': {
        'icon': Icons.sentiment_very_dissatisfied_rounded,
        'gradient': const LinearGradient(
            colors: [Color(0xFFE53935), Color(0xFFC62828)]),
      },
    };

    return configs[emotionType] ??
        {
          'icon': Icons.sentiment_neutral_rounded,
          'gradient': const LinearGradient(
              colors: [Color(0xFF9E9E9E), Color(0xFF757575)]),
        };
  }
}

// ─── Score Ring Painter ────────────────────────────────────────────
class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScoreRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

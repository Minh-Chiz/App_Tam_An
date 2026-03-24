import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tam_an/providers/emotion_provider.dart';
import 'package:tam_an/screens/emotion_flow_screen.dart';
import 'package:tam_an/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:tam_an/models/emotion_config.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmotionProvider>().loadEmotions();
    });
  }

  Future<void> _refreshData() async {
    await context.read<EmotionProvider>().loadEmotions();
  }

  void _writeNewJournal() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmotionFlowScreen()),
    ).then((_) {
      _refreshData();
    });
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
          'Nhật ký',
          style: TextStyle(
            color: textColor,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _writeNewJournal,
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: const Text(
          'Viết nhật ký',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryPurple,
        elevation: 4,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppTheme.primaryPurple,
        child: Consumer<EmotionProvider>(
          builder: (context, emotionProvider, _) {
            if (emotionProvider.isLoading && emotionProvider.emotions.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple));
            }

            final emotions = emotionProvider.emotions;

            if (emotions.isEmpty) {
              return _buildEmptyState(isDark);
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: emotions.length,
              itemBuilder: (context, index) {
                final entry = emotions[index];
                return _buildJournalCard(entry, isDark);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildJournalCard(dynamic entry, bool isDark) {
    final style = EmotionConfig.getStyle(entry.emotionType);
    final icon = style.icon;
    final color = style.color;
    final gradient = style.gradient;
    
    final dateTime = entry.timestamp as DateTime;
    final dateFormat = DateFormat('dd/MM/yyyy', 'vi');
    final timeFormat = DateFormat('HH:mm');
    final dateStr = dateFormat.format(dateTime);
    final timeStr = timeFormat.format(dateTime);

    final contextParts = <String>[];
    if (entry.location != null && entry.location.isNotEmpty) {
      contextParts.add('📍 ${entry.location}');
    }
    if (entry.activity != null && entry.activity.isNotEmpty) {
      contextParts.add('🏃 ${entry.activity}');
    }
    if (entry.company != null && entry.company.isNotEmpty) {
      contextParts.add('👥 ${entry.company}');
    }
    final contextStr = contextParts.join(' • ');

    // Theming Colors
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.03);
    final dateColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096);
    final contextBoxBg = isDark ? const Color(0xFF334155) : const Color(0xFFF7FAFC);
    final contextBoxBorder = isDark ? const Color(0xFF475569) : const Color(0xFFEDF2F7);
    final contextTextColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF4A5568);
    final noteTextColor = isDark ? Colors.white : const Color(0xFF2D3748);
    final intensityBgColor = isDark ? color.withOpacity(0.2) : color.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
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
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.emotionType,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dateStr • $timeStr',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: dateColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: intensityBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Cường độ: ${entry.intensity}/10',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          
          if (contextStr.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: contextBoxBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: contextBoxBorder),
              ),
              child: Text(
                contextStr,
                style: TextStyle(
                  color: contextTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          
          if (entry.noteText != null && entry.noteText.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              entry.noteText,
              style: TextStyle(
                color: noteTextColor,
                fontSize: 16,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ]
              ),
              child: const Text('📖', style: TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 32),
            Text(
              'Chưa có nhật ký',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bắt đầu ghi nhật ký cảm xúc\nđể xem tại đây',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

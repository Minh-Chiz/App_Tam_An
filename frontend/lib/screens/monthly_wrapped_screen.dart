import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tam_an/models/monthly_wrapped.dart';
import 'package:tam_an/theme/app_theme.dart';
import 'package:tam_an/models/emotion_config.dart';

class MonthlyWrappedScreen extends StatefulWidget {
  final MonthlyWrapped data;

  const MonthlyWrappedScreen({super.key, required this.data});

  @override
  State<MonthlyWrappedScreen> createState() => _MonthlyWrappedScreenState();
}

class _MonthlyWrappedScreenState extends State<MonthlyWrappedScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;
  
  Timer? _timer;
  double _progress = 0.0;
  static const int _storyDurationMilliseconds = 5000;
  static const int _timerTickMilliseconds = 50;

  @override
  void initState() {
    super.initState();
    _startStoryTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startStoryTimer() {
    _timer?.cancel();
    _progress = 0.0;
    
    _timer = Timer.periodic(const Duration(milliseconds: _timerTickMilliseconds), (timer) {
      if (!mounted) return;
      setState(() {
        _progress += _timerTickMilliseconds / _storyDurationMilliseconds;
      });

      if (_progress >= 1.0) {
        _timer?.cancel();
        _nextPage();
      }
    });
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      // Close at the end
      Navigator.pop(context);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void _handleTap(TapUpDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapPosition = details.globalPosition.dx;

    if (tapPosition < screenWidth / 3) {
      _previousPage();
    } else {
      // Skip current progress and go next
      _progress = 1.0;
      _timer?.cancel();
      _nextPage();
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    _startStoryTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark base
      body: GestureDetector(
        onTapUp: _handleTap,
        onLongPressDown: (_) => _timer?.cancel(),
        onLongPressUp: _startStoryTimer,
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Handle via taps only
              onPageChanged: _onPageChanged,
              children: [
                _buildSlideContainer(
                  gradient: const RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [Color(0xFF8B5CF6), Color(0xFF1E1B4B)],
                  ),
                  child: _buildCoverSlide(),
                ),
                _buildSlideContainer(
                  gradient: const RadialGradient(
                    center: Alignment.bottomLeft,
                    radius: 1.5,
                    colors: [Color(0xFFF97316), Color(0xFF431407)],
                  ),
                  child: _buildStatsSlide(),
                ),
                _buildSlideContainer(
                  gradient: _getEmotionDarkGradient(widget.data.mostCommonEmotion),
                  child: _buildEmotionSlide(),
                ),
                _buildSlideContainer(
                  gradient: const RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.5,
                    colors: [Color(0xFF0D9488), Color(0xFF042F2E)],
                  ),
                  child: _buildNotesSlide(),
                ),
                _buildSlideContainer(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E293B), Color(0xFF020617)],
                  ),
                  child: _buildSummarySlide(),
                ),
              ],
            ),
            
            // Story Bars at the top
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
                child: Row(
                  children: List.generate(_totalPages, (index) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                        child: _buildProgressBar(index),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Close button
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 24, right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideContainer({required Gradient gradient, required Widget child}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        child: child,
      ),
    );
  }

  Widget _buildProgressBar(int index) {
    double barProgress = 0.0;
    if (index < _currentPage) {
      barProgress = 1.0;
    } else if (index == _currentPage) {
      barProgress = _progress;
    }

    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                width: constraints.maxWidth * barProgress,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(32),
      child: child,
    );
  }

  Widget _buildCoverSlide() {
    final now = DateTime.now();
    final isCurrentMonth = widget.data.year == now.year && widget.data.month == now.month;
    
    final title = isCurrentMonth 
        ? "Hành trình tháng ${widget.data.month}" 
        : "Đã qua tháng ${widget.data.month} rồi!";
        
    final subtitle = isCurrentMonth
        ? "Cùng Tâm An nhìn lại những cảm xúc\ncủa bạn tính đến hiện tại nhé."
        : "Cùng Tâm An nhìn lại hành trình cảm xúc\ncủa bạn trong tháng qua nhé.";

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: _buildGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, size: 72, color: Colors.white),
              ),
              const SizedBox(height: 32),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSlide() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGlassCard(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${widget.data.totalDays}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 100,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 8),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "NGÀY ĐỒNG HÀNH",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Text(
              "Bạn đã tạo ra ${widget.data.totalEntries} khoảnh khắc cảm xúc\ntrong tháng ${widget.data.month}.",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Gradient _getEmotionDarkGradient(String emotionType) {
    final style = EmotionConfig.getStyle(emotionType);
    final baseColor = style.color;
    
    return RadialGradient(
      center: Alignment.center,
      radius: 1.5,
      colors: [
        baseColor.withOpacity(0.6),
        const Color(0xFF0F172A),
      ],
    );
  }

  Widget _buildEmotionSlide() {
    final mainEmotion = widget.data.mostCommonEmotion;
    final config = EmotionConfig.getStyle(mainEmotion);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Cảm xúc chủ đạo",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            _buildGlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: config.gradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: config.color.withOpacity(0.5),
                          blurRadius: 32,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(config.icon, size: 80, color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    mainEmotion.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Text(
              "Có tới ${widget.data.positivePercentage}% thời gian trong tháng\nbạn duy trì được trạng thái tích cực!",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSlide() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGlassCard(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_note_rounded, size: 80, color: Colors.white),
                  const SizedBox(height: 24),
                  Text(
                    "${widget.data.totalNotes}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "DÒNG NHẬT KÝ",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.white.withOpacity(0.5), width: 4),
                ),
              ),
              child: const Text(
                "Mỗi dòng chữ viết ra là một lần bạn trò chuyện và thấu hiểu chính bản thân mình sâu sắc hơn.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySlide() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "TỔNG KẾT",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 6,
          ),
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: _buildGlassCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Tháng ${widget.data.month} / ${widget.data.year}",
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildSummaryRow(Icons.calendar_month_rounded, "${widget.data.totalDays} Ngày"),
                const SizedBox(height: 24),
                _buildSummaryRow(Icons.mood_rounded, widget.data.mostCommonEmotion),
                const SizedBox(height: 24),
                _buildSummaryRow(Icons.bolt_rounded, "${widget.data.positivePercentage}% Tích cực"),
                const SizedBox(height: 24),
                _buildSummaryRow(Icons.book_rounded, "${widget.data.totalNotes} Nhật ký"),
              ],
            ),
          ),
        ),
        const SizedBox(height: 48),
        Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 48),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tính năng chia sẻ sắp ra mắt!')),
                );
              },
              borderRadius: BorderRadius.circular(28),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      "Chia sẻ hành trình",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tam_an/theme/app_theme.dart';
import 'package:tam_an/models/emotion_config.dart';
import 'package:tam_an/providers/emotion_provider.dart';

class EmotionCheckinScreen extends StatefulWidget {
  final Function(String, int) onNext;
  final VoidCallback? onSkip;

  const EmotionCheckinScreen({super.key, required this.onNext, this.onSkip});

  @override
  State<EmotionCheckinScreen> createState() => _EmotionCheckinScreenState();
}

class _EmotionCheckinScreenState extends State<EmotionCheckinScreen> {
  String? selectedEmotion;
  double intensity = 5.0;

  void _showAddEmotionDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final dialogBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF2D3748);
        return AlertDialog(
          backgroundColor: dialogBgColor,
          title: Text('Thêm cảm xúc mới', style: TextStyle(color: textColor)),
          content: TextField(
            controller: controller,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Nhập tên cảm xúc (ví dụ: Hào hứng)',
              hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : Colors.grey),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primaryPurple, width: 2),
              ),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  context.read<EmotionProvider>().addCustomEmotion(name);
                  Navigator.pop(context);
                  setState(() => selectedEmotion = name);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                minimumSize: const Size(80, 40),
              ),
              child: const Text('Thêm', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final emotionProvider = context.watch<EmotionProvider>();
    final availableEmotions = emotionProvider.allAvailableEmotions;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF7FAFC);
    final titleColor = isDark ? Colors.white : const Color(0xFF2D3748);
    final iconColor = isDark ? Colors.white : AppTheme.primaryPurple;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: iconColor),
          onPressed: widget.onSkip ?? () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Progress Indicator
              _buildProgressIndicator(isDark),
              const SizedBox(height: 24),

              // Title Section
              Text(
                "Chào bạn, bạn đang\ncảm thấy thế nào?",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                      height: 1.3,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Emotion Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: availableEmotions.length + 1,
                  itemBuilder: (context, index) {
                    if (index < availableEmotions.length) {
                      final emotion = availableEmotions[index];
                      final style = EmotionConfig.getStyle(emotion);
                      return _buildEmotionCard(
                        emotion: emotion,
                        icon: style.icon,
                        gradient: style.gradient,
                        isDark: isDark,
                      );
                    } else {
                      // Add button
                      return _buildAddEmotionCard(isDark);
                    }
                  },
                ),
              ),

              if (selectedEmotion != null) ...[
                const SizedBox(height: 24),
                _buildIntensitySelector(isDark),
              ],

              const SizedBox(height: 24),

              // Continue Button
              Container(
                width: double.infinity,
                height: 56,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: selectedEmotion != null 
                      ? const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: selectedEmotion == null 
                      ? (isDark ? const Color(0xFF334155) : Colors.grey.shade300)
                      : null,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: selectedEmotion != null ? [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ] : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: selectedEmotion != null 
                        ? () => widget.onNext(selectedEmotion!, intensity.round()) 
                        : null,
                    borderRadius: BorderRadius.circular(28),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Tiếp tục",
                            style: TextStyle(
                              fontSize: 18,
                              color: selectedEmotion != null 
                                  ? Colors.white 
                                  : (isDark ? const Color(0xFF64748B) : Colors.white.withOpacity(0.5)),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: selectedEmotion != null 
                                ? Colors.white 
                                : (isDark ? const Color(0xFF64748B) : Colors.white.withOpacity(0.5)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntensitySelector(bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF2D3748);
    final labelColor = isDark ? const Color(0xFF94A3B8) : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Mức độ cảm xúc",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            Text(
              "${intensity.round()}/10",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryPurple,
            inactiveTrackColor: AppTheme.primaryPurple.withOpacity(0.1),
            trackHeight: 8.0,
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14.0),
            overlayColor: AppTheme.primaryPurple.withOpacity(0.2),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 28.0),
            tickMarkShape: const RoundSliderTickMarkShape(),
            activeTickMarkColor: Colors.white.withOpacity(0.5),
            inactiveTickMarkColor: AppTheme.primaryPurple.withOpacity(0.3),
          ),
          child: Slider(
            value: intensity,
            min: 1,
            max: 10,
            divisions: 9,
            label: intensity.round().toString(),
            onChanged: (value) {
              setState(() {
                intensity = value;
              });
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Nhẹ", style: TextStyle(fontSize: 12, color: labelColor)),
            Text("Vừa", style: TextStyle(fontSize: 12, color: labelColor)),
            Text("Mạnh", style: TextStyle(fontSize: 12, color: labelColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildAddEmotionCard(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04);
    final iconBgColor = isDark ? const Color(0xFF334155) : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : AppTheme.textDark;

    return GestureDetector(
      onTap: _showAddEmotionDialog,
      child: Container(
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryPurple.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 42,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Thêm cảm xúc',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDot(true, isDark),
        const SizedBox(width: 8),
        _buildDot(false, isDark),
        const SizedBox(width: 8),
        _buildDot(false, isDark),
      ],
    );
  }

  Widget _buildDot(bool isActive, bool isDark) {
    final activeColor = const Color(0xFF8B5CF6);
    final inactiveColor = isDark ? const Color(0xFF334155) : activeColor.withOpacity(0.2);

    return Container(
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? activeColor : inactiveColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildEmotionCard({
    required String emotion, 
    required IconData icon, 
    required LinearGradient gradient,
    required bool isDark,
  }) {
    final isSelected = selectedEmotion == emotion;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2D3748);
    
    final unselectedShadow = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04);
    final selectedShadow = const Color(0xFF8B5CF6).withOpacity(0.3);

    return GestureDetector(
      onTap: () => setState(() => selectedEmotion = emotion),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: isSelected ? Border.all(color: const Color(0xFF8B5CF6), width: 2) : Border.all(color: Colors.transparent, width: 2),
          boxShadow: [
            BoxShadow(
              color: isSelected ? selectedShadow : unselectedShadow,
              blurRadius: isSelected ? 16 : 12,
              offset: Offset(0, isSelected ? 8 : 6),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Gradient Circle với Icon
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Emotion name
                  Text(
                    emotion,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Checkmark for selected
            if (isSelected)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B5CF6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

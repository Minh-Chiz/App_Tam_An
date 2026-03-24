import 'package:flutter/material.dart';

class EmotionStyle {
  final String name;
  final IconData icon;
  final Color color;
  final LinearGradient gradient;

  const EmotionStyle({
    required this.name,
    required this.icon,
    required this.color,
    required this.gradient,
  });
}

class EmotionConfig {
  static const Map<String, EmotionStyle> _defaultStyles = {
    'Vui vẻ': EmotionStyle(
      name: 'Vui vẻ',
      icon: Icons.sentiment_very_satisfied_rounded,
      color: Color(0xFFFDD835),
      gradient: LinearGradient(colors: [Color(0xFFFDD835), Color(0xFFFBC02D)]),
    ),
    'Vui': EmotionStyle(
      name: 'Vui',
      icon: Icons.sentiment_very_satisfied_rounded,
      color: Color(0xFFFDD835),
      gradient: LinearGradient(colors: [Color(0xFFFDD835), Color(0xFFFBC02D)]),
    ),
    'Bình thường': EmotionStyle(
      name: 'Bình thường',
      icon: Icons.sentiment_neutral_rounded,
      color: Color(0xFF64B5F6),
      gradient: LinearGradient(colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)]),
    ),
    'Buồn': EmotionStyle(
      name: 'Buồn',
      icon: Icons.sentiment_dissatisfied_rounded,
      color: Color(0xFF757575),
      gradient: LinearGradient(colors: [Color(0xFF424242), Color(0xFF212121)]),
    ),
    'Lo âu': EmotionStyle(
      name: 'Lo âu',
      icon: Icons.psychology_rounded,
      color: Color(0xFF9C27B0),
      gradient: LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)]),
    ),
    'Căng thẳng': EmotionStyle(
      name: 'Căng thẳng',
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFFF6F00),
      gradient: LinearGradient(colors: [Color(0xFFFF6F00), Color(0xFFE65100)]),
    ),
    'Giận dữ': EmotionStyle(
      name: 'Giận dữ',
      icon: Icons.sentiment_very_dissatisfied_rounded,
      color: Color(0xFFE53935),
      gradient: LinearGradient(colors: [Color(0xFFE53935), Color(0xFFC62828)]),
    ),
  };

  static const EmotionStyle fallbackStyle = EmotionStyle(
    name: 'Khác',
    icon: Icons.sentiment_neutral_rounded,
    color: Colors.grey,
    gradient: LinearGradient(colors: [Color(0xFF9E9E9E), Color(0xFF757575)]),
  );

  static EmotionStyle getStyle(String emotionName) {
    return _defaultStyles[emotionName] ?? fallbackStyle;
  }

  static List<String> get defaultEmotions => [
    'Vui vẻ',
    'Bình thường',
    'Buồn',
    'Lo âu',
    'Căng thẳng',
    'Giận dữ',
  ];
}

import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tổng quan tuần này"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoCard(),
            const SizedBox(height: 16),
            _emotionSummary(),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Sau này mở chi tiết AI
                },
                child: const Text("Xem phân tích chi tiết"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: const [
            Icon(Icons.psychology, size: 40, color: Colors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Tâm An nhận thấy bạn có xu hướng căng thẳng vào buổi chiều.",
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _emotionSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: const [
        _EmotionBox(label: "Vui", percent: "40%"),
        _EmotionBox(label: "Căng thẳng", percent: "30%"),
        _EmotionBox(label: "Bình thường", percent: "20%"),
      ],
    );
  }
}

class _EmotionBox extends StatelessWidget {
  final String label;
  final String percent;

  const _EmotionBox({
    required this.label,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(percent,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label),
      ],
    );
  }
}

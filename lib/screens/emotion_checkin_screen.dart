import 'package:flutter/material.dart';

class EmotionCheckinScreen extends StatelessWidget {
  final VoidCallback onNext;

  const EmotionCheckinScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cảm xúc hôm nay")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Chào bạn 👋\nBạn đang cảm thấy thế nào?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: const [
                  _EmotionCard("Vui 😊", Colors.orange),
                  _EmotionCard("Bình thường 😌", Colors.blue),
                  _EmotionCard("Buồn 😔", Colors.indigo),
                  _EmotionCard("Căng thẳng 😣", Colors.red),
                ],
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNext,
                child: const Text("Tiếp tục"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmotionCard extends StatelessWidget {
  final String text;
  final Color color;

  const _EmotionCard(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

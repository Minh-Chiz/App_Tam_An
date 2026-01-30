import 'package:flutter/material.dart';
import 'package:tam_an/screens/overview_screen.dart';
import 'emotion_checkin_screen.dart';
import 'context_tag_screen.dart';

class EmotionFlowScreen extends StatefulWidget {
  const EmotionFlowScreen({super.key});

  @override
  State<EmotionFlowScreen> createState() => _EmotionFlowScreenState();
}

class _EmotionFlowScreenState extends State<EmotionFlowScreen> {
  final PageController _controller = PageController();
  int currentPage = 0;

  void nextPage() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void previousPage() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() => currentPage = index);
            },
            children: [
              EmotionCheckinScreen(onNext: nextPage),
              ContextTagScreen(
                onSave: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OverviewScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          if (currentPage == 1)
            Positioned(
              top: 40,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: previousPage,
              ),
            ),
        ],
      ),
    );
  }
}

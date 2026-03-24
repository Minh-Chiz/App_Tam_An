import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tam_an/screens/home_screen.dart';
import 'package:tam_an/providers/emotion_provider.dart';
import 'emotion_checkin_screen.dart';
import 'context_tag_screen.dart';
import 'note_screen.dart';

class EmotionFlowScreen extends StatefulWidget {
  const EmotionFlowScreen({super.key});

  @override
  State<EmotionFlowScreen> createState() => _EmotionFlowScreenState();
}

class _EmotionFlowScreenState extends State<EmotionFlowScreen> {
  final PageController _controller = PageController();
  int currentPage = 0;

  // Data collected from flow
  String? selectedEmotion;
  int? selectedIntensity;
  String? selectedLocation;
  String? selectedActivity;
  String? selectedCompany;
  String? noteText;

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


  Future<void> _saveEmotion() async {
    if (selectedEmotion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn cảm xúc')),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final emotionProvider = context.read<EmotionProvider>();

    final success = await emotionProvider.createEmotion(
      emotionType: selectedEmotion!,
      intensity: selectedIntensity ?? 5,
      location: selectedLocation,
      activity: selectedActivity,
      company: selectedCompany,
      noteText: noteText,
    );

    if (!mounted) return;

    // Close loading dialog
    Navigator.pop(context);

    // Always navigate to home screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );

    // Show result message
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã lưu nhật ký thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Show error but still allow user to continue
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            emotionProvider.error ?? '⚠️ Không thể kết nối server. Dữ liệu chưa được lưu.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() => currentPage = index);
        },
        children: [
          EmotionCheckinScreen(
            onNext: (emotion, intensity) {
              setState(() {
                selectedEmotion = emotion;
                selectedIntensity = intensity;
              });
              nextPage();
            },
            onSkip: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
          ContextTagScreen(
            onSave: (location, activity, company) {
              setState(() {
                selectedLocation = location;
                selectedActivity = activity;
                selectedCompany = company;
              });
              nextPage();
            },
            onBack: previousPage,
          ),
          NoteScreen(
            onSave: (note) {
              setState(() => noteText = note);
              _saveEmotion();
            },
            onSkip: () {
              _saveEmotion();
            },
            onBack: previousPage,
          ),
        ],
      ),
    );
  }
}

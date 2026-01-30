import 'package:flutter/material.dart';

class ContextTagScreen extends StatelessWidget {
  final VoidCallback onSave;

  const ContextTagScreen({
    super.key,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Thêm ngữ cảnh"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("📍 Bạn đang ở đâu?"),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: const [
                Chip(label: Text("Ở nhà")),
                Chip(label: Text("Công ty")),
                Chip(label: Text("Trường học")),
              ],
            ),

            const SizedBox(height: 20),

            const Text("⚡ Bạn đang làm gì?"),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: const [
                Chip(label: Text("Học")),
                Chip(label: Text("Code")),
                Chip(label: Text("Làm việc")),
              ],
            ),

            const SizedBox(height: 20),

            const Text("⚡ Bạn đang ở cùng ai?"),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: const [
                Chip(label: Text("Người thân")),
                Chip(label: Text("Bạn bè")),
                Chip(label: Text("Gia đình")),
                Chip(label: Text("Một mình")),
                Chip(label: Text("Đồng nghiệp")),
                Chip(label: Text("Người yêu")),
                Chip(label: Text("->Khác<-")),
              ],
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSave,
                child: const Text("Lưu nhật ký ✓"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

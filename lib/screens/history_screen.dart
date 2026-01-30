import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lịch sử cảm xúc")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _item("08:00", "Lo lắng", "Công việc"),
          _item("12:30", "Bình tĩnh", "Ăn uống"),
          _item("20:00", "Biết ơn", "Gia đình"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // sau này mở ghi nhật ký
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _item(String time, String emotion, String tag) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.circle),
        title: Text(emotion),
        subtitle: Text(tag),
        trailing: Text(time),
      ),
    );
  }
}

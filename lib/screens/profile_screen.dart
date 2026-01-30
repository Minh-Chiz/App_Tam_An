import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hồ sơ")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 40,
            child: Icon(Icons.person, size: 40),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              "Nguyễn Văn A",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Center(child: Text("nguyenvana@gmail.com")),
          const SizedBox(height: 24),
          _item(Icons.notifications, "Thông báo cảm xúc"),
          _item(Icons.dark_mode, "Giao diện tối"),
          _item(Icons.help, "Trợ giúp & hỗ trợ"),
          const Divider(),
          TextButton(
            onPressed: () {},
            child: const Text(
              "Đăng xuất",
              style: TextStyle(color: Colors.red),
            ),
          )
        ],
      ),
    );
  }

  Widget _item(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}

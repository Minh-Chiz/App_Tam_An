import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điều khoản sử dụng'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(
            '1. Giới thiệu',
            'Chào mừng bạn đến với Tâm An - ứng dụng theo dõi và quản lý cảm xúc cá nhân. '
            'Bằng việc sử dụng ứng dụng này, bạn đồng ý với các điều khoản và điều kiện sau đây.',
          ),
          _buildSection(
            '2. Quyền và nghĩa vụ của người dùng',
            '• Bạn có quyền sử dụng ứng dụng để ghi nhận và theo dõi cảm xúc cá nhân.\n'
            '• Bạn có trách nhiệm bảo mật thông tin đăng nhập của mình.\n'
            '• Bạn cam kết không sử dụng ứng dụng cho mục đích bất hợp pháp.\n'
            '• Bạn có quyền yêu cầu xóa dữ liệu cá nhân bất kỳ lúc nào.',
          ),
          _buildSection(
            '3. Bảo mật thông tin',
            '• Tất cả dữ liệu cảm xúc của bạn được mã hóa và lưu trữ an toàn.\n'
            '• Chúng tôi không chia sẻ thông tin cá nhân của bạn với bên thứ ba.\n'
            '• Dữ liệu của bạn chỉ được sử dụng để cải thiện trải nghiệm ứng dụng.\n'
            '• Bạn có toàn quyền kiểm soát dữ liệu của mình.',
          ),
          _buildSection(
            '4. Thu thập dữ liệu',
            'Ứng dụng thu thập các thông tin sau:\n'
            '• Thông tin đăng ký: Email, tên, mật khẩu (đã mã hóa)\n'
            '• Dữ liệu cảm xúc: Loại cảm xúc, thời gian, ngữ cảnh, ghi chú\n'
            '• Dữ liệu sử dụng: Thời gian sử dụng, tính năng được sử dụng\n\n'
            'Tất cả dữ liệu được lưu trữ an toàn và không được chia sẻ.',
          ),
          _buildSection(
            '5. Giới hạn trách nhiệm',
            '• Tâm An là công cụ hỗ trợ theo dõi cảm xúc, không thay thế tư vấn y tế chuyên nghiệp.\n'
            '• Chúng tôi không chịu trách nhiệm cho các quyết định dựa trên dữ liệu từ ứng dụng.\n'
            '• Nếu bạn gặp vấn đề sức khỏe tâm thần nghiêm trọng, hãy tìm kiếm sự giúp đỡ chuyên nghiệp.',
          ),
          _buildSection(
            '6. Thay đổi điều khoản',
            'Chúng tôi có quyền cập nhật điều khoản sử dụng bất kỳ lúc nào. '
            'Các thay đổi sẽ được thông báo qua ứng dụng. '
            'Việc tiếp tục sử dụng ứng dụng sau khi có thay đổi đồng nghĩa với việc bạn chấp nhận các điều khoản mới.',
          ),
          _buildSection(
            '7. Chấm dứt sử dụng',
            'Bạn có thể ngừng sử dụng ứng dụng và xóa tài khoản bất kỳ lúc nào. '
            'Khi xóa tài khoản, tất cả dữ liệu của bạn sẽ bị xóa vĩnh viễn và không thể khôi phục.',
          ),
          _buildSection(
            '8. Liên hệ',
            'Nếu bạn có bất kỳ câu hỏi nào về điều khoản sử dụng, vui lòng liên hệ:\n'
            'Email: support@taman.app\n'
            'Hotline: 1900-xxxx',
          ),
          const SizedBox(height: 20),
          Text(
            'Cập nhật lần cuối: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

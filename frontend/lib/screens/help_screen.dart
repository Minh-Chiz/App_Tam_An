import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ giúp & Hỗ trợ'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Câu hỏi thường gặp (FAQ)',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildFAQ(
            context,
            'Làm thế nào để ghi nhận cảm xúc?',
            '1. Mở ứng dụng và đăng nhập\n'
            '2. Chọn biểu tượng cảm xúc phù hợp (Vui, Buồn, Tức giận, v.v.)\n'
            '3. Điều chỉnh mức độ cảm xúc bằng thanh trượt\n'
            '4. Chọn ngữ cảnh: Địa điểm, Hoạt động, Người đồng hành\n'
            '5. Thêm ghi chú nếu muốn\n'
            '6. Nhấn "Lưu" để hoàn tất',
          ),
          
          _buildFAQ(
            context,
            'Làm thế nào để xem lịch sử cảm xúc?',
            '1. Nhấn vào tab "Lịch sử" ở thanh điều hướng dưới\n'
            '2. Xem lịch với các ngày có ghi nhận cảm xúc\n'
            '3. Nhấn vào ngày cụ thể để xem chi tiết\n'
            '4. Xem thống kê tháng ở phần "Thống kê tháng này"',
          ),
          
          _buildFAQ(
            context,
            'Dashboard hiển thị những gì?',
            'Dashboard hiển thị:\n'
            '• Tổng quan cảm xúc 7 ngày gần nhất\n'
            '• Biểu đồ phân bố cảm xúc\n'
            '• Xu hướng cảm xúc theo tuần\n'
            '• Insights và gợi ý từ AI',
          ),
          
          _buildFAQ(
            context,
            'Làm thế nào để thay đổi mật khẩu?',
            '1. Vào tab "Hồ sơ"\n'
            '2. Nhấn "Cài đặt tài khoản"\n'
            '3. Chọn "Đổi mật khẩu"\n'
            '4. Nhập mật khẩu cũ và mật khẩu mới\n'
            '5. Xác nhận thay đổi',
          ),
          
          _buildFAQ(
            context,
            'Làm thế nào để bật chế độ tối?',
            '1. Vào tab "Hồ sơ"\n'
            '2. Tìm mục "Giao diện (Sáng/Tối)"\n'
            '3. Bật/tắt switch để chuyển đổi\n'
            '4. Giao diện sẽ thay đổi ngay lập tức',
          ),
          
          _buildFAQ(
            context,
            'Làm thế nào để thay đổi ảnh đại diện?',
            '1. Vào tab "Hồ sơ"\n'
            '2. Nhấn vào ảnh đại diện hiện tại\n'
            '3. Chọn "Chụp ảnh" hoặc "Chọn từ thư viện"\n'
            '4. Chọn/chụp ảnh mới\n'
            '5. Ảnh sẽ được cập nhật tự động',
          ),
          
          _buildFAQ(
            context,
            'Làm thế nào để bật thông báo nhắc nhở?',
            '1. Vào tab "Hồ sơ"\n'
            '2. Tìm mục "Thông báo nhắc nhở"\n'
            '3. Bật switch\n'
            '4. Chọn thời gian nhắc nhở phù hợp\n'
            '5. Ứng dụng sẽ nhắc bạn ghi nhận cảm xúc hàng ngày',
          ),
          
          _buildFAQ(
            context,
            'Dữ liệu của tôi có được lưu trữ an toàn không?',
            'Có! Tất cả dữ liệu của bạn được:\n'
            '• Mã hóa end-to-end\n'
            '• Lưu trữ trên server bảo mật\n'
            '• Không chia sẻ với bên thứ ba\n'
            '• Có thể xóa bất kỳ lúc nào',
          ),
          
          _buildFAQ(
            context,
            'Làm thế nào để xóa tài khoản?',
            '1. Vào tab "Hồ sơ"\n'
            '2. Nhấn "Cài đặt tài khoản"\n'
            '3. Chọn "Xóa tài khoản"\n'
            '4. Xác nhận quyết định\n'
            'Lưu ý: Dữ liệu sẽ bị xóa vĩnh viễn và không thể khôi phục!',
          ),
          
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          
          const Text(
            'Liên hệ hỗ trợ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildContactCard(
            context,
            Icons.email_rounded,
            'Email',
            'ngocbao7205@gmail.com',
            'Phản hồi trong 24 giờ',
          ),
          
          _buildContactCard(
            context,
            Icons.phone_rounded,
            'Hotline',
            '0832259672',
            'Hỗ trợ 24/7',
          ),
          
          _buildContactCard(
            context,
            Icons.chat_rounded,
            'Live Chat',
            'Chat trực tiếp trong app',
            'Sẵn sàng hỗ trợ',
          ),
          
          const SizedBox(height: 32),
          
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Cảm ơn bạn đã sử dụng Tâm An!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chúng tôi luôn sẵn sàng hỗ trợ bạn trên hành trình chăm sóc sức khỏe tinh thần.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFAQ(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    String subtitle,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(value),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/reminder_provider.dart';
import '../theme/app_theme.dart';
import 'terms_screen.dart';
import 'help_screen.dart';
import 'reminder_settings_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  String? get _fullAvatarUrl {
    final user = context.read<AuthProvider>().user;
    if (user?.avatarUrl == null) return null;
    
    final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
    return '$baseUrl${user!.avatarUrl}';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;
      if (!mounted) return;
      
      final authProvider = context.read<AuthProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⏳ Đang tải ảnh lên...')),
      );

      final success = await authProvider.uploadAvatar(image);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Đã cập nhật ảnh đại diện')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Lỗi: ${authProvider.error ?? 'Không thể tải ảnh lên'}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi chọn ảnh: ${e.toString()}')),
        );
      }
    }
  }

  void _showAvatarMenu(bool isDark) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ảnh đại diện',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            if (_fullAvatarUrl != null)
              _buildMenuTile(
                icon: Icons.fullscreen_rounded,
                title: 'Xem ảnh đại diện',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _showFullScreenAvatar();
                },
              ),
            _buildMenuTile(
              icon: Icons.camera_alt_rounded,
              title: 'Chụp ảnh mới',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            _buildMenuTile(
              icon: Icons.photo_library_rounded,
              title: 'Chọn từ thư viện',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_fullAvatarUrl != null)
              _buildMenuTile(
                icon: Icons.delete_rounded,
                title: 'Xóa ảnh hiện tại',
                color: const Color(0xFFE53E3E),
                isDark: isDark,
                onTap: () async {
                  Navigator.pop(context);
                  
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text('Xóa ảnh', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                      content: Text('Bạn có chắc chắn muốn xóa ảnh đại diện hiện tại?', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Hủy', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096))),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Xóa', style: TextStyle(color: Color(0xFFE53E3E), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('⏳ Đang xóa ảnh...')),
                    );
                    final success = await context.read<AuthProvider>().deleteAvatar();
                    if (!mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Đã xóa ảnh đại diện')),
                      );
                    } else {
                      final error = context.read<AuthProvider>().error;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('❌ Lỗi: $error')),
                      );
                    }
                  }
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({required IconData icon, required String title, required VoidCallback onTap, Color? color, required bool isDark}) {
    final useColor = color ?? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF4A5568));
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: useColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: useColor, size: 22),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: useColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenAvatar() {
    if (_fullAvatarUrl == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAvatarMenu(isDark);
                  },
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  label: const Text('Thay đổi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.network(
                _fullAvatarUrl!,
                fit: BoxFit.cover,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width,
                    color: Colors.white24,
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_rounded, size: 64, color: Colors.white),
                        SizedBox(height: 16),
                        Text('Ảnh không khả dụng', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        content: Text('Bạn có chắc chắn muốn đăng xuất khỏi Tâm An?', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất', style: TextStyle(color: Color(0xFFE53E3E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Logout
      await context.read<AuthProvider>().logout();
      
      if (mounted) {
        // Force explicit navigation to LoginScreen to clear the entire stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    // Dynamic Theming configuration
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF7FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2D3748);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096);
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFEDF2F7);
    final avatarPlaceholderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final avatarIconColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFFA0AEC0);
    final iconBgOpacity = isDark ? 0.2 : 0.1;
    final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.03);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Hồ sơ',
          style: TextStyle(
            color: textColor,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Avatar and User Info
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _showAvatarMenu(isDark),
                  onLongPress: () => _showAvatarMenu(isDark),
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 54,
                          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: avatarPlaceholderColor,
                            backgroundImage: _fullAvatarUrl != null
                                ? NetworkImage(_fullAvatarUrl!)
                                : null,
                            child: _fullAvatarUrl == null
                                ? Icon(Icons.person_rounded, size: 50, color: avatarIconColor)
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _showAvatarMenu(isDark),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white : const Color(0xFF2D3748),
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: isDark ? const Color(0xFF2D3748) : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  user?.name ?? 'Người dùng',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Settings Section
          _buildSectionTitle('Cài đặt', subtitleColor),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return _buildSettingsTile(
                      icon: themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      iconColor: const Color(0xFF3182CE),
                      iconBgOpacity: iconBgOpacity,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      title: 'Giao diện (Sáng/Tối)',
                      subtitle: themeProvider.isDarkMode ? 'Chế độ tối' : 'Chế độ sáng',
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (_) => themeProvider.toggleTheme(),
                        activeColor: const Color(0xFF4F46E5),
                      ),
                    );
                  },
                ),
                _buildDivider(dividerColor),
                Consumer<ReminderProvider>(
                  builder: (context, reminderProvider, _) {
                    return _buildSettingsTile(
                      icon: reminderProvider.isEnabled ? Icons.notifications_active_rounded : Icons.notifications_outlined,
                      iconColor: const Color(0xFFD69E2E),
                      iconBgOpacity: iconBgOpacity,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      title: 'Thông báo nhắc nhở',
                      subtitle: reminderProvider.isEnabled
                          ? 'Đang bật • ${reminderProvider.settings.selectedDays.length} ngày/tuần'
                          : 'Nhắc nhở ghi nhận cảm xúc',
                      trailing: Switch(
                        value: reminderProvider.isEnabled,
                        onChanged: (value) => reminderProvider.toggleReminder(value),
                        activeColor: const Color(0xFF4F46E5),
                      ),
                    );
                  },
                ),
                _buildDivider(dividerColor),
                _buildSettingsTile(
                  icon: Icons.tune_rounded,
                  iconColor: const Color(0xFF805AD5),
                  iconBgOpacity: iconBgOpacity,
                  textColor: textColor,
                  title: 'Tùy chỉnh nhắc nhở',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReminderSettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Info & Support Section
          _buildSectionTitle('Thông tin & Hỗ trợ', subtitleColor),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.help_outline_rounded,
                  iconColor: const Color(0xFF38A169),
                  iconBgOpacity: iconBgOpacity,
                  textColor: textColor,
                  title: 'Trợ giúp & Hỗ trợ',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpScreen()),
                    );
                  },
                ),
                _buildDivider(dividerColor),
                _buildSettingsTile(
                  icon: Icons.description_rounded,
                  iconColor: const Color(0xFF718096),
                  iconBgOpacity: iconBgOpacity,
                  textColor: textColor,
                  title: 'Điều khoản sử dụng',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TermsScreen()),
                    );
                  },
                ),
                _buildDivider(dividerColor),
                _buildSettingsTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFF319795),
                  iconBgOpacity: iconBgOpacity,
                  textColor: textColor,
                  title: 'Về ứng dụng',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Tâm An',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(Icons.favorite_rounded, size: 48, color: Color(0xFFE53E3E)),
                      children: [
                        Text(
                          'Ứng dụng theo dõi và quản lý cảm xúc cá nhân, '
                          'giúp bạn hiểu rõ hơn về bản thân và cải thiện sức khỏe tinh thần.',
                          style: TextStyle(height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Logout Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFFC8181).withOpacity(isDark ? 0.3 : 1.0), width: 1.5),
              color: isDark ? const Color(0xFF451A1A) : const Color(0xFFFFF5F5),
            ),
            child: InkWell(
              onTap: () => _logout(isDark),
              borderRadius: BorderRadius.circular(28),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: Color(0xFFFC8181), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Đăng xuất',
                    style: TextStyle(
                      color: Color(0xFFFC8181),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
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

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDivider(Color dividerColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 64),
      child: Divider(height: 1, color: dividerColor),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required double iconBgOpacity,
    required Color textColor,
    Color? subtitleColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(iconBgOpacity),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing
            else if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFA0AEC0)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tam_an/providers/reminder_provider.dart';
import 'package:tam_an/providers/emotion_provider.dart';
import 'package:tam_an/models/reminder_settings.dart';
import 'package:tam_an/theme/app_theme.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<ReminderProvider>().settings;
    _messageController = TextEditingController(text: settings.reminderMessage);

    // Auto-analyze stress patterns if emotions are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _analyzePatterns();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _analyzePatterns() {
    final emotionProvider = context.read<EmotionProvider>();
    final reminderProvider = context.read<ReminderProvider>();
    if (emotionProvider.emotions.isNotEmpty) {
      reminderProvider.updateSmartPatterns(emotionProvider.emotions);
    }
  }

  Future<void> _pickTime(BuildContext context, TimeOfDay currentTime,
      Function(TimeOfDay) onSelected) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt nhắc nhở'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ReminderProvider>(
        builder: (context, provider, _) {
          final settings = provider.settings;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header Card
              _buildHeaderCard(context, settings, provider),
              const SizedBox(height: 24),

              // Main time picker
              if (settings.isEnabled) ...[
                _buildSectionTitle('Giờ nhắc nhở chính'),
                _buildTimePickerCard(
                  context,
                  icon: Icons.alarm_rounded,
                  label: 'Nhắc nhở lúc',
                  time: settings.reminderTime,
                  gradient: AppTheme.primaryGradient,
                  onTap: () => _pickTime(
                    context,
                    settings.reminderTime,
                    provider.setReminderTime,
                  ),
                ),
                const SizedBox(height: 24),

                // Day selector
                _buildSectionTitle('Ngày nhắc nhở'),
                _buildDaySelector(context, settings, provider),
                const SizedBox(height: 24),

                // Second reminder
                _buildSectionTitle('Nhắc nhở lần 2'),
                _buildSecondReminderCard(context, settings, provider),
                const SizedBox(height: 24),

                // Smart reminder
                _buildSectionTitle('Nhắc nhở thông minh'),
                _buildSmartReminderCard(context, settings, provider),
                const SizedBox(height: 24),

                // Custom message
                _buildSectionTitle('Nội dung nhắc nhở'),
                _buildMessageCard(context, settings, provider),
                const SizedBox(height: 24),

                // Test button
                _buildTestButton(context, provider),
                const SizedBox(height: 40),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, ReminderSettings settings,
      ReminderProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: settings.isEnabled
            ? AppTheme.primaryGradient
            : LinearGradient(
                colors: [Colors.grey.shade400, Colors.grey.shade500],
              ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (settings.isEnabled
                    ? AppTheme.primaryPurple
                    : Colors.grey)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              settings.isEnabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nhắc nhở hàng ngày',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  settings.isEnabled
                      ? 'Đang hoạt động • ${settings.selectedDays.length} ngày/tuần'
                      : 'Đã tắt',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: settings.isEnabled,
            onChanged: (value) => provider.toggleReminder(value),
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withOpacity(0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTimePickerCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required TimeOfDay time,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaySelector(BuildContext context, ReminderSettings settings,
      ReminderProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Quick select buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => provider.selectAllDays(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: settings.selectedDays.length == 7
                            ? AppTheme.primaryPurple
                            : Colors.grey.shade300,
                      ),
                      foregroundColor: settings.selectedDays.length == 7
                          ? AppTheme.primaryPurple
                          : null,
                    ),
                    child: const Text('Mỗi ngày'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => provider.selectWeekdays(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _isWeekdaysOnly(settings.selectedDays)
                            ? AppTheme.primaryPurple
                            : Colors.grey.shade300,
                      ),
                      foregroundColor:
                          _isWeekdaysOnly(settings.selectedDays)
                              ? AppTheme.primaryPurple
                              : null,
                    ),
                    child: const Text('Ngày thường'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Day chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final day = index + 1;
                final isSelected = settings.selectedDays.contains(day);
                final isSmartDay = settings.smartReminderDays.contains(day);

                return GestureDetector(
                  onTap: () => provider.toggleDay(day),
                  child: Column(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient:
                              isSelected ? AppTheme.primaryGradient : null,
                          color: isSelected ? null : Colors.grey.shade200,
                          shape: BoxShape.circle,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryPurple
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            ReminderSettings.getDayName(day),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      if (isSmartDay) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.accentOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  bool _isWeekdaysOnly(List<int> days) {
    return days.length == 5 &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4) &&
        days.contains(5);
  }

  Widget _buildSecondReminderCard(BuildContext context,
      ReminderSettings settings, ReminderProvider provider) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: settings.secondReminderEnabled
                    ? AppTheme.softGreen.withOpacity(0.15)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.alarm_add_rounded,
                color: settings.secondReminderEnabled
                    ? AppTheme.softGreen
                    : Colors.grey,
              ),
            ),
            title: const Text('Nhắc nhở thêm'),
            subtitle: Text(
              settings.secondReminderEnabled
                  ? 'Nhắc thêm vào buổi trưa'
                  : 'Thêm lần nhắc thứ 2 trong ngày',
            ),
            value: settings.secondReminderEnabled,
            onChanged: (value) => provider.toggleSecondReminder(value),
          ),
          if (settings.secondReminderEnabled) ...[
            const Divider(height: 1),
            InkWell(
              onTap: () => _pickTime(
                context,
                settings.secondReminderTime,
                provider.setSecondReminderTime,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    const SizedBox(width: 48),
                    const Text('Nhắc lúc'),
                    const Spacer(),
                    Text(
                      '${settings.secondReminderTime.hour.toString().padLeft(2, '0')}:${settings.secondReminderTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmartReminderCard(BuildContext context,
      ReminderSettings settings, ReminderProvider provider) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: settings.isSmartReminderEnabled
                    ? AppTheme.sunsetGradient
                    : null,
                color: settings.isSmartReminderEnabled
                    ? null
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.psychology_rounded,
                color: settings.isSmartReminderEnabled
                    ? Colors.white
                    : Colors.grey,
                size: 22,
              ),
            ),
            title: Row(
              children: [
                const Text('Nhắc nhở thông minh'),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: AppTheme.sunsetGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'AI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: const Text(
              'Tự động nhắc thêm vào ngày hay căng thẳng',
            ),
            value: settings.isSmartReminderEnabled,
            onChanged: (value) => provider.toggleSmartReminder(value),
          ),
          if (settings.isSmartReminderEnabled) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: settings.smartReminderDays.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.insights_rounded,
                                color: AppTheme.accentOrange, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Ngày được phát hiện:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: settings.smartReminderDays.map((day) {
                            return Chip(
                              avatar: const Icon(Icons.warning_amber_rounded,
                                  size: 16, color: AppTheme.accentOrange),
                              label: Text(
                                  ReminderSettings.getDayFullName(day)),
                              backgroundColor:
                                  AppTheme.accentOrange.withOpacity(0.1),
                              side: BorderSide(
                                  color:
                                      AppTheme.accentOrange.withOpacity(0.3)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sẽ nhắc thêm 1 giờ trước giờ nhắc chính',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).textTheme.bodySmall?.color,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: Colors.grey.shade400, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Chưa phát hiện pattern — cần thêm dữ liệu cảm xúc để phân tích',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _analyzePatterns,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Phân tích lại'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentOrange,
                    side: BorderSide(
                        color: AppTheme.accentOrange.withOpacity(0.5)),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageCard(BuildContext context, ReminderSettings settings,
      ReminderProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.message_rounded,
                      color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Nội dung hiển thị trong thông báo',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung nhắc nhở...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  provider.setReminderMessage(value);
                }
              },
            ),
            const SizedBox(height: 12),
            // Preset messages
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip(
                  'Hãy ghi nhận cảm xúc nhé! 💜',
                  provider,
                ),
                _buildPresetChip(
                  'Bạn cảm thấy thế nào hôm nay? 🌟',
                  provider,
                ),
                _buildPresetChip(
                  'Dành 1 phút cho bản thân nhé! 🧘',
                  provider,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String message, ReminderProvider provider) {
    final isSelected = _messageController.text == message;
    return InkWell(
      onTap: () {
        _messageController.text = message;
        provider.setReminderMessage(message);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryPurple.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryPurple.withOpacity(0.5)
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          message,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? AppTheme.primaryPurple : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildTestButton(BuildContext context, ReminderProvider provider) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.coolGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.softGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await provider.sendTestNotification();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Đã gửi thông báo thử!'),
                    ],
                  ),
                  backgroundColor: AppTheme.softGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(28),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Gửi thử ngay',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

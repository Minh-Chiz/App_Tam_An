import 'package:flutter/material.dart';
import 'package:tam_an/theme/app_theme.dart';

class ContextTagScreen extends StatefulWidget {
  final Function(String?, String?, String?) onSave;
  final VoidCallback onBack;

  const ContextTagScreen({
    super.key,
    required this.onSave,
    required this.onBack,
  });

  @override
  State<ContextTagScreen> createState() => _ContextTagScreenState();
}

class _ContextTagScreenState extends State<ContextTagScreen> {
  String? selectedLocation;
  String? selectedActivity;
  String? selectedCompany;

  // Custom contexts
  List<String> customLocations = [];
  List<String> customActivities = [];
  List<String> customCompanies = [];

  Widget _buildDot(bool isActive, bool isDark) {
    final activeColor = const Color(0xFF8B5CF6);
    final inactiveColor = isDark ? const Color(0xFF334155) : activeColor.withOpacity(0.2);

    return Container(
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? activeColor : inactiveColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF7FAFC);
    final iconColor = isDark ? Colors.white : AppTheme.primaryPurple;
    final titleColor = isDark ? Colors.white : const Color(0xFF2D3748);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: iconColor),
          onPressed: widget.onBack,
        ),
        title: Text(
          "Thêm ngữ cảnh", 
          style: TextStyle(color: titleColor, fontWeight: FontWeight.bold)
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(false, isDark),
                  const SizedBox(width: 8),
                  _buildDot(true, isDark),
                  const SizedBox(width: 8),
                  _buildDot(false, isDark),
                ],
              ),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        title: "Bạn đang ở đâu?",
                        selectedValue: selectedLocation,
                        options: ["Ở nhà", "Công ty", "Trường học", "Quán cà phê"],
                        customOptions: customLocations,
                        isDark: isDark,
                        onSelected: (value) => setState(() => selectedLocation = value),
                        onAddCustom: () => _showAddContextDialog(
                          category: "địa điểm",
                          onAdd: (value) {
                            setState(() {
                              customLocations.add(value);
                              selectedLocation = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        title: "Bạn đang làm gì?",
                        selectedValue: selectedActivity,
                        options: ["Học", "Code", "Làm việc", "Thư giãn", "Ăn uống"],
                        customOptions: customActivities,
                        isDark: isDark,
                        onSelected: (value) => setState(() => selectedActivity = value),
                        onAddCustom: () => _showAddContextDialog(
                          category: "hoạt động",
                          onAdd: (value) {
                            setState(() {
                              customActivities.add(value);
                              selectedActivity = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        title: "Bạn đang ở cùng ai?",
                        selectedValue: selectedCompany,
                        options: [
                          "Người thân",
                          "Bạn bè",
                          "Gia đình",
                          "Một mình",
                          "Đồng nghiệp",
                          "Người yêu",
                        ],
                        customOptions: customCompanies,
                        isDark: isDark,
                        onSelected: (value) => setState(() => selectedCompany = value),
                        onAddCustom: () => _showAddContextDialog(
                          category: "người đồng hành",
                          onAdd: (value) {
                            setState(() {
                              customCompanies.add(value);
                              selectedCompany = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Save Button
              Container(
                width: double.infinity,
                height: 56,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onSave(
                      selectedLocation,
                      selectedActivity,
                      selectedCompany,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Tiếp tục",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String? selectedValue,
    required List<String> options,
    required List<String> customOptions,
    required bool isDark,
    required Function(String) onSelected,
    required VoidCallback onAddCustom,
  }) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04);
    final titleColor = isDark ? Colors.white : const Color(0xFF2D3748);
    final unselectedBg = isDark ? const Color(0xFF334155) : AppTheme.lightPurple.withOpacity(0.3);
    final unselectedText = isDark ? const Color(0xFFCBD5E0) : AppTheme.textDark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Default options
              ...options.map((option) {
                final isSelected = selectedValue == option;
                return _buildChip(option, isSelected, unselectedBg, unselectedText, onSelected);
              }).toList(),
              
              // Custom options
              ...customOptions.map((option) {
                final isSelected = selectedValue == option;
                return _buildChip(option, isSelected, unselectedBg, unselectedText, onSelected);
              }).toList(),
              
              // Add button
              GestureDetector(
                onTap: onAddCustom,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    border: Border.all(
                      color: const Color(0xFF8B5CF6),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF8B5CF6),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Thêm',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF8B5CF6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    String option, 
    bool isSelected, 
    Color unselectedBg, 
    Color unselectedText,
    Function(String) onSelected
  ) {
    return GestureDetector(
      onTap: () => onSelected(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          color: isSelected ? null : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          option,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : unselectedText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _showAddContextDialog({
    required String category,
    required Function(String) onAdd,
  }) async {
    final controller = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final dialogBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF2D3748);

        return AlertDialog(
          backgroundColor: dialogBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Thêm $category',
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Nhập $category...',
              hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF8B5CF6),
                  width: 2,
                ),
              ),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                onAdd(value.trim());
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  onAdd(controller.text.trim());
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Thêm', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }
}

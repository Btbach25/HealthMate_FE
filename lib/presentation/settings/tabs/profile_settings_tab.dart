import 'dart:async';
import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ProfileSettingsTab extends StatefulWidget {
  const ProfileSettingsTab({super.key});

  @override
  State<ProfileSettingsTab> createState() => _ProfileSettingsTabState();
}

class _ProfileSettingsTabState extends State<ProfileSettingsTab> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _customAllergyController;
  
  String? _selectedGender;
  DateTime? _selectedBirthday;
  String? _selectedBloodGroup;
  List<String> _allergies = [];
  bool _isLoading = false;
  List<String> _filteredAllergies = [];
  bool _showAllergySuggestions = false;
  String _allergySearchQuery = '';
  Timer? _saveTimer;

  final List<String> _commonAllergies = [
    'Penicillin',
    'Aspirin',
    'Ibuprofen',
    'Codeine',
    'Morphine',
    'Sulfonamides',
    'Cephalosporins',
    'Quinolones',
    'Tetracyclines',
    'Vancomycin',
    'Insulin',
    'Warfarin',
    'Acetaminophen',
    'Lidocaine',
    'Contrast Dye',
    'Latex',
    'Shellfish',
    'Nuts',
    'Eggs',
    'Milk',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    _customAllergyController = TextEditingController();
    _loadUserData();
  }

  void _loadUserData() {
    final user = context.read<AuthBloc>().state.user;
    if (user.isNotEmpty && user.name.isNotEmpty && user.email.isNotEmpty) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _selectedGender = 'Nam'; // Default
      // Load other data from user model or defaults
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _customAllergyController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng kiểm tra lại thông tin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedBirthday != null && _selectedBirthday!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ngày sinh không thể lớn hơn ngày hiện tại'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Cancel any existing timer
    _saveTimer?.cancel();

    // Simulate API call with cancellable timer
    _saveTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật hồ sơ thành công!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    });
  }

  void _handleCancel() {
    _loadUserData();
    setState(() {
      _isEditing = false;
      _allergies = [];
      _selectedBirthday = null;
      _selectedGender = 'Nam';
      _selectedBloodGroup = null;
    });
  }

  void _onAllergySearchChanged(String query) {
    setState(() {
      _allergySearchQuery = query;
      if (query.isEmpty) {
        _filteredAllergies = [];
        _showAllergySuggestions = false;
      } else {
        _filteredAllergies = _commonAllergies
            .where((allergy) => 
                allergy.toLowerCase().contains(query.toLowerCase()) &&
                !_allergies.contains(allergy))
            .toList();
        _showAllergySuggestions = _filteredAllergies.isNotEmpty;
      }
    });
  }

  void _addAllergy(String allergy) {
    final trimmedAllergy = allergy.trim();
    if (trimmedAllergy.isNotEmpty && !_allergies.contains(trimmedAllergy)) {
      setState(() {
        _allergies.add(trimmedAllergy);
        _customAllergyController.clear();
        _allergySearchQuery = '';
        _filteredAllergies = [];
        _showAllergySuggestions = false;
      });
    }
  }

  void _addCustomAllergy() {
    final allergy = _customAllergyController.text.trim();
    if (allergy.isNotEmpty && !_allergies.contains(allergy)) {
      _addAllergy(allergy);
    }
  }

  void _addCommonAllergy(String allergy) {
    _addAllergy(allergy);
  }

  void _addMultipleAllergies(List<String> allergies) {
    setState(() {
      for (final allergy in allergies) {
        final trimmed = allergy.trim();
        if (trimmed.isNotEmpty && !_allergies.contains(trimmed)) {
          _allergies.add(trimmed);
        }
      }
      _customAllergyController.clear();
      _allergySearchQuery = '';
      _filteredAllergies = [];
      _showAllergySuggestions = false;
    });
  }

  void _removeAllergy(String allergy) {
    setState(() {
      _allergies.remove(allergy);
    });
  }

  Future<void> _selectBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty || name.trim().isEmpty) return 'U';
    final trimmedName = name.trim();
    final parts = trimmedName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      final first = parts[0][0];
      final last = parts[parts.length - 1][0];
      return '$first$last'.toUpperCase();
    }
    final length = trimmedName.length > 2 ? 2 : trimmedName.length;
    return trimmedName.substring(0, length).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    final userName = user.isNotEmpty ? user.name : 'Người dùng';
    final userEmail = user.isNotEmpty ? user.email : '';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSize.p16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.cardShadowList,
                border: Border.all(color: AppColors.cardBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(userName),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: AppTextStyles.h4.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isEditing)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Chỉnh sửa'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
            
            // Basic Information Card
            _buildCard(
              title: 'Thông tin cơ bản',
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Họ tên',
                  icon: Icons.person_outline,
                  enabled: _isEditing,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập họ tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSize.spacing16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.mail_outline,
                  enabled: _isEditing,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSize.spacing16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Số điện thoại',
                  icon: Icons.phone_outlined,
                  enabled: _isEditing,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSize.spacing16),
                _buildDropdown(
                  label: 'Giới tính',
                  value: _selectedGender,
                  items: const ['Nam', 'Nữ', 'Khác'],
                  enabled: _isEditing,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
                const SizedBox(height: AppSize.spacing16),
                _buildDateField(
                  label: 'Ngày sinh',
                  value: _selectedBirthday,
                  enabled: _isEditing,
                  onTap: _selectBirthday,
                ),
                const SizedBox(height: AppSize.spacing16),
                _buildTextField(
                  controller: _addressController,
                  label: 'Địa chỉ',
                  icon: Icons.location_on_outlined,
                  enabled: _isEditing,
                  hintText: 'Nhập địa chỉ của bạn',
                ),
              ],
            ),
            
            const SizedBox(height: AppSize.spacing24),
            
            // Health Information Card
            _buildCard(
              icon: Icons.favorite_outline,
              title: 'Thông tin sức khỏe',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _weightController,
                        label: 'Cân nặng',
                        icon: Icons.monitor_weight_outlined,
                        enabled: _isEditing,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        suffixText: 'kg',
                        hintText: '65',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null; // Optional field
                          }
                          final weight = double.tryParse(value.trim());
                          if (weight == null) {
                            return 'Vui lòng nhập số hợp lệ';
                          }
                          if (weight < 1 || weight > 500) {
                            return 'Cân nặng phải từ 1 đến 500 kg';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSize.spacing16),
                    Expanded(
                      child: _buildTextField(
                        controller: _heightController,
                        label: 'Chiều cao',
                        icon: Icons.straighten_outlined,
                        enabled: _isEditing,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        suffixText: 'cm',
                        hintText: '170',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null; // Optional field
                          }
                          final height = double.tryParse(value.trim());
                          if (height == null) {
                            return 'Vui lòng nhập số hợp lệ';
                          }
                          if (height < 30 || height > 300) {
                            return 'Chiều cao phải từ 30 đến 300 cm';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSize.spacing16),
                _buildDropdown(
                  label: 'Nhóm máu',
                  value: _selectedBloodGroup,
                  items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                  enabled: _isEditing,
                  icon: Icons.water_drop_outlined,
                  onChanged: (value) {
                    setState(() {
                      _selectedBloodGroup = value;
                    });
                  },
                ),
              ],
            ),
            
            const SizedBox(height: AppSize.spacing24),
            
            // Allergies Card
            _buildCard(
              icon: Icons.warning_amber_outlined,
              title: 'Quản lý dị ứng',
              children: [
                if (_allergies.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allergies.map((allergy) {
                      return Chip(
                        label: Text(
                          allergy,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: AppColors.errorLight,
                        deleteIcon: _isEditing
                            ? const Icon(Icons.close, size: 18, color: AppColors.error)
                            : null,
                        onDeleted: _isEditing ? () => _removeAllergy(allergy) : null,
                        labelStyle: const TextStyle(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSize.spacing16),
                ],
                if (_isEditing) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customAllergyController,
                              decoration: InputDecoration(
                                hintText: 'Nhập tên chất dị ứng để tìm kiếm',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                suffixIcon: _allergySearchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _customAllergyController.clear();
                                          setState(() {
                                            _allergySearchQuery = '';
                                            _filteredAllergies = [];
                                            _showAllergySuggestions = false;
                                          });
                                        },
                                      )
                                    : null,
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: AppColors.inputBackground,
                              ),
                              onChanged: _onAllergySearchChanged,
                              onSubmitted: (_) => _addCustomAllergy(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addCustomAllergy,
                            icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              padding: const EdgeInsets.all(12),
                            ),
                            tooltip: 'Thêm dị ứng',
                          ),
                        ],
                      ),
                      // Suggestions dropdown
                      if (_showAllergySuggestions && _filteredAllergies.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                            boxShadow: AppColors.cardShadowList,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(8),
                            itemCount: _filteredAllergies.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final allergy = _filteredAllergies[index];
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                leading: Icon(
                                  Icons.add_circle_outline,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                title: Text(
                                  allergy,
                                  style: AppTextStyles.bodyMedium,
                                ),
                                onTap: () => _addCommonAllergy(allergy),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Danh sách phổ biến:',
                            style: AppTextStyles.labelMedium,
                          ),
                          const Spacer(),
                          if (_commonAllergies.any((a) => !_allergies.contains(a)))
                            TextButton.icon(
                              onPressed: () {
                                final toAdd = _commonAllergies
                                    .where((a) => !_allergies.contains(a))
                                    .toList();
                                if (toAdd.isNotEmpty) {
                                  _addMultipleAllergies(toAdd);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Đã thêm ${toAdd.length} dị ứng'),
                                      backgroundColor: AppColors.primary,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Thêm tất cả'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _commonAllergies
                            .where((allergy) => !_allergies.contains(allergy))
                            .map((allergy) {
                          return FilterChip(
                            label: Text(
                              allergy,
                              style: const TextStyle(fontSize: 13),
                            ),
                            selected: false,
                            onSelected: (_) => _addCommonAllergy(allergy),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: AppSize.spacing24),
            
            // Action Buttons
            if (_isEditing)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _handleCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textGrey,
                        side: BorderSide(color: AppColors.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppColors.buttonShadow,
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Lưu thay đổi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    IconData? icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadowList,
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textBlack,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? suffixText,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: icon != null 
            ? Icon(icon, color: AppColors.primary.withOpacity(0.7))
            : null,
        suffixText: suffixText,
        filled: true,
        fillColor: enabled ? AppColors.inputBackground : AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required bool enabled,
    IconData? icon,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null 
            ? Icon(icon, color: AppColors.primary.withOpacity(0.7))
            : null,
        filled: true,
        fillColor: enabled ? AppColors.inputBackground : AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          border: const OutlineInputBorder(),
          suffixIcon: value != null && enabled
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _selectedBirthday = null;
                    });
                  },
                )
              : null,
        ),
        child: Text(
          value != null
              ? DateFormat('dd/MM/yyyy').format(value)
              : 'Chọn ngày sinh',
          style: TextStyle(
            color: value != null ? AppColors.textBlack : AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}


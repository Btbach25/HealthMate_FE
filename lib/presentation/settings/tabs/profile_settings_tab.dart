import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/utils/string_helper.dart';
import 'package:fe/core/utils/user_facing_error.dart';
import 'package:fe/core/widgets/profile_text_field.dart';
import 'package:fe/core/widgets/settings_card.dart';
import 'package:fe/core/widgets/settings_dropdown.dart';
import 'package:fe/data/services/user_service.dart';
import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Tab hồ sơ trong Settings (form dài: nhiều controller + dị ứng + ngày sinh).
/// Khi sửa, tìm theo nhánh `_build…` / section trong [build].

/// BE/DB: male | female | other
const _genderUiToApi = {'Nam': 'male', 'Nữ': 'female', 'Khác': 'other'};
const _genderApiToUi = {'male': 'Nam', 'female': 'Nữ', 'other': 'Khác'};

String? _genderApiFromUi(String? ui) =>
    ui == null ? null : _genderUiToApi[ui];

String? _genderUiFromApi(String? api) =>
    api == null ? null : _genderApiToUi[api];

String _formatBirthdayApi(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _formatNumForField(double v) {
  if (v == v.roundToDouble()) return v.round().toString();
  return v.toString();
}

class ProfileSettingsTab extends StatefulWidget {
  const ProfileSettingsTab({super.key});

  @override
  State<ProfileSettingsTab> createState() => _ProfileSettingsTabState();
}

class _ProfileSettingsTabState extends State<ProfileSettingsTab> {
  final _formKey = GlobalKey<FormState>();
  final DateFormat _birthdayFormat = DateFormat('dd/MM/yyyy');
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
  final List<String> _allergies = [];
  bool _isLoading = false;
  List<String> _filteredAllergies = [];
  bool _showAllergySuggestions = false;
  String _allergySearchQuery = '';
  int? _birthdayDayPart;
  int? _birthdayMonthPart;
  int? _birthdayYearPart;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserData());
  }

  Future<void> _loadUserData() async {
    final authUser = context.read<AuthBloc>().state.user;
    if (authUser.isNotEmpty) {
      _nameController.text = authUser.name;
      _emailController.text = authUser.email;
    }
    try {
      final userService = context.read<UserService>();
      final profile = await userService.getProfile();
      if (profile.isNotEmpty && mounted) {
        setState(() {
          _nameController.text = profile.name;
          _emailController.text = profile.email;
          _phoneController.text = profile.phone ?? '';
          _addressController.text = profile.address ?? '';
          _selectedGender = _genderUiFromApi(profile.gender);
          _selectedBloodGroup = profile.bloodGroup;
          if (profile.birthday != null && profile.birthday!.isNotEmpty) {
            _selectedBirthday = DateTime.tryParse(profile.birthday!) ??
                DateTime.tryParse('${profile.birthday}T00:00:00');
          } else {
            _selectedBirthday = null;
          }
          if (_selectedBirthday != null) {
            _birthdayDayPart = _selectedBirthday!.day;
            _birthdayMonthPart = _selectedBirthday!.month;
            _birthdayYearPart = _selectedBirthday!.year;
          } else {
            _birthdayDayPart = null;
            _birthdayMonthPart = null;
            _birthdayYearPart = null;
          }
          _weightController.text =
              profile.weight != null ? _formatNumForField(profile.weight!) : '';
          _heightController.text =
              profile.height != null ? _formatNumForField(profile.height!) : '';
        });
      }
    } catch (_) {
      // Giữ data từ AuthBloc nếu API lỗi
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _customAllergyController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng kiểm tra lại thông tin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final birthdayDay = _birthdayDayPart?.toString() ?? '';
    final birthdayMonth = _birthdayMonthPart?.toString() ?? '';
    final birthdayYear = _birthdayYearPart?.toString() ?? '';
    final hasBirthdayPart =
        birthdayDay.isNotEmpty || birthdayMonth.isNotEmpty || birthdayYear.isNotEmpty;
    final birthdayInput = hasBirthdayPart
        ? '${birthdayDay.padLeft(2, '0')}/${birthdayMonth.padLeft(2, '0')}/${birthdayYear.padLeft(4, '0')}'
        : '';
    DateTime? birthdayToSave;
    if (birthdayInput.isNotEmpty) {
      try {
        birthdayToSave = _birthdayFormat.parseStrict(birthdayInput);
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ngày sinh phải đúng định dạng dd/mm/yyyy'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (birthdayToSave != null && birthdayToSave.isAfter(DateTime.now())) {
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

    try {
      final userService = context.read<UserService>();
      final wText = _weightController.text.trim();
      final hText = _heightController.text.trim();
      final w = wText.isEmpty ? null : double.tryParse(wText);
      final h = hText.isEmpty ? null : double.tryParse(hText);
      if (wText.isNotEmpty && w == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Can nang khong hop le'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      if (hText.isNotEmpty && h == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chieu cao khong hop le'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      await userService.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        gender: _genderApiFromUi(_selectedGender),
        birthday: birthdayToSave != null
            ? _formatBirthdayApi(birthdayToSave)
            : '',
        weight: w,
        height: h,
        bloodGroup: _selectedBloodGroup,
      );
      final profile = await userService.getProfile();
      if (mounted) {
        context.read<AuthBloc>().add(AuthUserUpdated(profile));
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(UserFacingError.message(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleCancel() {
    setState(() {
      _isEditing = false;
    });
    _loadUserData();
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    final userName = user.isNotEmpty ? user.name : 'Người dùng';
    final userEmail = user.isNotEmpty ? user.email : '';
    final avatarUrl =
        user.isNotEmpty && (user.picture ?? '').trim().isNotEmpty
            ? user.picture!.trim()
            : null;
    
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
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryContainer,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Text(
                            StringHelper.getInitials(userName),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 1.2,
                            ),
                          )
                        : null,
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
            SettingsCard(
              title: 'Thông tin cơ bản',
              children: [
                ProfileTextField(
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
                ProfileTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.mail_outline,
                  enabled: false,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSize.spacing16),
                ProfileTextField(
                  controller: _phoneController,
                  label: 'Số điện thoại',
                  icon: Icons.phone_outlined,
                  enabled: _isEditing,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSize.spacing16),
                SettingsDropdown(
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
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Ngày sinh',
                    prefixIcon: const Icon(Icons.cake_outlined),
                    suffixIcon: _isEditing
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_birthdayDayPart != null ||
                                  _birthdayMonthPart != null ||
                                  _birthdayYearPart != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _selectedBirthday = null;
                                      _birthdayDayPart = null;
                                      _birthdayMonthPart = null;
                                      _birthdayYearPart = null;
                                    });
                                  },
                                ),
                            ],
                          )
                        : null,
                    filled: true,
                    fillColor: _isEditing
                        ? AppColors.inputBackground
                        : AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSize.r12),
                      borderSide: BorderSide(color: AppColors.inputBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSize.r12),
                      borderSide: BorderSide(color: AppColors.inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSize.r12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSize.r12),
                      borderSide: BorderSide(color: AppColors.inputBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          value: _birthdayDayPart,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                          ),
                          items: [
                            for (int d = 1; d <= 31; d++)
                              DropdownMenuItem(
                                value: d,
                                child: Text(d.toString().padLeft(2, '0')),
                              ),
                          ],
                          onChanged: _isEditing
                              ? (value) => setState(() => _birthdayDayPart = value)
                              : null,
                          decoration: InputDecoration(
                            hintText: 'dd',
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: AppColors.inputBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: AppColors.inputBorder),
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '/',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          value: _birthdayMonthPart,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                          ),
                          items: [
                            for (int m = 1; m <= 12; m++)
                              DropdownMenuItem(
                                value: m,
                                child: Text(m.toString().padLeft(2, '0')),
                              ),
                          ],
                          onChanged: _isEditing
                              ? (value) => setState(() => _birthdayMonthPart = value)
                              : null,
                          decoration: InputDecoration(
                            hintText: 'mm',
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: AppColors.inputBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: AppColors.inputBorder),
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '/',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<int>(
                          value: _birthdayYearPart,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                          ),
                          items: [
                            for (int y = DateTime.now().year; y >= 1900; y--)
                              DropdownMenuItem(value: y, child: Text('$y')),
                          ],
                          onChanged: _isEditing
                              ? (value) => setState(() => _birthdayYearPart = value)
                              : null,
                          decoration: InputDecoration(
                            hintText: 'yyyy',
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: AppColors.inputBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: AppColors.inputBorder),
                            ),
                          ),
                        ),
                      ),
                      if (!_isEditing &&
                          _birthdayDayPart == null &&
                          _birthdayMonthPart == null &&
                          _birthdayYearPart == null)
                        Text(
                          'dd/mm/yyyy',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textGrey,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSize.spacing16),
                ProfileTextField(
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
            SettingsCard(
              icon: Icons.favorite_outline,
              title: 'Thông tin sức khỏe',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ProfileTextField(
                        controller: _weightController,
                        label: 'Cân nặng',
                        icon: Icons.monitor_weight_outlined,
                        enabled: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        suffixText: 'kg',
                        hintText: 'Nhập cân nặng',
                        onChanged: (_) {
                          if (!_isEditing) {
                            setState(() => _isEditing = true);
                          }
                        },
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
                      child: ProfileTextField(
                        controller: _heightController,
                        label: 'Chiều cao',
                        icon: Icons.straighten_outlined,
                        enabled: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        suffixText: 'cm',
                        hintText: 'Nhập chiều cao',
                        onChanged: (_) {
                          if (!_isEditing) {
                            setState(() => _isEditing = true);
                          }
                        },
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
                SettingsDropdown(
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
            SettingsCard(
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
            
            SizedBox(
              height: MediaQuery.of(context).padding.bottom +
                  AppSize.bottomTabSafeInset,
            ),
          ],
        ),
      ),
    );
  }

}


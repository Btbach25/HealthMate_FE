import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/data/models/medication/medication.dart';
import 'package:fe/data/models/medication/medication_frequency.dart';
import 'package:fe/data/models/medication/medication_reminder.dart';
import 'dart:async';

import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:fe/presentation/medications/bloc/medication_bloc.dart';
import 'package:fe/presentation/medications/widgets/medication_dialog_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Form thêm thuốc — hiển thị trong [showDialog].
class AddMedicationDialog extends StatefulWidget {
  const AddMedicationDialog({super.key});

  @override
  State<AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<AddMedicationDialog> {
  static const TimeOfDay _defaultReminderTime = TimeOfDay(hour: 8, minute: 0);
  static const String _selectDateLabel = 'Chọn ngày';
  static const Duration _submitTimeout = Duration(seconds: 45);
  static const int _minDateYear = 2020;
  static const int _maxDateYear = 2030;

  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _prescribedByCtrl = TextEditingController();

  MedicationFrequencyType _frequencyType = MedicationFrequencyType.daily;
  final List<TimeOfDay> _times = [ _defaultReminderTime ];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _instructionsCtrl.dispose();
    _prescribedByCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _times[index] = picked);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: DateTime(_minDateYear),
      lastDate: DateTime(_maxDateYear),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return _selectDateLabel;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _showErrorSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_nameCtrl.text.trim().isEmpty || _dosageCtrl.text.trim().isEmpty) {
      _showErrorSnack('Vui lòng nhập tên thuốc và liều lượng');
      return;
    }

    final userId = context.read<AuthBloc>().state.user.id;
    if (userId.isEmpty) {
      _showErrorSnack('Không xác định được tài khoản. Vui lòng đăng nhập lại.');
      return;
    }

    final id = 'med-${DateTime.now().millisecondsSinceEpoch}';
    final timeStrings = _times.map(_formatTime).toList();
    final now = DateTime.now();
    final startDateStr = _startDate != null
        ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'
        : '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final medication = Medication(
      id: id,
      userId: userId,
      name: _nameCtrl.text.trim(),
      dosage: _dosageCtrl.text.trim(),
      frequency: MedicationFrequency(
        type: _frequencyType,
        timesPerDay: _times.length,
        specificTimes: timeStrings,
      ),
      startDate: startDateStr,
      endDate: _endDate != null
          ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
          : null,
      instructions: _instructionsCtrl.text.trim(),
      prescribedBy: _prescribedByCtrl.text.trim(),
      reminders: timeStrings
          .asMap()
          .entries
          .map((e) => MedicationReminder(
                id: 'rem-${DateTime.now().millisecondsSinceEpoch}-${e.key}',
                medicationId: id,
                time: e.value,
              ))
          .toList(),
    );

    final bloc = context.read<MedicationBloc>();
    final countBefore = bloc.state.medications.length;
    setState(() => _submitting = true);
    bloc.add(AddMedication(medication: medication));
    try {
      await bloc.stream
          .timeout(_submitTimeout)
          .firstWhere(
        (s) =>
            s.medications.length > countBefore || s.errorMessage != null,
      );
    } on TimeoutException {
      if (!mounted) return;
      _showErrorSnack('Hết thời gian chờ. Kiểm tra kết nối và thử lại.');
      return;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    if (!mounted) return;
    if (bloc.state.errorMessage != null) {
      _showErrorSnack(bloc.state.errorMessage!);
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewInsets.bottom;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: mq.size.height * 0.88,
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MedicationDialogHeader(
                title: 'Thêm thuốc mới',
                subtitle: 'Điền thông tin cơ bản và lịch nhắc uống mỗi ngày.',
                onClose: () => Navigator.of(context).pop(),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Tên thuốc *'),
                      _buildTextField(_nameCtrl, hint: 'Nhập tên thuốc'),
                      const SizedBox(height: 12),
                      _buildLabel('Liều lượng *'),
                      _buildTextField(_dosageCtrl, hint: 'VD: 40mg, 1 viên, 5ml'),
                      const SizedBox(height: 12),
                      _buildLabel('Tần suất'),
                      _buildFrequencyDropdown(),
                      const SizedBox(height: 12),
                      MedicationSectionCard(
                        title: 'Lịch uống',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Thời gian uống'),
                            ..._times.asMap().entries.map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _pickTime(e.key),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 14),
                                            decoration: BoxDecoration(
                                              color: AppColors.inputBackground,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.access_time,
                                                    size: 18, color: AppColors.textGrey),
                                                const SizedBox(width: 8),
                                                Text(_formatTime(e.value),
                                                    style: AppTextStyles.bodyMedium),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_times.length > 1) ...[
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () =>
                                              setState(() => _times.removeAt(e.key)),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.errorLight,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.close,
                                                size: 18, color: AppColors.error),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                )),
                            TextButton.icon(
                              onPressed: () =>
                                  setState(() => _times.add(_defaultReminderTime)),
                              icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                              label: const Text('Thêm giờ uống',
                                  style: TextStyle(color: AppColors.primary)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Ngày bắt đầu'),
                                      _buildDateButton(
                                          label: _formatDate(_startDate),
                                          onTap: () => _pickDate(isStart: true)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Ngày kết thúc'),
                                      _buildDateButton(
                                          label: _formatDate(_endDate),
                                          onTap: () => _pickDate(isStart: false)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildLabel('Hướng dẫn sử dụng'),
                      _buildTextField(_instructionsCtrl,
                          hint: 'VD: Uống sau ăn, tránh ánh nắng...'),
                      const SizedBox(height: 12),
                      _buildLabel('Bác sĩ kê đơn'),
                      _buildTextField(_prescribedByCtrl,
                          hint: 'Tên bác sĩ (tùy chọn)'),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _submitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Thêm thuốc',
                                  style: AppTextStyles.buttonLarge),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: AppTextStyles.labelSmall),
      );

  Widget _buildTextField(
    TextEditingController ctrl, {
    required String hint,
  }) =>
      TextField(
        controller: ctrl,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.caption,
          filled: true,
          fillColor: AppColors.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      );

  Widget _buildFrequencyDropdown() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<MedicationFrequencyType>(
            value: _frequencyType,
            isExpanded: true,
            style: AppTextStyles.bodyMedium,
            items: MedicationFrequencyType.values
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.label),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _frequencyType = v);
            },
          ),
        ),
      );

  Widget _buildDateButton(
          {required String label, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 16, color: AppColors.textGrey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: label == _selectDateLabel
                      ? AppTextStyles.caption
                      : AppTextStyles.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
}

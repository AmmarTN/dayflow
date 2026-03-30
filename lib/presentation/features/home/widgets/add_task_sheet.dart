import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dayflow/presentation/common/theme/app_colors.dart';
import 'package:dayflow/presentation/common/theme/app_text_styles.dart';
import 'package:dayflow/presentation/features/home/cubit/tasks_cubit.dart';
import 'package:dayflow/i18n/strings.g.dart';
import 'package:intl/intl.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<TasksCubit>(),
        child: const AddTaskSheet(),
      ),
    );
  }

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _focusNode = FocusNode();
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = context.read<TasksCubit>().state.currentDate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    _focusNode.unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) => _darkPickerTheme(child!),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    _focusNode.unfocus();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) => _darkPickerTheme(child!),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Widget _darkPickerTheme(Widget child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accentGreen,
          onPrimary: AppColors.darkBackground,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkTextPrimary,
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: AppColors.darkSurface,
          hourMinuteColor: AppColors.darkCardBg,
          hourMinuteTextColor: AppColors.darkTextPrimary,
          dialBackgroundColor: AppColors.darkCardBg,
          dialHandColor: AppColors.accentGreen,
          dialTextColor: AppColors.darkTextPrimary,
          entryModeIconColor: AppColors.accentGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
        ),
      ),
      child: child,
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final subtitle = _subtitleController.text.trim();

    String? timeStr;
    if (_selectedTime != null) {
      final h = _selectedTime!.hour.toString().padLeft(2, '0');
      final m = _selectedTime!.minute.toString().padLeft(2, '0');
      timeStr = '$h:$m';
    }

    context.read<TasksCubit>().addTask(
          title,
          subtitle: subtitle.isNotEmpty ? subtitle : null,
          date: _selectedDate,
          scheduledTime: timeStr,
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    final dateLabel = isToday
        ? 'Today'
        : DateFormat('EEE, MMM d').format(_selectedDate);

    final timeLabel = _selectedTime != null
        ? _selectedTime!.format(context)
        : 'Set time';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border(
            top: BorderSide(color: AppColors.darkBorder, width: 1),
            left: BorderSide(color: AppColors.darkBorder, width: 1),
            right: BorderSide(color: AppColors.darkBorder, width: 1),
          ),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              t.home.add_task,
              style: AppTextStyles(context).px18wBold().copyWith(
                    color: AppColors.darkTextPrimary,
                  ),
            ),
            SizedBox(height: 20.h),
            _buildTextField(
              controller: _titleController,
              focusNode: _focusNode,
              hint: t.home.task_title_hint,
              onSubmitted: (_) => _submit(),
            ),
            SizedBox(height: 12.h),
            _buildTextField(
              controller: _subtitleController,
              hint: 'Add a note (optional)',
              onSubmitted: (_) => _submit(),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildPickerTile(
                    icon: Icons.calendar_today_rounded,
                    label: dateLabel,
                    onTap: _pickDate,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  flex: 2,
                  child: _buildPickerTile(
                    icon: Icons.access_time_rounded,
                    label: timeLabel,
                    isPlaceholder: _selectedTime == null,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: AppColors.darkBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  t.home.add_task,
                  style: AppTextStyles(context).px16wBold().copyWith(
                        color: AppColors.darkBackground,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String label,
    bool isPlaceholder = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.darkCardBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accentGreen, size: 18.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles(context).px14wRegular().copyWith(
                      color: isPlaceholder
                          ? AppColors.darkTextMuted
                          : AppColors.darkTextPrimary,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String hint,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onSubmitted: onSubmitted,
      style: AppTextStyles(context).px15wRegular().copyWith(
            color: AppColors.darkTextPrimary,
          ),
      cursorColor: AppColors.accentGreen,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles(context).px15wRegular().copyWith(
              color: AppColors.darkTextMuted,
            ),
        filled: true,
        fillColor: AppColors.darkCardBg,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.accentGreen.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

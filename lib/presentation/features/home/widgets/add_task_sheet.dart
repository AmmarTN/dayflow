import 'dart:ui';

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
      builder: (_) => BlocProvider.value(value: context.read<TasksCubit>(), child: const AddTaskSheet()),
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
  String _reminderType = 'notification';

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
    final picked = await _showStyledDatePicker();
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    _focusNode.unfocus();
    final picked = await _showStyledTimePicker();
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<DateTime?> _showStyledDatePicker() async {
    DateTime tempSelected = _selectedDate;
    final today = DateTime.now();

    return showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.74),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isToday = _isSameDay(tempSelected, today);

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28.r),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [const Color(0xFF151918), AppColors.darkCardBg, AppColors.darkBackground],
                      ),
                      border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.9)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.34),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                        BoxShadow(
                          color: AppColors.accentGreen.withValues(alpha: 0.05),
                          blurRadius: 24,
                          spreadRadius: -12,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: Container(
                              height: 120.h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.accentGreen.withValues(alpha: 0.06),
                                    AppColors.accentGreen.withValues(alpha: 0.018),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.4, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 18.h),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Select date',
                                          style: AppTextStyles(
                                            context,
                                          ).px12wMedium().copyWith(color: AppColors.darkTextMuted, letterSpacing: 0.8),
                                        ),
                                        SizedBox(height: 8.h),
                                        Text(
                                          DateFormat('EEE, MMM d').format(tempSelected),
                                          style: AppTextStyles(
                                            context,
                                          ).px28wBold().copyWith(color: AppColors.darkTextPrimary, height: 1.05),
                                        ),
                                        SizedBox(height: 6.h),
                                        Text(
                                          DateFormat('MMMM yyyy').format(tempSelected),
                                          style: AppTextStyles(
                                            context,
                                          ).px13wRegular().copyWith(color: AppColors.darkTextSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.darkCardBg.withValues(alpha: 0.96),
                                      borderRadius: BorderRadius.circular(18.r),
                                      border: Border.all(
                                        color: isToday
                                            ? AppColors.accentGreen.withValues(alpha: 0.18)
                                            : AppColors.darkBorder.withValues(alpha: 0.9),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          isToday ? 'Today' : DateFormat('EEE').format(tempSelected),
                                          style: AppTextStyles(context).px12wSemiBold().copyWith(
                                            color: isToday ? AppColors.accentGreen : AppColors.darkTextSecondary,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          DateFormat('d MMM').format(tempSelected),
                                          style: AppTextStyles(
                                            context,
                                          ).px11wRegular().copyWith(color: AppColors.darkTextMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 18.h),
                              Container(height: 1, color: AppColors.darkBorder.withValues(alpha: 0.82)),
                              SizedBox(height: 8.h),
                              Theme(
                                data: _buildCalendarTheme(context),
                                child: CalendarDatePicker(
                                  initialDate: tempSelected,
                                  firstDate: DateTime(2024),
                                  lastDate: DateTime(2030),
                                  currentDate: today,
                                  onDateChanged: (date) {
                                    setDialogState(() => tempSelected = date);
                                  },
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.darkTextSecondary,
                                        side: BorderSide(color: AppColors.darkBorder),
                                        minimumSize: Size.fromHeight(48.h),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                                      ),
                                      child: Text(
                                        MaterialLocalizations.of(context).cancelButtonLabel,
                                        style: AppTextStyles(
                                          context,
                                        ).px14wMedium().copyWith(color: AppColors.darkTextSecondary),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.of(context).pop(tempSelected),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accentGreen,
                                        foregroundColor: AppColors.darkBackground,
                                        minimumSize: Size.fromHeight(48.h),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                                      ),
                                      child: Text(
                                        'Choose date',
                                        style: AppTextStyles(
                                          context,
                                        ).px14wBold().copyWith(color: AppColors.darkBackground),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  ThemeData _buildCalendarTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentGreen,
        onPrimary: AppColors.darkBackground,
        surface: Colors.transparent,
        onSurface: AppColors.darkTextPrimary,
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppColors.darkTextSecondary)),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: AppColors.darkTextSecondary)),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        dividerColor: Colors.transparent,
        weekdayStyle: AppTextStyles(context).px13wMedium().copyWith(color: AppColors.darkTextMuted),
        dayStyle: AppTextStyles(context).px14wSemiBold().copyWith(color: AppColors.darkTextSecondary),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkBackground;
          }
          if (states.contains(WidgetState.disabled)) {
            return AppColors.darkTextMuted.withValues(alpha: 0.35);
          }
          return AppColors.darkTextSecondary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentGreen;
          }
          return Colors.transparent;
        }),
        dayOverlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.accentGreen.withValues(alpha: 0.12);
          }
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkBackground;
          }
          return AppColors.accentGreen;
        }),
        todayBorder: BorderSide(color: AppColors.accentGreen.withValues(alpha: 0.8), width: 1.4),
        subHeaderForegroundColor: AppColors.darkTextSecondary,
        yearStyle: AppTextStyles(context).px14wMedium().copyWith(color: AppColors.darkTextSecondary),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkBackground;
          }
          return AppColors.darkTextSecondary;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentGreen;
          }
          return Colors.transparent;
        }),
        yearOverlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.accentGreen.withValues(alpha: 0.12);
          }
          return Colors.transparent;
        }),
      ),
    );
  }

  Future<TimeOfDay?> _showStyledTimePicker() async {
    final initialTime = _selectedTime ?? TimeOfDay.now();

    return showDialog<TimeOfDay>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.74),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28.r),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [Color(0xFF151918), AppColors.darkCardBg, AppColors.darkBackground],
                  ),
                  border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.9)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.34), blurRadius: 28, offset: const Offset(0, 14)),
                    BoxShadow(
                      color: AppColors.accentGreen.withValues(alpha: 0.05),
                      blurRadius: 24,
                      spreadRadius: -12,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: 64.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.accentGreen.withValues(alpha: 0.06),
                                AppColors.accentGreen.withValues(alpha: 0.018),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                    MediaQuery.removePadding(
                      context: dialogContext,
                      removeTop: true,
                      removeBottom: true,
                      removeLeft: true,
                      removeRight: true,
                      child: Theme(
                        data: _buildTimePickerThemeData(dialogContext),
                        child: TimePickerDialog(
                          initialTime: initialTime,
                          initialEntryMode: TimePickerEntryMode.dial,
                          helpText: 'Select time',
                          cancelText: MaterialLocalizations.of(dialogContext).cancelButtonLabel,
                          confirmText: 'Choose time',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  ThemeData _buildTimePickerThemeData(BuildContext context) {
    return ThemeData.dark().copyWith(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentGreen,
        onPrimary: AppColors.darkBackground,
        surface: Colors.transparent,
        onSurface: AppColors.darkTextPrimary,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppColors.darkTextSecondary)),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 0),
        helpTextStyle: AppTextStyles(
          context,
        ).px12wMedium().copyWith(color: AppColors.darkTextMuted, letterSpacing: 0.8),
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
          side: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.9)),
        ),
        hourMinuteColor: AppColors.darkCardBg.withValues(alpha: 0.98),
        hourMinuteTextStyle: AppTextStyles(context).px32wBold().copyWith(color: AppColors.darkTextPrimary),
        hourMinuteTextColor: AppColors.darkTextPrimary,
        dayPeriodShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.9)),
        ),
        dayPeriodBorderSide: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.9)),
        dayPeriodColor: AppColors.darkCardBg.withValues(alpha: 0.98),
        dayPeriodTextStyle: AppTextStyles(context).px16wBold().copyWith(color: AppColors.darkTextPrimary),
        dayPeriodTextColor: AppColors.darkTextPrimary,
        dialBackgroundColor: AppColors.darkSurface.withValues(alpha: 0.98),
        dialHandColor: AppColors.accentGreen,
        dialTextStyle: AppTextStyles(context).px16wMedium().copyWith(color: AppColors.darkTextPrimary),
        dialTextColor: AppColors.darkTextPrimary,
        entryModeIconColor: AppColors.accentGreen,
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.darkTextSecondary,
          textStyle: AppTextStyles(context).px14wMedium(),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.accentGreen,
          textStyle: AppTextStyles(context).px14wBold(),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
      reminderType: timeStr != null ? _reminderType : null,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year && _selectedDate.month == now.month && _selectedDate.day == now.day;
    final dateLabel = isToday ? 'Today' : DateFormat('EEE, MMM d').format(_selectedDate);

    final timeLabel = _selectedTime != null ? _selectedTime!.format(context) : 'Set time';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF131716).withValues(alpha: 0.98),
                  AppColors.darkCardBg.withValues(alpha: 0.99),
                  AppColors.darkBackground,
                ],
              ),
              border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.85), width: 1),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.36), blurRadius: 32, offset: const Offset(0, -14)),
                BoxShadow(
                  color: AppColors.accentGreen.withValues(alpha: 0.06),
                  blurRadius: 26,
                  spreadRadius: -10,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 132.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.accentGreen.withValues(alpha: 0.08),
                            AppColors.accentGreen.withValues(alpha: 0.025),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.42, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -6.h,
                  left: 54.w,
                  right: 54.w,
                  child: IgnorePointer(
                    child: Container(
                      height: 78.h,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppColors.accentGreen.withValues(alpha: 0.07),
                            AppColors.accentGreenGlow.withValues(alpha: 0.025),
                            Colors.transparent,
                          ],
                          radius: 0.95,
                          center: const Alignment(0, -0.15),
                        ),
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 22.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999.r),
                            color: AppColors.accentGreen,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.home.add_task,
                                  style: AppTextStyles(
                                    context,
                                  ).px24wBold().copyWith(color: AppColors.darkTextPrimary, height: 1.08),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  'Keep it quick. Add the task, then choose when it should surface.',
                                  style: AppTextStyles(
                                    context,
                                  ).px13wRegular().copyWith(color: AppColors.darkTextSecondary, height: 1.42),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          _buildSchedulePreview(dateLabel, timeLabel),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      _buildTextField(
                        controller: _titleController,
                        focusNode: _focusNode,
                        hint: t.home.task_title_hint,
                        icon: Icons.edit_outlined,
                        onSubmitted: (_) => _submit(),
                      ),
                      SizedBox(height: 12.h),
                      _buildTextField(
                        controller: _subtitleController,
                        hint: 'Add a note (optional)',
                        icon: Icons.notes_rounded,
                        onSubmitted: (_) => _submit(),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildPickerTile(
                              title: 'Date',
                              icon: Icons.calendar_today_rounded,
                              label: dateLabel,
                              onTap: _pickDate,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            flex: 2,
                            child: _buildPickerTile(
                              title: 'Time',
                              icon: Icons.access_time_rounded,
                              label: timeLabel,
                              isPlaceholder: _selectedTime == null,
                              onTap: _pickTime,
                            ),
                          ),
                        ],
                      ),
                      if (_selectedTime != null) ...[
                        SizedBox(height: 14.h),
                        Text(
                          'Reminder mode',
                          style: AppTextStyles(
                            context,
                          ).px12wMedium().copyWith(color: AppColors.darkTextMuted, letterSpacing: 1.2),
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildReminderOption(
                                icon: Icons.notifications_none_rounded,
                                label: t.home.notify_label,
                                value: 'notification',
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: _buildReminderOption(
                                icon: Icons.alarm_rounded,
                                label: t.home.alarm_label,
                                value: 'alarm',
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 22.h),
                      Container(
                        width: double.infinity,
                        height: 56.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentGreen.withValues(alpha: 0.22),
                              blurRadius: 24,
                              spreadRadius: -8,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGreen,
                            foregroundColor: AppColors.darkBackground,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                            elevation: 0,
                          ),
                          child: Text(
                            t.home.add_task,
                            style: AppTextStyles(context).px16wBold().copyWith(color: AppColors.darkBackground),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderOption({required IconData icon, required String label, required String value}) {
    final isSelected = _reminderType == value;
    return GestureDetector(
      onTap: () => setState(() => _reminderType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentGreen.withValues(alpha: 0.1)
              : AppColors.darkCardBg.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isSelected
                ? AppColors.accentGreen.withValues(alpha: 0.32)
                : AppColors.darkBorder.withValues(alpha: 0.9),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.accentGreen.withValues(alpha: 0.08),
                blurRadius: 20,
                spreadRadius: -10,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.accentGreen.withValues(alpha: 0.14)
                    : AppColors.darkBackground.withValues(alpha: 0.55),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accentGreen.withValues(alpha: 0.22)
                      : AppColors.darkBorder.withValues(alpha: 0.9),
                ),
              ),
              child: Icon(icon, color: isSelected ? AppColors.accentGreen : AppColors.darkTextMuted, size: 18.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles(
                  context,
                ).px14wMedium().copyWith(color: isSelected ? AppColors.darkTextPrimary : AppColors.darkTextSecondary),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: isSelected ? 1 : 0,
              child: Container(
                width: 22.w,
                height: 22.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentGreen.withValues(alpha: 0.16),
                  border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.24)),
                ),
                child: Icon(Icons.check_rounded, color: AppColors.accentGreen, size: 14.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required String title,
    required IconData icon,
    required String label,
    bool isPlaceholder = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isPlaceholder
              ? AppColors.darkCardBg.withValues(alpha: 0.96)
              : AppColors.accentGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isPlaceholder
                ? AppColors.darkBorder.withValues(alpha: 0.95)
                : AppColors.accentGreen.withValues(alpha: 0.28),
          ),
          boxShadow: [
            if (!isPlaceholder)
              BoxShadow(
                color: AppColors.accentGreen.withValues(alpha: 0.06),
                blurRadius: 16,
                spreadRadius: -10,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPlaceholder
                        ? AppColors.darkBackground.withValues(alpha: 0.54)
                        : AppColors.accentGreen.withValues(alpha: 0.14),
                    border: Border.all(
                      color: isPlaceholder ? AppColors.darkBorder : AppColors.accentGreen.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isPlaceholder ? AppColors.darkTextMuted : AppColors.accentGreen,
                    size: 17.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  title,
                  style: AppTextStyles(context).px12wMedium().copyWith(
                    color: isPlaceholder ? AppColors.darkTextMuted : AppColors.accentGreen.withValues(alpha: 0.9),
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Text(
              label,
              style: AppTextStyles(
                context,
              ).px15wSemiBold().copyWith(color: isPlaceholder ? AppColors.darkTextMuted : AppColors.darkTextPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulePreview(String dateLabel, String timeLabel) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: AppColors.darkCardBg.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: _selectedTime != null
              ? AppColors.accentGreen.withValues(alpha: 0.18)
              : AppColors.darkBorder.withValues(alpha: 0.9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            dateLabel,
            style: AppTextStyles(context).px12wSemiBold().copyWith(
              color: _selectedTime != null ? AppColors.accentGreen : AppColors.darkTextSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _selectedTime != null ? timeLabel : 'No time yet',
            style: AppTextStyles(context).px11wRegular().copyWith(color: AppColors.darkTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String hint,
    required IconData icon,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onSubmitted: onSubmitted,
      style: AppTextStyles(context).px15wRegular().copyWith(color: AppColors.darkTextPrimary),
      cursorColor: AppColors.accentGreen,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles(context).px15wRegular().copyWith(color: AppColors.darkTextMuted),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: 6.w, right: 4.w),
          child: Icon(icon, color: AppColors.accentGreen.withValues(alpha: 0.78), size: 20.sp),
        ),
        prefixIconConstraints: BoxConstraints(minWidth: 42.w, minHeight: 20.h),
        filled: true,
        fillColor: AppColors.darkCardBg.withValues(alpha: 0.82),
        contentPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.r),
          borderSide: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.95)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.r),
          borderSide: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.95)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.r),
          borderSide: BorderSide(color: AppColors.accentGreen.withValues(alpha: 0.42), width: 1.2),
        ),
      ),
    );
  }
}

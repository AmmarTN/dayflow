import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dayflow/presentation/common/theme/app_colors.dart';
import 'package:dayflow/presentation/common/theme/app_text_styles.dart';
import 'package:dayflow/presentation/features/home/cubit/tasks_state.dart';
import 'package:dayflow/i18n/strings.g.dart';
import 'package:intl/intl.dart';

class GreetingCard extends StatelessWidget {
  final DateTime selectedDate;
  final TemporalState temporalState;
  final int totalCount;
  final int completedCount;
  final int pendingCount;

  const GreetingCard({
    super.key,
    required this.selectedDate,
    required this.temporalState,
    required this.totalCount,
    required this.completedCount,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    switch (temporalState) {
      case TemporalState.today:
        return _buildToday(context);
      case TemporalState.past:
        return _buildPast(context);
      case TemporalState.future:
        return _buildFuture(context);
    }
  }

  Widget _buildToday(BuildContext context) {
    final baseStyle = AppTextStyles(context).px24wBold().copyWith(color: AppColors.darkTextPrimary, height: 1.35);
    final accentStyle = baseStyle.copyWith(color: AppColors.accentGreen);
    final taskLabel = pendingCount == 1 ? t.home.task_word : t.home.tasks_word;
    final greeting = _getTimeGreeting();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$greeting.', style: baseStyle),
        SizedBox(height: 4.h),
        Text.rich(
          TextSpan(
            style: baseStyle,
            children: [
              TextSpan(text: t.home.tasks_before_count),
              TextSpan(text: '$pendingCount $taskLabel', style: accentStyle),
              TextSpan(text: t.home.tasks_after_count),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPast(BuildContext context) {
    final baseStyle = AppTextStyles(context).px24wBold().copyWith(color: AppColors.darkTextPrimary, height: 1.35);
    final accentStyle = baseStyle.copyWith(color: AppColors.accentBlue);
    final subStyle = AppTextStyles(context).px14wMedium().copyWith(color: AppColors.darkTextSecondary);
    final dateLabel = DateFormat('EEEE, MMMM d').format(selectedDate);
    final missedCount = totalCount - completedCount;
    final taskLabel = totalCount == 1 ? t.home.task_word : t.home.tasks_word;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$dateLabel —', style: baseStyle.copyWith(fontSize: 20.sp)),
        SizedBox(height: 4.h),
        Text.rich(
          TextSpan(
            style: baseStyle,
            children: [
              TextSpan(text: t.home.past_you_had),
              TextSpan(text: '$totalCount $taskLabel', style: accentStyle),
              TextSpan(text: t.home.past_this_day),
            ],
          ),
        ),
        if (totalCount > 0) ...[
          SizedBox(height: 6.h),
          Text('$completedCount${t.home.past_completed} · $missedCount${t.home.past_missed}', style: subStyle),
        ],
      ],
    );
  }

  Widget _buildFuture(BuildContext context) {
    final baseStyle = AppTextStyles(context).px24wBold().copyWith(color: AppColors.darkTextPrimary, height: 1.35);
    final accentStyle = baseStyle.copyWith(color: AppColors.accentOrange);
    final subStyle = AppTextStyles(context).px14wMedium().copyWith(color: AppColors.darkTextSecondary);
    final dateLabel = DateFormat('EEEE, MMMM d').format(selectedDate);
    final taskLabel = totalCount == 1 ? t.home.task_word : t.home.tasks_word;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$dateLabel —', style: baseStyle.copyWith(fontSize: 20.sp)),
        SizedBox(height: 4.h),
        Text.rich(
          TextSpan(
            style: baseStyle,
            children: [
              TextSpan(text: t.home.future_you_have),
              TextSpan(text: '$totalCount $taskLabel', style: accentStyle),
              TextSpan(text: t.home.future_planned),
            ],
          ),
        ),
        SizedBox(height: 6.h),
        //Text(t.home.future_tap_add, style: subStyle),
      ],
    );
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return t.home.good_morning;
    if (hour < 17) return t.home.good_afternoon;
    return t.home.good_evening;
  }
}

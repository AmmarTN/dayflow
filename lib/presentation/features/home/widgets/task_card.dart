import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dayflow/infrastructure/models/tasks/task_model.dart';
import 'package:dayflow/presentation/common/theme/app_colors.dart';
import 'package:dayflow/presentation/common/theme/app_text_styles.dart';
import 'package:dayflow/presentation/features/home/cubit/tasks_cubit.dart';
import 'package:dayflow/presentation/features/home/cubit/tasks_state.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final TemporalState temporalState;
  final bool showDateBadge;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.temporalState,
    this.showDateBadge = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFuture = temporalState == TemporalState.future;
    final isPast = temporalState == TemporalState.past;
    final cardOpacity = isPast ? 0.65 : 1.0;

    return Opacity(
      opacity: cardOpacity,
      child: Dismissible(
        key: Key(task.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => context.read<TasksCubit>().deleteTask(task.id),
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.w),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(
            Icons.delete_outline,
            color: Colors.red.shade300,
            size: 24.sp,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16.r),
            child: Ink(
              padding: EdgeInsets.all(16.w),
              decoration: _cardDecoration(isFuture),
              child: Row(
                children: [
                  _buildIndicator(context),
                  SizedBox(width: 14.w),
                  Expanded(child: _buildContent(context)),
                  if (showDateBadge || task.scheduledTime != null) ...[
                    SizedBox(width: 8.w),
                    _buildMetaBadge(context),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(bool isFuture) {
    if (isFuture) {
      return BoxDecoration(
        color: AppColors.darkCardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.accentOrange.withValues(alpha: 0.3),
          width: 1,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      );
    }
    return BoxDecoration(
      color: AppColors.darkCardBg,
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(color: AppColors.darkBorder, width: 1),
    );
  }

  Widget _buildIndicator(BuildContext context) {
    switch (temporalState) {
      case TemporalState.today:
        return _todayCheckbox(context);
      case TemporalState.past:
        return task.isDone ? _pastCompletedIcon() : _pastMissedIcon();
      case TemporalState.future:
        return _futureIndicator();
    }
  }

  Widget _todayCheckbox(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<TasksCubit>().toggleTask(task.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24.w,
        height: 24.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: task.isDone ? AppColors.accentGreen : Colors.transparent,
          border: Border.all(
            color: task.isDone
                ? AppColors.accentGreen
                : AppColors.darkTextMuted,
            width: 2,
          ),
        ),
        child: task.isDone
            ? Icon(Icons.check, size: 14.sp, color: AppColors.darkBackground)
            : null,
      ),
    );
  }

  Widget _pastCompletedIcon() {
    return Container(
      width: 24.w,
      height: 24.w,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accentBlue,
      ),
      child: Icon(Icons.check, size: 14.sp, color: AppColors.darkBackground),
    );
  }

  Widget _pastMissedIcon() {
    return Container(
      width: 24.w,
      height: 24.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.missedRed.withValues(alpha: 0.6),
      ),
      child: Icon(Icons.close, size: 14.sp, color: Colors.red.shade200),
    );
  }

  Widget _futureIndicator() {
    return Container(
      width: 24.w,
      height: 24.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accentOrange.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isPast = temporalState == TemporalState.past;
    final isMissedPast = isPast && !task.isDone;
    final isCompletedPast = isPast && task.isDone;
    final isDoneToday = temporalState == TemporalState.today && task.isDone;

    final titleColor = (isDoneToday || isCompletedPast)
        ? AppColors.darkTextMuted
        : isMissedPast
        ? AppColors.darkTextSecondary
        : AppColors.darkTextPrimary;

    final titleDecoration = (isDoneToday || isCompletedPast)
        ? TextDecoration.lineThrough
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles(context).px15wSemiBold().copyWith(
            color: titleColor,
            decoration: titleDecoration,
            decorationColor: AppColors.darkTextMuted,
          ),
        ),
        if (task.subtitle != null && task.subtitle!.isNotEmpty) ...[
          SizedBox(height: 4.h),
          Text(
            task.subtitle!,
            style: AppTextStyles(
              context,
            ).px12wRegular().copyWith(color: AppColors.darkTextMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildMetaBadge(BuildContext context) {
    final isDone = task.isDone;
    final isPast = temporalState == TemporalState.past;
    final isMuted = isDone || isPast;

    final accent = temporalState.accent;
    final badgeColor = isMuted
        ? AppColors.darkTextMuted.withValues(alpha: 0.15)
        : accent.withValues(alpha: 0.12);
    final textColor = isMuted ? AppColors.darkTextMuted : accent;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDateBadge)
            _buildMetaLine(
              context,
              text: _formatCompactDate(task.createdAt),
              icon: Icons.calendar_today_outlined,
              color: textColor,
            ),
          if (showDateBadge && task.scheduledTime != null)
            SizedBox(height: 3.h),
          if (task.scheduledTime != null)
            _buildMetaLine(
              context,
              text: _formatTime(task.scheduledTime!),
              icon: task.reminderType == 'alarm'
                  ? Icons.alarm_rounded
                  : (task.reminderType != null
                        ? Icons.notifications_none_rounded
                        : Icons.schedule_rounded),
              color: textColor,
            ),
        ],
      ),
    );
  }

  Widget _buildMetaLine(
    BuildContext context, {
    required String text,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 11.sp),
        SizedBox(width: 4.w),
        Text(
          text,
          style: AppTextStyles(
            context,
          ).px10wMedium().copyWith(color: color, height: 1),
        ),
      ],
    );
  }

  String _formatCompactDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diffDays = target.difference(today).inDays;

    if (diffDays == 1) return 'Tomorrow';
    if (diffDays == -1) return 'Yesterday';
    return DateFormat('MMM d').format(date);
  }

  String _formatTime(String hhMm) {
    final parts = hhMm.split(':');
    if (parts.length != 2) return hhMm;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final dt = DateTime(2000, 1, 1, hour, minute);
    return DateFormat.jm().format(dt);
  }
}

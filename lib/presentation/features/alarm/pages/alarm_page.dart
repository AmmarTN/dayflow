import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dayflow/core/services/notification_service.dart';
import 'package:dayflow/infrastructure/models/tasks/task_model.dart';
import 'package:dayflow/injection.dart';
import 'package:dayflow/presentation/common/theme/app_colors.dart';
import 'package:dayflow/presentation/common/theme/app_text_styles.dart';
import 'package:dayflow/presentation/features/home/cubit/tasks_cubit.dart';
import 'package:dayflow/presentation/features/home/cubit/tasks_state.dart';
import 'package:dayflow/i18n/strings.g.dart';
import 'package:intl/intl.dart';

@RoutePage()
class AlarmPage extends StatefulWidget {
  final String taskId;

  const AlarmPage({super.key, required this.taskId});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    getIt<NotificationService>().cancelNotification(widget.taskId);
  }

  TaskModel? _findTask(TasksState state) {
    try {
      return state.tasks.firstWhere((t) => t.id == widget.taskId);
    } catch (_) {
      return null;
    }
  }

  String _formatTime(String hhMm) {
    final parts = hhMm.split(':');
    if (parts.length != 2) return hhMm;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final dt = DateTime(2000, 1, 1, hour, minute);
    return DateFormat.jm().format(dt);
  }

  void _markDone() {
    getIt<NotificationService>().cancelNotification(widget.taskId);
    context.read<TasksCubit>().toggleTask(widget.taskId);
    context.router.maybePop();
  }

  void _snooze() {
    getIt<NotificationService>().cancelNotification(widget.taskId);
    final newTime = DateTime.now().add(const Duration(minutes: 10));
    context.read<TasksCubit>().rescheduleTask(widget.taskId, newTime);
    context.router.maybePop();
  }

  void _dismiss() {
    getIt<NotificationService>().cancelNotification(widget.taskId);
    context.router.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final task = _findTask(state);

        if (task == null) {
          return Scaffold(
            backgroundColor: AppColors.darkBackground,
            body: Center(
              child: Text(
                'Task not found',
                style: AppTextStyles(context).px16wRegular().copyWith(
                      color: AppColors.darkTextMuted,
                    ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  _buildPulsingIcon(),
                  SizedBox(height: 32.h),
                  Text(
                    t.alarm.task_reminder,
                    style: AppTextStyles(context).px12wMedium().copyWith(
                          color: AppColors.darkTextMuted,
                          letterSpacing: 3,
                        ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    task.title,
                    style: AppTextStyles(context).px24wBold().copyWith(
                          color: AppColors.darkTextPrimary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (task.subtitle != null && task.subtitle!.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Text(
                      task.subtitle!,
                      style: AppTextStyles(context).px14wRegular().copyWith(
                            color: AppColors.darkTextSecondary,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (task.scheduledTime != null) ...[
                    SizedBox(height: 20.h),
                    Text(
                      _formatTime(task.scheduledTime!),
                      style: AppTextStyles(context).px16wMedium().copyWith(
                            color: AppColors.accentGreen,
                          ),
                    ),
                  ],
                  const Spacer(flex: 3),
                  _buildMarkDoneButton(),
                  SizedBox(height: 12.h),
                  _buildSnoozeButton(),
                  SizedBox(height: 12.h),
                  _buildDismissButton(),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPulsingIcon() {
    return SizedBox(
      width: 90.w,
      height: 90.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 90.w,
            height: 90.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accentGreen.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.15, 1.15),
                duration: 1200.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(duration: 600.ms),
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGreen.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              color: AppColors.accentGreen,
              size: 30.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkDoneButton() {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton.icon(
        onPressed: _markDone,
        icon: Icon(Icons.check_rounded, size: 20.sp),
        label: Text(
          t.alarm.mark_done,
          style: AppTextStyles(context).px16wBold().copyWith(
                color: AppColors.darkBackground,
              ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGreen,
          foregroundColor: AppColors.darkBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildSnoozeButton() {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: OutlinedButton.icon(
        onPressed: _snooze,
        icon: Icon(Icons.snooze_rounded, size: 20.sp),
        label: Text(
          t.alarm.snooze_10_min,
          style: AppTextStyles(context).px16wMedium().copyWith(
                color: AppColors.darkTextPrimary,
              ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.darkBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissButton() {
    return TextButton(
      onPressed: _dismiss,
      child: Text(
        t.alarm.dismiss,
        style: AppTextStyles(context).px14wMedium().copyWith(
              color: AppColors.darkTextMuted,
            ),
      ),
    );
  }
}

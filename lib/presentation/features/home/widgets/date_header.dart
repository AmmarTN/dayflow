import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dayflow/presentation/common/theme/app_colors.dart';
import 'package:dayflow/presentation/common/theme/app_text_styles.dart';
import 'package:dayflow/presentation/features/home/cubit/tasks_state.dart';
import 'package:intl/intl.dart';

class DateHeader extends StatelessWidget {
  final DateTime selectedDate;
  final double completionRatio;
  final int completedCount;
  final int totalCount;
  final TemporalState temporalState;

  const DateHeader({
    super.key,
    required this.selectedDate,
    required this.completionRatio,
    required this.completedCount,
    required this.totalCount,
    required this.temporalState,
  });

  @override
  Widget build(BuildContext context) {
    final dayNumber = selectedDate.day.toString();
    final dayName = DateFormat('EEEE').format(selectedDate);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildIndicator(context),
        SizedBox(width: 10.w),
        Text(
          dayNumber,
          style: AppTextStyles(context).px32wBold().copyWith(
                color: AppColors.darkTextPrimary,
              ),
        ),
        SizedBox(width: 8.w),
        Text(
          dayName,
          style: AppTextStyles(context).px20wRegular().copyWith(
                color: AppColors.darkTextSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildIndicator(BuildContext context) {
    switch (temporalState) {
      case TemporalState.today:
        return _ActivityRing(ratio: completionRatio);
      case TemporalState.past:
        return _FractionBadge(
          completed: completedCount,
          total: totalCount,
        );
      case TemporalState.future:
        return _CountBadge(count: totalCount);
    }
  }
}

class _ActivityRing extends StatelessWidget {
  final double ratio;

  const _ActivityRing({required this.ratio});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36.w,
      height: 36.w,
      child: CustomPaint(
        painter: _ActivityRingPainter(ratio: ratio),
      ),
    );
  }
}

class _ActivityRingPainter extends CustomPainter {
  final double ratio;

  _ActivityRingPainter({required this.ratio});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    final bgPaint = Paint()
      ..color = AppColors.darkBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = AppColors.accentGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (ratio > 0) {
      final sweepAngle = 2 * pi * ratio;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityRingPainter oldDelegate) =>
      oldDelegate.ratio != ratio;
}

class _FractionBadge extends StatelessWidget {
  final int completed;
  final int total;

  const _FractionBadge({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.w,
      height: 36.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accentBlue.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.4), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        total == 0 ? '0' : '$completed/$total',
        style: AppTextStyles(context).px11wBold().copyWith(
              color: AppColors.accentBlue,
            ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.w,
      height: 36.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accentOrange.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.4), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: AppTextStyles(context).px14wBold().copyWith(
              color: AppColors.accentOrange,
            ),
      ),
    );
  }
}

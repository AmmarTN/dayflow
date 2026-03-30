import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dayflow/presentation/common/theme/app_colors.dart';
import 'package:dayflow/presentation/common/theme/app_text_styles.dart';
import 'package:dayflow/presentation/features/home/cubit/tasks_state.dart';
import 'package:intl/intl.dart';

class WeekStrip extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final TemporalState temporalState;

  const WeekStrip({super.key, required this.selectedDate, required this.onDateSelected, required this.temporalState});

  @override
  State<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<WeekStrip> {
  static const int _totalPages = 1000;
  static const int _centerPage = 500;

  late final PageController _pageController;
  late final DateTime _anchorMonday;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anchorMonday = _mondayOf(now);

    final initialOffset = _weekOffset(widget.selectedDate);
    _pageController = PageController(initialPage: _centerPage + initialOffset);
  }

  @override
  void didUpdateWidget(WeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_mondayOf(oldWidget.selectedDate) != _mondayOf(widget.selectedDate)) {
      final target = _centerPage + _weekOffset(widget.selectedDate);
      if (_pageController.hasClients) {
        final current = _pageController.page?.round() ?? _centerPage;
        if (current != target) {
          if ((current - target).abs() > 3) {
            _pageController.jumpToPage(target);
          } else {
            _pageController.animateToPage(target, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _mondayOf(DateTime date) {
    final d = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(d.year, d.month, d.day);
  }

  int _weekOffset(DateTime date) {
    final monday = _mondayOf(date);
    return monday.difference(_anchorMonday).inDays ~/ 7;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64.h,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _totalPages,
        onPageChanged: (page) {
          final offset = page - _centerPage;
          final monday = _anchorMonday.add(Duration(days: offset * 7));
          final sameWeekday = monday.add(Duration(days: widget.selectedDate.weekday - 1));
          widget.onDateSelected(sameWeekday);
        },
        itemBuilder: (context, page) {
          final offset = page - _centerPage;
          final monday = _anchorMonday.add(Duration(days: offset * 7));
          final days = List.generate(7, (i) => monday.add(Duration(days: i)));
          final accent = widget.temporalState.accent;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((day) {
                final isSelected =
                    day.year == widget.selectedDate.year &&
                    day.month == widget.selectedDate.month &&
                    day.day == widget.selectedDate.day;
                return _DayColumn(
                  day: day,
                  isSelected: isSelected,
                  accent: accent,
                  onTap: () => widget.onDateSelected(day),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  const _DayColumn({required this.day, required this.isSelected, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dayLabel = DateFormat('E').format(day)[0];
    final dateNumber = day.day.toString();
    final now = DateTime.now();
    final isToday = day.year == now.year && day.month == now.month && day.day == now.day;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dayLabel,
            style: AppTextStyles(
              context,
            ).px12wMedium().copyWith(color: isSelected ? AppColors.darkTextPrimary : AppColors.darkTextMuted),
          ),
          SizedBox(height: 8.h),
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? accent : Colors.transparent,
              border: isToday && !isSelected ? Border.all(color: AppColors.accentGreen, width: 1.5) : null,
            ),
            alignment: Alignment.center,
            child: Text(
              dateNumber,
              style: AppTextStyles(context).px14wSemiBold().copyWith(
                color: isSelected
                    ? AppColors.darkBackground
                    : isToday
                    ? AppColors.accentGreen
                    : AppColors.darkTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

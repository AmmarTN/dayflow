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

  const WeekStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.temporalState,
  });

  @override
  State<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<WeekStrip> with TickerProviderStateMixin {
  static const int _totalPages = 1000;
  static const int _centerPage = 500;

  late final PageController _pageController;
  late final DateTime _anchorMonday;
  late DateTime _displayedMonth;
  bool _isExpanded = false;
  double _verticalDragDelta = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anchorMonday = _mondayOf(now);
    _displayedMonth = _monthStart(widget.selectedDate);

    final initialOffset = _weekOffset(widget.selectedDate);
    _pageController = PageController(initialPage: _centerPage + initialOffset);
  }

  @override
  void didUpdateWidget(covariant WeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      final target = _centerPage + _weekOffset(widget.selectedDate);
      if (_pageController.hasClients) {
        final current = _pageController.page?.round() ?? _centerPage;
        if (current != target) {
          if ((current - target).abs() > 3) {
            _pageController.jumpToPage(target);
          } else {
            _pageController.animateToPage(
              target,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
            );
          }
        }
      }
    }

    if (!_isSameMonth(_displayedMonth, widget.selectedDate) ||
        !_isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      _displayedMonth = _monthStart(widget.selectedDate);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.temporalState.accent;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: (details) {
        _verticalDragDelta += details.delta.dy;
      },
      onVerticalDragEnd: (_) {
        if (_verticalDragDelta > 16 && !_isExpanded) {
          _setExpanded(true);
        } else if (_verticalDragDelta < -16 && _isExpanded) {
          _setExpanded(false);
        }
        _verticalDragDelta = 0;
      },
      onVerticalDragCancel: () {
        _verticalDragDelta = 0;
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedCrossFade(
              firstChild: _buildCollapsedWeek(accent),
              secondChild: _buildExpandedMonth(context, accent),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 260),
              sizeCurve: Curves.easeOutCubic,
              firstCurve: Curves.easeOutCubic,
              secondCurve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
            ),
            SizedBox(height: _isExpanded ? 10.h : 8.h),
            _buildExpandIndicator(accent),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedWeek(Color accent) {
    return SizedBox(
      height: 64.h,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _totalPages,
        onPageChanged: (page) {
          final offset = page - _centerPage;
          final monday = _anchorMonday.add(Duration(days: offset * 7));
          final sameWeekday = monday.add(
            Duration(days: widget.selectedDate.weekday - 1),
          );
          widget.onDateSelected(sameWeekday);
        },
        itemBuilder: (context, page) {
          final offset = page - _centerPage;
          final monday = _anchorMonday.add(Duration(days: offset * 7));
          final days = List.generate(7, (i) => monday.add(Duration(days: i)));

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((day) {
                return _WeekDayColumn(
                  day: day,
                  isSelected: _isSameDay(day, widget.selectedDate),
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

  Widget _buildExpandedMonth(BuildContext context, Color accent) {
    final monthDays = _monthGridDays(_displayedMonth);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy', locale).format(_displayedMonth),
                  style: AppTextStyles(
                    context,
                  ).px16wSemiBold().copyWith(color: AppColors.darkTextPrimary),
                ),
              ),
              _CalendarIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => _changeMonth(-1),
              ),
              SizedBox(width: 8.w),
              _CalendarIconButton(
                icon: Icons.chevron_right_rounded,
                onTap: () => _changeMonth(1),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final day = _anchorMonday.add(Duration(days: index));
              return Expanded(
                child: Center(
                  child: Text(
                    DateFormat('E', locale).format(day)[0],
                    style: AppTextStyles(
                      context,
                    ).px12wMedium().copyWith(color: AppColors.darkTextMuted),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 10.h),
          ...List.generate(6, (weekIndex) {
            final weekDays = monthDays.skip(weekIndex * 7).take(7).toList();
            return Padding(
              padding: EdgeInsets.only(bottom: weekIndex == 5 ? 0 : 10.h),
              child: Row(
                children: weekDays.map((day) {
                  return Expanded(
                    child: Center(
                      child: _MonthDayCell(
                        day: day,
                        isSelected: _isSameDay(day, widget.selectedDate),
                        isInCurrentMonth: _isSameMonth(day, _displayedMonth),
                        accent: accent,
                        onTap: () {
                          if (!_isSameMonth(day, _displayedMonth)) {
                            setState(() {
                              _displayedMonth = _monthStart(day);
                            });
                          }
                          widget.onDateSelected(day);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExpandIndicator(Color accent) {
    final indicatorColor = Color.lerp(
      AppColors.darkTextMuted,
      accent,
      _isExpanded ? 0.24 : 0.16,
    )!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _setExpanded(!_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 34.w,
        height: 18.h,
        alignment: Alignment.center,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: _isExpanded ? 0.9 : 0.72,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 220),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: indicatorColor,
              size: 17.sp,
            ),
          ),
        ),
      ),
    );
  }

  void _setExpanded(bool value) {
    if (_isExpanded == value) return;
    setState(() {
      _isExpanded = value;
      if (value) {
        _displayedMonth = _monthStart(widget.selectedDate);
      }
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + delta,
        1,
      );
    });
  }

  List<DateTime> _monthGridDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final gridStart = _mondayOf(firstDay);
    return List.generate(42, (index) => gridStart.add(Duration(days: index)));
  }

  DateTime _monthStart(DateTime date) => DateTime(date.year, date.month, 1);

  DateTime _mondayOf(DateTime date) {
    final d = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(d.year, d.month, d.day);
  }

  int _weekOffset(DateTime date) {
    final monday = _mondayOf(date);
    return monday.difference(_anchorMonday).inDays ~/ 7;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}

class _WeekDayColumn extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  const _WeekDayColumn({
    required this.day,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dayLabel = DateFormat('E', locale).format(day)[0];
    final dateNumber = day.day.toString();
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dayLabel,
            style: AppTextStyles(context).px12wMedium().copyWith(
              color: isSelected
                  ? AppColors.darkTextPrimary
                  : AppColors.darkTextMuted,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? accent : Colors.transparent,
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.accentGreen, width: 1.5)
                  : null,
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

class _MonthDayCell extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool isInCurrentMonth;
  final Color accent;
  final VoidCallback onTap;

  const _MonthDayCell({
    required this.day,
    required this.isSelected,
    required this.isInCurrentMonth,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;
    final textColor = isSelected
        ? AppColors.darkBackground
        : isToday
        ? AppColors.accentGreen
        : isInCurrentMonth
        ? AppColors.darkTextSecondary
        : AppColors.darkTextMuted.withValues(alpha: 0.42);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38.w,
        height: 38.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? accent : Colors.transparent,
          border: isToday && !isSelected
              ? Border.all(color: AppColors.accentGreen, width: 1.5)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: AppTextStyles(
            context,
          ).px14wSemiBold().copyWith(color: textColor),
        ),
      ),
    );
  }
}

class _CalendarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CalendarIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34.w,
        height: 34.w,
        decoration: BoxDecoration(
          color: AppColors.darkCardBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.darkBorder),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: AppColors.darkTextSecondary, size: 20.sp),
      ),
    );
  }
}

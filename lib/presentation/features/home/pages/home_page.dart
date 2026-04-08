import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dayflow/i18n/strings.g.dart';
import 'package:dayflow/infrastructure/models/tasks/task_model.dart';
import 'package:dayflow/presentation/common/theme/app_colors.dart';
import 'package:dayflow/presentation/common/theme/app_text_styles.dart';
import 'package:dayflow/presentation/features/home/cubit/tasks_cubit.dart';
import 'package:dayflow/presentation/features/home/cubit/tasks_state.dart';
import 'package:dayflow/presentation/features/home/widgets/add_task_sheet.dart';
import 'package:dayflow/presentation/features/home/widgets/date_header.dart';
import 'package:dayflow/presentation/features/home/widgets/greeting_card.dart';
import 'package:dayflow/presentation/features/home/widgets/task_card.dart';
import 'package:dayflow/presentation/features/home/widgets/weather_row.dart';
import 'package:dayflow/presentation/features/home/widgets/week_strip.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _previousDate = DateTime.now();
  bool _slidingForward = true;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TasksCubit, TasksState>(
      listenWhen: (prev, curr) => prev.currentDate != curr.currentDate,
      listener: (context, state) {
        _slidingForward = state.currentDate.isAfter(_previousDate);
        _previousDate = state.currentDate;
      },
      builder: (context, state) {
        final temporal = state.temporalState;
        final accent = temporal.accent;
        final filteredTasks = state.filteredTasks;
        final overdueTasks = state.overdueTasks;
        final upcomingTasks = state.upcomingTasks;

        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8.h),
                          DateHeader(
                            selectedDate: state.currentDate,
                            completionRatio: state.completionRatio,
                            completedCount: state.completedCount,
                            totalCount: filteredTasks.length,
                            temporalState: temporal,
                          ),
                          SizedBox(height: 20.h),
                          WeekStrip(
                            selectedDate: state.currentDate,
                            onDateSelected: (date) {
                              context.read<TasksCubit>().selectDate(date);
                            },
                            temporalState: temporal,
                          ),
                          SizedBox(height: 10.h),
                        ],
                      ),
                    ),
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _HomeSummaryHeaderDelegate(
                              screenHeight: MediaQuery.of(context).size.height,
                              accent: accent,
                              selectedDate: state.currentDate,
                              temporalState: temporal,
                              totalCount: filteredTasks.length,
                              completedCount: state.completedCount,
                              pendingCount: state.pendingCount,
                              compactValue: _compactSummaryValue(
                                temporal,
                                totalCount: filteredTasks.length,
                                completedCount: state.completedCount,
                                pendingCount: state.pendingCount,
                              ),
                              compactCaption: _compactSummaryCaption(temporal, totalCount: filteredTasks.length),
                              slidingForward: _slidingForward,
                            ),
                          ),
                          ..._buildTaskSlivers(
                            context,
                            temporal: temporal,
                            filteredTasks: filteredTasks,
                            overdueTasks: overdueTasks,
                            upcomingTasks: upcomingTasks,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: accent),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                builder: (context, color, _) => _buildGlowOverlay(context, color!),
              ),
            ],
          ),
          floatingActionButton: _buildFab(context, accent),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  List<Widget> _buildTaskSlivers(
    BuildContext context, {
    required TemporalState temporal,
    required List<TaskModel> filteredTasks,
    required List<TaskModel> overdueTasks,
    required List<TaskModel> upcomingTasks,
  }) {
    if (temporal != TemporalState.today) {
      if (filteredTasks.isEmpty) {
        return [_buildEmptySliver(context, temporal), SliverToBoxAdapter(child: SizedBox(height: 100.h))];
      }

      return [
        ..._buildTaskListSliver(context, tasks: filteredTasks, temporalState: temporal),
        SliverToBoxAdapter(child: SizedBox(height: 100.h)),
      ];
    }

    if (filteredTasks.isEmpty && overdueTasks.isEmpty && upcomingTasks.isEmpty) {
      return [_buildEmptySliver(context, temporal), SliverToBoxAdapter(child: SizedBox(height: 100.h))];
    }

    final slivers = <Widget>[];

    if (filteredTasks.isEmpty) {
      slivers.add(
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 18.h),
          sliver: SliverToBoxAdapter(
            child: Text(
              _emptyMessage(temporal),
              style: AppTextStyles(context).px15wRegular().copyWith(color: AppColors.darkTextMuted),
            ),
          ),
        ),
      );
    } else {
      slivers.addAll(_buildTaskListSliver(context, tasks: filteredTasks, temporalState: TemporalState.today));
    }

    if (upcomingTasks.isNotEmpty) {
      slivers.add(
        _buildSectionHeaderSliver(
          context,
          topSpacing: filteredTasks.isEmpty ? 4.h : 10.h,
          title: t.home.upcoming_label,
          count: upcomingTasks.length,
          accent: AppColors.accentOrange,
        ),
      );
      slivers.addAll(
        _buildTaskListSliver(
          context,
          tasks: upcomingTasks,
          temporalState: TemporalState.future,
          showDateBadge: true,
          onTaskTap: (task) {
            context.read<TasksCubit>().selectDate(task.createdAt);
          },
        ),
      );
    }

    if (overdueTasks.isNotEmpty) {
      slivers.add(
        _buildSectionHeaderSliver(
          context,
          topSpacing: upcomingTasks.isNotEmpty || filteredTasks.isNotEmpty ? 10.h : 4.h,
          title: t.home.overdue_label,
          count: overdueTasks.length,
          accent: const Color(0xFFFF6F6F),
        ),
      );
      slivers.addAll(
        _buildTaskListSliver(
          context,
          tasks: overdueTasks,
          temporalState: TemporalState.past,
          showDateBadge: true,
          onTaskTap: (task) {
            context.read<TasksCubit>().selectDate(task.createdAt);
          },
        ),
      );
    }

    slivers.add(SliverToBoxAdapter(child: SizedBox(height: 100.h)));
    return slivers;
  }

  List<Widget> _buildTaskListSliver(
    BuildContext context, {
    required List<TaskModel> tasks,
    required TemporalState temporalState,
    bool showDateBadge = false,
    ValueChanged<TaskModel>? onTaskTap,
  }) {
    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final task = tasks[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child:
                  TaskCard(
                        task: task,
                        temporalState: temporalState,
                        showDateBadge: showDateBadge,
                        onTap: onTaskTap != null ? () => onTaskTap(task) : null,
                      )
                      .animate()
                      .fadeIn(
                        delay: Duration(milliseconds: 45 * index),
                        duration: 280.ms,
                      )
                      .slideY(
                        begin: 0.08,
                        delay: Duration(milliseconds: 45 * index),
                        duration: 280.ms,
                      ),
            );
          }, childCount: tasks.length),
        ),
      ),
    ];
  }

  Widget _buildSectionHeaderSliver(
    BuildContext context, {
    required double topSpacing,
    required String title,
    required int count,
    required Color accent,
  }) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(20.w, topSpacing, 20.w, 12.h),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Text(title, style: AppTextStyles(context).px18wSemiBold().copyWith(color: AppColors.darkTextPrimary)),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999.r),
                border: Border.all(color: accent.withValues(alpha: 0.24)),
              ),
              child: Text('$count', style: AppTextStyles(context).px11wBold().copyWith(color: accent)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySliver(BuildContext context, TemporalState temporal) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: 60.h),
          child: Text(
            _emptyMessage(temporal),
            style: AppTextStyles(context).px16wRegular().copyWith(color: AppColors.darkTextMuted),
          ),
        ),
      ),
    );
  }

  String _compactSummaryValue(
    TemporalState temporal, {
    required int totalCount,
    required int completedCount,
    required int pendingCount,
  }) {
    switch (temporal) {
      case TemporalState.today:
        final taskLabel = pendingCount == 1 ? t.home.task_word : t.home.tasks_word;
        return '$pendingCount $taskLabel';
      case TemporalState.past:
        return '$completedCount/$totalCount';
      case TemporalState.future:
        return '$totalCount';
    }
  }

  String _compactSummaryCaption(TemporalState temporal, {required int totalCount}) {
    switch (temporal) {
      case TemporalState.today:
        return _cleanCaption(t.home.tasks_after_count);
      case TemporalState.past:
        return totalCount == 0 ? _cleanCaption(t.home.past_missed) : _cleanCaption(t.home.past_completed);
      case TemporalState.future:
        return _cleanCaption(t.home.future_planned);
    }
  }

  String _cleanCaption(String value) => value.trim().replaceAll('.', '');

  String _emptyMessage(TemporalState temporal) {
    switch (temporal) {
      case TemporalState.today:
        return t.home.no_tasks;
      case TemporalState.past:
        return t.home.no_tasks_past;
      case TemporalState.future:
        return t.home.no_tasks_future;
    }
  }

  Widget _buildGlowOverlay(BuildContext context, Color accent) {
    final screenH = MediaQuery.of(context).size.height;
    return Positioned(
      top: -screenH * 0.07,
      left: -100.w,
      right: -100.w,
      child: IgnorePointer(
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0.0, 0.7, 1.0],
            ).createShader(bounds);
          },
          child: Container(
            height: screenH * 0.395,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -0.3),
                colors: [
                  accent.withValues(alpha: 0.12),
                  accent.withValues(alpha: 0.06),
                  accent.withValues(alpha: 0.02),
                  AppColors.darkBackground.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.3, 0.55, 1.0],
                radius: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context, Color accent) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)],
      ),
      child: FloatingActionButton(
        onPressed: () => AddTaskSheet.show(context),
        backgroundColor: AppColors.darkCardBg,
        shape: const CircleBorder(),
        child: Icon(Icons.add, color: accent, size: 28.sp),
      ),
    );
  }
}

class _HomeSummaryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double screenHeight;
  final Color accent;
  final DateTime selectedDate;
  final TemporalState temporalState;
  final int totalCount;
  final int completedCount;
  final int pendingCount;
  final String compactValue;
  final String compactCaption;
  final bool slidingForward;

  const _HomeSummaryHeaderDelegate({
    required this.screenHeight,
    required this.accent,
    required this.selectedDate,
    required this.temporalState,
    required this.totalCount,
    required this.completedCount,
    required this.pendingCount,
    required this.compactValue,
    required this.compactCaption,
    this.slidingForward = true,
  });

  @override
  double get maxExtent => temporalState == TemporalState.past ? screenHeight * 0.17 : screenHeight * 0.14;

  @override
  double get minExtent => screenHeight * 0.065;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final expandedOpacity = (1 - Curves.easeOut.transform(progress)).clamp(0.0, 1.0);
    final compactOpacity = Curves.easeInOut.transform(progress);
    final compactScale = 0.94 + (0.06 * compactOpacity);

    return ClipRect(
      child: Container(
        color: AppColors.darkBackground.withValues(alpha: progress),
        padding: EdgeInsets.fromLTRB(20.w, 2.h, 20.w, 2.h),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Expanded: weather + greeting
            if (expandedOpacity > 0)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: IgnorePointer(
                  ignoring: progress > 0.84,
                  child: Opacity(
                    opacity: expandedOpacity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const WeatherRow(),
                        SizedBox(height: 10.h),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          alignment: Alignment.topLeft,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            layoutBuilder: (currentChild, previousChildren) {
                              return Stack(
                                alignment: Alignment.topLeft,
                                children: [...previousChildren, if (currentChild != null) currentChild],
                              );
                            },
                            transitionBuilder: (child, animation) {
                              final offset = slidingForward
                                  ? Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero)
                                  : Tween<Offset>(begin: const Offset(-0.15, 0), end: Offset.zero);
                              return SlideTransition(
                                position: offset.animate(animation),
                                child: FadeTransition(opacity: animation, child: child),
                              );
                            },
                            child: GreetingCard(
                              key: ValueKey(selectedDate),
                              selectedDate: selectedDate,
                              temporalState: temporalState,
                              totalCount: totalCount,
                              completedCount: completedCount,
                              pendingCount: pendingCount,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Compact: weather row + summary chip
            if (compactOpacity > 0)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  ignoring: progress < 0.12,
                  child: Opacity(
                    opacity: compactOpacity,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Expanded(
                            child: Transform.scale(
                              scale: compactScale,
                              alignment: Alignment.centerLeft,
                              child: const WeatherRow(compact: true),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            child: KeyedSubtree(
                              key: ValueKey('$compactValue$compactCaption'),
                              child: _CompactSummaryChip(
                                temporalState: temporalState,
                                value: compactValue,
                                caption: compactCaption,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeSummaryHeaderDelegate oldDelegate) {
    return oldDelegate.selectedDate != selectedDate ||
        oldDelegate.temporalState != temporalState ||
        oldDelegate.totalCount != totalCount ||
        oldDelegate.completedCount != completedCount ||
        oldDelegate.pendingCount != pendingCount ||
        oldDelegate.compactValue != compactValue ||
        oldDelegate.compactCaption != compactCaption ||
        oldDelegate.accent != accent ||
        oldDelegate.screenHeight != screenHeight ||
        oldDelegate.slidingForward != slidingForward;
  }
}

class _CompactSummaryChip extends StatelessWidget {
  final TemporalState temporalState;
  final String value;
  final String caption;

  const _CompactSummaryChip({required this.temporalState, required this.value, required this.caption});

  @override
  Widget build(BuildContext context) {
    final accent = temporalState.accent;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.darkCardBg,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles(context).px12wBold().copyWith(color: AppColors.darkTextPrimary),
          ),
          SizedBox(width: 4.w),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles(context).px10wMedium().copyWith(color: accent.withValues(alpha: 0.86)),
          ),
        ],
      ),
    );
  }
}

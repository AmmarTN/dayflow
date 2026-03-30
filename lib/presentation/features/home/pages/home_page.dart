import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dayflow/presentation/common/theme/app_colors.dart';
import 'package:dayflow/presentation/common/theme/app_text_styles.dart';
import 'package:dayflow/presentation/features/home/cubit/tasks_cubit.dart';
import 'package:dayflow/presentation/features/home/cubit/tasks_state.dart';
import 'package:dayflow/presentation/features/home/widgets/date_header.dart';
import 'package:dayflow/presentation/features/home/widgets/week_strip.dart';
import 'package:dayflow/presentation/features/home/widgets/weather_row.dart';
import 'package:dayflow/presentation/features/home/widgets/greeting_card.dart';
import 'package:dayflow/presentation/features/home/widgets/task_card.dart';
import 'package:dayflow/presentation/features/home/widgets/add_task_sheet.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dayflow/i18n/strings.g.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final temporal = state.temporalState;
        final accent = temporal.accent;
        final glow = temporal.glow;
        final filteredTasks = state.filteredTasks;

        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          body: Stack(
            children: [
              _buildGlowBackground(accent),
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
                          SizedBox(height: 20.h),
                          const WeatherRow(),
                          SizedBox(height: 24.h),
                          GreetingCard(
                            selectedDate: state.currentDate,
                            temporalState: temporal,
                            totalCount: filteredTasks.length,
                            completedCount: state.completedCount,
                            pendingCount: state.pendingCount,
                          ),
                          SizedBox(height: 24.h),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filteredTasks.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 60.h),
                                child: Text(
                                  _emptyMessage(temporal),
                                  style: AppTextStyles(context)
                                      .px16wRegular()
                                      .copyWith(color: AppColors.darkTextMuted),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.only(
                                left: 20.w,
                                right: 20.w,
                                bottom: 100.h,
                              ),
                              itemCount: filteredTasks.length,
                              itemBuilder: (context, index) {
                                final task = filteredTasks[index];
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 12.h),
                                  child: TaskCard(
                                    task: task,
                                    temporalState: temporal,
                                  )
                                      .animate()
                                      .fadeIn(
                                        delay: Duration(
                                            milliseconds: 50 * index),
                                        duration: 300.ms,
                                      )
                                      .slideY(
                                        begin: 0.1,
                                        delay: Duration(
                                            milliseconds: 50 * index),
                                        duration: 300.ms,
                                      ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: _buildFab(context, accent, glow),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

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

  Widget _buildGlowBackground(Color accent) {
    return Positioned(
      top: -100.h,
      left: -50.w,
      right: -50.w,
      child: Container(
        height: 400.h,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              accent.withValues(alpha: 0.08),
              AppColors.darkBackground.withValues(alpha: 0.0),
            ],
            radius: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context, Color accent, Color glow) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
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

Perfect! Here's the complete IMPLEMENTATION_RULES.md file:

# DayFlow — Implementation Rules & Conventions

This document captures the implicit coding rules, design system, and architectural conventions extracted from the DayFlow Flutter codebase. These are the patterns consistently applied throughout the project.

---

## 1. PROJECT STRUCTURE & FILE ORGANIZATION

### Rule: Feature-First with Layer Separation
**Example:**
lib/ ├── core/ # Cross-cutting concerns ├── infrastructure/ # Data layer (models, repos, datasources) ├── presentation/ # UI layer (pages, widgets, cubits) ├── features/ # Empty (features live in presentation/features/) ├── services/ # App-level services └── i18n/ # Internationalization

**Intent:** Separate concerns by layer (core, infrastructure, presentation) while organizing features within the presentation layer.

### Rule: Snake_case for Folders and Files
**Example:**
```dart
lib/presentation/features/home/pages/home_page.dart
lib/core/usecases/tasks/get_tasks.dart
lib/infrastructure/datasources/local_datasources/tasks_local_data_source.dart
Intent: Follow Dart conventions for file naming consistency.

⚠️ Inconsistent: One file uses cubitStatus.dart instead of cubit_status.dart

Rule: Feature Modules Contain pages/, widgets/, cubit/
Example:

lib/presentation/features/home/
├── cubit/
│   ├── tasks_cubit.dart
│   └── tasks_state.dart
├── pages/
│   └── home_page.dart
└── widgets/
    ├── task_card.dart
    ├── add_task_sheet.dart
    └── greeting_card.dart
Intent: Each feature is self-contained with its state management, pages, and widgets.

Rule: Common/Shared Code Lives in presentation/common/
Example:

lib/presentation/common/
├── constants/
├── cubit/
├── routes/
├── theme/
├── utils/
└── widgets/
Intent: Reusable UI components, themes, and utilities are centralized for cross-feature access.

2. NAMING CONVENTIONS
Rule: Files Use Descriptive Suffixes
Example:

home_page.dart          // Pages
task_card.dart          // Widgets
tasks_cubit.dart        // Cubits
tasks_state.dart        // States
task_model.dart         // Models
get_tasks.dart          // Use cases
tasks_repository_impl.dart  // Repository implementations
tasks_local_data_source.dart // Data sources
Intent: File names immediately communicate their purpose and layer.

Rule: Classes Use PascalCase with Suffixes
Example:

class HomePage extends StatefulWidget {}
class TaskCard extends StatelessWidget {}
class TasksCubit extends Cubit<TasksState> {}
class TaskModel with _$TaskModel {}
class GetTasks extends UnawaitedUsecase {}
class TasksRepositoryImpl implements ITasksRepository {}
Intent: Class names follow Flutter conventions and clearly indicate their role.

Rule: Variables and Functions Use camelCase
Example:

final selectedDate = DateTime.now();
final filteredTasks = state.filteredTasks;
void loadTasks() {}
Future<void> addTask(String title) async {}
Intent: Standard Dart naming for readability.

Rule: Booleans Use is/has/can Prefixes
Example:

bool isLoading = false;
bool isDone = task.isDone;
bool isArabic = context.isArabic;
bool hasError = state.status.statusType == CubitStatusType.failure;
Intent: Make boolean intent immediately clear.

Rule: Private Members Use _ Prefix
Example:

final GetTasks _getTasks;
final SaveTasks _saveTasks;
void _scheduleForTask(TaskModel task) {}
DateTime _previousDate = DateTime.now();
Intent: Encapsulation - private members are implementation details.

Rule: Constants Use Static const with Descriptive Names
Example:

class AppColors {
  static const Color whiteColor = Colors.white;
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color accentGreen = Color(0xFF1EE468);
}

class UIConstants {
  static const double defaultBorderRadius = 31.0;
  static const String dashedDateFormat = "dd-MM-yyyy";
}
Intent: Centralized, typed constants with clear naming.

Rule: Named Constructors Follow Dart Patterns
Example:

factory TaskModel.fromJson(Map<String, dynamic> json) => _$TaskModelFromJson(json);
const factory TasksState({...}) = _TasksState;
const factory Failure.platformFailure({String? message}) = PlatformFailure;
Intent: Use standard Dart patterns (fromJson, copyWith) and freezed factories.

3. STATE MANAGEMENT PATTERNS
Rule: Use Bloc/Cubit for State Management
Example:

@injectable
class TasksCubit extends Cubit<TasksState> {
  final GetTasks _getTasks;
  final SaveTasks _saveTasks;
  
  TasksCubit(this._getTasks, this._saveTasks)
    : super(TasksState(selectedDate: _dateOnly(DateTime.now())));
}
Intent: Bloc pattern with injectable dependency injection for testability.

Rule: States Are Immutable Freezed Classes
Example:

@freezed
class TasksState with _$TasksState {
  const TasksState._();
  
  const factory TasksState({
    @Default(CubitStatus()) CubitStatus status,
    @Default([]) List<TaskModel> tasks,
    DateTime? selectedDate,
  }) = _TasksState;
}
Intent: Immutable state with freezed for copyWith, equality, and serialization.

Rule: Loading/Success/Failure States Use CubitStatus
Example:

enum CubitStatusType { idle, loading, success, failure }

enum CubitAction {
  none,
  loadTasks,
  addTask,
  updateTask,
  toggleTask,
  deleteTask,
}

class CubitStatus extends Equatable {
  final CubitStatusType statusType;
  final CubitAction? action;
  final String? errorMsg;
  // ...
}
Intent: Standardized status tracking with action context for granular UI responses.

Rule: Business Logic Lives in Cubits, UI Logic in Widgets
Example:

// Cubit: Business logic
void loadTasks() {
  emit(state.copyWith(status: const CubitStatus(statusType: CubitStatusType.loading)));
  final result = _getTasks(NoParams());
  result.fold(
    (failure) => emit(state.copyWith(status: CubitStatus(statusType: CubitStatusType.failure))),
    (tasks) => emit(state.copyWith(tasks: tasks, status: const CubitStatus(statusType: CubitStatusType.success))),
  );
}

// Widget: UI logic
@override
Widget build(BuildContext context) {
  return BlocConsumer<TasksCubit, TasksState>(
    listener: (context, state) {
      if (state.status.statusType == CubitStatusType.failure) {
        // Show error
      }
    },
    builder: (context, state) => /* UI */,
  );
}
Intent: Clear separation - cubits handle data/business logic, widgets handle presentation.

Rule: State Is Passed via context.read/context.watch
Example:

// Read for one-time actions
context.read<TasksCubit>().toggleTask(task.id);

// BlocBuilder for reactive UI
BlocBuilder<TasksCubit, TasksState>(
  builder: (context, state) => Text('${state.completedCount}'),
)

// BlocConsumer for both
BlocConsumer<TasksCubit, TasksState>(
  listener: (context, state) { /* side effects */ },
  builder: (context, state) => /* UI */,
)
Intent: Use context.read for actions, BlocBuilder/Consumer for reactive UI updates.

Rule: Computed Properties in State Classes
Example:

@freezed
class TasksState with _$TasksState {
  const TasksState._();
  
  const factory TasksState({...}) = _TasksState;
  
  // Computed properties
  List<TaskModel> get filteredTasks => tasks.where((t) => /* filter */).toList();
  int get completedCount => filteredTasks.where((t) => t.isDone).length;
  double get completionRatio => filteredTasks.isEmpty ? 0.0 : completedCount / filteredTasks.length;
}
Intent: Derived state is computed in state class, not in widgets or cubits.

4. WIDGET PATTERNS & COMPOSITION
Rule: Prefer StatelessWidget, Use StatefulWidget Only When Needed
Example:

// Stateless for pure presentation
class TaskCard extends StatelessWidget {
  final TaskModel task;
  const TaskCard({super.key, required this.task});
}

// Stateful for local UI state (animations, controllers, focus)
class _HomePageState extends State<HomePage> {
  DateTime _previousDate = DateTime.now();
  bool _slidingForward = true;
}
Intent: Minimize mutable state; use StatefulWidget only for local UI concerns.

Rule: Decompose into Small, Focused Widgets
Example:

// Main page delegates to smaller widgets
class HomePage extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          DateHeader(...),
          WeekStrip(...),
          Expanded(child: CustomScrollView(...)),
        ],
      ),
    );
  }
}

// Small, reusable widgets
class DateHeader extends StatelessWidget {}
class WeekStrip extends StatelessWidget {}
class TaskCard extends StatelessWidget {}
Intent: Improve readability, reusability, and performance (granular rebuilds).

Rule: Widget Parameters Are Named and Required When Critical
Example:

class TaskCard extends StatelessWidget {
  final TaskModel task;                    // required
  final TemporalState temporalState;       // required
  final bool showDateBadge;                // optional with default
  final VoidCallback? onTap;               // optional nullable
  final VoidCallback? onEdit;              // optional nullable

  const TaskCard({
    super.key,
    required this.task,
    required this.temporalState,
    this.showDateBadge = false,
    this.onTap,
    this.onEdit,
  });
}
Intent: Required for essential data, optional with defaults or nullable for flexibility.

Rule: Conditional Rendering Uses if/Ternary in Widget Trees
Example:

Column(
  children: [
    if (task.subtitle != null && task.subtitle!.isNotEmpty) ...[
      SizedBox(height: 4.h),
      Text(task.subtitle!),
    ],
    if (showDateBadge || task.scheduledTime != null) ...[
      SizedBox(width: 8.w),
      _buildMetaBadge(context),
    ],
  ],
)

// Ternary for simple cases
child: task.isDone ? Icon(Icons.check) : null,
Intent: Declarative conditional rendering within widget trees.

Rule: Extract Builder Methods for Complex Subtrees
Example:

Widget _buildGlowOverlay(BuildContext context, Color accent) {
  return Positioned(
    top: -screenH * 0.07,
    child: Container(/* ... */),
  );
}

Widget _buildFab(BuildContext context, Color accent) {
  return Container(
    decoration: BoxDecoration(/* ... */),
    child: FloatingActionButton(/* ... */),
  );
}
Intent: Keep build() readable; extract complex subtrees to private methods.

Rule: Use const Constructors Eagerly
Example:

const SizedBox(height: 8.h)  // ❌ Not const (uses .h extension)
SizedBox(height: 8.h)         // ✓ Correct

const Icon(Icons.check, size: 14)  // ✓ Const where possible
const Padding(padding: EdgeInsets.all(16))  // ✓ Const
Intent: Performance optimization - const widgets are not rebuilt.

5. STYLING & THEME SYSTEM
Rule: Centralized Theme in AppThemeData
Example:

class AppThemeData {
  static ThemeData getAppThemeData({
    required LocaleLanguage language,
    required BuildContext context,
  }) {
    return ThemeData(
      textTheme: TextStylesManager.getAppTextTheme(isArabic: isArabic),
      scaffoldBackgroundColor: dynamicBgColor,
      colorScheme: ColorScheme.fromSwatch(...),
    );
  }
}
Intent: Single source of truth for app-wide theme configuration.

Rule: Colors Referenced via AppColors Static Constants
Example:

class AppColors {
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkCardBg = Color(0xFF141414);
  static const Color accentGreen = Color(0xFF1EE468);
}

// Usage
Container(color: AppColors.darkBackground)
Text(style: TextStyle(color: AppColors.accentGreen))
Intent: Centralized color palette prevents magic values and ensures consistency.

Rule: Text Styles via AppTextStyles Context-Aware Methods
Example:

class AppTextStyles {
  final BuildContext context;
  late final bool isArabic;
  
  AppTextStyles(this.context) {
    isArabic = Localizations.localeOf(context).languageCode == 'ar';
  }
  
  TextStyle px14wBold() => _getStyle(14, FontWeight.w700);
  TextStyle px16wSemiBold() => _getStyle(16, FontWeight.w600);
}

// Usage
Text('Hello', style: AppTextStyles(context).px14wBold())
Intent: Context-aware text styles that adapt to language (Arabic vs English fonts).

Rule: Text Style Extensions for Color Variants
Example:

extension CustomTextStyles on TextStyle {
  TextStyle get toWhiteColor => copyWith(color: AppColors.whiteColor);
  TextStyle get toBlackColor => copyWith(color: AppColors.blackColor);
  TextStyle get toPrimaryBlueColor => copyWith(color: AppColors.primaryBlueColor);
}

// Usage
AppTextStyles(context).px14wBold().toWhiteColor
Intent: Fluent API for composing text styles with color variants.

Rule: Spacing Uses flutter_screenutil (.w, .h, .r, .sp)
Example:

SizedBox(height: 8.h)
Padding(padding: EdgeInsets.symmetric(horizontal: 20.w))
BorderRadius.circular(16.r)
Icon(Icons.check, size: 14.sp)
Intent: Responsive sizing that scales with screen dimensions (design size: 375x831).

Rule: Design System Uses 4px/8px Grid
Example:

SizedBox(height: 4.h)
SizedBox(height: 8.h)
SizedBox(height: 12.h)
SizedBox(height: 16.h)
SizedBox(height: 20.h)
Padding(padding: EdgeInsets.all(16.w))
Intent: Consistent spacing rhythm based on 4px increments.

Rule: Border Radius Centralized in GeneralUtils
Example:

class GeneralUtils {
  static BorderRadius defaultBorderRadius({double? radius}) {
    return BorderRadius.all(
      Radius.circular(radius ?? UIConstants.defaultBorderRadius)
    );
  }
  
  static BorderRadius borderRadius15() {
    return const BorderRadius.all(Radius.circular(15));
  }
}

// Usage
decoration: BoxDecoration(borderRadius: GeneralUtils.defaultBorderRadius())
Intent: Reusable border radius patterns for consistency.

Rule: Typography Scale: px10 to px44_75 with Weight Variants
Example:

// Available sizes: 10, 11, 12, 13, 14, 14.7, 15, 16, 17, 18, 19, 20, 22, 24, 28, 32, 44.75
// Weights: wRegular (400), wMedium (500), wSemiBold (600), wBold (700)

AppTextStyles(context).px10wRegular()
AppTextStyles(context).px14wBold()
AppTextStyles(context).px28wSemiBold()
Intent: Predefined typography scale ensures consistent text sizing across the app.

6. NAVIGATION PATTERNS
Rule: Use AutoRoute for Navigation
Example:

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  final List<AutoRoute> routes = [
    CustomRoute(
      path: '/',
      page: SplashRoute.page,
      transitionsBuilder: TransitionsBuilders.fadeIn,
      durationInMilliseconds: 300,
    ),
    CustomRoute(page: HomeRoute.page, transitionsBuilder: TransitionsBuilders.fadeIn),
  ];
}
Intent: Type-safe, declarative routing with custom transitions.

Rule: Routes Defined with @RoutePage Annotation
Example:

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});
}
Intent: Code generation for type-safe route navigation.

Rule: Navigation via Router Push/Pop
Example:

// Push route
getIt<AppRouter>().push(AlarmRoute(taskId: taskId));

// Pop
Navigator.pop(context);
Intent: Centralized router instance via dependency injection.

Rule: Data Passed via Route Constructors
Example:

@RoutePage()
class AlarmPage extends StatefulWidget {
  final String taskId;
  const AlarmPage({super.key, required this.taskId});
}

// Navigate with data
getIt<AppRouter>().push(AlarmRoute(taskId: task.id));
Intent: Type-safe parameter passing through route constructors.

Rule: Custom Transitions for Locale-Aware Direction
Example:


static Widget localisedLateralTransition(context, animation, secondaryAnimation, child) {
  final isRTL = Localizations.localeOf(context).languageCode == LocaleLanguage.ar.name;
  final transitionBuilder = isRTL ? TransitionsBuilders.slideRight : TransitionsBuilders.slideLeft;
  return transitionBuilder(context, animation, secondaryAnimation, child);
}
Intent: RTL-aware transitions for Arabic language support.
## 7. NAVIGATION PATTERNS

**Rule:** Use AutoRoute for declarative routing with code generation  
**Example:**
```dart
@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();
  @override
  final List<AutoRoute> routes = [
    CustomRoute(
      path: '/',
      page: SplashRoute.page,
      transitionsBuilder: TransitionsBuilders.fadeIn,
      durationInMilliseconds: 300,
    ),
  ];
}
Intent: Centralized, type-safe routing with automatic route generation

Rule: Use CustomRoute with transition builders for animated page transitions
Example:

CustomRoute(
  page: HomeRoute.page,
  transitionsBuilder: TransitionsBuilders.fadeIn,
  durationInMilliseconds: 300,
)
Intent: Consistent, smooth transitions between screens

Rule: Use @RoutePage() annotation on page widgets
Example:

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});
}
Intent: Mark pages for AutoRoute code generation

Rule: Access router via dependency injection with getIt<AppRouter>()
Example:

getIt<AppRouter>().push(AlarmRoute(taskId: taskId));
Intent: Centralized router instance management

Rule: Pass data through route constructors, not query parameters
Example:

getIt<AppRouter>().push(AlarmRoute(taskId: taskId));
Intent: Type-safe data passing between screens

Rule: Use RTL-aware transitions based on locale
Example:

static Widget localisedLateralTransition(context, animation, secondaryAnimation, child) {
  final isRTL = Localizations.localeOf(context).languageCode == LocaleLanguage.ar.name;
  final transitionBuilder = isRTL ? TransitionsBuilders.slideRight : TransitionsBuilders.slideLeft;
  return transitionBuilder(context, animation, secondaryAnimation, child);
}
Intent: Proper directional navigation for Arabic/RTL languages

8. DATA LAYER PATTERNS
Rule: Use Repository pattern with abstract interfaces
Example:

abstract class ITasksRepository {
  Either<Failure, List<TaskModel>> getTasks();
  Future<Either<Failure, Unit>> saveTasks(List<TaskModel> tasks);
}

@Singleton(as: ITasksRepository)
class TasksRepositoryImpl implements ITasksRepository {
  final ITasksLocalDataSource _localDataSource;
  TasksRepositoryImpl(this._localDataSource);
}
Intent: Abstraction layer for testability and flexibility

Rule: Use DataSource pattern for data access (local/remote)
Example:

abstract class ITasksLocalDataSource {
  Either<Failure, List<TaskModel>> getTasks();
  Future<Either<Failure, Unit>> saveTasks(List<TaskModel> tasks);
}

@Singleton(as: ITasksLocalDataSource)
class TasksLocalDataSourceImpl implements ITasksLocalDataSource {
  final MainHiveStorageService _storage;
  TasksLocalDataSourceImpl(this._storage);
}
Intent: Separation of data sources (local storage, API, etc.)

Rule: Use Freezed for immutable data models with JSON serialization
Example:

@freezed
class TaskModel with _$TaskModel {
  const factory TaskModel({
    required String id,
    required String title,
    @Default(false) bool isDone,
    required DateTime createdAt,
    String? subtitle,
    String? scheduledTime,
  }) = _TaskModel;

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);
}
Intent: Type-safe, immutable models with automatic copyWith, equality, and JSON serialization

Rule: Use Dartz Either<Failure, T> for error handling
Example:

Either<Failure, List<TaskModel>> getTasks() {
  try {
    final tasks = _storage.get(StorageConstants.tasksKey);
    return Right(tasks);
  } catch (e) {
    return const Left(Failure.cacheReadFailure());
  }
}
Intent: Functional error handling without exceptions

Rule: Use Freezed for sealed Failure types
Example:

@freezed
class Failure<T> with _$Failure<T> {
  const factory Failure.platformFailure({String? message}) = PlatformFailure;
  const factory Failure.networkFailure({String? message}) = NetworkFailure;
  const factory Failure.cacheReadFailure() = CacheReadFailure;
  const factory Failure.cacheWriteFailure() = CacheWriteFailure;
}
Intent: Type-safe, exhaustive error handling

Rule: Store JSON as encoded strings in Hive
Example:

Future<Either<Failure, Unit>> saveTasks(List<TaskModel> tasks) async {
  try {
    final encoded = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await _storage.set(StorageConstants.tasksKey, encoded);
    return const Right(unit);
  } catch (e) {
    return const Left(Failure.cacheWriteFailure());
  }
}
Intent: Simple serialization strategy for Hive storage

Rule: Use extension methods to convert Failures to user messages
Example:

extension FailureMessage on Failure {
  String getMessage() {
    return map(
      cacheReadFailure: (_) => t.errors.failures.cacheReadFailure,
      networkFailure: (f) => f.message ?? t.errors.failures.unexpectedError,
    );
  }
}
Intent: Centralized, localized error messages

9. DEPENDENCY INJECTION
Rule: Use Injectable with GetIt for dependency injection
Example:

final getIt = GetIt.instance;

@injectableInit
Future<void> configureDependencies() async => await getIt.init();
Intent: Automatic dependency registration with code generation

Rule: Use @injectable for automatic registration
Example:

@injectable
class TasksCubit extends Cubit<TasksState> {
  final GetTasks _getTasks;
  final SaveTasks _saveTasks;
  TasksCubit(this._getTasks, this._saveTasks) : super(TasksState());
}
Intent: Automatic dependency graph construction

Rule: Use @singleton for single-instance services
Example:

@singleton
class GetTasks extends UnawaitedUsecase<List<TaskModel>, NoParams> {
  final ITasksRepository _repository;
  GetTasks(this._repository);
}
Intent: Shared service instances across the app

Rule: Use @Singleton(as: Interface) for interface binding
Example:

@Singleton(as: ITasksRepository)
class TasksRepositoryImpl implements ITasksRepository {
  // implementation
}
Intent: Program to interfaces, not implementations

Rule: Use @module for external library registration
Example:

@module
abstract class ExternalLibraryInjectableModule {
  @lazySingleton
  ReorderToFrontPageStack get bottomNavPageStack =>
      ReorderToFrontPageStack(initialPage: 0);

  @preResolve
  @lazySingleton
  Future<MainHiveStorageService> get openBox async {
    await Hive.initFlutter();
    final service = MainHiveStorageService();
    await service.init();
    return service;
  }
}
Intent: Register third-party dependencies and async initialization

Rule: Call configureDependencies() in main before runApp
Example:

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await configureDependencies();
      runApp(const DayFlowAppProvided());
    },
    (e, stackTrace) {
      debugPrint("[Error] Top level main error: $e");
    },
  );
}
Intent: Initialize DI container before app starts

10. ASYNC & ERROR HANDLING
Rule: Use async/await, not .then() chaining
Example:

Future<void> addTask(String title) async {
  final result = await _saveTasks(updatedTasks);
  result.fold(
    (failure) => emit(state.copyWith(status: CubitStatus.failure)),
    (_) => emit(state.copyWith(tasks: updatedTasks)),
  );
}
Intent: Cleaner, more readable asynchronous code

Rule: Use runZonedGuarded for top-level error handling
Example:

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      // app initialization
      runApp(const DayFlowAppProvided());
    },
    (e, stackTrace) {
      debugPrint("[Error] Top level main error: $e");
      throw e;
    },
  );
}
Intent: Catch uncaught errors at the app level

Rule: Use unawaited() for fire-and-forget operations
Example:

unawaited(SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]));
unawaited(WidgetDataSync.sync());
Intent: Explicitly mark intentionally unawaited futures

Rule: Use CubitStatus with action enums for loading states
Example:

emit(state.copyWith(
  status: const CubitStatus(
    statusType: CubitStatusType.loading,
    action: CubitAction.addTask,
  ),
));
Intent: Track which operation is in progress

Rule: Use BlocConsumer for both listening and building
Example:

BlocConsumer<TasksCubit, TasksState>(
  listenWhen: (prev, curr) => prev.currentDate != curr.currentDate,
  listener: (context, state) {
    _slidingForward = state.currentDate.isAfter(_previousDate);
  },
  builder: (context, state) {
    return Scaffold(/* ... */);
  },
)
Intent: Separate side effects from UI building

Rule: Handle errors by emitting failure states, not throwing
Example:

result.fold(
  (failure) => emit(state.copyWith(
    status: CubitStatus(
      statusType: CubitStatusType.failure,
      action: CubitAction.loadTasks,
      errorMsg: failure.getMessage(),
    ),
  )),
  (tasks) => emit(state.copyWith(tasks: tasks)),
);
Intent: Errors are data, not exceptions

11. CODE STYLE & FORMATTING
Rule: Use trailing commas consistently for better formatting
Example:

const TaskModel({
  required String id,
  required String title,
  @Default(false) bool isDone,
  required DateTime createdAt,
  String? subtitle,
});
Intent: Better auto-formatting and git diffs

Rule: Use const constructors eagerly
Example:

const SizedBox(height: 8.h)
const CubitStatus()
const Right([])
Intent: Performance optimization through compile-time constants

Rule: Prefer final over var for immutability
Example:

final _titleController = TextEditingController();
final updatedTasks = [task, ...state.tasks];
Intent: Immutability by default

Rule: Use private members with _ prefix
Example:

final GetTasks _getTasks;
final SaveTasks _saveTasks;
void _scheduleForTask(TaskModel task) { }
Intent: Encapsulation and clear API boundaries

Rule: Use flutter_lints for code analysis
Example: analysis_options.yaml

include: package:flutter_lints/flutter.yaml
Intent: Consistent code quality standards

Rule: Use descriptive variable names, avoid abbreviations
Example:

final filteredTasks = state.filteredTasks;  // Good
final overdueTasks = state.overdueTasks;   // Good
// Not: final ft = state.filteredTasks;
Intent: Code readability and maintainability

Rule: Group imports: Flutter, packages, project
Example:

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:dayflow/core/usecases/tasks/get_tasks.dart';
import 'package:dayflow/presentation/common/theme/app_colors.dart';
Intent: Organized, scannable imports

12. COMPONENT-LEVEL PATTERNS
Rule: Use showModalBottomSheet with transparent background for custom sheets
Example:

static void show(BuildContext context, {TaskModel? initialTask}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<TasksCubit>(),
      child: AddTaskSheet(initialTask: initialTask),
    ),
  );
}
Intent: Custom-styled bottom sheets with backdrop blur

Rule: Use BackdropFilter for glassmorphism effects
Example:

ClipRRect(
  borderRadius: BorderRadius.circular(32.r),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
    child: Container(/* ... */),
  ),
)
Intent: Modern, polished UI with blur effects

Rule: Use Dismissible for swipe-to-delete/edit
Example:

Dismissible(
  key: Key(task.id),
  direction: canEdit ? DismissDirection.horizontal : DismissDirection.endToStart,
  confirmDismiss: (direction) async {
    if (direction == DismissDirection.startToEnd) {
      onEdit?.call();
      return false;
    }
    return true;
  },
  onDismissed: (_) => context.read<TasksCubit>().deleteTask(task.id),
  child: /* ... */,
)
Intent: Intuitive swipe gestures for actions

Rule: Use SliverPersistentHeader for collapsing headers
Example:

SliverPersistentHeader(
  pinned: true,
  delegate: _HomeSummaryHeaderDelegate(
    screenHeight: MediaQuery.of(context).size.height,
    accent: accent,
  ),
)
Intent: Dynamic, scrollable headers with animations

Rule: Use AnimatedSwitcher for content transitions
Example:

AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  switchInCurve: Curves.easeOut,
  switchOutCurve: Curves.easeIn,
  transitionBuilder: (child, animation) {
    return SlideTransition(
      position: offset.animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    );
  },
  child: GreetingCard(key: ValueKey(selectedDate)),
)
Intent: Smooth transitions when content changes

Rule: Use flutter_animate for staggered list animations
Example:

TaskCard(task: task)
  .animate()
  .fadeIn(delay: Duration(milliseconds: 45 * index), duration: 280.ms)
  .slideY(begin: 0.08, delay: Duration(milliseconds: 45 * index), duration: 280.ms)
Intent: Polished, staggered entrance animations

Rule: Use CustomScrollView with Slivers for complex scrolling
Example:

CustomScrollView(
  physics: const BouncingScrollPhysics(),
  slivers: [
    SliverPersistentHeader(/* ... */),
    SliverList(/* ... */),
    SliverToBoxAdapter(child: SizedBox(height: 100.h)),
  ],
)
Intent: Advanced scrolling layouts with mixed content

Rule: Use DateFormat from intl for date formatting
Example:

DateFormat('EEE, MMM d').format(date)
DateFormat.jm().format(time)
Intent: Localized, consistent date/time formatting

QUICK REFERENCE CARD
Essential Rules to Memorize
Project Structure:

lib/core/ → Domain logic, usecases, failures
lib/infrastructure/ → Data layer, models, repositories
lib/presentation/ → UI layer, pages, widgets, cubits
Naming:

Files: snake_case.dart (e.g., task_card.dart)
Classes: PascalCase with suffixes (e.g., TasksCubit, TaskModel, HomePage)
Variables: camelCase, booleans with is/has prefix
Private: _prefixWithUnderscore
Constants: camelCase in class (e.g., AppColors.darkBackground)
State Management:

Use Bloc/Cubit with Freezed states
Pattern: emit(state.copyWith(...))
Access: context.read<Cubit>() for actions, BlocBuilder/BlocConsumer for UI
Styling:

Responsive: Use .w, .h, .sp, .r from ScreenUtil
Colors: AppColors.constantName
Text: AppTextStyles(context).px14wBold()
Spacing: Explicit SizedBox(height: 8.h)
Data Layer:

Pattern: UseCase → Repository → DataSource → Storage
Errors: Either<Failure, T> with Dartz
Models: Freezed with @freezed and JSON serialization
DI:

Use @injectable, @singleton annotations
Access: getIt<Type>()
Initialize in main() before runApp()
Navigation:

AutoRoute with @RoutePage() annotation
Navigate: getIt<AppRouter>().push(Route())
Key Patterns:

Always use const when possible
Prefer final over var
Use trailing commas
Async with async/await, not .then()
Private by default, public when needed
STYLE GUIDE SUMMARY
DO:
✅ Use Freezed for models and states
✅ Use ScreenUtil for responsive sizing
✅ Use context extensions for common operations
✅ Use Dartz Either for error handling
✅ Use Injectable for dependency injection
✅ Use const constructors eagerly
✅ Use trailing commas
✅ Use private members by default
✅ Use descriptive variable names
✅ Use flutter_animate for animations

DON'T:
❌ Don't use setState in complex state management
❌ Don't hardcode sizes without ScreenUtil
❌ Don't throw exceptions in data layer
❌ Don't use .then() for async operations
❌ Don't access Theme.of(context) directly (use AppColors/AppTextStyles)
❌ Don't create widgets without const when possible
❌ Don't use abbreviations in variable names
❌ Don't mix business logic in UI widgets

Document Version: 1.0
Last Updated: Based on DayFlow codebase analysis
App Name: DayFlow (Task Management App)
# DayFlow Architecture Documentation

## Overview

DayFlow is a mobile-first Flutter planner application for managing daily tasks with a calm, focused interface. The app follows clean architecture principles with clear separation between presentation, domain, and data layers.

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Screens   │  │   Widgets   │  │       Cubits        │  │
│  │   (Pages)   │  │             │  │  (State Management) │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Use Cases  │  │  Entities   │  │   Repository        │  │
│  │             │  │  (Models)   │  │   Interfaces        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       DATA LAYER                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Repositories│  │Data Sources │  │      Models         │  │
│  │    Impl     │  │ Local/Remote│  │   (JSON/Freezed)    │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── injection.dart               # Dependency injection setup
├── dayflow_app.dart            # App widget configuration
│
├── core/                        # Domain layer
│   ├── erros/                   # Failure types
│   ├── services/                # App services (notifications)
│   ├── storage/                 # Storage abstractions
│   └── usecases/                # Business logic use cases
│       ├── common/              # Language, locale use cases
│       ├── tasks/               # Task CRUD use cases
│       └── weather/             # Weather fetch use case
│
├── infrastructure/              # Data layer
│   ├── constants/               # Storage keys, API constants
│   ├── datasources/             # Local and remote data sources
│   │   ├── local_datasources/   # Hive-based task storage
│   │   └── remote_datasources/  # Open-Meteo weather API
│   ├── models/                  # Data models
│   │   ├── tasks/               # TaskModel
│   │   ├── weather/             # WeatherModel
│   │   └── general/             # CubitStatus, etc.
│   └── repositories/            # Repository implementations
│
├── presentation/                # Presentation layer
│   ├── common/                  # Shared UI components
│   │   ├── cubit/               # Language, navigation cubits
│   │   ├── routes/              # Auto-route configuration
│   │   ├── theme/               # App colors, text styles
│   │   └── widgets/             # Reusable widgets
│   └── features/                # Feature-based modules
│       ├── home/                # Home page & task management
│       ├── alarm/               # Alarm screen
│       └── splash_page/         # Splash screen
│
├── services/                    # App-specific services
│   └── widget_data_sync.dart    # Home widget data sync
│
└── i18n/                        # Localization
    └── strings.g.dart           # Generated translations
```

## Key Architectural Patterns

### 1. Repository Pattern

Abstract interfaces separate business logic from data access:

```dart
abstract class ITasksRepository {
  Either<Failure, List<TaskModel>> getTasks();
  Future<Either<Failure, Unit>> saveTasks(List<TaskModel> tasks);
}

@Singleton(as: ITasksRepository)
class TasksRepositoryImpl implements ITasksRepository {
  final ITasksLocalDataSource _localDataSource;
  // Implementation delegates to data source
}
```

### 2. Use Case Pattern

Single-responsibility business logic operations:

```dart
class GetTasks extends UseCase<List<TaskModel>, NoParams> {
  final ITasksRepository repository;

  @override
  Either<Failure, List<TaskModel>> call(NoParams params) {
    return repository.getTasks();
  }
}
```

### 3. BLoC/Cubit State Management

Reactive state management with clear state transitions:

```dart
@injectable
class TasksCubit extends Cubit<TasksState> {
  final GetTasks _getTasks;
  final SaveTasks _saveTasks;
  final NotificationService _notificationService;

  void loadTasks() {
    emit(state.copyWith(status: CubitStatus.loading()));
    final result = _getTasks(NoParams());
    // Handle success/failure
  }
}
```

### 4. Dependency Injection

Service locator pattern with `get_it` and `injectable`:

```dart
final getIt = GetIt.instance;

@injectableInit
Future<void> configureDependencies() async => await getIt.init();
```

## Data Flow

### Task Creation Flow

```
User Input → AddTaskSheet
     │
     ▼
TasksCubit.addTask()
     │
     ├──► SaveTasks use case
     │         │
     │         ▼
     │    TasksRepository.saveTasks()
     │         │
     │         ▼
     │    TasksLocalDataSource.saveTasks()
     │         │
     │         ▼
     │    Hive Storage (JSON)
     │
     └──► NotificationService.scheduleAlarm/Notification()
              │
              ▼
         OS Notification System
```

### Weather Fetching Flow

```
WeatherCubit.loadWeather()
     │
     ▼
GetWeather use case
     │
     ▼
WeatherRepository.getWeather()
     │
     ├──► Geolocator (device location)
     │
     ├──► Geocoding (city name)
     │
     └──► WeatherRemoteDataSource.fetchWeather()
              │
              ▼
         Open-Meteo API (HTTP)
```

### Alarm Triggering Flow

```
Scheduled Time Reached
     │
     ├─[Foreground]─► Dart Timer fires → alarmStream
     │
     └─[Background/Killed]─► OS Notification fires
              │
              ▼
         AppLifecycleObserver detects resume
              │
              ▼
         syncAndroidAlarmActionsAndWidget()
              │
              ▼
         Navigate to AlarmPage
              │
              ▼
         User Action (Done/Snooze/Dismiss)
```

## State Management Details

### TasksState

```dart
@freezed
class TasksState with _$TasksState {
  const factory TasksState({
    required DateTime selectedDate,
    @Default([]) List<TaskModel> tasks,
    required CubitStatus status,
  }) = _TasksState;

  // Computed properties
  DateTime get currentDate;
  TemporalState get temporalState;
  List<TaskModel> get filteredTasks;
  List<TaskModel> get overdueTasks;
  List<TaskModel> get upcomingTasks;
  double get completionRatio;
}
```

### Temporal States

The app changes behavior based on temporal context:

| State    | Description   | UI Behavior                                    |
| -------- | ------------- | ---------------------------------------------- |
| `today`  | Current day   | Interactive checklist with completion tracking |
| `past`   | Previous days | Completed vs missed history view               |
| `future` | Upcoming days | Planned items preview                          |

### CubitStatus Pattern

Standardized status tracking across all cubits:

```dart
@freezed
class CubitStatus with _$CubitStatus {
  const factory CubitStatus({
    required CubitStatusType statusType,
    CubitAction? action,
    String? errorMsg,
  }) = _CubitStatus;
}

enum CubitStatusType { initial, loading, success, failure }
enum CubitAction { loadTasks, addTask, updateTask, toggleTask, deleteTask }
```

## Error Handling

### Failure Types

```dart
@freezed
class Failure<T> with _$Failure<T> {
  const factory Failure.platformFailure({String? message}) = PlatformFailure;
  const factory Failure.networkFailure({String? message}) = NetworkFailure;
  const factory Failure.cacheReadFailure() = CacheReadFailure;
  const factory Failure.cacheWriteFailure() = CacheWriteFailure;
  // ... more failure types
}
```

### Either Pattern

Uses `dartz` package for functional error handling:

```dart
Either<Failure, List<TaskModel>> getTasks();

// Usage:
result.fold(
  (failure) => handleFailure(failure),
  (tasks) => handleSuccess(tasks),
);
```

## Navigation

### Auto-Route Configuration

Type-safe declarative routing:

```dart
@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  final List<AutoRoute> routes = [
    CustomRoute(path: '/', page: SplashRoute.page),
    CustomRoute(page: HomeRoute.page),
    CustomRoute(page: AlarmRoute.page),
  ];
}
```

### Route Transitions

- Default: Fade-in (300ms)
- RTL-aware: Slide transitions for Arabic locale

## Localization

### Slang Package Integration

Type-safe i18n with compile-time checking:

```dart
// Usage in code:
Text(t.home.no_tasks)
Text(t.home.upcoming_label)

// Supported locales:
// - English (en)
// - Arabic (ar) with RTL support
```

### Language Management

```dart
@injectable
class LanguageCubit extends Cubit<LocaleLanguage> {
  final GetLanguageLocale _getLanguageLocale;
  final CacheLanguageLocale _cacheLanguageLocale;

  void toggleLanguage() {
    // Toggle between en/ar
    // Persist to local storage
    // Update LocaleSettings
  }
}
```

## Storage

### Hive Local Database

```dart
class MainHiveStorageService implements StorageService {
  late Box hiveBox;

  Future<void> init() async {
    hiveBox = await Hive.openBox<dynamic>('dayflow_box');
  }

  dynamic get(String key) => hiveBox.get(key);
  Future<void> set(String? key, dynamic data) => hiveBox.put(key, data);
}
```

### Data Persistence

- Tasks: JSON-serialized list stored in Hive
- Language preference: Cached in Hive
- Weather: Fetched fresh on app launch (not persisted)

## Notifications & Alarms

### Dual-Layer Alarm System

The app implements a sophisticated dual-layer notification system:

**Layer 1: OS Notifications**

- Handled by `flutter_local_notifications`
- Works in background and killed states
- Uses `zonedSchedule` for exact timing

**Layer 2: Dart Timers (iOS)**

- Handled by `alarm` package
- Provides instant foreground experience
- Full-screen alarm UI

**Android Native Alarms**

- MethodChannel to native AlarmManager
- Foreground service for reliability
- Full-screen intent support

### NotificationService API

```dart
@lazySingleton
class NotificationService {
  Future<void> scheduleNotification(TaskModel task);
  Future<void> scheduleAlarm(TaskModel task);
  Future<void> cancelNotification(String taskId);
  Future<bool> syncPendingAndroidAlarmActions(...);
}
```

## Home Widget Integration

### WidgetDataSync Service

Syncs task data to native home screen widgets:

```dart
class WidgetDataSync {
  static Future<void> sync({WeatherModel? weatherOverride}) async {
    // Read tasks from Hive
    // Categorize: today, overdue
    // Compute greeting, date label
    // Push to HomeWidget shared storage
    // Trigger widget redraw
  }
}
```

### Widget Data Keys

- `greeting` - Time-based greeting text
- `date_label` - Formatted date string
- `weather_temp` - Temperature display
- `task_count_today` - Total tasks today
- `tasks_completed_today` - Completed count
- `next_tasks_json` - Next 3 uncompleted tasks
- `overdue_count` - Overdue task count

## Platform-Specific Implementation

### Android

- Native alarm via MethodChannel (`dayflow/native_alarm`)
- AlarmManager + BroadcastReceiver + Foreground Service
- Full-screen intent for alarm display
- Exact alarm permission handling
- Pending alarm action sync on app resume

### iOS

- Uses `alarm` package for full-screen alarms
- Standard push notifications via `flutter_local_notifications`
- Location permission for weather

## Code Generation

The project uses code generation for:

| Package             | Purpose                            |
| ------------------- | ---------------------------------- |
| `freezed`           | Immutable models and state classes |
| `json_serializable` | JSON serialization                 |
| `injectable`        | Dependency injection registration  |
| `auto_route`        | Route generation                   |
| `slang`             | Localization files                 |

### Build Command

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Testing Strategy

### Unit Tests

- Use case business logic
- Repository implementations
- Cubit state transitions
- Model serialization

### Widget Tests

- UI component rendering
- User interaction flows

### Integration Tests

- Full user journeys
- Alarm triggering scenarios

## Performance Considerations

1. **Lazy Loading**: Cubits use `lazy: false` only when needed
2. **Stream Subscriptions**: Properly disposed in `dispose()`
3. **Widget Rebuilds**: `BlocBuilder` with `buildWhen` for optimization
4. **List Rendering**: `SliverList` with `SliverChildBuilderDelegate`
5. **Animations**: Hardware-accelerated via `flutter_animate`

## Security Considerations

1. **Local Storage Only**: No sensitive data transmitted to servers
2. **Location Permission**: Requested only for weather feature
3. **Notification Permission**: Requested on first alarm schedule
4. **No PII**: Tasks contain only user-created content

# DayFlow API Reference

## Cubits

### TasksCubit

Manages task state and operations.

**Location**: `lib/presentation/features/home/cubit/tasks_cubit.dart`

#### Dependencies

```dart
@injectable
class TasksCubit extends Cubit<TasksState> {
  final GetTasks _getTasks;
  final SaveTasks _saveTasks;
  final NotificationService _notificationService;
}
```

#### Methods

| Method                 | Parameters                                                | Description                        |
| ---------------------- | --------------------------------------------------------- | ---------------------------------- |
| `loadTasks()`          | -                                                         | Loads all tasks from local storage |
| `selectDate(DateTime)` | date                                                      | Updates selected date              |
| `addTask(...)`         | title, subtitle?, date?, scheduledTime?, reminderType?    | Creates new task                   |
| `updateTask(...)`      | id, title, subtitle?, date, scheduledTime?, reminderType? | Updates existing task              |
| `toggleTask(String)`   | id                                                        | Toggles completion status          |
| `deleteTask(String)`   | id                                                        | Removes task                       |
| `rescheduleTask(...)`  | id, newTime                                               | Changes task date/time             |

#### Usage

```dart
// In widget
context.read<TasksCubit>().addTask(
  'Buy groceries',
  subtitle: 'Milk, eggs, bread',
  scheduledTime: '18:00',
  reminderType: 'notification',
);

// Listen to state
BlocBuilder<TasksCubit, TasksState>(
  builder: (context, state) {
    if (state.status.statusType == CubitStatusType.loading) {
      return CircularProgressIndicator();
    }
    return TaskList(tasks: state.filteredTasks);
  },
)
```

---

### WeatherCubit

Manages weather data fetching.

**Location**: `lib/presentation/features/home/cubit/weather_cubit.dart`

#### Dependencies

```dart
@injectable
class WeatherCubit extends Cubit<WeatherState> {
  final GetWeather _getWeather;
}
```

#### Methods

| Method          | Parameters | Description                                   |
| --------------- | ---------- | --------------------------------------------- |
| `loadWeather()` | -          | Fetches current weather using device location |

#### Usage

```dart
// Load weather on app start
context.read<WeatherCubit>().loadWeather();

// Display weather
BlocBuilder<WeatherCubit, WeatherState>(
  builder: (context, state) {
    final weather = state.weather;
    if (weather == null) return SizedBox.shrink();
    return Text('${weather.temperature.round()}°');
  },
)
```

---

### LanguageCubit

Manages app language/locale.

**Location**: `lib/presentation/common/cubit/language/language_cubit.dart`

#### Dependencies

```dart
@injectable
class LanguageCubit extends Cubit<LocaleLanguage> {
  final GetLanguageLocale _getLanguageLocale;
  final CacheLanguageLocale _cacheLanguageLocale;
}
```

#### Methods

| Method                    | Parameters | Description                      |
| ------------------------- | ---------- | -------------------------------- |
| `setLanguage()`           | -          | Loads cached language preference |
| `toggleLanguage()`        | -          | Switches between en/ar           |
| `setLang(LocaleLanguage)` | ll         | Sets specific language           |

#### Properties

| Property   | Type | Description                                |
| ---------- | ---- | ------------------------------------------ |
| `isArabic` | bool | Returns true if current language is Arabic |

#### Usage

```dart
// Toggle language
context.read<LanguageCubit>().toggleLanguage();

// Check current language
final isArabic = context.read<LanguageCubit>().isArabic;
```

---

## Services

### NotificationService

Handles all notification and alarm operations.

**Location**: `lib/core/services/notification_service.dart`

#### Methods

| Method                                | Parameters          | Description                             |
| ------------------------------------- | ------------------- | --------------------------------------- |
| `init()`                              | -                   | Initializes notification plugin         |
| `requestPermissions()`                | -                   | Requests notification/alarm permissions |
| `scheduleNotification(TaskModel)`     | task                | Schedules push notification             |
| `scheduleAlarm(TaskModel)`            | task                | Schedules full-screen alarm             |
| `cancelNotification(String)`          | taskId              | Cancels notification/alarm              |
| `cancelAll()`                         | -                   | Cancels all notifications               |
| `syncPendingAndroidAlarmActions(...)` | getTasks, saveTasks | Syncs pending alarm actions             |
| `canUseFullScreenIntent()`            | -                   | Checks Android 14+ permission           |
| `openFullScreenIntentSettings()`      | -                   | Opens system settings                   |

#### Usage

```dart
// Schedule notification
await notificationService.scheduleNotification(task);

// Schedule alarm
await notificationService.scheduleAlarm(task);

// Cancel
await notificationService.cancelNotification(task.id);
```

---

### WidgetDataSync

Syncs data to home screen widgets.

**Location**: `lib/services/widget_data_sync.dart`

#### Methods

| Method   | Parameters       | Description                   |
| -------- | ---------------- | ----------------------------- |
| `sync()` | weatherOverride? | Syncs all task data to widget |

#### Widget Data Keys

| Key                     | Type   | Description                      |
| ----------------------- | ------ | -------------------------------- |
| `greeting`              | String | Time-based greeting              |
| `date_label`            | String | Formatted date                   |
| `weather_temp`          | String | Temperature string (e.g., "22°") |
| `weather_temp_value`    | int    | Numeric temperature              |
| `weather_code`          | int    | WMO weather code                 |
| `task_count_today`      | int    | Total tasks today                |
| `tasks_completed_today` | int    | Completed count                  |
| `next_tasks_json`       | String | JSON of next 3 tasks             |
| `overdue_count`         | int    | Overdue task count               |

#### Usage

```dart
// Sync after task changes
await WidgetDataSync.sync();

// Sync with weather override
await WidgetDataSync.sync(weatherOverride: weather);
```

---

## Repositories

### ITasksRepository

Abstract interface for task data access.

**Location**: `lib/infrastructure/repositories/tasks_repository_impl.dart`

#### Methods

| Method                       | Return Type                        | Description     |
| ---------------------------- | ---------------------------------- | --------------- |
| `getTasks()`                 | `Either<Failure, List<TaskModel>>` | Gets all tasks  |
| `saveTasks(List<TaskModel>)` | `Future<Either<Failure, Unit>>`    | Saves task list |

---

### IWeatherRepository

Abstract interface for weather data.

**Location**: `lib/infrastructure/repositories/weather_repository_impl.dart`

#### Methods

| Method         | Return Type                             | Description             |
| -------------- | --------------------------------------- | ----------------------- |
| `getWeather()` | `Future<Either<Failure, WeatherModel>>` | Fetches current weather |

---

## Use Cases

### GetTasks

Retrieves all tasks from storage.

**Location**: `lib/core/usecases/tasks/get_tasks.dart`

```dart
final result = getTasks(NoParams());
result.fold(
  (failure) => handleFailure(failure),
  (tasks) => handleTasks(tasks),
);
```

---

### SaveTasks

Persists task list to storage.

**Location**: `lib/core/usecases/tasks/save_tasks.dart`

```dart
final result = await saveTasks(updatedTasks);
result.fold(
  (failure) => handleFailure(failure),
  (_) => handleSuccess(),
);
```

---

### GetWeather

Fetches weather from API.

**Location**: `lib/core/usecases/weather/get_weather.dart`

```dart
final result = await getWeather(NoParams());
result.fold(
  (failure) => handleFailure(failure),
  (weather) => handleWeather(weather),
);
```

---

### GetLanguageLocale

Retrieves cached language preference.

**Location**: `lib/core/usecases/common/get_language_locale.dart`

```dart
final result = getLanguageLocale(NoParams());
result.fold(
  (failure) => useDefaultLanguage(),
  (locale) => setLanguage(locale),
);
```

---

### CacheLanguageLocale

Persists language preference.

**Location**: `lib/core/usecases/common/cache_language_locale.dart`

```dart
cacheLanguageLocale(LocaleLanguage.ar);
```

---

## Data Sources

### TasksLocalDataSource

Hive-based task storage.

**Location**: `lib/infrastructure/datasources/local_datasources/tasks_local_data_source.dart`

#### Methods

| Method                       | Return Type                        | Description           |
| ---------------------------- | ---------------------------------- | --------------------- |
| `getTasks()`                 | `Either<Failure, List<TaskModel>>` | Reads tasks from Hive |
| `saveTasks(List<TaskModel>)` | `Future<Either<Failure, Unit>>`    | Writes tasks to Hive  |

---

### WeatherRemoteDataSource

Open-Meteo API client.

**Location**: `lib/infrastructure/datasources/remote_datasources/weather_remote_data_source.dart`

#### Methods

| Method           | Parameters         | Return Type                             | Description              |
| ---------------- | ------------------ | --------------------------------------- | ------------------------ |
| `fetchWeather()` | lat, lon, cityName | `Future<Either<Failure, WeatherModel>>` | Fetches weather from API |

#### API Endpoint

```
GET https://api.open-meteo.com/v1/forecast
  ?latitude={lat}
  &longitude={lon}
  &current_weather=true
```

---

## Storage Service

### MainHiveStorageService

Hive database wrapper.

**Location**: `lib/core/storage/sb_hive_storage_service.dart`

#### Methods

| Method                 | Parameters | Return Type    | Description      |
| ---------------------- | ---------- | -------------- | ---------------- |
| `init()`               | -          | `Future<void>` | Opens Hive box   |
| `get(String)`          | key        | `dynamic`      | Gets value       |
| `set(String, dynamic)` | key, data  | `Future<void>` | Sets value       |
| `remove(String)`       | key        | `Future<void>` | Deletes value    |
| `has(String)`          | key        | `bool`         | Checks existence |
| `getAll()`             | -          | `List`         | Gets all values  |
| `clear()`              | -          | `Future<void>` | Clears box       |
| `close()`              | -          | `Future<void>` | Closes box       |

---

## Router

### AppRouter

Auto-route navigation configuration.

**Location**: `lib/presentation/common/routes/router.dart`

#### Routes

| Route         | Path | Page       | Description            |
| ------------- | ---- | ---------- | ---------------------- |
| `SplashRoute` | `/`  | SplashPage | Initial loading screen |
| `HomeRoute`   | -    | HomePage   | Main task interface    |
| `AlarmRoute`  | -    | AlarmPage  | Full-screen alarm      |

#### Usage

```dart
// Navigate
context.router.push(HomeRoute());
context.router.replace(AlarmRoute(taskId: '123'));

// Get router
final router = getIt<AppRouter>();
```

---

## Localization

### Translation Keys

**Location**: `lib/i18n/strings.g.dart`

#### Home Screen

| Key                      | English               | Arabic                  |
| ------------------------ | --------------------- | ----------------------- |
| `t.home.no_tasks`        | No tasks for today    | لا توجد مهام لليوم      |
| `t.home.no_tasks_past`   | No tasks for this day | لا توجد مهام لهذا اليوم |
| `t.home.no_tasks_future` | No tasks planned      | لا توجد مهام مخططة      |
| `t.home.upcoming_label`  | Upcoming              | القادمة                 |
| `t.home.overdue_label`   | Overdue               | المتأخرة                |
| `t.home.task_word`       | task                  | مهمة                    |
| `t.home.tasks_word`      | tasks                 | مهام                    |

#### Usage

```dart
Text(t.home.no_tasks)
Text(t.home.upcoming_label)
```

---

## Theme

### AppColors

**Location**: `lib/presentation/common/theme/app_colors.dart`

| Color             | Value   | Usage             |
| ----------------- | ------- | ----------------- |
| `darkBackground`  | #0F0F0F | Screen background |
| `darkCardBg`      | #1A1A1A | Card background   |
| `darkTextPrimary` | #FFFFFF | Primary text      |
| `darkTextMuted`   | #888888 | Secondary text    |
| `accentBlue`      | #4A90D9 | Today accent      |
| `accentPurple`    | #9B59B6 | Past accent       |
| `accentOrange`    | #E67E22 | Future accent     |

---

### AppTextStyles

**Location**: `lib/presentation/common/theme/app_text_styles.dart`

```dart
// Usage
Text(
  'Title',
  style: AppTextStyles(context).px18wSemiBold(),
)

// Available styles
px11wBold()
px12wBold()
px15wRegular()
px16wRegular()
px18wSemiBold()
```

---

## Dependency Injection

### GetIt Service Locator

**Location**: `lib/injection.dart`

```dart
// Get registered instances
final tasksCubit = getIt<TasksCubit>();
final notificationService = getIt<NotificationService>();
final router = getIt<AppRouter>();

// Initialize
await configureDependencies();
```

### Registration Types

| Annotation       | Scope          | Description                        |
| ---------------- | -------------- | ---------------------------------- |
| `@injectable`    | Factory        | New instance each time             |
| `@singleton`     | Singleton      | One instance, created eagerly      |
| `@lazySingleton` | Lazy Singleton | One instance, created on first use |

---

## Platform Channels

### Native Alarm Channel

**Channel**: `dayflow/native_alarm`

#### Methods

| Method                      | Parameters                               | Return       |
| --------------------------- | ---------------------------------------- | ------------ |
| `scheduleAlarm`             | taskId, title, subtitle, triggerAtMillis | void         |
| `cancelAlarm`               | taskId                                   | void         |
| `cancelAllAlarms`           | -                                        | void         |
| `getPendingSnoozeActions`   | -                                        | List<Map>    |
| `getPendingDoneActions`     | -                                        | List<String> |
| `clearPendingSnoozeActions` | -                                        | void         |
| `clearPendingDoneActions`   | -                                        | void         |

### Permission Channel

**Channel**: `dayflow/permissions`

#### Methods

| Method                         | Return |
| ------------------------------ | ------ |
| `canUseFullScreenIntent`       | bool   |
| `openFullScreenIntentSettings` | void   |

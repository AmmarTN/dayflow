# DayFlow Data Models

## Core Models

### TaskModel

The primary data model representing a user task.

```dart
@freezed
class TaskModel with _$TaskModel {
  const factory TaskModel({
    required String id,
    required String title,
    @Default(false) bool isDone,
    required DateTime createdAt,
    String? subtitle,
    String? category,
    String? scheduledTime,
    String? reminderType,
  }) = _TaskModel;

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);
}
```

#### Properties

| Property        | Type     | Required | Default | Description                         |
| --------------- | -------- | -------- | ------- | ----------------------------------- |
| `id`            | String   | Yes      | -       | Unique identifier (timestamp-based) |
| `title`         | String   | Yes      | -       | Task name                           |
| `subtitle`      | String?  | No       | null    | Optional notes/description          |
| `isDone`        | bool     | No       | false   | Completion status                   |
| `createdAt`     | DateTime | Yes      | -       | Task date (time portion ignored)    |
| `scheduledTime` | String?  | No       | null    | Time in "HH:mm" 24-hour format      |
| `reminderType`  | String?  | No       | null    | "notification" or "alarm"           |
| `category`      | String?  | No       | null    | Optional categorization             |

#### JSON Example

```json
{
  "id": "1712345678901",
  "title": "Team meeting",
  "subtitle": "Discuss Q2 roadmap",
  "isDone": false,
  "createdAt": "2024-04-05T00:00:00.000",
  "scheduledTime": "14:30",
  "reminderType": "alarm",
  "category": "work"
}
```

#### Usage

```dart
// Creating a task
final task = TaskModel(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  title: 'Review PR',
  subtitle: 'Check the new feature branch',
  createdAt: DateTime.now(),
  scheduledTime: '10:00',
  reminderType: 'notification',
);

// Updating a task
final updated = task.copyWith(
  isDone: true,
  scheduledTime: '11:00',
);

// Serialization
final json = task.toJson();
final restored = TaskModel.fromJson(json);
```

---

### WeatherModel

Data model for weather information.

```dart
@freezed
class WeatherModel with _$WeatherModel {
  const factory WeatherModel({
    required double temperature,
    required int weatherCode,
    required String cityName,
  }) = _WeatherModel;

  factory WeatherModel.fromJson(Map<String, dynamic> json) =>
      _$WeatherModelFromJson(json);
}
```

#### Properties

| Property      | Type   | Required | Description            |
| ------------- | ------ | -------- | ---------------------- |
| `temperature` | double | Yes      | Temperature in Celsius |
| `weatherCode` | int    | Yes      | WMO weather code       |
| `cityName`    | String | Yes      | City/locality name     |

#### WMO Weather Codes

Common weather codes from Open-Meteo:

| Code   | Description              |
| ------ | ------------------------ |
| 0      | Clear sky                |
| 1-3    | Mainly clear to overcast |
| 45, 48 | Fog                      |
| 51-57  | Drizzle                  |
| 61-67  | Rain                     |
| 71-77  | Snow                     |
| 80-82  | Rain showers             |
| 95-99  | Thunderstorm             |

#### JSON Example

```json
{
  "temperature": 22.5,
  "weatherCode": 1,
  "cityName": "San Francisco"
}
```

---

## State Models

### TasksState

State container for task management.

```dart
@freezed
class TasksState with _$TasksState {
  const TasksState._();

  const factory TasksState({
    required DateTime selectedDate,
    @Default([]) List<TaskModel> tasks,
    required CubitStatus status,
  }) = _TasksState;
}
```

#### Properties

| Property       | Type            | Description                           |
| -------------- | --------------- | ------------------------------------- |
| `selectedDate` | DateTime        | Currently selected date in week strip |
| `tasks`        | List<TaskModel> | All tasks from storage                |
| `status`       | CubitStatus     | Current operation status              |

#### Computed Properties

```dart
// Current date (normalized to midnight)
DateTime get currentDate => DateTime(
  selectedDate.year,
  selectedDate.month,
  selectedDate.day,
);

// Temporal state based on selected date
TemporalState get temporalState {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  if (currentDate.isAtSameMomentAs(today)) return TemporalState.today;
  if (currentDate.isBefore(today)) return TemporalState.past;
  return TemporalState.future;
}

// Tasks filtered by selected date
List<TaskModel> get filteredTasks => tasks
  .where((t) => _dateOnly(t.createdAt) == currentDate)
  .toList();

// Overdue tasks (past, uncompleted)
List<TaskModel> get overdueTasks => tasks
  .where((t) => !t.isDone && _dateOnly(t.createdAt).isBefore(today))
  .toList();

// Upcoming tasks (future)
List<TaskModel> get upcomingTasks => tasks
  .where((t) => _dateOnly(t.createdAt).isAfter(today))
  .toList();

// Completion statistics
int get completedCount => filteredTasks.where((t) => t.isDone).length;
int get pendingCount => filteredTasks.where((t) => !t.isDone).length;
double get completionRatio =>
  filteredTasks.isEmpty ? 0 : completedCount / filteredTasks.length;
```

---

### WeatherState

State container for weather data.

```dart
@freezed
class WeatherState with _$WeatherState {
  const factory WeatherState({
    WeatherModel? weather,
    @Default(CubitStatus.initial()) CubitStatus status,
  }) = _WeatherState;
}
```

#### Properties

| Property  | Type          | Description                                |
| --------- | ------------- | ------------------------------------------ |
| `weather` | WeatherModel? | Current weather data (null if unavailable) |
| `status`  | CubitStatus   | Loading/success/failure status             |

---

### CubitStatus

Generic status tracking for all cubits.

```dart
@freezed
class CubitStatus with _$CubitStatus {
  const factory CubitStatus({
    required CubitStatusType statusType,
    CubitAction? action,
    String? errorMsg,
  }) = _CubitStatus;
}
```

#### Status Types

```dart
enum CubitStatusType {
  initial,   // Initial state, no operation
  loading,   // Operation in progress
  success,   // Operation completed successfully
  failure,   // Operation failed
}
```

#### Actions

```dart
enum CubitAction {
  loadTasks,
  addTask,
  updateTask,
  toggleTask,
  deleteTask,
}
```

#### Usage

```dart
// Check status
if (state.status.statusType == CubitStatusType.loading) {
  // Show loading indicator
}

// Check specific action
if (state.status.action == CubitAction.addTask) {
  // Handle add task result
}

// Get error message
if (state.status.statusType == CubitStatusType.failure) {
  final error = state.status.errorMsg;
}
```

---

## Enumerations

### TemporalState

Represents the temporal context of the selected date.

```dart
enum TemporalState {
  today,  // Current day
  past,   // Previous days
  future, // Upcoming days
}
```

#### Usage

```dart
// Get accent color
Color get accent {
  switch (temporalState) {
    case TemporalState.today: return AppColors.accentBlue;
    case TemporalState.past: return AppColors.accentPurple;
    case TemporalState.future: return AppColors.accentOrange;
  }
}
```

---

### LocaleLanguage

Supported app languages.

```dart
enum LocaleLanguage {
  ar,  // Arabic
  en,  // English
}
```

---

## Failure Types

Error handling model using freezed union types.

```dart
@freezed
class Failure<T> with _$Failure<T> {
  const factory Failure.platformFailure({String? message}) = PlatformFailure;
  const factory Failure.formatExceptionFailure() = FormatExceptionFailure;
  const factory Failure.unableToProcess(dynamic error) = UnableToProcess;
  const factory Failure.unexpectedError(dynamic data) = UnexpectedError;
  const factory Failure.cacheReadFailure() = CacheReadFailure;
  const factory Failure.cacheWriteFailure() = CacheWriteFailure;
  const factory Failure.networkFailure({String? message}) = NetworkFailure;
}
```

#### Usage with Either

```dart
// Repository returns Either<Failure, T>
Either<Failure, List<TaskModel>> getTasks();

// Pattern matching
result.fold(
  (failure) {
    switch (failure) {
      case CacheReadFailure():
        // Handle cache error
      case NetworkFailure(:final message):
        // Handle network error
      default:
        // Handle other errors
    }
  },
  (tasks) => handleSuccess(tasks),
);
```

---

## Storage Schema

### Hive Box Structure

```dart
// Box name
static const String dayflowHiveBox = 'dayflow_box';

// Keys
static const String tasksKey = 'tasks';       // JSON string of task list
static const String languageKey = 'language'; // Language code string
```

### Data Format

**Tasks Storage**

```dart
// Key: 'tasks'
// Value: JSON string
'[{"id":"123","title":"Task 1",...},{"id":"456","title":"Task 2",...}]'
```

**Language Storage**

```dart
// Key: 'language'
// Value: Language code
'en' // or 'ar'
```

---

## Model Relationships

```
┌─────────────────┐
│   TaskModel     │
│  (Hive storage) │
└────────┬────────┘
         │
         │ managed by
         ▼
┌─────────────────┐     ┌─────────────────┐
│   TasksState    │────►│  CubitStatus    │
│   (Cubit state) │     │  (status info)  │
└─────────────────┘     └─────────────────┘
         │
         │ displays
         ▼
┌─────────────────┐
│   TaskCard      │
│   (UI widget)   │
└─────────────────┘

┌─────────────────┐
│  WeatherModel   │
│  (API response) │
└────────┬────────┘
         │
         │ managed by
         ▼
┌─────────────────┐     ┌─────────────────┐
│  WeatherState   │────►│  CubitStatus    │
│   (Cubit state) │     │  (status info)  │
└─────────────────┘     └─────────────────┘
         │
         │ displays
         ▼
┌─────────────────┐
│   WeatherRow    │
│   (UI widget)   │
└─────────────────┘
```

---

## Code Generation

All models use code generation via `freezed` and `json_serializable`.

### Required Imports

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_name.freezed.dart';
part 'model_name.g.dart';
```

### Build Command

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Generated Files

- `*.freezed.dart` - Union types, copyWith, equality
- `*.g.dart` - JSON serialization

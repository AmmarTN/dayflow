# DayFlow Features Documentation

## Core Features

### 1. Daily Task Planning

The primary feature of DayFlow is daily task management with a timeline-based interface.

#### Task Properties

| Property        | Type     | Description                         |
| --------------- | -------- | ----------------------------------- |
| `id`            | String   | Unique identifier (timestamp-based) |
| `title`         | String   | Task name (required)                |
| `subtitle`      | String?  | Optional notes/description          |
| `isDone`        | bool     | Completion status                   |
| `createdAt`     | DateTime | Task date                           |
| `scheduledTime` | String?  | Time in "HH:mm" format              |
| `reminderType`  | String?  | "notification" or "alarm"           |
| `category`      | String?  | Optional categorization             |

#### Task Operations

- **Add Task**: Create new tasks with optional time and reminder
- **Edit Task**: Modify all task properties
- **Toggle Complete**: Mark tasks as done/undone
- **Delete Task**: Remove tasks with swipe gesture
- **Reschedule**: Move task to different date/time

### 2. Week Strip Navigation

Horizontal date selector showing the current week.

#### Features

- Visual indication of selected date
- Temporal state coloring (today/past/future)
- Smooth date transitions
- Automatic scroll to current day

#### Implementation

```dart
WeekStrip(
  selectedDate: state.currentDate,
  onDateSelected: (date) => context.read<TasksCubit>().selectDate(date),
  temporalState: temporal,
)
```

### 3. Temporal State System

The app changes behavior based on the selected date's relationship to today.

#### States

| State      | Condition                     | UI Behavior                                                 |
| ---------- | ----------------------------- | ----------------------------------------------------------- |
| **Today**  | Selected date == current date | Interactive checklist, completion progress, weather display |
| **Past**   | Selected date < current date  | Read-only history, completed vs missed indicators           |
| **Future** | Selected date > current date  | Planned items preview, no completion tracking               |

#### Accent Colors

```dart
extension TemporalStateAccent on TemporalState {
  Color get accent {
    switch (this) {
      case TemporalState.today: return AppColors.accentBlue;
      case TemporalState.past: return AppColors.accentPurple;
      case TemporalState.future: return AppColors.accentOrange;
    }
  }
}
```

### 4. Weather Display

Current weather conditions using device location.

#### Data Source

- **API**: Open-Meteo (free, no API key required)
- **Location**: Device GPS (requires permission)
- **Data**: Temperature, weather code, city name

#### Weather Model

```dart
@freezed
class WeatherModel with _$WeatherModel {
  const factory WeatherModel({
    required double temperature,
    required int weatherCode,  // WMO weather code
    required String cityName,
  }) = _WeatherModel;
}
```

#### Error Handling

- Location services disabled → Weather unavailable
- Permission denied → Weather unavailable
- Network error → Graceful degradation

### 5. Alarms & Notifications

Dual reminder system for task alerts.

#### Reminder Types

**Notification**

- Standard push notification
- Works in all app states
- No full-screen UI
- Lower battery impact

**Alarm**

- Full-screen alarm UI
- Sound and vibration
- Works in all app states
- Platform-specific implementation

#### Alarm Actions

| Action        | Behavior                              |
| ------------- | ------------------------------------- |
| **Mark Done** | Completes the task, cancels alarm     |
| **Snooze**    | Reschedules alarm for 5 minutes later |
| **Dismiss**   | Cancels alarm without completing task |

#### Platform Differences

**Android**

- Native AlarmManager implementation
- Foreground service for reliability
- Full-screen intent support
- MethodChannel bridge

**iOS**

- `alarm` package implementation
- System notification + in-app timer
- Background app refresh

### 6. Home Screen Widget

Native widget showing task summary.

#### Widget Data

- Greeting (time-based)
- Current date
- Weather (if available)
- Today's task count
- Completed count
- Next 3 uncompleted tasks
- Overdue count

#### Sync Triggers

- Task added/edited/deleted
- Task completion toggled
- Weather updated
- App resumed from background
- Widget tapped

### 7. Localization

Bilingual support with RTL layout.

#### Supported Languages

- English (en) - LTR
- Arabic (ar) - RTL

#### Implementation

```dart
// Toggle language
LanguageCubit.toggleLanguage()

// Access translations
Text(t.home.no_tasks)
Text(t.home.upcoming_label)
```

#### RTL Support

- Automatic layout direction
- Slide transitions reversed for Arabic
- Text alignment adjusted

## UI Components

### Home Page

Main screen with task list and navigation.

#### Layout

```
┌─────────────────────────────────┐
│  Date Header                     │
│  (Selected date, completion)     │
├─────────────────────────────────┤
│  Week Strip                      │
│  (Horizontal date selector)      │
├─────────────────────────────────┤
│  Weather Row                     │
│  (Temperature, city)             │
├─────────────────────────────────┤
│  Greeting Card                   │
│  (Summary, progress)             │
├─────────────────────────────────┤
│  Task List                       │
│  (Filtered by date)              │
│  - Today's tasks                 │
│  - Upcoming section              │
│  - Overdue section               │
└─────────────────────────────────┘
         [FAB: Add Task]
```

### Task Card

Individual task display with actions.

#### Features

- Title and optional subtitle
- Time badge (if scheduled)
- Completion checkbox
- Swipe-to-delete
- Tap to edit
- Date badge (for overdue/upcoming)

### Add Task Sheet

Modal bottom sheet for task creation/editing.

#### Fields

- Title (required)
- Notes (optional)
- Date picker
- Time picker
- Reminder type selector

### Alarm Page

Full-screen alarm interface.

#### Elements

- Task title
- Task notes
- Scheduled time
- Action buttons (Done, Snooze, Dismiss)

## Animations

### Entry Animations

- Task cards: Fade + slide (staggered)
- Greeting card: Fade + slide (date change)
- Week strip: Scale animation on selection

### Transition Animations

- Page transitions: Fade (300ms)
- Date changes: Slide direction based on navigation
- Accent color: Tween animation

### Micro-interactions

- Checkbox: Scale bounce
- FAB: Shadow glow
- Glow overlay: Color tween

## Data Persistence

### Local Storage (Hive)

```dart
// Storage keys
class StorageConstants {
  static const String dayflowHiveBox = 'dayflow_box';
  static const String tasksKey = 'tasks';
  static const String languageKey = 'language';
}
```

### Task Serialization

```dart
// Model to JSON
final json = task.toJson();

// JSON to Model
final task = TaskModel.fromJson(json);

// List storage
final tasksJson = jsonEncode(tasks.map((t) => t.toJson()).toList());
```

## Background Processing

### App Lifecycle Handling

```dart
class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Sync pending alarm actions
      // Refresh widget data
    }
  }
}
```

### Android Alarm Sync

On app resume, sync pending alarm actions:

1. Get pending snooze actions from native
2. Get pending done actions from native
3. Update task states accordingly
4. Clear pending actions
5. Sync widget data

## Error Handling

### User-Facing Errors

- Network failures → Graceful degradation
- Storage errors → Toast notification
- Permission denied → Feature unavailable message

### Error Display

```dart
// Toast notifications
Toastification().show(
  context: context,
  title: Text('Error message'),
  type: ToastificationType.error,
);
```

## Performance Optimizations

### List Rendering

- `SliverList` with builder delegate
- Lazy loading of task cards
- Staggered animations (45ms delay per item)

### State Management

- `buildWhen` for selective rebuilds
- Computed properties in state class
- Lazy cubit initialization

### Memory Management

- Stream subscription disposal
- Animation controller disposal
- Proper widget lifecycle handling

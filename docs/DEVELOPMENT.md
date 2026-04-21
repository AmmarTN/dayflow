# DayFlow Development Guide

## Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- Dart SDK ^3.9.2
- Xcode (for iOS development)
- Android SDK (for Android development)
- VS Code or Android Studio

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd dayflow

# Install dependencies
flutter pub get

# Generate code (routes, DI, models, i18n)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

## Project Configuration

### pubspec.yaml

Key dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^9.1.0
  equatable: ^2.0.5

  # Navigation
  auto_route: ^9.3.0+1

  # Dependency Injection
  get_it: ^7.6.0
  injectable: ^2.4.1

  # Models
  freezed_annotation: ^2.2.0
  json_annotation: ^4.8.0

  # Storage
  hive_flutter: ^1.1.0

  # Localization
  slang: 4.4.1
  slang_flutter: 4.4.0
  intl: ^0.20.0

  # Notifications
  flutter_local_notifications: ^17.0.0
  alarm: ^5.0.0
  timezone: ^0.9.0

  # Location & Weather
  geolocator: ^11.0.0
  geocoding: ^3.0.0
  http: ^1.0.0

  # UI
  flutter_screenutil: ^5.5.3+2
  flutter_svg: ^2.0.0
  google_fonts: ^6.2.1
  flutter_animate: ^4.2.0
  lottie: ^3.3.1

  # Home Widget
  home_widget: ^0.7.0

dev_dependencies:
  # Code Generation
  build_runner: ^2.4.0
  freezed: ^2.5.2
  injectable_generator: ^2.6.1
  auto_route_generator: ^9.3.1
  json_serializable: ^6.6.1
  slang_build_runner: 4.4.2

  # Testing
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

## Code Generation

### When to Run

Run code generation after modifying:

- `freezed` models or state classes
- `json_serializable` models
- `injectable` registrations
- `auto_route` route definitions
- `slang` localization files

### Commands

```bash
# One-time build
dart run build_runner build --delete-conflicting-outputs

# Watch mode (continuous)
dart run build_runner watch --delete-conflicting-outputs

# Clean and rebuild
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Generated Files

| Source File         | Generated Files                                |
| ------------------- | ---------------------------------------------- |
| `task_model.dart`   | `task_model.freezed.dart`, `task_model.g.dart` |
| `tasks_state.dart`  | `tasks_state.freezed.dart`                     |
| `router.dart`       | `router.gr.dart`                               |
| `injection.dart`    | `injection.config.dart`                        |
| `strings.i18n.yaml` | `strings.g.dart`                               |

## Architecture Guidelines

### Adding a New Feature

1. **Create Model** (if needed)

   ```dart
   // lib/infrastructure/models/feature/feature_model.dart
   @freezed
   class FeatureModel with _$FeatureModel {
     const factory FeatureModel({...}) = _FeatureModel;
     factory FeatureModel.fromJson(Map<String, dynamic> json) =>
         _$FeatureModelFromJson(json);
   }
   ```

2. **Create Data Source**

   ```dart
   // lib/infrastructure/datasources/feature_data_source.dart
   abstract class IFeatureDataSource {
     Either<Failure, FeatureModel> getData();
   }
   ```

3. **Create Repository**

   ```dart
   // lib/infrastructure/repositories/feature_repository_impl.dart
   abstract class IFeatureRepository {
     Either<Failure, FeatureModel> getFeature();
   }

   @Singleton(as: IFeatureRepository)
   class FeatureRepositoryImpl implements IFeatureRepository {...}
   ```

4. **Create Use Case**

   ```dart
   // lib/core/usecases/feature/get_feature.dart
   @injectable
   class GetFeature extends UseCase<FeatureModel, NoParams> {
     final IFeatureRepository repository;
     GetFeature(this.repository);

     @override
     Either<Failure, FeatureModel> call(NoParams params) {
       return repository.getFeature();
     }
   }
   ```

5. **Create State**

   ```dart
   // lib/presentation/features/feature/cubit/feature_state.dart
   @freezed
   class FeatureState with _$FeatureState {
     const factory FeatureState({...}) = _FeatureState;
   }
   ```

6. **Create Cubit**

   ```dart
   // lib/presentation/features/feature/cubit/feature_cubit.dart
   @injectable
   class FeatureCubit extends Cubit<FeatureState> {
     final GetFeature _getFeature;
     FeatureCubit(this._getFeature) : super(FeatureState.initial());
   }
   ```

7. **Create UI**

   ```dart
   // lib/presentation/features/feature/pages/feature_page.dart
   @RoutePage()
   class FeaturePage extends StatelessWidget {...}
   ```

8. **Register Route**

   ```dart
   // lib/presentation/common/routes/router.dart
   CustomRoute(page: FeatureRoute.page),
   ```

9. **Run Code Generation**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

### State Management Pattern

```dart
// 1. Define state with freezed
@freezed
class FeatureState with _$FeatureState {
  const factory FeatureState({
    required DataModel? data,
    @Default(CubitStatus.initial()) CubitStatus status,
  }) = _FeatureState;
}

// 2. Create cubit with injectable
@injectable
class FeatureCubit extends Cubit<FeatureState> {
  final GetFeature _getFeature;

  FeatureCubit(this._getFeature) : super(const FeatureState());

  // 3. Methods emit new states
  Future<void> loadData() async {
    emit(state.copyWith(status: const CubitStatus.loading()));

    final result = await _getFeature(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
        status: CubitStatus.failure(errorMsg: failure.getMessage()),
      )),
      (data) => emit(state.copyWith(
        data: data,
        status: const CubitStatus.success(),
      )),
    );
  }
}

// 4. Use in widget
BlocBuilder<FeatureCubit, FeatureState>(
  buildWhen: (prev, curr) => prev.data != curr.data,
  builder: (context, state) {
    // Build UI based on state
  },
)
```

### Error Handling Pattern

```dart
// Use Either for operations that can fail
Either<Failure, Success> operation() {
  try {
    // Perform operation
    return Right(success);
  } catch (e) {
    return Left(Failure.unexpectedError(e));
  }
}

// Pattern match on result
result.fold(
  (failure) => handleFailure(failure),
  (success) => handleSuccess(success),
);
```

## Testing

### Unit Tests

```dart
// test/core/usecases/tasks/get_tasks_test.dart
void main() {
  late GetTasks useCase;
  late MockTasksRepository mockRepo;

  setUp(() {
    mockRepo = MockTasksRepository();
    useCase = GetTasks(mockRepo);
  });

  test('should get tasks from repository', () {
    // Arrange
    final tasks = [TaskModel(...)];
    when(() => mockRepo.getTasks())
        .thenReturn(Right(tasks));

    // Act
    final result = useCase(NoParams());

    // Assert
    expect(result, Right(tasks));
    verify(() => mockRepo.getTasks()).called(1);
  });
}
```

### Widget Tests

```dart
// test/presentation/features/home/widgets/task_card_test.dart
void main() {
  testWidgets('displays task title', (tester) async {
    // Arrange
    final task = TaskModel(
      id: '1',
      title: 'Test Task',
      createdAt: DateTime.now(),
    );

    // Act
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TaskCard(task: task),
      ),
    ));

    // Assert
    expect(find.text('Test Task'), findsOneWidget);
  });
}
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/core/usecases/tasks/get_tasks_test.dart

# Run with coverage
flutter test --coverage
```

## Debugging

### Logging

```dart
import 'package:logger/logger.dart';

final logger = Logger();

logger.d('Debug message');
logger.i('Info message');
logger.w('Warning message');
logger.e('Error message', error: e, stackTrace: stackTrace);
```

### BLoC Observer

```dart
// lib/core/debug/app_bloc_observer.dart
class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    debugPrint('${bloc.runtimeType} $change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    debugPrint('${bloc.runtimeType} $error');
  }
}
```

### Platform-Specific Debugging

**iOS**

```bash
# Open in Xcode
open ios/Runner.xcworkspace

# View logs
flutter logs
```

**Android**

```bash
# View logcat
adb logcat -s flutter

# Check alarm manager
adb shell dumpsys alarm
```

## Build & Deploy

### Build Commands

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web (if supported)
flutter build web --release
```

### Environment Configuration

No environment-specific configuration is currently used. All data is stored locally.

### Version Management

Update version in `pubspec.yaml`:

```yaml
version: 1.0.0+1 # version+buildNumber
```

## Platform-Specific Notes

### Android

**Permissions** (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
```

**Alarm Configuration**:

- Uses native AlarmManager via MethodChannel
- Full-screen intent for alarm display
- Exact alarm permissions for Android 12+

### iOS

**Permissions** (`ios/Runner/Info.plist`):

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>DayFlow needs your location to show local weather.</string>
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
  <string>fetch</string>
  <string>processing</string>
</array>
```

**Alarm Configuration**:

- Uses `alarm` package
- Background audio for alarm sound
- Background fetch for timer restoration

## Common Tasks

### Adding a New Task Property

1. Update `TaskModel`:

   ```dart
   @freezed
   class TaskModel with _$TaskModel {
     const factory TaskModel({
       // ... existing properties
       String? newProperty,  // Add new property
     }) = _TaskModel;
   }
   ```

2. Run code generation:

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. Update UI to display/edit the property

4. Update widget sync if needed:
   ```dart
   // lib/services/widget_data_sync.dart
   await HomeWidget.saveWidgetData<String>('new_property', value);
   ```

### Adding a New Language

1. Create translation file:

   ```yaml
   # lib/i18n/strings_fr.i18n.yaml
   home:
     no_tasks: "Pas de tâches pour aujourd'hui"
   ```

2. Run code generation:

   ```bash
   dart run slang
   ```

3. Update `LocaleLanguage` enum:

   ```dart
   enum LocaleLanguage { ar, en, fr }
   ```

4. Update language cubit to support new locale

### Adding a New Notification Type

1. Define notification channel (Android):

   ```dart
   static const _newChannelId = 'new_channel';
   static const _newChannelName = 'New Channel Name';
   ```

2. Add scheduling method:

   ```dart
   Future<void> scheduleNewNotification(...) async {
     // Implementation
   }
   ```

3. Update `NotificationService` initialization

## Troubleshooting

### Common Issues

**Code Generation Fails**

```bash
# Clean and rebuild
dart run build_runner clean
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

**Hive Box Not Opening**

```dart
// Ensure Hive is initialized before opening boxes
await Hive.initFlutter();
await storageService.init();
```

**Notifications Not Working**

- Check permissions are granted
- Verify exact alarm permission (Android 12+)
- Check battery optimization settings

**Location Not Working**

- Verify location services are enabled
- Check permission status
- Test on physical device (simulator may not have location)

### Debug Commands

```bash
# Check Flutter doctor
flutter doctor -v

# Check connected devices
flutter devices

# Clear app data
adb shell pm clear com.example.dayflow

# Reinstall app
flutter clean
flutter pub get
flutter run
```

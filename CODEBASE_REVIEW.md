# DayFlow — Codebase & Feature Review

_Review date: 2026-04-23_
_Repo: `/Users/ahmed/dayflow/dayflow` (Flutter)_

---

## 1. Overview

**DayFlow** is a mobile-first, locally-focused daily task planner built with Flutter. It centers on a polished dark-themed UI with temporal awareness (today / past / future), local-only Hive storage, time-based scheduling with dual notification/alarm modes, Open-Meteo weather integration, and bilingual support (English / Arabic).

The design philosophy is **"simple over feature-rich"**: no backend, no authentication, no multi-device sync. It's a focused personal productivity tool.

**Entry point**: `lib/main.dart` initializes DI, permissions, and timezone data, then launches `DayFlowAppProvided`.

---

## 2. Tech Stack & Dependencies

| Concern | Choice |
|---|---|
| State management | `flutter_bloc` 9.1.0 (Cubits) |
| Dependency injection | `get_it` 4.x + `injectable` 2.4.1 (compile-time) |
| Storage | `hive_flutter` (local, schema-less) |
| Navigation | `auto_route` 9.3.0+ (code-generated routes) |
| Codegen | `freezed` 2.5.2, `json_serializable` 6.6.1, `slang` 4.4.1 |
| Notifications | `flutter_local_notifications` + `alarm` 5.0.0 + custom Android native bridge |
| Location / Weather | `geolocator`, `geocoding`, `http` (Open-Meteo) |
| Home widget | `home_widget` 0.7.0 (iOS + Android) |
| UI / Responsive | `flutter_screenutil`, `flutter_svg`, `lottie`, `flutter_animate` |
| Toasts | `toastification` 3.0.2 |

**Observation:** Several critical packages (Hive, geolocator, geocoding, http) aren't version-pinned in `pubspec.yaml` — could cause breakage on fresh `pub get`.

---

## 3. Architecture & Folder Structure

Layered clean architecture, domain-oriented.

```
lib/
├── core/                      # Shared utilities & domain logic
│   ├── debug/                 # AppBlocObserver, logger
│   ├── services/              # NotificationService (271 lines)
│   ├── storage/               # MainHiveStorageService
│   ├── usecases/              # GetTasks, SaveTasks, GetWeather, ...
│   ├── extensions/            # DateTime, context, dartz, string
│   └── erros/                 # Failure (freezed)
├── infrastructure/            # Data layer
│   ├── datasources/
│   │   ├── local_datasources/ # TasksLocalDataSource, CommonLocalDataSource
│   │   └── remote_datasources/# WeatherRemoteDataSource (Open-Meteo)
│   ├── models/                # TaskModel, WeatherModel
│   ├── repositories/          # TasksRepositoryImpl, WeatherRepositoryImpl
│   └── injections/            # External library DI module
├── presentation/              # UI layer
│   ├── common/                # theme, routes, shared widgets, global cubits
│   └── features/
│       ├── home/              # TasksCubit, WeatherCubit, home_page, widgets
│       ├── alarm/             # Full-screen alarm UI
│       ├── splash_page/       # Splash + alarm cold-start routing
│       ├── authentification/  # Unused stub (dead code)
│       └── static/
├── services/                  # App-level (WidgetDataSync)
└── i18n/                      # Slang-generated en/ar strings
```

**Pattern:** Clean architecture with clear presentation / domain / data separation. BLoC (Cubits) is the sole state tool — no Provider, no Riverpod, no MVC leakage.

---

## 4. Features

| Feature | Where | What it does |
|---|---|---|
| **Task CRUD** | `lib/presentation/features/home/` | Create/read/update/delete/complete tasks; Hive-backed; temporal filtering |
| **Scheduling & Alarms** | `lib/core/services/notification_service.dart` | Two reminder modes: push notification (passive) or full-screen alarm (mandatory action). Dual-layer: OS + Dart timer. |
| **Add/Edit Task Sheet** | `add_task_sheet.dart` (1216 lines) | Date/time pickers, reminder type, subtitle |
| **Week Strip Nav** | `week_strip.dart` (528 lines) | Swipeable week view with temporal color coding |
| **Weather** | `weather_cubit.dart` | Open-Meteo + reverse geocoding; graceful permission-denied fallback |
| **Home Widgets** | `lib/services/widget_data_sync.dart` (125 lines) | Syncs task count, next 3 tasks, greeting, weather to iOS/Android widgets |
| **Localization** | `lib/i18n/` | EN/AR via Slang; locale preference cached |
| **Splash + Cold-start Alarm** | `lib/presentation/features/splash_page/` | Splash animation; routes directly to AlarmPage if alarm fired while closed |
| **Bottom Nav** | `bottom_nav_layout_manager.dart/` | Scaffolding only — no multi-tab feature wired up (incomplete) |
| **Authentication** | `features/authentification/` | Stubbed; completely unused — **likely dead code** |

**Temporal states** (from `tasks_state.dart:11-32`) — a clever pattern: enum with computed `accent` / `glow` color properties.
- **Today**: green (#1EE468), interactive, overdue-first
- **Past**: blue (#5B7FFF), read-only, done vs. missed
- **Future**: orange (#FF9F2E), preview

---

## 5. Data Layer

**Storage:** Hive, a single `"tasks_hive_key"` holding a JSON-encoded list. No separate schema / boxes per task.
- Path: `lib/infrastructure/datasources/local_datasources/tasks_local_data_source.dart`
- Serialization: freezed `TaskModel` → JSON via `json_serializable`

**Core models:**
- `TaskModel` — `id`, `title`, `isDone`, `createdAt` (date-only), `subtitle?`, `category` (unused), `scheduledTime` ("HH:mm" string), `reminderType` ("notification" | "alarm")
- `WeatherModel` — `temperature`, `weatherCode` (WMO), `cityName`

**Repositories:** `ITasksRepository` → `TasksRepositoryImpl`; `IWeatherRepository` → `WeatherRepositoryImpl`. Both return `Either<Failure, T>` via dartz.

**Concerns:**
- `scheduledTime` as a free-form `"HH:mm"` string is parsed/formatted in at least 4 places (NotificationService, AlarmPage, AddTaskSheet, WidgetDataSync) — ripe for centralization.
- `category` field exists on `TaskModel` but is never used — should be removed or implemented.
- Single-key Hive storage means every task write rewrites the full list; fine for small N, painful at scale.

---

## 6. Notifications & Alarms System

(See the dedicated `NOTIFICATION_ALARM_IMPLEMENTATION_DOCS.md` — 34 pages.)

DayFlow implements a **sophisticated dual-reminder architecture** with cross-platform parity:

### Dual-layer scheduling
1. **OS layer** — `FlutterLocalNotificationsPlugin.zonedSchedule()` with `fullScreenIntent: true` (Android) or alarm presentation (iOS).
2. **Dart timer layer** — In-app timer that navigates to AlarmPage instantly if app is foreground when the alarm fires.

### Platform split
- **iOS**: uses the `alarm` package (`Alarm.set`, `Alarm.ringing` stream)
- **Android**: custom native bridge via `MethodChannel("dayflow/native_alarm")` → AlarmManager + BroadcastReceiver + foreground service + full-screen activity

### Android sync-on-startup
`syncPendingAndroidAlarmActions()` catches actions (snooze / done / dismiss) taken while the app was cold. Reschedules snoozes and propagates "done" into task state.

### Channels
- `task_reminders_v3` — push notifications (max importance, reminder category)
- `task_alarms_v3` — alarms (max importance, alarm category, full-screen intent)

### Strengths
- Robust cross-platform handling with real consideration for cold-start edge cases.
- Graceful permission degradation.
- Snooze + reschedule logic.

### Concerns
- **271-line service mixing scheduling, native bridge, state sync, timer management** — violates SRP; hard to test.
- **Hash-based notification IDs** (`task.id.hashCode`, line 79) — collision risk at large task counts.
- Silent exception swallowing (lines 216-218) hides real failures.
- **`alarm_sound.mp3` is referenced (line 118) but does not exist in `assets/`** — will fail at runtime. ⚠️
- Zero test coverage for any alarm/notification path.

---

## 7. Platforms

| Platform | Status |
|---|---|
| **iOS** | ✅ Active — Xcode project, Podfile, `TaskWidgetExtension` widget |
| **Android** | ✅ Active — Gradle, native alarm bridge |
| **macOS** | ⚠️ Configured (Podfile), likely dev-only |
| **Web** | ⚠️ Minimal scaffolding, not a real target |
| **Windows / Linux** | ⚠️ Default scaffolding, no platform-aware code |

Platform-specific code uses `defaultTargetPlatform` branching for alarm behavior. Non-Android / non-iOS platforms receive graceful no-ops.

---

## 8. UI & Theming

**Design system**
- Dark theme (`#0A0A0A` bg, `#1A1A1A` surface)
- Temporal accents: green (today) / blue (past) / orange (future) — extend to glows, borders, badges
- `AppColors` (`lib/presentation/common/theme/app_colors.dart`) — **83 colors defined, ~15 actively used**. The rest is legacy branding (HIA, GoFood, `ramliColor`, etc.) from a prior project lineage.

**Typography:** `AppTextStyles` + Google Fonts, responsive via `flutter_screenutil`.

**Custom widgets:** `MainButton`, `MainTextButton`, `MainTextField` (243 lines), `AppSvgImage`, `AppAssetImage`, `ScrollGlowIndicatorDisabler`.

**Animations:** `flutter_animate` for transitions, Lottie for splash, custom pulsing alarm icon.

**Observations:**
- Temporal color language is well-executed and coherent.
- `AppColors` needs pruning.
- Several screens are too large — see Code Quality section.

---

## 9. Assets

```
assets/
├── animations/food_loader.json     # Unused (GoFood legacy)
├── images/png/
│   ├── dayflow_app_icon.png        # Used
│   ├── splash_background.png       # Used
│   ├── login_background.png        # Unused (no login)
│   └── gofood_logo*.png            # Legacy, unused
├── images/svg/                     # success/failure icons + legacy login & nav SVGs
├── icons/svg/                      # Legacy login icons
├── env/development.env             # Empty placeholder
└── fonts/                          # Empty
```

**Cruft ratio is high.** Only the DayFlow icon, splash background, and status icons are live. Legacy GoFood / HIA / login assets inflate the bundle and muddy the repo.

**Missing:** `alarm_sound.mp3`, referenced in `NotificationService:118`.

---

## 10. Notable Patterns & Quirks

1. **Alarm cold-start handoff** (`main.dart:16-39`) — captures `pendingAlarmTaskId` at startup via a global; splash reads it and deep-links into AlarmPage. Clean in effect, mutable-global in form.
2. **Temporal enum with computed colors** (`tasks_state.dart:11-32`) — elegant; avoids switch duplication.
3. **Android alarm sync state machine** (`NotificationService:153-218`) — native→Dart recovery on cold start; no logging if sync fails.
4. **Code duplication** — task filtering lives in both `tasks_state.dart:58-65` and `widget_data_sync.dart:41-47`. Time string formatting duplicated across 4+ files.
5. **Dead feature folders** — `authentification/` and `bottom_nav_layout_manager.dart/` are empty shells kept in tree.
6. **Silent failure as a pattern** — `WidgetDataSync` uses blanket `catch (_)` (line 120). Defensible for widget sync (user-visible crash worse than stale widget) but hides diagnostics.

---

## 11. Test Coverage

**Current state: essentially none.**

- `test/widget_test.dart` — 8 lines, placeholder: `expect(1 + 1, equals(2))`.

**Missing:**
- Cubit unit tests (TasksCubit, WeatherCubit, LanguageCubit)
- Repository / use case tests
- Notification/alarm flow tests (the riskiest area)
- Widget tests for home page, add-task sheet
- Timezone / DST edge cases

**Impact:** Very high regression risk, especially in alarm scheduling, cold-start sync, and temporal filtering.

---

## 12. Code Quality — Issues & Priorities

| # | Issue | Location | Severity |
|---|---|---|---|
| 1 | **Missing `alarm_sound.mp3`** asset | `NotificationService:118` vs `assets/` | 🔴 High — runtime failure |
| 2 | **No test coverage** | `test/` | 🔴 High — fragile alarm logic |
| 3 | **Huge widget files** | `add_task_sheet.dart` (1216), `home_page.dart` (622), `week_strip.dart` (528) | 🟡 Medium |
| 4 | **NotificationService mixes concerns** (271 lines) | `lib/core/services/notification_service.dart` | 🟡 Medium |
| 5 | **Silent `catch (_)`** hiding bugs | `NotificationService:216-218`, `WidgetDataSync:120` | 🟡 Medium |
| 6 | **Task filtering duplicated** | `tasks_state.dart` + `widget_data_sync.dart` | 🟡 Medium |
| 7 | **`scheduledTime` string parsing scattered** | 4+ files | 🟡 Medium |
| 8 | **Dead code: `authentification/`** | `lib/presentation/features/authentification/` | 🟢 Low |
| 9 | **Dead code: `bottom_nav_layout_manager.dart/`** | — | 🟢 Low |
| 10 | **`AppColors` legacy cruft** (~68 unused colors) | `app_colors.dart` | 🟢 Low |
| 11 | **Legacy assets** (GoFood, HIA, login) | `assets/` | 🟢 Low |
| 12 | **No version pins** for Hive, geolocator, geocoding, http | `pubspec.yaml` | 🟢 Low |
| 13 | **Hash-based notification IDs** | `NotificationService:79` | 🟢 Low |
| 14 | **Unused `category` field** on TaskModel | `task_model.dart` | 🟢 Low |
| 15 | **No timezone handling** — plain `DateTime` | global | 🟢 Low |
| 16 | **`print()` instead of `debugPrint()`** | `AppBlocObserver` | 🟢 Low |

---

## 13. Strengths to Preserve

- Clean architecture boundaries held consistently
- Freezed for models & states — zero boilerplate drift
- Dartz `Either<Failure, T>` at repo/usecase layer — predictable error flow
- Responsive design via `flutter_screenutil`
- Thoughtful cross-platform alarm strategy with cold-start recovery
- Temporal UI language (green/blue/orange) is coherent and unique
- BLoC Observer for state-transition logging

---

## 14. Recommended Fix Order

1. **Ship-blocker**: Add `alarm_sound.mp3` to `assets/` (or remove the reference if sound isn't needed).
2. **Test foundation**: Cover `TasksCubit`, alarm scheduling, and `WidgetDataSync` with unit/integration tests before touching anything else.
3. **Refactor `add_task_sheet.dart`** into 4-6 sub-widgets (DatePicker, TimePicker, ReminderTypeSelector, etc.).
4. **Split `NotificationService`** into: `AlarmScheduler`, `NativeAlarmBridge` (Android), `AlarmStateSync`.
5. **Extract `ScheduledTime` value type** — parse once, carry the parsed form everywhere.
6. **Delete dead code**: `authentification/`, `bottom_nav_layout_manager.dart/`, unused TaskModel.category, unused assets.
7. **Prune `AppColors`** — keep only colors actually referenced.
8. **Pin all package versions** in `pubspec.yaml`.

---

## 15. Summary

DayFlow is a **well-structured, feature-complete personal task planner** with strong architectural bones: clean layering, BLoC, freezed, dartz, responsive UI, coherent dark-theme design. The **dual-mode notification/alarm system is genuinely sophisticated** — especially the Android native bridge and cold-start recovery — and would be hard to rebuild.

The honest concerns are **polish and testability, not architecture**: a missing alarm audio asset, zero tests on the riskiest subsystem, oversized widget files, lingering legacy assets/code from prior projects, and a monolithic NotificationService mixing scheduling with state sync.

With ~1-2 focused weeks of cleanup and test-writing, this codebase would be production-ready for wider distribution.

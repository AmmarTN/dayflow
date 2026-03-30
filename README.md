# DayFlow

DayFlow is a mobile-first Flutter planner for managing daily tasks in a calm, focused interface. The app centers on a single timeline: users can move across days, add tasks with optional notes and times, mark tasks complete for today, review past days, preview upcoming plans, and see the current local weather.

## What The App Does

- Shows a splash screen and launches into a single primary home experience.
- Lets users navigate the current week and switch between past, present, and future dates.
- Stores tasks locally on the device, including title, optional note, date, completion state, and optional scheduled time.
- Changes task presentation based on temporal context:
  - `today`: interactive checklist
  - `past`: completed vs missed history
  - `future`: planned items
- Fetches current weather using device location and the Open-Meteo API.
- Supports English and Arabic localization, with language preference cached locally.

## Core Features

- Daily task planning
- Week strip date navigation
- Add-task bottom sheet with date and time pickers
- Swipe-to-delete task cards
- Completion progress and daily summary
- Weather row with location-aware temperature and city name
- Dark UI with animated transitions and temporal accent colors
- Local persistence with no required backend

## Tech Stack

- Flutter
- Dart `^3.9.2`
- `flutter_bloc` for state management
- `get_it` + `injectable` for dependency injection
- `auto_route` for navigation
- `freezed` + `json_serializable` for models and state classes
- `hive_flutter` for local storage
- `slang` for localization
- `geolocator` + `geocoding` for location and reverse geocoding
- `http` for weather requests

## Architecture

The codebase follows a layered structure with clear separation between UI, domain logic, and data access:

- `lib/presentation/`
  - Screens, widgets, routes, themes, and Cubits
- `lib/core/`
  - Shared app utilities, storage abstractions, failures, and use cases
- `lib/infrastructure/`
  - Local and remote data sources, repositories, models, and constants
- `lib/i18n/`
  - Generated and source localization files

At runtime:

1. `main.dart` initializes Flutter, dependency injection, and the BLoC observer.
2. `DayFlowAppProvided` registers the main Cubits and loads cached state.
3. The app opens on a splash screen, then routes to the home page.
4. Tasks are loaded from Hive-backed local storage.
5. Weather is fetched from Open-Meteo using the current device location.

## Project Structure

```text
lib/
  core/
  i18n/
  infrastructure/
    datasources/
    models/
    repositories/
  presentation/
    common/
    features/
      home/
      splash_page/
main.dart
```

## Local Data And External Services

### Local Storage

- Tasks are persisted locally in Hive.
- Language preference is cached locally.
- There is no app-specific backend in this project.

### Weather

- Weather is requested from [Open-Meteo](https://open-meteo.com/).
- The app requests location permission in order to determine the user’s current coordinates.
- If location services are disabled or permission is denied, the planner still works and weather is shown as unavailable.

## Getting Started

### Prerequisites

- Flutter stable
- Dart SDK compatible with `^3.9.2`
- Xcode for iOS builds
- Android SDK for Android builds

### Install Dependencies

```bash
flutter pub get
```

### Run The App

```bash
flutter run
```

### Run Tests

```bash
flutter test
```

## Code Generation

This project uses generated files for routing, dependency injection, state classes, models, and localization.

Run code generation after changing files related to:

- `freezed` models or states
- `json_serializable` models
- `injectable` registrations
- `auto_route` route definitions
- localization resources

```bash
dart run build_runner build --delete-conflicting-outputs
```

For continuous generation during development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Platform Notes

- The app forces portrait orientation at startup.
- Android requests fine and coarse location permissions.
- iOS requests when-in-use location permission with the message: `DayFlow needs your location to show local weather.`

## Main Entry Points

- `lib/main.dart`
- `lib/presentation/dayflow_app.dart`
- `lib/presentation/features/home/pages/home_page.dart`
- `lib/presentation/features/home/cubit/tasks_cubit.dart`
- `lib/presentation/features/home/cubit/weather_cubit.dart`

## Current Product Scope

DayFlow is currently a focused personal planner rather than a full productivity platform. The implemented experience is centered on one polished home flow with local task management, lightweight weather context, and bilingual support.

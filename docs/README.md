# DayFlow Documentation

Welcome to the DayFlow documentation. This folder contains comprehensive documentation for the DayFlow Flutter application.

## Documentation Index

| Document                               | Description                                         |
| -------------------------------------- | --------------------------------------------------- |
| [ARCHITECTURE.md](./ARCHITECTURE.md)   | System architecture, design patterns, and data flow |
| [FEATURES.md](./FEATURES.md)           | Feature descriptions and UI components              |
| [DATA_MODELS.md](./DATA_MODELS.md)     | Data model definitions and storage schema           |
| [API_REFERENCE.md](./API_REFERENCE.md) | Cubits, services, repositories, and use cases API   |
| [DEVELOPMENT.md](./DEVELOPMENT.md)     | Development setup, testing, and deployment guide    |

## Quick Start

```bash
# Install dependencies
flutter pub get

# Generate code
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

## App Overview

DayFlow is a mobile-first Flutter planner for managing daily tasks with:

- Daily task planning with timeline navigation
- Week strip date selector
- Task reminders (notifications and alarms)
- Weather display using device location
- Home screen widget support
- English and Arabic localization

## Architecture Summary

```
lib/
├── core/           # Domain layer (use cases, services)
├── infrastructure/ # Data layer (repositories, data sources)
├── presentation/   # UI layer (screens, widgets, cubits)
├── services/       # App services (widget sync)
└── i18n/           # Localization
```

## Key Technologies

- **State Management**: flutter_bloc
- **Dependency Injection**: get_it + injectable
- **Navigation**: auto_route
- **Storage**: Hive
- **Localization**: slang
- **Notifications**: flutter_local_notifications + alarm
- **UI**: flutter_screenutil, flutter_animate

## Support

For issues or questions, please refer to the specific documentation files or the main [README.md](../README.md).

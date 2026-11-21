# Flutter Project qa3ty_app

This repository provides a scalable and maintainable architecture for Flutter applications, utilizing a feature-based folder qa3ty_app, centralized core logic, and environment-specific flavors.

## 🏗 Project Architecture

The project follows a clean, modular architecture divided into two primary directories: `core` and `features`.

### 1. Core Folder (`lib/core`)
The `core` directory contains code that is shared across multiple features or provides global infraqa3ty_app for the application.

| Folder | Description |
| :--- | :--- |
| **config** | Global app configurations, such as global Bloc providers. |
| **cubit** | Global state management (e.g., Internet connectivity, App intro state). |
| **helpers** | Common Dart extensions and utility helpers like spacing. |
| **navigation** | Centralized routing logic and app router configuration. |
| **networking** | API services, Dio factory, and standardized error handling. |
| **services** | External service integrations (Firebase, Remote Config) and Service Locator (GetIt). |
| **utils** | Global constants, theme data (colors, styles), and reusable UI widgets. |

### 2. Features Folder (`lib/features`)
The `features` directory follows a feature-first approach, where each module is self-contained and represents a specific functional area of the app (e.g., `auth`, `home`).

Each feature typically includes:
*   **data**: Contains models (data qa3ty_apps) and repositories (data fetching logic).
*   **presentation**: Contains UI components, including screens, feature-specific widgets, and Cubits for state management.
*   **export.dart**: A barrel file to simplify imports within and outside the feature.

---

## 🎨 Flutter Flavors

This project supports multiple environments using Flutter flavors to separate development and production configurations.

### Available Flavors
*   **Development**: Used for active development and testing.
    *   **Entry Point**: `lib/main_development.dart`
    *   **Android App Name**: `qa3ty_app Development`
    *   **Application ID Suffix**: `.dev`
*   **Production**: The stable version intended for end-users.
    *   **Entry Point**: `lib/main_production.dart`
    *   **Android App Name**: `qa3ty_app`

### Running the App
To run the application with a specific flavor, use the following commands:

**Development:**
```bash
flutter run --flavor Development -t lib/main_development.dart
```

**Production:**
```bash
flutter run --flavor Production -t lib/main_production.dart
```

---

## 🛠 Getting Started

1.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```
2.  **Generate Code**:
    Since this project uses `retrofit` and `freezed`, run the build runner:
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```
3.  **Run the App**:
    Choose your desired flavor as shown in the [Flavors](#-flutter-flavors) section.

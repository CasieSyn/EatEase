# EatEase Mobile App

AI-powered meal planning mobile application built with Flutter.

## Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: Provider / Riverpod (TBD)
- **HTTP Client**: Dio
- **Camera**: camera plugin
- **Image Processing**: image_picker
- **Storage**: shared_preferences, flutter_secure_storage
- **Navigation**: go_router

## Project Structure

```
frontend/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── app.dart                  # App widget & routing
│   ├── config/                   # App configuration
│   │   └── constants.dart
│   ├── models/                   # Data models
│   │   ├── user.dart
│   │   ├── recipe.dart
│   │   ├── ingredient.dart
│   │   └── meal_plan.dart
│   ├── services/                 # API & business logic
│   │   ├── api_service.dart
│   │   ├── auth_service.dart
│   │   ├── recipe_service.dart
│   │   └── camera_service.dart
│   ├── state/                    # State management
│   │   ├── auth_provider.dart
│   │   └── recipe_provider.dart
│   ├── screens/                  # UI screens
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── camera/
│   │   │   └── camera_screen.dart
│   │   ├── recipes/
│   │   │   ├── recipe_list_screen.dart
│   │   │   └── recipe_detail_screen.dart
│   │   ├── profile/
│   │   │   ├── profile_screen.dart
│   │   │   └── preferences_screen.dart
│   │   └── meal_plan/
│   │       └── meal_plan_screen.dart
│   ├── widgets/                  # Reusable components
│   │   ├── common/
│   │   │   ├── custom_button.dart
│   │   │   ├── custom_text_field.dart
│   │   │   └── loading_indicator.dart
│   │   ├── recipe/
│   │   │   └── recipe_card.dart
│   │   └── ingredient/
│   │       └── ingredient_chip.dart
│   └── utils/                    # Helpers
│       ├── validators.dart
│       └── formatters.dart
├── assets/                       # Images, fonts, etc.
│   ├── images/
│   ├── icons/
│   └── fonts/
├── test/                         # Tests
├── pubspec.yaml                  # Dependencies
└── README.md
```

## Setup Instructions

### Prerequisites

- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / Xcode (for emulators)
- VS Code with Flutter extension (recommended)

### 1. Install Flutter

Follow official guide: https://docs.flutter.dev/get-started/install

Verify installation:
```bash
flutter doctor
```

### 2. Create Flutter Project

```bash
cd frontend
flutter create . --org com.eatease --platforms android,ios
```

### 3. Install Dependencies

Add to `pubspec.yaml`, then run:

```bash
flutter pub get
```

### 4. Configure API Endpoint

Create `lib/config/constants.dart`:

```dart
const String API_BASE_URL = 'http://localhost:5000/api';
```

For Android emulator: `http://10.0.2.2:5000/api`
For iOS simulator: `http://localhost:5000/api`

### 5. Run App

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Run in debug mode
flutter run

# Run in release mode
flutter run --release
```

## Required Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  provider: ^6.1.1

  # HTTP & API
  dio: ^5.4.0

  # Storage
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0

  # Camera & Images
  camera: ^0.10.5
  image_picker: ^1.0.7

  # Navigation
  go_router: ^13.0.0

  # UI Components
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.1

  # Utilities
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

## Screens to Implement

### Phase 1 (MVP)
1. **Splash Screen** - App loading
2. **Onboarding** - First-time user intro
3. **Login/Register** - Authentication
4. **Home** - Dashboard with quick actions
5. **Manual Input** - Add ingredients manually
6. **Recipe List** - Browse matched recipes
7. **Recipe Detail** - View full recipe

### Phase 2
8. **Camera Scan** - Ingredient detection
9. **Profile** - User settings
10. **Preferences** - Dietary settings
11. **Meal Plan** - Weekly planner
12. **Shopping List** - Generated lists

### Phase 3
13. **Nutrition Dashboard** - Insights
14. **Recipe Favorites** - Saved recipes
15. **Subscription** - Premium features

## Development Commands

```bash
# Run app
flutter run

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format lib/

# Clean project
flutter clean
```

## API Integration

Base URL: Configure in `lib/config/constants.dart`

### Authentication Flow
1. User registers/login → Receive JWT token
2. Store token in `flutter_secure_storage`
3. Add token to all API requests via Dio interceptor

### Example API Call

```dart
final dio = Dio(BaseOptions(
  baseUrl: API_BASE_URL,
  headers: {'Authorization': 'Bearer $token'}
));

final response = await dio.get('/recipes');
```

## Next Steps

1. Setup Flutter project with dependencies
2. Implement authentication screens (Login/Register)
3. Create API service layer with Dio
4. Implement recipe browsing & search
5. Add camera integration for ingredient detection
6. Build meal planning feature
7. Implement shopping list generation
8. Add user preferences & profile
9. Setup app icons & splash screen
10. Testing & optimization

## Design Guidelines

- Follow Material Design 3 principles
- Use EatEase brand colors (define in theme)
- Ensure responsive layouts (phone & tablet)
- Implement dark mode support
- Accessibility considerations (screen readers, contrast)

## Resources

- [Flutter Documentation](https://docs.flutter.dev)
- [Dart Documentation](https://dart.dev/guides)
- [Material Design 3](https://m3.material.io)
- [Provider State Management](https://pub.dev/packages/provider)

## License

Proprietary - EatEase Team

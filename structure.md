# Project Structure & Architecture

## Overview
- **Framework**: Flutter
- **State Management**: `Provider` (MultiProvider used in `main.dart`, `ChangeNotifierProvider` used locally).
- **Navigation**: Named routes managed in `lib/app/routes/app_routes.dart`.
- **Services**: Firebase (Core, Messaging), Network API, Secure Storage.

## Directory Structure (`lib/app`)

The core application logic is contained entirely within the `lib/app` directory.

### 1. **Screens (`lib/app/view`)**
Screens are strictly organized by feature/flow folders.

- **Onboarding & Authentication**:
  - `splash/`: Splash entry point.
  - `onboarding/`: Onboarding slides.
  - `lets_get_started/`: Landing page.
  - `sign_in/`: Login screen.
  - `create_account/`: Sign up flow (`add_email`, `create_new_account`, `account_created`).
  - `forgot_password/`: Password recovery logic.
  - `create_new_password/`: New password setting.
  - `basic_information/`: User setup steps (`basic_info`, `stages`, `processing_details`).

- **Main Flows**:
  - `Pre_pregnancy_flow/`: Logic for users planning pregnancy (Cycle tracking, Logs).
  - `Pregnancy_Flow/`: Main pregnancy tracking (Home, Appointments, Fetal Development).
  - `Post_pregnancy_flow/`: Post-birth logic (Baby details, Post-appointments).

- **Key Features**:
  - `baby_growth/`: Tools for tracking baby growth (Milestones, Photos, Vaccinations).
  - `expert_consultation/`: Doctor appointment bookings, slot selection, records.
  - `ai_assistant/`: AI Chat interface.
  - `subscription_unlock_plans/`: Subscription screens tailored to pregnancy stages.
  - `profile_screen/`: User profile management and legal pages (Privacy, Terms).

### 2. **Navigation (`lib/app/routes`)**
- `app_routes.dart`: The central routing file.
  - Defines static String constants for all route names.
  - Implements `generateRoute` switch-case to map routes to Widget classes.
  - **Screen Mapping**: Check this file to see exactly which Widget class corresponds to a route name.

### 3. **State Management (`lib/app/controller` & `lib/app/nodes`)**
- Controllers are primarily located in `lib/app/controller`.
- They extend `ChangeNotifier` to work with the Provider package.
- Global providers are injected in `main.dart` using `MultiProvider`.
- Local providers are often created using `ChangeNotifierProvider` within the specific view files.

### 4. **Theme (`lib/app/theme`)**
- `app_colors.dart`: Contains static color definitions (e.g., `AppColors.backgroundClr`).
- `font_family.dart` & `font_style.dart`: Define text styles and font families used across the app.

### 5. **Common Widgets (`lib/app/widgets`)**
- Contains reusable components such as `Button`, `CustomImage`, and `loader`.
- Custom logging utility `pt()` is defined here (inside `print.dart`).

---

## Code Format & Style Guidelines

### Naming Conventions
- **Files**: `snake_case` (e.g., `splash_view.dart`, `booking_controller.dart`).
- **Classes**: `PascalCase` (e.g., `SplashView`, `BookingController`).
- **Variables/Methods**: `camelCase` (e.g., `currentUser`, `fetchData()`).

### Widget Implementation
- **StatefulWidget**: Used for screens needing lifecycle methods (e.g., `initState` for fetching data).
- **StatelessWidget**: Used for static UI screens.
- **Scaffold**: Most screens return a `Scaffold` as the root widget.
- **SafeArea**: Often wraps the body of the Scaffold.

### State Management Logic
- **Accessing State**:
  - `Consumer<MyController>` is used inside `build()` to rebuild UI on changes.
  - `Provider.of<MyController>(context, listen: false)` is used for triggering actions (functions) without rebuilding.

### Navigation Pattern
```dart
// Example Navigation Code
Navigator.pushNamed(context, AppRoutes.homeView);

// Removing previous routes
Navigator.pushNamedAndRemoveUntil(context, AppRoutes.loginView, (route) => false);
```

### Logging
- Do **not** use `print()`. Use the custom `pt()` function.
```dart
pt("Message to log");
pt("Value", name: "Label");
```

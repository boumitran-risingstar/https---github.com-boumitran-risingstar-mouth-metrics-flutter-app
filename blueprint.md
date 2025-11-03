
# Blueprint: Mouth Metrics Flutter App

## Overview

Mouth Metrics is a Flutter application designed to be a personal dental health companion. It aims to provide users with tools and insights to better track and understand their oral hygiene habits and health. The application is built with a focus on a modern, clean, and intuitive user interface.

## Style, Design, and Features

This document outlines the design and features implemented in the application.

### Version 1.1.0

*   **Phone Authentication:**
    *   **Dependencies:** Added `firebase_core`, `firebase_auth`, and `pinput` for a complete authentication experience.
    *   **Firebase Setup:** The project is now connected to a new Firebase project (`mouth-metrics-flutter-app`). The configuration file `firebase_options.dart` has been generated.
    *   **Login Screen:** A new `login_screen.dart` has been created with UI and logic for users to sign in using their phone number. It includes:
        *   An input field for the phone number.
        *   A 'Send OTP' button to trigger the SMS verification process.
        *   A `pinput` field for a smooth OTP entry experience.
        *   A 'Verify OTP' button to complete the sign-in process.
    *   **Navigation:**
        *   The `go_router` configuration has been updated to include the `/login` route.
        *   The "Get Started" button on the `landing_page.dart` now navigates the user to the `/login` screen.
        *   Upon successful authentication, the user is redirected to the `/home` screen.
    *   **State Management:** The authentication state is managed by the `firebase_auth` package, which handles user sessions automatically.

### Version 1.0.0

*   **Initial Setup:**
    *   The project was initialized as a standard Flutter application.
    *   The app name was set to "Mouth Metrics" and the description was updated in `pubspec.yaml`.
*   **Landing Page:**
    *   **Theme:** A comprehensive Material 3 theme is implemented with support for both light and dark modes, managed by the `provider` package.
        *   **Color Scheme:** The theme is generated from a seed color (`Colors.teal`) using `ColorScheme.fromSeed`.
        *   **Typography:** The `google_fonts` package is used to apply the 'Poppins' font.
        *   **Component Styling:** The `AppBarTheme` and `ElevatedButtonTheme` are customized for a consistent look and feel.
    *   **Layout & UI:**
        *   The landing page features a centered, visually engaging layout with an animated gradient background and animated UI elements.
        *   A prominent "Get Started" button serves as the primary call to action.
    *   **State Management:**
        *   `provider` is used for theme management (`ThemeProvider`).
*   **Routing:**
    *   `go_router` was added and configured to handle navigation between the landing page and the home screen.

## Current Plan: Implement Phone Authentication

*   **Objective:** To create a secure and user-friendly phone authentication flow, allowing users to sign in and access personalized features.

*   **Steps:**
    1.  **[COMPLETED]** Add Firebase dependencies: `firebase_core`, `firebase_auth`, and `pinput`.
    2.  **[COMPLETED]** Initialize a new Firebase project and configure it for the Flutter app.
    3.  **[COMPLETED]** Run `flutterfire configure` to connect the app to the Firebase project and generate `firebase_options.dart`.
    4.  **[COMPLETED]** Create the `login_screen.dart` with the necessary UI and logic for phone number input and OTP verification.
    5.  **[COMPLETED]** Update the `go_router` configuration to include the `/login` route.
    6.  **[COMPLETED]** Update the `landing_page.dart` to navigate to the `/login` screen.
    7.  **[COMPLETED]** Update `main.dart` to initialize Firebase.
    8.  **[USER ACTION REQUIRED]** Enable Phone Number sign-in in the Firebase Console.

# Blueprint: Mouth Metrics Flutter App

## Overview

Mouth Metrics is a Flutter application designed to be a personal dental health companion. It aims to provide users with tools and insights to better track and understand their oral hygiene habits and health. The application is built with a focus on a modern, clean, and intuitive user interface.

## Backend Services

The application is supported by a set of backend microservices that handle business logic and data persistence.

*   **`user-service`**: This service is responsible for managing user-related data, such as profiles and preferences. It is a private service that requires Firebase authentication for all endpoints, ensuring that users can only access their own data.

*   **`business-service`**: This service handles business-specific logic. It is also a private service that requires Firebase authentication, protecting sensitive business data.

*   **Security**: Both services are deployed as private Cloud Run services. Public access has been removed, and all requests must be authenticated with a valid Firebase ID token.

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

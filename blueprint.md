
# Blueprint: Mouth Metrics Flutter App

## Overview

Mouth Metrics is a Flutter application designed to be a personal dental health companion. It aims to provide users with tools and insights to better track and understand their oral hygiene habits and health. The application is built with a focus on a modern, clean, and intuitive user interface.

## Style, Design, and Features

This document outlines the design and features implemented in the application.

### Version 1.0.0

*   **Initial Setup:**
    *   The project was initialized as a standard Flutter application.
    *   The app name was set to "Mouth Metrics" and the description was updated in `pubspec.yaml`.
    *   A basic, empty app structure was created in `lib/main.dart`.
*   **Landing Page (Current):**
    *   **Theme:** A comprehensive Material 3 theme is implemented with support for both light and dark modes, managed by the `provider` package.
        *   **Color Scheme:** The theme is generated from a seed color (`Colors.teal`) using `ColorScheme.fromSeed`, ensuring a harmonious and modern palette.
        *   **Typography:** The `google_fonts` package is used to apply the 'Poppins' font, providing a clean and trendy text style. Specific styles are defined for `displayLarge`, `titleLarge`, and `bodyMedium`.
        *   **Component Styling:** The `AppBarTheme` and `ElevatedButtonTheme` are customized for a consistent look and feel.
    *   **Layout & UI:**
        *   The landing page features a centered, visually engaging layout.
        *   **Background:** A subtle linear gradient from teal to a lighter shade creates a sense of depth and vibrancy.
        *   **Visuals:** A large, stylized icon (`Icons.health_and_safety_outlined`) serves as the main visual anchor, representing health and care.
        *   **Content:**
            *   A bold, prominent "hero" title: "Mouth Metrics".
            *   An encouraging tagline: "Unlock a brighter smile, one day at a time."
            *   A placeholder for a future chart/visual element.
        *   **Interactivity:** A primary Call-to-Action (CTA) button ("Get Started") is styled with a "glowing" shadow effect to draw user attention.
    *   **State Management:**
        *   `provider` is used for theme management (`ThemeProvider`), allowing users to toggle between light and dark modes.

## Current Plan: Create an Awesome Trendy Landing Page

*   **Objective:** Transform the basic placeholder screen into a visually appealing and modern landing page that captures the user's interest and clearly communicates the app's purpose.

*   **Steps:**
    1.  **[COMPLETED]** Add necessary dependencies: `google_fonts` for typography and `provider` for state management (specifically for theme toggling).
    2.  **[COMPLETED]** Create `blueprint.md` to document the project's design and features.
    3.  **[COMPLETED]** Implement a full Material 3 theme in `lib/main.dart` with both light and dark modes.
    4.  **[COMPLETED]** Use `ColorScheme.fromSeed` with a `teal` seed color for a fresh, health-oriented palette.
    5.  **[COMPLETED]** Integrate the 'Poppins' font using `google_fonts` for all text styles.
    6.  **[COMPLETED]** Design and build the `LandingPage` widget with a gradient background, a central icon, a hero title, a tagline, and a prominent "Get Started" button.
    7.  **[COMPLETED]** Style the button with a shadow/glow effect to make it interactive and visually appealing.
    8.  **[COMPLETED]** Implement a `ThemeProvider` using `provider` to allow for future theme toggling.

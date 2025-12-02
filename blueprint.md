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

### Version 1.7.0 (Current)

*   **User Photo Gallery Management:**
    *   **Backend Deployed:** The `user-service` has been enhanced with a complete photo gallery management system.
        *   **New Data Model:** The user model in Firestore now includes a `photoGallery` field, which is an array of photo objects. Each photo object contains a unique `id`, a public `url`, a boolean `isDefault` flag, and a `createdAt` timestamp.
        *   **Secure File Uploads:** The backend now uses `multer` for secure and efficient handling of image uploads. Cloud Storage rules have been implemented to enforce a 2MB file size limit and allow only JPEG/PNG image types.
        *   **New API Endpoints:** Three new, secure endpoints have been added:
            *   `POST /api/users/:userId/photos`: Upload a new photo.
            *   `PUT /api/users/:userId/photos/:photoId/default`: Set a specific photo as the default profile picture.
            *   `DELETE /api/users/:userId/photos/:photoId`: Delete a photo from the gallery and from Cloud Storage.

    *   **Frontend Implemented:**
        *   **Profile Screen UI Overhaul:**
            *   The `profile_screen.dart` has been updated with a dynamic photo gallery.
            *   The main profile picture at the top of the screen displays the photo from the gallery where `isDefault` is `true`.
            *   A grid of thumbnails is displayed below the main picture, showing all photos in the user's `photoGallery`.
        *   **Photo Management UI:**
            *   An "Upload Photo" button allows users to select and upload new images.
            *   Tapping on a thumbnail provides options to "Set as Default" or "Delete" the photo. A confirmation dialog is used for the delete action to prevent accidental deletions.
        *   **Updated Frontend Service (`user_service.dart`):**
            *   New methods (`uploadPhoto`, `deletePhoto`, `setDefaultPhoto`) have been created to interact with the new backend endpoints.

### Version 1.6.0

*   **Improved Slug Generation:**
    *   The `syncUser` function in `user_service.dart` has been updated to ensure that all users, including those who sign up with only a phone number, are assigned a unique slug.
    *   If a user's `displayName` is not available, the `phoneNumber` is now used as the basis for generating the slug. If neither is available, it defaults to 'user'. This ensures that the public profile feature is available to all users, regardless of their sign-up method.

### Version 1.5.0

*   **Comprehensive User Profile Feature:**
    *   **Public Profile Screen:** A new `my_profile_screen.dart` was created to display a user's public-facing profile. This screen shows the user's name, bio, and profile picture.
    *   **Profile Sharing:** The public profile screen includes a "Share" button that uses the `share_plus` package to open the native device sharing UI, allowing users to share a link to their public profile.
    *   **Editable Profile Screen:** The `profile_screen.dart` was completely redesigned to provide a modern and intuitive interface for users to edit their profile information. Features include:
        *   An improved layout with a `CircleAvatar` for the profile picture.
        *   A new multi-line text field for the user's bio.
        *   The ability to upload a new profile picture using the `image_picker` package.
    *   **Backend Integration:**
        *   The `user_service.dart` was updated to include an `uploadProfilePicture` method that uploads images to Firebase Storage.
        *   The `updateUser` method in the service was enhanced to handle the new `bio` and `profilePictureUrl` fields.

### Version 1.4.0

*   **Shareable Public Profiles (Frontend):**
    *   **Backend Deployed:** The `user-service` is successfully deployed on Cloud Run, providing endpoints for user creation and public profile retrieval. All IAM and permissions issues have been resolved.
    *   **Profile Navigation:** A "My Profile" button was added to the `HomeScreen` to navigate users to their dedicated profile page.
    *   **Profile Screen:** A new `profile_screen.dart` was created to display the user's public profile information (name, bio, profile picture) fetched from the backend.
    *   **Profile Sharing:** The profile screen features a "Share" button. Tapping this button will open the native device sharing UI, allowing users to share a public link to their profile page.
    *   **Dependencies:** The `share_plus` package was added to the project to facilitate the sharing functionality.
    *   **Routing:** A new `/my-profile` route was added to the `go_router` configuration.

### Version 1.3.0

*   **Public User Profiles & Slug Management:**
    *   **Static Page Generation:** The `user-service` now generates a static HTML profile page for each user when they update their name. These pages are stored in Cloud Storage and made public.
    *   **Unique Slug Generation:** When a user sets or updates their name, a unique, URL-friendly "slug" (e.g., `john-doe-x4f7`) is generated.
    *   **Atomic Operations:** The entire process of creating a slug, linking it to a user, and updating the user's profile is handled within a Firestore transaction. This ensures data integrity and prevents race conditions, guaranteeing slug uniqueness.
    *   **Slug History & Permanent Redirects:**
        *   When a user changes their name, the old slug is saved in a `slugHistory` array.
        *   A new Cloud Function, `redirectHandler`, was created. If a request is made to an old profile URL, this function looks up the old slug in the `slugHistory` and issues a permanent (301) redirect to the user's current profile URL. This is crucial for SEO and maintaining link integrity.
    *   **Firebase Hosting Integration:** Firebase Hosting is configured to use the `redirectHandler` function for any request to the `/profiles/` path, seamlessly managing the redirection from old to new profile URLs.

### Version 1.2.0

*   **User Profile Management:**
    *   **Profile Screen:** A new `profile_screen.dart` was created, allowing users to view and edit their profile information.
        *   Users can update their `name` and `email`.
        *   The `phone number` is displayed but is not editable.
    *   **Backend Integration:** A `user_service.dart` was implemented to communicate with the backend `user-service`.
        *   The service handles `GET` and `PUT` requests to fetch and update user data.
        *   All requests are authenticated using a Firebase ID token.
    *   **User Sync:** A `syncUser` function was added to the `user_service` to synchronize user data between Firebase Authentication and the application's backend after login.

*   **Enhanced Home Screen & Navigation:**
    *   **Profile Access:** A "Profile" icon button was added to the `HomeScreen` app bar, navigating users to the new `/profile` screen.
    *   **Logout Functionality:** A "Logout" button was added to the `HomeScreen` to sign the user out and return them to the landing page.
    *   **UI Improvements:** The `HomeScreen` UI was updated with `Card` elements for a more organized and visually appealing layout, displaying health metrics, daily tips, and articles.

*   **Routing:**
    *   The `go_router` configuration was updated to include the `/profile` route, which directs to the `ProfileScreen`.

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

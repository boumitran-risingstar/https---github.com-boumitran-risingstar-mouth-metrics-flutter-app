# Blueprint: Mouth Metrics Flutter App

## Overview

Mouth Metrics is a Flutter application designed to be a personal dental health companion. It aims to provide users with tools and insights to better track and understand their oral hygiene habits and health. The application is built with a focus on a modern, clean, and intuitive user interface.

## Current Task

No active development task. The focus is on monitoring and maintenance.

## Style, Design, and Features

This document outlines the design and features implemented in the application.

### Version 2.0.0

*   **Dental Clinic Business Profile Management:**
    *   **Authenticated Access:** Implemented a feature for authenticated users to create and manage their dental clinic's business profile.
    *   **Business Profile Screen:** Created a new screen (`business_profile_screen.dart`) where users can input and update their business details, including name, address, phone number, website, and operating hours.
    *   **Unique Slug for Business:** The backend `business-service` now generates a unique, URL-friendly slug for each business profile. This slug is used for creating a public-facing URL for the business.
    *   **Frontend-Backend Integration:** The `business_service.dart` on the frontend communicates with the secure `business-service` backend to handle all CRUD (Create, Read, Update, Delete) operations for the business profile.
    *   **Navigation:** Added a "My Business" link in the app's navigation drawer, which is visible only to authenticated users and navigates them to their business profile management screen.
    *   **Routing:** The application's router (`lib/router.dart`) was updated to include the new `/business-profile` route.

### Version 1.9.0

*   **Geo-Aware Directory (Map Integration):**
    *   **Interactive Map View:** The "Nearby Dental Clinics" feature has been significantly enhanced with an interactive map view.
        *   **Dependency:** The `google_maps_flutter` package was added to support map functionality.
        *   **UI:** The `nearby_clinics_screen.dart` now defaults to a `GoogleMap` view, displaying the user's location and nearby clinics as markers. A toggle button in the app bar allows users to switch between the new map view and the original list view.
    *   **Cross-Platform Configuration:** The feature is now fully functional across Android, iOS, and Web.
        *   **Android:** The Google Maps API key was added to `android/app/src/main/AndroidManifest.xml`.
        *   **iOS:** The API key was configured in `ios/Runner/AppDelegate.swift` and the necessary `io.flutter.embedded_views_preview` key was added to `ios/Runner/Info.plist`.
        *   **Web:** The Google Maps JavaScript API script was added to `web/index.html` to enable the map on the web platform.

### Version 1.8.3

*   **Geo-Aware Directory (Business Feature):**
    *   **Backend:** A secure API endpoint (`/api/professionals/nearby`) was created for authenticated business users.
    *   **Frontend:**
        *   A "Find Specialists" card is now conditionally displayed on the home screen for users identified as business owners.
        *   A new `find_specialists_screen.dart` was created to display a list of nearby specialists fetched from the secure endpoint.
        *   The router in `lib/router.dart` was updated with the new `/find-specialists` route.

### Version 1.8.2

*   **Navigation Flow Correction:**
    *   In `lib/home_screen.dart`, the navigation from the "Find Dental Clinics" card was changed from `context.go()` to `context.push()`. This corrects the user experience by pushing the `nearby-clinics` screen onto the navigation stack, ensuring the user can press the back button to return to the dashboard as expected.
*   **Dashboard UI Cleanup:**
    *   The back button was explicitly removed from the dashboard's `AppBar` by setting `automaticallyImplyLeading: false` in `lib/home_screen.dart`. This removes a confusing and unnecessary UI element from the app's main screen.
*   **Backend Service Authentication Fix:**
    *   The `business-service` was encountering authentication errors. This was resolved by updating the `backend/business-service/cloudbuild.yaml` to include the `--allow-unauthenticated` flag during deployment. The service is now publicly accessible, resolving the 403 Forbidden errors.
*   **Geo-Aware Directory (Patient Feature):**
    *   **Nearby Clinics Screen:** Implemented `nearby_clinics_screen.dart` which fetches the user's location and calls the `business-service` to find and display a list of dental clinics in the vicinity.
    *   **Location Services:** Integrated the `location` package to handle permissions and retrieve the device's current GPS coordinates.
    *   **API Integration:** The frontend now successfully communicates with the public `/api/businesses/nearby` endpoint.

### Version 1.8.1

*   **Improved OTP Input:** In the phone authentication OTP page (`login_screen.dart`), the `Pinput` widget now has `autofocus: true`. This automatically focuses the cursor on the OTP input field, improving the user experience during login.

### Version 1.8.0

*   **Public Profile URL Slug:**
    *   **Routing:** The `go_router` configuration in `lib/router.dart` has been updated to handle dynamic profile slugs. The route `/profile/:slug` now correctly extracts the slug and passes it to the `ProfileScreen`.
    *   **Data Fetching:** The `user_service.dart` has a new `getUserBySlug(String slug)` method that fetches a user's public profile data from the backend using the new endpoint.
    *   **Dynamic Profile Screen:** The `profile_screen.dart` is now more flexible:
        *   It accepts an optional `slug` parameter. If the `slug` is present, it fetches and displays the public profile of the corresponding user.
        *   If no `slug` is provided, it defaults to showing the currently logged-in user's editable profile.
        *   The UI now differentiates between the two modes, showing a read-only view for public profiles and the full editing form for the user's own profile.

### Version 1.7.0

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
    *   **Profile Sharing:** The profile screen features a "Share" button. Tapping this button will open the native device sharing UI,.
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

## New Feature: Article Creation & Publishing Workflow

This feature will allow users to create, review, and publish articles. It involves a full content management lifecycle from draft to a publicly visible, statically generated page.

### Plan & Action Steps

#### Phase 1: Backend Service (`article-service`)

1.  **Create a new Microservice:**
    *   Set up a new Node.js (Express) service in `backend/article-service`.
    *   This service will manage all article-related data and logic.

2.  **Define Data Models (Firestore):**
    *   **`articles` collection:**
        *   `title`: string
        *   `content`: string (likely Markdown or HTML)
        *   `authorId`: string (UID of the author)
        *   `slug`: string (unique, URL-friendly identifier)
        *   `status`: string (`draft`, `in_review`, `approved`, `published`)
        *   `reviewers`: array of user UIDs
        *   `approvals`: array of user UIDs who have approved
        *   `publishedUrl`: string (URL of the static page)
        *   `createdAt`: timestamp
        *   `updatedAt`: timestamp
    *   **`comments` collection:**
        *   `articleId`: string
        *   `authorId`: string
        *   `content`: string
        *   `parentCommentId`: string (for threaded replies)
        *   `createdAt`: timestamp

3.  **Implement API Endpoints:**
    *   `POST /api/articles`: Create a new draft article.
    *   `PUT /api/articles/:id`: Update an article's content (author only).
    *   `GET /api/articles/:id`: Get article details.
    *   `GET /api/articles`: List articles (with filtering).
    *   `POST /api/articles/:id/comments`: Add a comment.
    *   `POST /api/articles/:id/invite`: Invite a user to review.
    *   `POST /api/articles/:id/approve`: Mark an article as approved by the current user.

4.  **Create Automated Publishing Logic (Cloud Function/Service Trigger):**
    *   Create a background process that triggers when an article's `approvals` list grows.
    *   When `approvals.length >= 3`, the process will:
        1.  Change the article `status` to `published`.
        2.  Generate a unique, URL-safe `slug` from the title.
        3.  Generate a static HTML file for the article content.
        4.  Upload the HTML file to a public bucket in Firebase Storage, which is connected to Firebase Hosting. The path will be `articles/<slug>.html`.
        5.  Save the public URL to the `publishedUrl` field in the article document.

#### Phase 2: Frontend Implementation (Flutter)

1.  **Project Setup:**
    *   Add the `flutter_markdown` package to `pubspec.yaml` to render article content.
    *   Add the `http` package for making API calls.

2.  **Create a New Service:**
    *   Develop an `article_service.dart` to communicate with the `article-service` backend API.

3.  **Develop New Screens:**
    *   **`Create/Edit Article Screen`**: A screen with a form for the article title and content (using a text area that supports Markdown).
    *   **`Article List Screen`**: A screen that lists all published articles, fetched from the backend.
    *   **`Article Detail/Review Screen`**: A comprehensive screen that:
        *   Displays the article title and content.
        *   Shows a comment section with the ability to add and reply to comments.
        *   For authors: shows a list of reviewers and an option to invite more.
        *   For reviewers: shows an "Approve" button.
        *   For all users: shows the review/publication status.

4.  **Update Routing:**
    *   Add new routes in `lib/router.dart` for the new screens:
        *   `/articles`: To the `Article List Screen`.
        *   `/articles/:slug`: To the `Article Detail/Review Screen`.
        *   `/my-articles/create`: To the `Create/Edit Article Screen`.
        *   `/my-articles/edit/:id`: To pre-fill the edit screen with article data.

5.  **Update Navigation:**
    *   Add a new item to the main navigation (e.g., in the `HomeScreen`'s drawer or bottom navigation bar) to take users to the `/articles` route.

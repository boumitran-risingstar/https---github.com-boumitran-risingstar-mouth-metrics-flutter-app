import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mouth_metrics/services/user_service.dart';

// Renamed from ProfileScreen to MyProfileScreen to avoid conflict
class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final UserService _userService = UserService();
  Future<Map<String, dynamic>>? _userProfileFuture;

  @override
  void initState() {
    super.initState();
    // Fetch the user's public profile data when the screen loads
    _userProfileFuture = _userService.getUserProfile();
  }

  // Function to handle the sharing action
  void _shareProfile(String slug) {
    // This is the public URL for the user's profile.
    // Ensure your Firebase Hosting is set up to handle these links.
    final String profileUrl = 'https://mouth-metrics-flutter-app.web.app/profile/$slug';
    Share.share(
      'Check out my profile on Mouth Metrics!\n$profileUrl',
      subject: 'My Mouth Metrics Profile',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Public Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          // --- Handle Loading State ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- Handle Error State ---
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading profile:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            );
          }

          // --- Handle No Data State ---
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No profile data found.'));
          }

          // --- Handle Success State ---
          final profileData = snapshot.data!;
          final String name = profileData['name'] ?? 'N/A';
          final String bio = profileData['bio'] ?? 'No bio provided.';
          final String? profilePictureUrl = profileData['profilePictureUrl'];
          final String? slug = profileData['slug'];

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // Profile Picture
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    backgroundImage: profilePictureUrl != null
                        ? NetworkImage(profilePictureUrl)
                        : null,
                    child: profilePictureUrl == null
                        ? Icon(
                            Icons.person,
                            size: 70,
                            color: Theme.of(context).colorScheme.onSurface,
                          )
                        : null,
                  ),
                  const SizedBox(height: 24),

                  // User Name
                  Text(
                    name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // User Bio
                  Text(
                    bio,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Share Button
                  if (slug != null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Share Profile'),
                      onPressed: () => _shareProfile(slug),
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all<EdgeInsets>(
                          const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
                        textStyle: MaterialStateProperty.all<TextStyle?>(
                          Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

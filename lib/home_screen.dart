
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:mouth_metrics/main.dart';
import 'package:mouth_metrics/services/user_service.dart';
import 'package:provider/provider.dart';

import 'models/user_model.dart' as app_user;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  Future<app_user.User?>? _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _userService.syncUser();
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return FutureBuilder<app_user.User?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error ?? "User not found."}')),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _signOut(context),
              child: const Icon(Icons.logout),
              tooltip: 'Logout',
            ),
          );
        }

        final user = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: Icon(
                  themeProvider.themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: 'Toggle Theme',
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      context.push('/profile');
                      break;
                    case 'my_businesses':
                      context.push('/my-businesses');
                      break;
                    case 'business_profile':
                      context.push('/business-profile');
                      break;
                    case 'logout':
                      _signOut(context);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) {
                  final menuItems = <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'profile',
                      child: ListTile(
                        leading: Icon(Icons.person_outline),
                        title: Text('My Profile'),
                      ),
                    ),
                  ];

                  if (user.isBusinessOwner) {
                    menuItems.add(
                      const PopupMenuItem<String>(
                        value: 'my_businesses',
                        child: ListTile(
                          leading: Icon(Icons.store_mall_directory_outlined),
                          title: Text('My Businesses'),
                        ),
                      ),
                    );
                  }

                  menuItems.add(
                    const PopupMenuItem<String>(
                      value: 'business_profile',
                      child: ListTile(
                        leading: Icon(Icons.business_center_outlined),
                        title: Text('Business Profile'),
                      ),
                    ),
                  );

                  menuItems.addAll([
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: ListTile(
                        leading: Icon(Icons.logout),
                        title: Text('Logout'),
                      ),
                    ),
                  ]);

                  return menuItems;
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Welcome Header
              Text(
                'Welcome Back, ${user.name}!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),

              // Daily Tip Card
              Card(
                elevation: 2.0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Tip',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Don\'t forget to floss! It\'s as important as brushing for preventing cavities and gum disease.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Find Clinics Card
              Card(
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Find Dental Clinics'),
                  subtitle: const Text('Search for clinics near you'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => context.push('/nearby-clinics'),
                ),
              ),
              const SizedBox(height: 24),

              // Conditional "Find Specialists" Card
              if (user.isBusinessOwner)
                Card(
                  elevation: 2.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.search),
                    title: const Text('Find Specialists'),
                    subtitle: const Text('Search for specialists in your area'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => context.push('/find-specialists'),
                  ),
                ),

              const SizedBox(height: 24),

              // Article of the Day Card
              Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 2.0,
                child: Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    Image.network(
                      'https://images.pexels.com/photos/5935791/pexels-photo-5935791.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      height: 200,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black, Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'The Surprising Benefits of Oil Pulling',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

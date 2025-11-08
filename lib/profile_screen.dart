import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:mouth_metrics/services/user_service.dart';

import 'models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  final UserService _userService = UserService();
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final fba.User? currentUser = fba.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final user = await _userService.getUser(currentUser.uid);
        if (mounted && user != null) {
          setState(() {
            _user = user;
            _nameController.text = _user?.name ?? '';
            _emailController.text = _user?.email ?? '';
            _phoneNumberController.text = _user?.phoneNumber ?? '';
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load user data: $e')),
          );
        }
      }
    }
  }

  Future<void> _updateUserProfile() async {
    if (_formKey.currentState!.validate()) {
      final fba.User? currentUser = fba.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          await _userService.updateUser(
            currentUser.uid,
            name: _nameController.text,
            email: _emailController.text,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update profile: $e')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 8.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Text(
                              'Edit Your Profile',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                border: OutlineInputBorder(),
                              ),
                              enabled: false, // Phone number is not editable
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _updateUserProfile,
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mouth_metrics/models/user_model.dart' as app_user;
import 'package:mouth_metrics/services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();
  final ValueNotifier<app_user.User?> _userNotifier = ValueNotifier(null);

  bool _isSaving = false;
  bool _isProcessingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadInitialUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _userNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadInitialUserData() async {
    final user = await _fetchUserData();
    if (mounted) {
      _userNotifier.value = user;
    }
  }

  Future<app_user.User?> _fetchUserData() async {
    final fba.User? currentUser = fba.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showErrorSnackBar('You need to be logged in.');
      return null;
    }

    try {
      final user = await _userService.getUser(currentUser.uid);
      if (mounted && user != null) {
        _nameController.text = user.name ?? '';
        _bioController.text = user.bio ?? '';
        _emailController.text = user.email ?? '';
        _phoneNumberController.text = user.phoneNumber ?? '';
      }
      return user;
    } catch (e) {
      _showErrorSnackBar('Error loading user data: $e');
      return null;
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _handlePhotoAction(Future<List<app_user.Photo>> Function() action, String successMessage) async {
    if (_isProcessingPhoto) return;

    setState(() {
      _isProcessingPhoto = true;
    });

    try {
      final newGallery = await action();
      final newDefaultPhoto = newGallery.firstWhere((p) => p.isDefault, orElse: () => newGallery.isNotEmpty ? newGallery.first : app_user.Photo(id: '', url: '', isDefault: false, createdAt: DateTime.now()));
      _userNotifier.value = _userNotifier.value?.copyWith(photoGallery: newGallery, profilePictureUrl: newDefaultPhoto.url);
      _showSuccessSnackBar(successMessage);
    } catch (e) {
      String errorMessage = 'An unexpected error occurred.';
      if (e is http.ClientException) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e is Exception) {
        String exceptionString = e.toString();
        if (exceptionString.contains('Status code: 413') || exceptionString.contains('File too large')) {
            errorMessage = 'File upload failed. The file may be too large (max 2MB).';
        } else if (exceptionString.contains('html') || exceptionString.contains('Unsupported Media Type')) {
          errorMessage = 'Invalid file type. Please upload a JPEG or PNG image.';
        } else {
            errorMessage = 'Action failed: ${exceptionString.substring(0, exceptionString.length > 100 ? 100 : exceptionString.length)}';
        }
      }
      _showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPhoto = false;
        });
      }
    }
  }


  Future<void> _pickAndUploadImage() async {
    final fba.User? currentUser = fba.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile == null) return;

    await _handlePhotoAction(
      () async {
        if (kIsWeb) {
          final Uint8List imageBytes = await pickedFile.readAsBytes();
          return _userService.uploadPhotoFromBytes(currentUser.uid, imageBytes, pickedFile.name);
        } else {
          final File imageFile = File(pickedFile.path);
          return _userService.uploadPhoto(currentUser.uid, imageFile);
        }
      },
      'Photo uploaded successfully!',
    );
  }

  Future<void> _setDefaultPhoto(String photoId) async {
    final fba.User? currentUser = fba.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await _handlePhotoAction(
      () => _userService.setDefaultPhoto(currentUser.uid, photoId),
      'Default photo updated!',
    );
  }

  Future<void> _deletePhoto(String photoId) async {
    final fba.User? currentUser = fba.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      await _handlePhotoAction(
        () => _userService.deletePhoto(currentUser.uid, photoId),
        'Photo deleted successfully.',
      );
    }
  }

  Future<void> _updateUserProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      final fba.User? currentUser = fba.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          await _userService.updateUser(
            currentUser.uid,
            name: _nameController.text,
            bio: _bioController.text,
            email: _emailController.text,
          );
          _showSuccessSnackBar('Profile updated successfully');
        } catch (e) {
          _showErrorSnackBar('Failed to update profile: $e');
        } finally {
          if (mounted) {
            setState(() {
              _isSaving = false;
            });
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
        elevation: 0,
      ),
      body: ValueListenableBuilder<app_user.User?>(
        valueListenable: _userNotifier,
        builder: (context, user, child) {
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildProfileAvatar(user),
                const SizedBox(height: 24),
                _buildPhotoGallery(user),
                const SizedBox(height: 32),
                _buildProfileForm(),
                const SizedBox(height: 32),
                _buildSaveChangesButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileAvatar(app_user.User user) {
    final imageUrl = _userService.getFullPhotoUrl(user.profilePictureUrl);

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            backgroundImage: (imageUrl != null)
                ? CachedNetworkImageProvider(imageUrl)
                : null,
            child: (imageUrl == null)
                ? const Icon(Icons.person, size: 60)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: Theme.of(context).colorScheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _isProcessingPhoto ? null : _pickAndUploadImage,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _isProcessingPhoto
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.add_a_photo, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(app_user.User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('My Photo Gallery', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        user.photoGallery.isEmpty
            ? const Center(
                child: Text('Upload your first photo!'),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: user.photoGallery.length,
                itemBuilder: (context, index) {
                  final photo = user.photoGallery[index];
                  final imageUrl = _userService.getFullPhotoUrl(photo.url);
                  return GestureDetector(
                    onTap: () => _showPhotoOptions(context, photo),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imageUrl != null 
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.grey[300]),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              )
                            : Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                        ),
                        if (photo.isDefault)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Icon(Icons.star, color: Colors.yellow.shade700, size: 20),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  void _showPhotoOptions(BuildContext context, app_user.Photo photo) {
    showModalBottomSheet(
      context: context,
      builder: (builderContext) {
        return SafeArea(
          child: Wrap(
            children: [
              if (!photo.isDefault)
                ListTile(
                  leading: const Icon(Icons.star_border),
                  title: const Text('Set as Default'),
                  onTap: () {
                    Navigator.of(builderContext).pop();
                    _setDefaultPhoto(photo.id);
                  },
                ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                title: Text('Delete Photo', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () {
                  Navigator.of(builderContext).pop();
                  _deletePhoto(photo.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bioController,
            decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder()),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneNumberController,
            decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
            enabled: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveChangesButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _updateUserProfile,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isSaving
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text('Save Changes'),
    );
  }
}

// Add a copyWith method to the User model for easier state updates
extension UserCopyWith on app_user.User {
  app_user.User copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? slug,
    String? bio,
    String? profilePictureUrl,
    DateTime? createdAt,
    List<app_user.Photo>? photoGallery,
  }) {
    return app_user.User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      slug: slug ?? this.slug,
      bio: bio ?? this.bio,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      createdAt: createdAt ?? this.createdAt,
      photoGallery: photoGallery ?? this.photoGallery,
    );
  }
}

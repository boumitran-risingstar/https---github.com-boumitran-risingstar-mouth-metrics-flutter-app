
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mouth_metrics/models/business_model.dart';
import 'package:mouth_metrics/services/business_service.dart';

class BusinessProfileScreen extends StatefulWidget {
  final String? businessId;
  const BusinessProfileScreen({super.key, this.businessId});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _servicesController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

  final _businessService = BusinessService();
  bool _isLoading = false;
  Business? _existingBusiness;

  @override
  void initState() {
    super.initState();
    if (widget.businessId != null) {
      _loadBusinessData();
    }
  }

  Future<void> _loadBusinessData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final business = await _businessService.getBusinessById(widget.businessId!);
      setState(() {
        _existingBusiness = business;
        _nameController.text = business.name;
        _addressController.text = business.location.toString(); // Simplified for now
        _phoneController.text = ''; // Add phone to model
        _servicesController.text = business.services.join(', ');
        _descriptionController.text = business.description;
        _categoryController.text = business.category;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load business data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.businessId == null ? 'Create Business Profile' : 'Edit Business Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Clinic Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your clinic name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your clinic address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _servicesController,
                      decoration: const InputDecoration(
                        labelText: 'Services Offered (comma-separated)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text('Save Profile'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not authenticated');
        }

        // NOTE: Location handling needs to be improved.
        // For now, we are not updating it properly.
        final business = Business(
          id: _existingBusiness?.id,
          name: _nameController.text,
          description: _descriptionController.text,
          image: _existingBusiness?.image ?? '',
          services: _servicesController.text.split(',').map((s) => s.trim()).toList(),
          location: _existingBusiness?.location ?? const GeoPoint(0, 0),
          category: _categoryController.text,
          ownerId: user.uid,
          slug: _existingBusiness?.slug,
          geohash: _existingBusiness?.geohash ?? '',
        );

        if (widget.businessId == null) {
          await _businessService.createBusiness(business);
        } else {
          await _businessService.updateBusiness(business);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
        // Go back to the list of businesses after saving.
        context.go('/my-businesses');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _servicesController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}

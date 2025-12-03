
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mouth_metrics/models/business_model.dart';
import 'package:mouth_metrics/services/business_service.dart';

class MyBusinessesScreen extends StatefulWidget {
  const MyBusinessesScreen({super.key});

  @override
  State<MyBusinessesScreen> createState() => _MyBusinessesScreenState();
}

class _MyBusinessesScreenState extends State<MyBusinessesScreen> {
  final BusinessService _businessService = BusinessService();
  late Future<List<Business>> _myBusinessesFuture;

  @override
  void initState() {
    super.initState();
    _myBusinessesFuture = _businessService.getMyBusinesses();
  }

  void _refreshBusinesses() {
    setState(() {
      _myBusinessesFuture = _businessService.getMyBusinesses();
    });
  }

  Future<void> _deleteBusiness(String businessId) async {
    try {
      await _businessService.deleteBusiness(businessId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business deleted successfully!')),
      );
      _refreshBusinesses();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete business: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Businesses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined),
            tooltip: 'Create Business',
            onPressed: () => context.push('/business-profile'),
          ),
        ],
      ),
      body: FutureBuilder<List<Business>>(
        future: _myBusinessesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('You have not created any businesses yet.'),
            );
          }

          final businesses = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _refreshBusinesses(),
            child: ListView.builder(
              itemCount: businesses.length,
              itemBuilder: (context, index) {
                final business = businesses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    title: Text(business.name),
                    subtitle: Text(business.category),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit',
                          onPressed: () {
                            context.push('/business-profile?businessId=${business.id}');
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete',
                          onPressed: () => _showDeleteConfirmation(business.id!),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(String businessId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this business?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteBusiness(businessId);
              },
            ),
          ],
        );
      },
    );
  }
}


import 'package:flutter/material.dart';
import 'package:mouth_metrics/models/business_model.dart';
import 'package:mouth_metrics/services/business_service.dart';

class FindSpecialistsScreen extends StatefulWidget {
  const FindSpecialistsScreen({super.key});

  @override
  State<FindSpecialistsScreen> createState() => _FindSpecialistsScreenState();
}

class _FindSpecialistsScreenState extends State<FindSpecialistsScreen> {
  final BusinessService _businessService = BusinessService();
  Future<List<Business>>? _specialistsFuture;

  @override
  void initState() {
    super.initState();
    // TODO: Replace with actual user location
    _specialistsFuture = _businessService.findNearbyBusinesses(0, 0); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Specialists'),
      ),
      body: FutureBuilder<List<Business>>(
        future: _specialistsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No specialists found near you.'));
          }

          final specialists = snapshot.data!;

          return ListView.builder(
            itemCount: specialists.length,
            itemBuilder: (context, index) {
              final specialist = specialists[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListTile(
                  title: Text(specialist.name),
                  subtitle: Text(specialist.category),
                  onTap: () {
                    // TODO: Handle specialist tap, maybe navigate to a detail screen
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

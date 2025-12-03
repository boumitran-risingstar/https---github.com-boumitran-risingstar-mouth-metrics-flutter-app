import 'package:flutter/material.dart';
import 'package:mouth_metrics/services/user_service.dart';
import 'package:mouth_metrics/models/user_model.dart';

class FindSpecialistsScreen extends StatefulWidget {
  const FindSpecialistsScreen({Key? key}) : super(key: key);

  @override
  State<FindSpecialistsScreen> createState() => _FindSpecialistsScreenState();
}

class _FindSpecialistsScreenState extends State<FindSpecialistsScreen> {
  final UserService _userService = UserService();
  Future<List<User>>? _nearbySpecialists;

  @override
  void initState() {
    super.initState();
    _fetchNearbySpecialists();
  }

  void _fetchNearbySpecialists() {
    setState(() {
      _nearbySpecialists = _userService.findNearbyProfessionals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Specialists'),
      ),
      body: FutureBuilder<List<User>>(
        future: _nearbySpecialists,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No specialists found nearby.'));
          }

          final specialists = snapshot.data!;

          return ListView.builder(
            itemCount: specialists.length,
            itemBuilder: (context, index) {
              final specialist = specialists[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: specialist.profilePictureUrl != null
                        ? NetworkImage(specialist.profilePictureUrl!)
                        : null,
                    child: specialist.profilePictureUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(specialist.name!),
                  subtitle: Text(specialist.userType),
                  trailing: const Text(''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
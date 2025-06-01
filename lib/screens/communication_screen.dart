import 'package:flutter/material.dart';

class CommunicationScreen extends StatelessWidget {
  const CommunicationScreen({Key? key}) : super(key: key);

  final List<Map<String, String>> _providers = const [
    {'name': 'Dr. John Mwangi', 'specialty': 'General Physician'},
    {'name': 'Nurse Amina Hassan', 'specialty': 'Nursing'},
    {'name': 'Dr. James Otieno', 'specialty': 'Pharmacist'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Healthcare Providers'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: _providers.length,
        itemBuilder: (context, index) {
          final provider = _providers[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(provider['name']!),
              subtitle: Text(provider['specialty']!),
              trailing: const Icon(Icons.chat),
              onTap: () {
                // TODO: Open chat or communication method
              },
            ),
          );
        },
      ),
    );
  }
}

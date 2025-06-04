import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  bool isUserRegistered = false;
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userEmailController = TextEditingController();

  final TextEditingController _providerNameController = TextEditingController();
  final TextEditingController _providerCategoryController =
      TextEditingController();
  final TextEditingController _providerEmailController =
      TextEditingController();
  final TextEditingController _providerWhatsAppController =
      TextEditingController();

  final List<Map<String, String>> _providers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DoziYangu - Communication'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 4,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.medical_services),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            isUserRegistered
                ? _buildProviderSection()
                : _buildUserRegistration(),
      ),
    );
  }

  // 1. USER REGISTRATION
  Widget _buildUserRegistration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Register to Continue',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _userNameController,
          decoration: const InputDecoration(labelText: 'Your Name'),
        ),
        TextField(
          controller: _userEmailController,
          decoration: const InputDecoration(labelText: 'Your Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            if (_userNameController.text.isNotEmpty &&
                _userEmailController.text.isNotEmpty) {
              setState(() => isUserRegistered = true);
            } else {
              _showSnack('Please fill in all fields.');
            }
          },
          child: const Text('Register'),
        ),
      ],
    );
  }

  // 2. PROVIDER LIST + ADD BUTTON
  Widget _buildProviderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, ${_userNameController.text}',
          style: const TextStyle(fontSize: 18),
        ),
        Text(
          'Email: ${_userEmailController.text}',
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
        const Divider(height: 30),
        const Text(
          'Your Providers:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Expanded(
          child:
              _providers.isEmpty
                  ? const Center(child: Text('No providers registered yet.'))
                  : ListView.builder(
                    itemCount: _providers.length,
                    itemBuilder: (context, index) {
                      final provider = _providers[index];
                      return Card(
                        elevation: 3,
                        child: ListTile(
                          title: Text(
                            '${provider['name']} (${provider['category']})',
                          ),
                          subtitle: Text(
                            'Email: ${provider['email']}\nWhatsApp: ${provider['whatsapp']}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'email') {
                                _contactViaEmail(provider['email']!);
                              } else if (value == 'whatsapp') {
                                _contactViaWhatsApp(provider['whatsapp']!);
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: 'email',
                                    child: Text('Contact via Email'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'whatsapp',
                                    child: Text('Contact via WhatsApp'),
                                  ),
                                ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton.icon(
            onPressed: _showAddProviderDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Add Provider'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          ),
        ),
      ],
    );
  }

  // 3. PROVIDER REGISTRATION FORM DIALOG
  void _showAddProviderDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Provider'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _providerNameController,
                  decoration: const InputDecoration(labelText: 'Provider Name'),
                ),
                TextField(
                  controller: _providerCategoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: _providerEmailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: _providerWhatsAppController,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp Number',
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _providerNameController.clear();
                _providerCategoryController.clear();
                _providerEmailController.clear();
                _providerWhatsAppController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_providerNameController.text.isNotEmpty &&
                    _providerCategoryController.text.isNotEmpty &&
                    _providerEmailController.text.isNotEmpty &&
                    _providerWhatsAppController.text.isNotEmpty) {
                  setState(() {
                    _providers.add({
                      'name': _providerNameController.text,
                      'category': _providerCategoryController.text,
                      'email': _providerEmailController.text,
                      'whatsapp': _providerWhatsAppController.text,
                    });
                  });
                  _providerNameController.clear();
                  _providerCategoryController.clear();
                  _providerEmailController.clear();
                  _providerWhatsAppController.clear();
                  Navigator.pop(context);
                } else {
                  _showSnack('Please fill all fields.');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // 4. UTILITIES
  void _contactViaEmail(String toEmail) async {
    final userEmail = _userEmailController.text;
    final uri = Uri(
      scheme: 'mailto',
      path: toEmail,
      query:
          'subject=Health Inquiry&body=Hello,\n\nThis is $userEmail. I need assistance.',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnack('Could not launch email app');
    }
  }

  void _contactViaWhatsApp(String phone) async {
    final number = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$number?text=Hello%20Doctor');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Could not open WhatsApp');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

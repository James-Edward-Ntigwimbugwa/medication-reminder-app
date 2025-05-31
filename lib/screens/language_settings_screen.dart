import 'package:flutter/material.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = 'Swahili';

  final Map<String, String> _languages = {
    'Swahili': 'Swahili (Kiswahili)',
    'English': 'English',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Language Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children:
            _languages.entries.map((entry) {
              return RadioListTile<String>(
                title: Text(entry.value),
                value: entry.key,
                groupValue: _selectedLanguage,
                onChanged: (val) {
                  setState(() {
                    _selectedLanguage = val!;
                    // TODO: Integrate app-wide localization support
                  });
                },
              );
            }).toList(),
      ),
    );
  }
}

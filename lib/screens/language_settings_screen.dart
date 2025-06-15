import 'package:flutter/material.dart';
import '../main.dart';
import 'package:doziyangu/l10n/l10n.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settings),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.language,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.selectLanguage,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const Divider(height: 20),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.teal),
              title: Text(localizations.english),
              trailing:
                  currentLocale.languageCode == 'en'
                      ? const Icon(Icons.check, color: Colors.teal)
                      : null,
              onTap: () {
                MyApp.setLocale(context, const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.teal),
              title: Text(localizations.swahili),
              trailing:
                  currentLocale.languageCode == 'sw'
                      ? const Icon(Icons.check, color: Colors.teal)
                      : null,
              onTap: () {
                MyApp.setLocale(context, const Locale('sw'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

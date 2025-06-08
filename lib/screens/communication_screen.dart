import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  bool isUserRegistered = false;
  bool isUserLoggedIn = false;
  bool isLoading = false;
  bool _hasInitialized = false;

  // User controllers
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userEmailController = TextEditingController();
  final TextEditingController _userPasswordController = TextEditingController();
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();

  // Provider controllers
  final TextEditingController _providerNameController = TextEditingController();
  final TextEditingController _providerCategoryController =
      TextEditingController();
  final TextEditingController _providerEmailController =
      TextEditingController();
  final TextEditingController _providerWhatsAppController =
      TextEditingController();

  final List<Map<String, String>> _providers = [];
  bool _isPasswordVisible = false;
  bool _isLoginPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _setupPeriodicBackup();
  }

  void _setupPeriodicBackup() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted && _providers.isNotEmpty) {
        _createDataBackup();
      }
    });
  }

  Future<void> _initializeApp() async {
    if (!_hasInitialized) {
      setState(() => isLoading = true);
      await _loadUserData();
      _hasInitialized = true;
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _userEmailController.dispose();
    _userPasswordController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _providerNameController.dispose();
    _providerCategoryController.dispose();
    _providerEmailController.dispose();
    _providerWhatsAppController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isRegistered = prefs.getBool('isUserRegistered') ?? false;
      final isLoggedIn = prefs.getBool('isUserLoggedIn') ?? false;

      if (isRegistered && isLoggedIn) {
        _userNameController.text = prefs.getString('userName') ?? '';
        _userEmailController.text = prefs.getString('userEmail') ?? '';
        await _loadProviders();
        if (!await _validateBackup()) {
          debugPrint('Backup validation failed, attempting recovery...');
          await _recoverProvidersFromBackup();
        }
        await prefs.setInt(
          'last_app_access',
          DateTime.now().millisecondsSinceEpoch,
        );
      }

      if (mounted) {
        setState(() {
          isUserRegistered = isRegistered;
          isUserLoggedIn = isLoggedIn;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      await _recoverUserDataFromBackup();
    }
  }

  Future<void> _recoverUserDataFromBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupJson = prefs.getString('user_data_backup');
      if (backupJson != null && backupJson.isNotEmpty) {
        try {
          final userData = json.decode(backupJson) as Map<String, dynamic>;
          _userNameController.text = userData['name']?.toString() ?? '';
          _userEmailController.text = userData['email']?.toString() ?? '';
          if (mounted) {
            setState(() {
              isUserRegistered = true;
              isUserLoggedIn = true;
            });
          }
          _showSnack('User data recovered from backup');
        } catch (e) {
          debugPrint('Error decoding user backup: $e');
          _showSnack('Failed to decode user backup');
        }
      }
    } catch (e) {
      debugPrint('Error recovering user data: $e');
      _showSnack('Failed to recover user data');
    }
  }

  Future<void> _saveUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isUserRegistered', true);
      await prefs.setBool('isUserLoggedIn', true);
      await prefs.setString('userName', _userNameController.text.trim());
      await prefs.setString('userEmail', _userEmailController.text.trim());
      final hashedPassword = _hashPassword(_userPasswordController.text);
      await prefs.setString('userPassword', hashedPassword);
      await prefs.setInt(
        'user_registered_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      final userData = {
        'name': _userNameController.text.trim(),
        'email': _userEmailController.text.trim(),
        'registrationDate': DateTime.now().toIso8601String(),
      };
      await prefs.setString('user_data_backup', json.encode(userData));
      debugPrint('User data saved successfully');
    } catch (e) {
      debugPrint('Error saving user data: $e');
      _showSnack('Error saving user data');
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<void> _loadProviders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final providersJson = prefs.getString('providers');
      debugPrint('Loading providers JSON: $providersJson');
      if (providersJson != null && providersJson.isNotEmpty) {
        try {
          final decoded = json.decode(providersJson);
          if (decoded is List &&
              decoded.every(
                (item) => item is Map && item.containsKey('name'),
              )) {
            if (mounted) {
              setState(() {
                _providers.clear();
                _providers.addAll(decoded.cast<Map<String, String>>());
              });
            }
            await prefs.setInt(
              'providers_last_accessed',
              DateTime.now().millisecondsSinceEpoch,
            );
            debugPrint('Providers loaded: ${_providers.length} entries');
          } else {
            debugPrint('Invalid providers JSON format');
            await _recoverProvidersFromBackup();
          }
        } catch (e) {
          debugPrint('Error decoding providers: $e');
          await _recoverProvidersFromBackup();
        }
      }
    } catch (e) {
      debugPrint('Error loading providers: $e');
      await _recoverProvidersFromBackup();
    }
  }

  Future<void> _saveProviders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Validate providers before saving
      for (var provider in _providers) {
        if (!provider.containsKey('name') ||
            !provider.containsKey('category') ||
            !provider.containsKey('email') ||
            !provider.containsKey('whatsapp')) {
          throw Exception('Invalid provider data: $provider');
        }
      }
      final providersJson = json.encode(_providers);
      // Write to temporary key first
      await prefs.setString('providers_temp', providersJson);
      await prefs.setString('providers', providersJson);
      await prefs.setString('providers_backup', providersJson);
      await prefs.remove('providers_temp');
      await prefs.setInt(
        'providers_saved_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
      await prefs.setInt('providers_count', _providers.length);
      debugPrint('Providers saved with ${_providers.length} entries');
    } catch (e) {
      debugPrint('Error saving providers: $e');
      _showSnack('Failed to save providers');
      try {
        final prefs = await SharedPreferences.getInstance();
        final minimalData =
            _providers
                .map(
                  (p) => {
                    'name': p['name'] ?? '',
                    'category': p['category'] ?? '',
                    'email': p['email'] ?? '',
                    'whatsapp': p['whatsapp'] ?? '',
                  },
                )
                .toList();
        await prefs.setString('providers_backup', json.encode(minimalData));
        debugPrint('Minimal provider backup saved');
      } catch (fallbackError) {
        debugPrint('Error saving minimal backup: $fallbackError');
      }
    }
  }

  Future<bool> _validateBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCount = prefs.getInt('providers_count') ?? 0;
      final backupJson = prefs.getString('providers_backup');
      if (backupJson != null && backupJson.isNotEmpty) {
        final decoded = json.decode(backupJson);
        if (decoded is List) {
          return decoded.length == savedCount;
        }
      }
      return savedCount == _providers.length;
    } catch (e) {
      debugPrint('Error validating backup: $e');
      return false;
    }
  }

  Future<void> _recoverProvidersFromBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? backupJson = prefs.getString('providers_backup');
      debugPrint('Recovering providers backup JSON: $backupJson');
      if (backupJson == null || backupJson.isEmpty) {
        backupJson = prefs.getString('complete_data_backup');
        if (backupJson != null && backupJson.isNotEmpty) {
          try {
            final backupData = json.decode(backupJson) as Map<String, dynamic>;
            if (backupData['providers'] != null) {
              backupJson = json.encode(backupData['providers']);
              debugPrint(
                'Extracted providers from complete backup: $backupJson',
              );
            } else {
              backupJson = null;
            }
          } catch (e) {
            debugPrint('Error extracting providers from complete backup: $e');
            backupJson = null;
          }
        }
      }

      if (backupJson != null && backupJson.isNotEmpty) {
        try {
          final decoded = json.decode(backupJson);
          if (decoded is List &&
              decoded.every(
                (item) => item is Map && item.containsKey('name'),
              )) {
            if (mounted) {
              setState(() {
                _providers.clear();
                _providers.addAll(
                  decoded.map(
                    (item) => Map<String, String>.from(
                      item.map((k, v) => MapEntry(k, v?.toString() ?? '')),
                    ),
                  ),
                );
              });
            }
            await _saveProviders();
            debugPrint('Providers recovered: ${_providers.length} entries');
            _showSnack('Providers recovered from backup');
          } else {
            debugPrint('Invalid provider backup format: $decoded');
            await prefs.remove('providers_backup');
            _showSnack('Cleared invalid provider backup');
          }
        } catch (e) {
          debugPrint('Error decoding provider backup: $e');
          await prefs.remove('providers_backup');
          _showSnack(
            'Failed to decode provider backup, cleared corrupted data',
          );
        }
      } else {
        debugPrint('No provider backup found');
        _showSnack('No provider backup available');
      }
    } catch (e) {
      debugPrint('Error recovering providers: $e');
      _showSnack('Failed to recover providers');
    }
  }

  Future<void> _debugStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final providers = prefs.getString('providers') ?? 'null';
      final backup = prefs.getString('providers_backup') ?? 'null';
      final completeBackup = prefs.getString('complete_data_backup') ?? 'null';
      int providerCount = 0;
      try {
        if (providers != 'null') {
          final decoded = json.decode(providers);
          providerCount = decoded is List ? decoded.length : 0;
        }
      } catch (e) {
        debugPrint('Error parsing providers for debug: $e');
      }
      debugPrint('=== Debug Storage ===');
      debugPrint('Providers (count: $providerCount): $providers');
      debugPrint('Backup: $backup');
      debugPrint('Complete Backup: $completeBackup');
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Debug Storage'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Providers Count: $providerCount'),
                    const SizedBox(height: 8),
                    Text('Clear corrupted backup?'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await prefs.remove('providers');
                      await prefs.remove('providers_backup');
                      await prefs.remove('complete_data_backup');
                      if (mounted) {
                        Navigator.pop(context);
                        _showSnack('Cleared backup data');
                      }
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      debugPrint('Error debugging storage: $e');
      _showSnack('Failed to debug storage');
    }
  }

  Future<void> _createDataBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupData = {
        'providers': _providers,
        'userData': {
          'name': _userNameController.text,
          'email': _userEmailController.text,
        },
        'backupTimestamp': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
      };
      final backupJson = json.encode(backupData);
      await prefs.setString('complete_data_backup', backupJson);
      debugPrint('Complete data backup created');
    } catch (e) {
      debugPrint('Error creating backup: $e');
      _showSnack('Failed to create backup');
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  bool _isValidWhatsAppNumber(String number) {
    return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DoziYangu - Communication'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 4,
        actions: [
          if (isUserRegistered && isUserLoggedIn)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  _logout();
                } else if (value == 'recover') {
                  _recoverProvidersFromBackup();
                } else if (value == 'debug') {
                  _debugStorage();
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(value: 'logout', child: Text('Logout')),
                    const PopupMenuItem(
                      value: 'recover',
                      child: Text('Recover Providers'),
                    ),
                    const PopupMenuItem(
                      value: 'debug',
                      child: Text('Debug Storage'),
                    ),
                  ],
            ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.medical_services),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildCurrentView(),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    if (!isUserRegistered) {
      return _buildRegistrationView();
    } else if (!isUserLoggedIn) {
      return _buildLoginView();
    } else {
      return _buildProviderSection();
    }
  }

  Widget _buildRegistrationView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Your Account',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Register to manage your healthcare providers',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _userNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _userEmailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _userPasswordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password (min 6 characters)',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed:
                    () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Create Account',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already have an account? '),
              TextButton(
                onPressed:
                    () => setState(() {
                      isUserRegistered = true;
                      isUserLoggedIn = false;
                    }),
                child: const Text('Login'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoginView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome Back',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Login to access your healthcare providers',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _loginEmailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _loginPasswordController,
            obscureText: !_isLoginPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _isLoginPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed:
                    () => setState(
                      () => _isLoginPasswordVisible = !_isLoginPasswordVisible,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Login', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account? "),
              TextButton(
                onPressed:
                    () => setState(() {
                      isUserRegistered = false;
                      isUserLoggedIn = false;
                    }),
                child: const Text('Register'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${_userNameController.text}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Email: ${_userEmailController.text}',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Your Healthcare Providers',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Expanded(
          child:
              _providers.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medical_services,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No providers registered yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first healthcare provider to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showAddProviderDialog(),
                          icon: const Icon(Icons.person_add, size: 20),
                          label: const Text('Add Provider'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _providers.length,
                          itemBuilder: (context, index) {
                            final provider = _providers[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.teal.shade100,
                                  child: Icon(
                                    _getCategoryIcon(
                                      provider['category'] ?? '',
                                    ),
                                    color: Colors.teal,
                                  ),
                                ),
                                title: Text(
                                  provider['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Category: ${provider['category']}'),
                                    Text('Email: ${provider['email']}'),
                                    Text('WhatsApp: ${provider['whatsapp']}'),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'email') {
                                      _contactViaEmail(provider['email']!);
                                    } else if (value == 'whatsapp') {
                                      _contactViaWhatsApp(
                                        provider['whatsapp']!,
                                      );
                                    } else if (value == 'edit') {
                                      _editProvider(index);
                                    } else if (value == 'delete') {
                                      _deleteProvider(index);
                                    }
                                  },
                                  itemBuilder:
                                      (context) => [
                                        const PopupMenuItem(
                                          value: 'email',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.email,
                                                size: 18,
                                                color: Colors.blue,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Email'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'whatsapp',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.chat,
                                                size: 18,
                                                color: Colors.green,
                                              ),
                                              SizedBox(width: 8),
                                              Text('WhatsApp'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 18),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                size: 18,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddProviderDialog(),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add New Provider'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'doctor':
      case 'physician':
        return Icons.medical_services;
      case 'dentist':
        return Icons.medical_information;
      case 'nurse':
        return Icons.local_hospital;
      case 'pharmacist':
        return Icons.local_pharmacy;
      case 'therapist':
        return Icons.psychology;
      default:
        return Icons.person;
    }
  }

  Future<void> _register() async {
    setState(() => isLoading = true);
    try {
      if (_userNameController.text.trim().isEmpty) {
        _showSnack('Please enter your full name');
        return;
      }
      if (!_isValidEmail(_userEmailController.text.trim())) {
        _showSnack('Please enter a valid email address');
        return;
      }
      if (!_isValidPassword(_userPasswordController.text)) {
        _showSnack('Password must be at least 6 characters long');
        return;
      }
      await _saveUserData();
      if (mounted) {
        setState(() {
          isUserRegistered = true;
          isUserLoggedIn = true;
        });
      }
      _showSnack('Account created successfully!');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _login() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('userEmail') ?? '';
      final savedPassword = prefs.getString('userPassword') ?? '';
      final inputPassword = _hashPassword(_loginPasswordController.text);

      if (_loginEmailController.text.trim() != savedEmail ||
          inputPassword != savedPassword) {
        _showSnack('Invalid email or password');
        return;
      }

      _userNameController.text = prefs.getString('userName') ?? '';
      _userEmailController.text = savedEmail;
      await prefs.setBool('isUserLoggedIn', true);
      await _loadProviders();
      if (mounted) {
        setState(() => isUserLoggedIn = true);
      }
      _showSnack('Welcome back!');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isUserLoggedIn', false);
      if (mounted) {
        setState(() {
          isUserLoggedIn = false;
          _loginEmailController.clear();
          _loginPasswordController.clear();
        });
      }
      _showSnack('Logged out successfully');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _showAddProviderDialog([int? editIndex]) async {
    if (editIndex != null) {
      final provider = _providers[editIndex];
      _providerNameController.text = provider['name'] ?? '';
      _providerCategoryController.text = provider['category'] ?? '';
      _providerEmailController.text = provider['email'] ?? '';
      _providerWhatsAppController.text = provider['whatsapp'] ?? '';
    } else {
      _clearProviderFields();
    }

    if (mounted) {
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(editIndex != null ? 'Edit Provider' : 'Add Provider'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _providerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Provider Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _providerCategoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category (e.g., Doctor, Dentist)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _providerEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _providerWhatsAppController,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp Number (e.g., +1234567890)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _clearProviderFields();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => _saveProvider(editIndex),
                  child: Text(editIndex != null ? 'Update' : 'Save'),
                ),
              ],
            ),
      );
    }
  }

  void _editProvider(int index) {
    _showAddProviderDialog(index);
  }

  Future<void> _saveProvider([int? editIndex]) async {
    setState(() => isLoading = true);
    try {
      if (_providerNameController.text.trim().isEmpty ||
          _providerCategoryController.text.trim().isEmpty ||
          _providerEmailController.text.trim().isEmpty ||
          _providerWhatsAppController.text.trim().isEmpty) {
        _showSnack('Please fill all fields');
        return;
      }
      if (!_isValidEmail(_providerEmailController.text.trim())) {
        _showSnack('Please enter a valid email address');
        return;
      }
      if (!_isValidWhatsAppNumber(_providerWhatsAppController.text.trim())) {
        _showSnack('Please enter a valid WhatsApp number (e.g., +1234567890)');
        return;
      }

      final provider = {
        'name': _providerNameController.text.trim(),
        'category': _providerCategoryController.text.trim(),
        'email': _providerEmailController.text.trim(),
        'whatsapp': _providerWhatsAppController.text.trim(),
        'dateAdded':
            editIndex != null
                ? _providers[editIndex]['dateAdded'] ??
                    DateTime.now().toIso8601String()
                : DateTime.now().toIso8601String(),
        'id':
            editIndex?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
      };
      if (editIndex != null) {
        provider['dateModified'] = DateTime.now().toIso8601String();
      }

      if (mounted) {
        setState(() {
          if (editIndex != null) {
            _providers[editIndex] = provider;
          } else {
            _providers.add(provider);
          }
        });
      }

      await _saveProviders();
      _clearProviderFields();
      if (mounted) {
        Navigator.of(context).pop();
        _showSnack(
          editIndex != null
              ? 'Provider updated successfully!'
              : 'Provider added successfully!',
        );
      }
      await _createDataBackup();
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _deleteProvider(int index) async {
    if (mounted) {
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Delete Provider'),
              content: Text(
                'Are you sure you want to delete ${_providers[index]['provider']}?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setState(() => isLoading = true);
                    try {
                      if (mounted) {
                        setState(() {
                          _providers.removeAt(index);
                        });
                      }
                      await _saveProviders();
                      await _createDataBackup();
                      if (mounted) {
                        Navigator.pop(context);
                        _showSnack('Provider deleted successfully');
                      }
                    } finally {
                      if (mounted) {
                        setState(() => isLoading = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
      );
    }
  }

  void _clearProviderFields() {
    _providerNameController.clear();
    _providerCategoryController.clear();
    _providerEmailController.clear();
    _providerWhatsAppController.clear();
  }

  Future<void> _contactViaEmail(String toEmail) async {
    setState(() => isLoading = true);
    try {
      if (!_isValidEmail(toEmail)) {
        if (mounted) {
          _showSnack('Invalid email address');
        }
        return;
      }

      final uri = Uri.parse('mailto:$toEmail');
      debugPrint('Launching email URI: $uri');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      debugPrint('Email app launched successfully');
    } catch (e) {
      debugPrint('Error launching email: $e');
      if (mounted) {
        _showSnack(
          'Failed to open email app for $toEmail. Please open your email app and send to $toEmail.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _contactViaWhatsApp(String phone) async {
    setState(() => isLoading = true);
    try {
      final number = phone.replaceAll(RegExp(r'\D'), '');
      final fullNumber = '+$number';
      if (!_isValidWhatsAppNumber(fullNumber)) {
        if (mounted) {
          _showSnack('Invalid WhatsApp number. Use format like +1234567890.');
        }
        return;
      }

      final uri = Uri.parse('https://api.whatsapp.com/send?phone=$number');
      debugPrint('Launching WhatsApp URI: $uri');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      debugPrint('WhatsApp launched successfully');
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
      if (mounted) {
        _showSnack(
          'Failed to open WhatsApp for $phone. Please open WhatsApp and message $phone.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showSnack(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
      );
    }
  }
}

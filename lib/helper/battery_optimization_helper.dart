// battery_optimization_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class BatteryOptimizationHelper {
  static const MethodChannel _channel = MethodChannel('battery_optimization');

  /// Check if battery optimization is disabled for the app
  static Future<bool> isBatteryOptimizationDisabled() async {
    try {
      final bool result = await _channel.invokeMethod('isBatteryOptimizationDisabled');
      return result;
    } on PlatformException catch (e) {
      print('Error checking battery optimization: ${e.message}');
      return false;
    }
  }

  /// Request to disable battery optimization
  static Future<bool> requestDisableBatteryOptimization() async {
    try {
      final bool result = await _channel.invokeMethod('requestDisableBatteryOptimization');
      return result;
    } on PlatformException catch (e) {
      print('Error requesting battery optimization disable: ${e.message}');
      return false;
    }
  }

  /// Show dialog to guide user to disable battery optimization
  static void showBatteryOptimizationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.battery_alert, color: Colors.orange),
            SizedBox(width: 8),
            Text('Battery Optimization'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For reliable medication reminders, please disable battery optimization for this app.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Steps:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('1. Tap "Open Settings" below'),
            Text('2. Find this app in the list'),
            Text('3. Select "Don\'t optimize"'),
            Text('4. Tap "Done"'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Without this, alarms may be delayed or not work when the screen is off.',
                      style: TextStyle(fontSize: 14, color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await requestDisableBatteryOptimization();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Check and request all necessary permissions
  static Future<Map<String, bool>> checkAllPermissions() async {
    final results = <String, bool>{};

    // Check notification permission
    results['notification'] = await Permission.notification.isGranted;

    // Check exact alarm permission
    results['exactAlarm'] = await Permission.scheduleExactAlarm.isGranted;

    // Check system alert window permission (for overlay)
    results['systemAlertWindow'] = await Permission.systemAlertWindow.isGranted;

    // Check battery optimization
    results['batteryOptimization'] = await isBatteryOptimizationDisabled();

    return results;
  }

  /// Request all necessary permissions
  static Future<bool> requestAllPermissions(BuildContext context) async {
    bool allGranted = true;

    // Request notification permission
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        allGranted = false;
        print('Notification permission denied');
      }
    }

    // Request exact alarm permission
    if (await Permission.scheduleExactAlarm.isDenied) {
      final status = await Permission.scheduleExactAlarm.request();
      if (!status.isGranted) {
        allGranted = false;
        print('Exact alarm permission denied');
      }
    }

    // Request system alert window permission
    if (await Permission.systemAlertWindow.isDenied) {
      final status = await Permission.systemAlertWindow.request();
      if (!status.isGranted) {
        allGranted = false;
        print('System alert window permission denied');
      }
    }

    // Check battery optimization
    if (!await isBatteryOptimizationDisabled()) {
      showBatteryOptimizationDialog(context);
    }

    return allGranted;
  }
}

// Widget to show permission status
class PermissionStatusWidget extends StatefulWidget {
  const PermissionStatusWidget({super.key});

  @override
  _PermissionStatusWidgetState createState() => _PermissionStatusWidgetState();
}

class _PermissionStatusWidgetState extends State<PermissionStatusWidget> {
  Map<String, bool> _permissions = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final permissions = await BatteryOptimizationHelper.checkAllPermissions();
    setState(() {
      _permissions = permissions;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permission Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ...(_permissions.entries.map((entry) => _buildPermissionRow(entry.key, entry.value))),
            SizedBox(height: 16),
            if (_permissions.values.any((granted) => !granted))
              ElevatedButton(
                onPressed: () async {
                  await BatteryOptimizationHelper.requestAllPermissions(context);
                  _checkPermissions();
                },
                child: Text('Fix Permissions'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRow(String permission, bool granted) {
    final String displayName = _getDisplayName(permission);
    final Color color = granted ? Colors.green : Colors.red;
    final IconData icon = granted ? Icons.check_circle : Icons.cancel;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(fontSize: 16),
            ),
          ),
          Text(
            granted ? 'Granted' : 'Denied',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayName(String permission) {
    switch (permission) {
      case 'notification':
        return 'Notifications';
      case 'exactAlarm':
        return 'Exact Alarms';
      case 'systemAlertWindow':
        return 'Display over other apps';
      case 'batteryOptimization':
        return 'Battery optimization disabled';
      default:
        return permission;
    }
  }
}
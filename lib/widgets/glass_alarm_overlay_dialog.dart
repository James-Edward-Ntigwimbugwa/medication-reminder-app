// glass_alarm_overlay_dialog.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../database/medication_db.dart';
import '../models/medication.dart';

class AlarmOverlayDialog extends StatefulWidget {
  final String? payload;
  final VoidCallback? onDismiss;

  const AlarmOverlayDialog({
    Key? key,
    this.payload,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<AlarmOverlayDialog> createState() => _AlarmOverlayDialogState();
}

class _AlarmOverlayDialogState extends State<AlarmOverlayDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _pulseAnimation;

  Medication? _medication;
  int _medicationId = 0;
  int _reminderIndex = 0;
  String _medicationName = '';
  String _dose = '';
  String _time = '';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _parsePayload();
    _animationController.forward();
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _parsePayload() async {
    if (widget.payload != null) {
      final parts = widget.payload!.split(':');
      if (parts.length == 2) {
        _medicationId = int.tryParse(parts[0]) ?? 0;
        _reminderIndex = int.tryParse(parts[1]) ?? 0;

        // Cancel scheduled notification
        final notificationId = NotificationService.generateNotificationId(_medicationId, _reminderIndex);
        await NotificationService.cancelSpecificNotification(notificationId);

        try {
          final medications = await MedicationDB.instance.readAllMedications();
          _medication = medications.firstWhere(
                (m) => m.id == _medicationId,
            orElse: () => Medication(
              name: 'Unknown Medication',
              unit: '',
              frequency: '',
              reminderTimes: [],
              doses: [],
              takenStatus: [],
            ),
          );

          if (_medication != null) {
            setState(() {
              _medicationName = _medication!.name;
              _dose = _reminderIndex < _medication!.doses.length
                  ? _medication!.doses[_reminderIndex]
                  : '1 dose';
              _time = _reminderIndex < _medication!.reminderTimes.length
                  ? _medication!.reminderTimes[_reminderIndex]
                  : 'Unknown time';
            });
          }
        } catch (e) {
          print('Error fetching medication details: $e');
          setState(() {
            _medicationName = 'Unknown Medication';
            _dose = '1 dose';
            _time = 'Unknown time';
          });
        }
      }
    } else {
      setState(() {
        _medicationName = 'Medication Reminder';
        _dose = 'Time to take your medication';
        _time = DateTime.now().toString().substring(11, 16);
      });
    }
  }

  Future<void> _handleTakeMedication() async {
    try {
      await NotificationService.markMedicationAsTaken(_medicationId, _reminderIndex);

      // Update local state
      if (_medication != null) {
        final updatedStatus = List<bool>.from(_medication!.takenStatus);
        if (_reminderIndex < updatedStatus.length) {
          updatedStatus[_reminderIndex] = true;
          setState(() {
            _medication = _medication!.copyWith(takenStatus: updatedStatus);
          });
        }
      }

      _dismissDialog();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Medication marked as taken!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error taking medication: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSnooze() async {
    try {
      await NotificationService.snoozeMedication(_medicationId, _reminderIndex);
      _dismissDialog();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏰ Medication snoozed for 10 minutes'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error snoozing medication: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleTurnOff() async {
    try {
      await NotificationService.stopCurrentAlarm();
      if (_medicationId > 0) {
        final notificationId = NotificationService.generateNotificationId(_medicationId, _reminderIndex);
        await NotificationService.cancelSpecificNotification(notificationId);
      }
      _dismissDialog();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔕 Alarm turned off'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error turning off alarm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _dismissDialog() {
    widget.onDismiss?.call();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _opacityAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value * 0.8,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                );
              },
            ),
          ),

          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _pulseAnimation.value,
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.red.withOpacity(0.5),
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.medication,
                                            size: 48,
                                            color: Colors.red,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 20),

                                  const Text(
                                    '💊 MEDICATION TIME!',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(1, 1),
                                          blurRadius: 3,
                                          color: Colors.black54,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.medical_services,
                                              color: Colors.white70,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _medicationName,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              color: Colors.white70,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Time: $_time',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.medication_liquid,
                                              color: Colors.white70,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Dose: $_dose',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildActionButton(
                                          icon: Icons.snooze,
                                          label: 'Snooze\n10 min',
                                          color: Colors.orange,
                                          onPressed: _handleSnooze,
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      Expanded(
                                        child: _buildActionButton(
                                          icon: Icons.volume_off,
                                          label: 'Turn Off\nAlarm',
                                          color: Colors.grey,
                                          onPressed: _handleTurnOff,
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      Expanded(
                                        child: _buildActionButton(
                                          icon: Icons.check_circle,
                                          label: 'Taken\nMedication',
                                          color: Colors.green,
                                          onPressed: _handleTakeMedication,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;

class CustomGlassTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onTimeChanged;

  const CustomGlassTimePicker({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
  });

  @override
  State<CustomGlassTimePicker> createState() => _CustomGlassTimePickerState();
}

class _CustomGlassTimePickerState extends State<CustomGlassTimePicker>
    with TickerProviderStateMixin {
  late TimeOfDay selectedTime;
  late TextEditingController hourController;
  late TextEditingController minuteController;
  bool isEditingHour = false;
  bool isEditingMinute = false;

  @override
  void initState() {
    super.initState();
    selectedTime = widget.initialTime;
    hourController = TextEditingController(
      text: selectedTime.hourOfPeriod.toString().padLeft(2, '0'),
    );
    minuteController = TextEditingController(
      text: selectedTime.minute.toString().padLeft(2, '0'),
    );
  }

  @override
  void dispose() {
    hourController.dispose();
    minuteController.dispose();
    super.dispose();
  }

  void _updateTime(TimeOfDay newTime) {
    setState(() {
      selectedTime = newTime;
      hourController.text = selectedTime.hourOfPeriod.toString().padLeft(
        2,
        '0',
      );
      minuteController.text = selectedTime.minute.toString().padLeft(2, '0');
    });
    widget.onTimeChanged(newTime);
  }

  void _updateFromTextField() {
    try {
      int hour = int.parse(hourController.text);
      int minute = int.parse(minuteController.text);

      if (hour >= 1 && hour <= 12 && minute >= 0 && minute <= 59) {
        int actualHour =
            selectedTime.period == DayPeriod.pm && hour != 12
                ? hour + 12
                : selectedTime.period == DayPeriod.am && hour == 12
                ? 0
                : hour;

        if (selectedTime.period == DayPeriod.pm && hour != 12) {
          actualHour = hour + 12;
        } else if (selectedTime.period == DayPeriod.am && hour == 12) {
          actualHour = 0;
        } else {
          actualHour = hour;
        }

        _updateTime(TimeOfDay(hour: actualHour, minute: minute));
      }
    } catch (e) {
      // Reset to current values if invalid
      hourController.text = selectedTime.hourOfPeriod.toString().padLeft(
        2,
        '0',
      );
      minuteController.text = selectedTime.minute.toString().padLeft(2, '0');
    }
  }

  void _togglePeriod() {
    final newHour =
        selectedTime.period == DayPeriod.am
            ? selectedTime.hour + 12
            : selectedTime.hour - 12;
    _updateTime(TimeOfDay(hour: newHour, minute: selectedTime.minute));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        height: 460, // Increased height to accommodate all content
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, 10),
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 40,
              offset: const Offset(0, -5),
              spreadRadius: -5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Title
                    Text(
                      'Select Time',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 16), // Reduced from 20
                    // Time Display with Direct Edit
                    _buildTimeDisplay(),

                    const SizedBox(height: 24), // Reduced from 30
                    // Glass Clock Face
                    _buildClockFace(),

                    const SizedBox(height: 24), // Increased from 20
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          'Cancel',
                          () => Navigator.of(context).pop(),
                          isCancel: true,
                        ),
                        _buildActionButton(
                          'OK',
                          () => Navigator.of(context).pop(selectedTime),
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
    );
  }

  Widget _buildTimeDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hour
          GestureDetector(
            onTap: () {
              setState(() {
                isEditingHour = !isEditingHour;
                isEditingMinute = false;
              });
            },
            child: Container(
              width: 50,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color:
                    isEditingHour
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.transparent,
                border:
                    isEditingHour
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
              ),
              child: Center(
                child:
                    isEditingHour
                        ? TextField(
                          controller: hourController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (_) {
                            setState(() {
                              isEditingHour = false;
                            });
                            _updateFromTextField();
                          },
                          onTapOutside: (_) {
                            setState(() {
                              isEditingHour = false;
                            });
                            _updateFromTextField();
                          },
                        )
                        : Text(
                          selectedTime.hourOfPeriod.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ),

          // Separator
          const Text(
            ':',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          // Minute
          GestureDetector(
            onTap: () {
              setState(() {
                isEditingMinute = !isEditingMinute;
                isEditingHour = false;
              });
            },
            child: Container(
              width: 50,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color:
                    isEditingMinute
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.transparent,
                border:
                    isEditingMinute
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
              ),
              child: Center(
                child:
                    isEditingMinute
                        ? TextField(
                          controller: minuteController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (_) {
                            setState(() {
                              isEditingMinute = false;
                            });
                            _updateFromTextField();
                          },
                          onTapOutside: (_) {
                            setState(() {
                              isEditingMinute = false;
                            });
                            _updateFromTextField();
                          },
                        )
                        : Text(
                          selectedTime.minute.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // AM/PM Toggle
          GestureDetector(
            onTap: _togglePeriod,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.3),
                    Colors.blue.withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Text(
                selectedTime.period == DayPeriod.am ? 'AM' : 'PM',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockFace() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: CustomPaint(
        painter: TimePickerClockPainter(selectedTime),
        child: GestureDetector(
          onPanUpdate: (details) {
            final center = const Offset(90, 90);
            final offset = details.localPosition - center;
            final angle = math.atan2(offset.dy, offset.dx);
            final minutes = ((angle + math.pi / 2) * 30 / math.pi).round() % 60;
            if (minutes < 0) return;

            _updateTime(TimeOfDay(hour: selectedTime.hour, minute: minutes));
          },
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    VoidCallback onPressed, {
    bool isCancel = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors:
              isCancel
                  ? [Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.1)]
                  : [
                    Colors.blue.withOpacity(0.3),
                    Colors.blue.withOpacity(0.1),
                  ],
        ),
        border: Border.all(
          color:
              isCancel
                  ? Colors.grey.withOpacity(0.4)
                  : Colors.blue.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isCancel ? Colors.grey[700] : Colors.blue[700],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TimePickerClockPainter extends CustomPainter {
  final TimeOfDay time;

  TimePickerClockPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - 10;

    // Draw hour markers
    final hourPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.6)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;

    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final startPoint = Offset(
        center.dx + (radius - 8) * math.cos(angle),
        center.dy + (radius - 8) * math.sin(angle),
      );
      final endPoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(startPoint, endPoint, hourPaint);
    }

    // Draw minute markers
    final minutePaint =
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..strokeWidth = 1;

    for (int i = 0; i < 60; i++) {
      if (i % 5 != 0) {
        final angle = (i * 6 - 90) * math.pi / 180;
        final startPoint = Offset(
          center.dx + (radius - 4) * math.cos(angle),
          center.dy + (radius - 4) * math.sin(angle),
        );
        final endPoint = Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );
        canvas.drawLine(startPoint, endPoint, minutePaint);
      }
    }

    // Draw minute hand
    final minuteAngle = (time.minute * 6 - 90) * math.pi / 180;
    final minuteHandPaint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.7 * math.cos(minuteAngle),
        center.dy + radius * 0.7 * math.sin(minuteAngle),
      ),
      minuteHandPaint,
    );

    // Draw center dot
    canvas.drawCircle(center, 4, Paint()..color = Colors.blue);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Helper function to show the custom time picker
Future<TimeOfDay?> showCustomTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) async {
  return showDialog<TimeOfDay>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext context) {
      TimeOfDay selectedTime = initialTime;
      return CustomGlassTimePicker(
        initialTime: initialTime,
        onTimeChanged: (time) {
          selectedTime = time;
        },
      );
    },
  );
}

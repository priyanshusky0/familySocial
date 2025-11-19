import 'package:family_socail/app/modules/Alarm/models/alarm_data.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../widgets/clock_painter.dart';


const Color primaryBlue = Color(0xFF2196F3);
const Color lightBlue = Color(0xFFE3F2FD);
const Color backgroundColor = Color(0xFFF5F7FA);
const Color cardWhite = Color(0xFFFFFFFF);
const Color textDark = Color(0xFF1A1A1A);
const Color textGrey = Color(0xFF6B7280);


class AnalogClock extends StatelessWidget {
  final double screenWidth;

  const AnalogClock({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final clockSize = math.min(screenWidth * 0.5, 220.0);

    return Container(
      width: clockSize,
      height: clockSize,
      decoration: BoxDecoration(
        color: cardWhite,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        painter: ClockPainter(),
      ),
    );
  }
}


class CreateAlarmButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CreateAlarmButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        padding: EdgeInsets.symmetric(
          vertical: math.max(12.0, 12.0 + textScaleFactor * 4),
        ),
        elevation: 2,
        minimumSize: Size(
          double.infinity,
          math.max(48.0, 48.0 + textScaleFactor * 6),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add,
            color: Colors.white,
            size: math.min(22, 18 + textScaleFactor * 4),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Create New Alarm',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


class AlarmCard extends StatelessWidget {
  final AlarmData alarm;
  final VoidCallback onDelete;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    final isPast = alarm.scheduledTime.isBefore(DateTime.now());
    final timeString =
        '${alarm.scheduledTime.hour.toString().padLeft(2, '0')}:'
        '${alarm.scheduledTime.minute.toString().padLeft(2, '0')}';
    final period = alarm.scheduledTime.hour >= 12 ? 'PM' : 'AM';

    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              timeString,
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w300,
                                color: isPast ? textGrey : textDark,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.015),
                          Text(
                            period,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isPast ? textGrey : textDark,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.008),
                      Text(
                        alarm.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: screenHeight * 0.004),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: math.min(13, 11 + textScaleFactor * 2),
                            color: textGrey,
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Flexible(
                            child: Text(
                              'By ${alarm.createdByName}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: textGrey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Column(
                  children: [
                    if (isPast)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                          vertical: screenHeight * 0.005,
                        ),
                        constraints: const BoxConstraints(minHeight: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Expired',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    SizedBox(height: screenHeight * 0.008),
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                        maxWidth: 44,
                        maxHeight: 44,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade600,
                          size: math.min(18, 16 + textScaleFactor * 2),
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: onDelete,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (alarm.message.isNotEmpty) ...[
              SizedBox(height: screenHeight * 0.015),
              Container(
                padding: EdgeInsets.all(screenWidth * 0.025),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: math.min(14, 12 + textScaleFactor * 2),
                      color: textGrey,
                    ),
                    SizedBox(width: screenWidth * 0.015),
                    Expanded(
                      child: Text(
                        alarm.message,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textGrey,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: screenHeight * 0.012),
            Divider(color: backgroundColor, height: 1, thickness: 1),
            SizedBox(height: screenHeight * 0.01),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: math.min(13, 11 + textScaleFactor * 2),
                  color: textGrey,
                ),
                SizedBox(width: screenWidth * 0.012),
                Flexible(
                  child: Text(
                    _formatDate(alarm.scheduledTime),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: textGrey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
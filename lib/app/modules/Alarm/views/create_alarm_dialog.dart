import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class CreateAlarmDialog extends StatefulWidget {
  final List<QueryDocumentSnapshot> familyMembers;
  final String currentUserId;

  const CreateAlarmDialog({
    super.key,
    required this.familyMembers,
    required this.currentUserId,
  });

  @override
  State<CreateAlarmDialog> createState() => _CreateAlarmDialogState();
}

class _CreateAlarmDialogState extends State<CreateAlarmDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedUserId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF6B7280);

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryBlue),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryBlue),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _createAlarm() {
    if (_titleController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter alarm title',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      Get.snackbar(
        'Error',
        'Please select date and time',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_selectedUserId == null) {
      Get.snackbar(
        'Error',
        'Please select a family member',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final scheduledTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    Get.back(result: {
      'targetUserId': _selectedUserId!,
      'scheduledTime': scheduledTime,
      'title': _titleController.text,
      'message': _descriptionController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    final dialogPadding = screenWidth * 0.06;
    final maxDialogWidth = math.min(screenWidth * 0.9, 500.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxDialogWidth,
          maxHeight: screenHeight * 0.85,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(dialogPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Row(
                  children: [
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                        maxWidth: 52,
                        maxHeight: 52,
                      ),
                      decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.alarm_add,
                        color: primaryBlue,
                        size: math.min(24, 20 + textScaleFactor * 4),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    Expanded(
                      child: Text(
                        'Create New Alarm',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                      color: textGrey,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),

                
                Text(
                  'Alarm Title',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Morning Routine',
                    hintStyle: GoogleFonts.inter(color: textGrey),
                    filled: true,
                    fillColor: backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: math.max(12.0, 12.0 + textScaleFactor * 2),
                    ),
                  ),
                  style: GoogleFonts.inter(fontSize: 15),
                ),
                SizedBox(height: screenHeight * 0.025),

                
                Text(
                  'For Family Member',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedUserId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: math.max(12.0, 12.0 + textScaleFactor * 2),
                      ),
                    ),
                    hint: Text(
                      'Select member',
                      style: GoogleFonts.inter(color: textGrey),
                    ),
                    icon: const Icon(Icons.arrow_drop_down, color: primaryBlue),
                    dropdownColor: Colors.white,
                    style: GoogleFonts.inter(fontSize: 15, color: textDark),
                    isExpanded: true,
                    items: widget.familyMembers.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: math.min(16, 14 + textScaleFactor * 2),
                              backgroundColor: lightBlue,
                              child: Text(
                                (data['name'] ?? 'U')[0].toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Text(
                                data['name'] ?? 'Unknown',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedUserId = value);
                    },
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),

                
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          InkWell(
                            onTap: _selectDate,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                                vertical: math.max(12.0, 12.0 + textScaleFactor * 2),
                              ),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: primaryBlue,
                                    size: math.min(18, 16 + textScaleFactor * 2),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Expanded(
                                    child: Text(
                                      _selectedDate == null
                                          ? 'Select date'
                                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        color: _selectedDate == null
                                            ? textGrey
                                            : textDark,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          InkWell(
                            onTap: _selectTime,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                                vertical: math.max(12.0, 12.0 + textScaleFactor * 2),
                              ),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: primaryBlue,
                                    size: math.min(18, 16 + textScaleFactor * 2),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Expanded(
                                    child: Text(
                                      _selectedTime == null
                                          ? 'Select time'
                                          : _selectedTime!.format(context),
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        color: _selectedTime == null
                                            ? textGrey
                                            : textDark,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.025),

                
                Text(
                  'Message (Optional)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add a note or reminder...',
                    hintStyle: GoogleFonts.inter(color: textGrey),
                    filled: true,
                    fillColor: backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.all(screenWidth * 0.04),
                  ),
                  style: GoogleFonts.inter(fontSize: 15),
                ),
                SizedBox(height: screenHeight * 0.03),

                
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: math.max(14.0, 14.0 + textScaleFactor * 2),
                          ),
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textGrey,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _createAlarm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          padding: EdgeInsets.symmetric(
                            vertical: math.max(14.0, 14.0 + textScaleFactor * 2),
                          ),
                          elevation: 0,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check,
                              color: Colors.white,
                              size: math.min(20, 18 + textScaleFactor * 2),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Flexible(
                              child: Text(
                                'Create Alarm',
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
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
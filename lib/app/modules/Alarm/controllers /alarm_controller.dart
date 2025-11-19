
import 'package:family_socail/app/modules/Alarm/models/alarm_data.dart';
import 'package:family_socail/app/modules/Alarm/services/alarm_services.dart';
import 'package:family_socail/app/modules/Alarm/views/create_alarm_dialog.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AlarmController extends GetxController {
  final AlarmService _alarmService = AlarmService();

  
  final _isLoading = true.obs;
  final _alarms = <AlarmData>[].obs;
  final _familyMembers = <QueryDocumentSnapshot>[].obs;

  
  late final String currentUserId;
  late final String currentUserName;
  late final String familyId;

  
  bool get isLoading => _isLoading.value;
  List<AlarmData> get alarms => _alarms;
  List<QueryDocumentSnapshot> get familyMembers => _familyMembers;
  int get alarmsCount => _alarms.length;

  @override
  void onInit() {
    super.onInit();
    _initializeFromArguments();
    _initialize();
  }


  
  void _initializeFromArguments() {
    final args = Get.arguments as Map<String, dynamic>;
    currentUserId = args['currentUserId'] ?? '';
    currentUserName = args['currentUserName'] ?? '';
    familyId = args['familyId'] ?? '';

    if (currentUserId.isEmpty || familyId.isEmpty) {
      _showError('Invalid user data. Please try again.');
      Get.back();
    }
  }

  
  Future<void> _initialize() async {
    try {
      _isLoading.value = true;

      
      await _alarmService.initialize();

      
      await _loadFamilyMembers();

      
      _listenForAlarms();

      _isLoading.value = false;
    } catch (e) {
      debugPrint('Initialization error: $e');
      _showError('Failed to initialize alarms');
      _isLoading.value = false;
    }
  }

  
  Future<void> _loadFamilyMembers() async {
    try {
      final familySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('familyId', isEqualTo: familyId)
          .get();

      _familyMembers.value = familySnapshot.docs;
    } catch (e) {
      debugPrint('Error loading family members: $e');
      _showError('Failed to load family members');
    }
  }

  
  void _listenForAlarms() {
    _alarmService.getFamilyAlarms(familyId).listen(
      (alarmsList) {
        _alarms.value = alarmsList;
        
        
        for (final alarm in alarmsList) {
          if (alarm.targetUserId == currentUserId) {
            _alarmService.scheduleAlarm(alarm);
          }
        }
      },
      onError: (e) {
        debugPrint('Error listening to alarms: $e');
        _showError('Failed to sync alarms');
      },
    );
  }

  
  Future<void> showCreateAlarmDialog() async {
    if (_familyMembers.isEmpty) {
      _showError('No family members available');
      return;
    }

    final result = await Get.dialog<Map<String, dynamic>>(
      CreateAlarmDialog(
        familyMembers: _familyMembers,
        currentUserId: currentUserId,
      ),
      barrierDismissible: false,
    );

    if (result != null) {
      await _createAlarm(result);
    }
  }

  
  Future<void> _createAlarm(Map<String, dynamic> data) async {
    try {
      await _alarmService.createAlarm(
        familyId: familyId,
        targetUserId: data['targetUserId'],
        createdBy: currentUserId,
        createdByName: currentUserName,
        scheduledTime: data['scheduledTime'],
        title: data['title'],
        message: data['message'],
      );

      _showSuccess('Alarm created successfully');
    } catch (e) {
      debugPrint('Create alarm error: $e');
      _showError('Failed to create alarm');
    }
  }

  
  Future<void> deleteAlarm(AlarmData alarm) async {
    final confirm = await Get.dialog<bool>(
      _buildDeleteConfirmDialog(alarm),
      barrierDismissible: false,
    );

    if (confirm == true) {
      try {
        await _alarmService.deleteAlarm(alarm.id);
        _showSuccess('Alarm deleted');
      } catch (e) {
        debugPrint('Delete alarm error: $e');
        _showError('Failed to delete alarm');
      }
    }
  }

  
  Widget _buildDeleteConfirmDialog(AlarmData alarm) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.delete_outline,
              color: Colors.red.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Delete Alarm?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to delete "${alarm.title}"? This action cannot be undone.',
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF6B7280),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            minimumSize: const Size(0, 44),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Get.back(result: true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 0,
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Delete',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  
  bool isAlarmExpired(DateTime scheduledTime) {
    return scheduledTime.isBefore(DateTime.now());
  }

  
  String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  
  String getPeriod(DateTime time) {
    return time.hour >= 12 ? 'PM' : 'AM';
  }

  
  String formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  
  Future<void> refreshAlarms() async {
    await _loadFamilyMembers();
  }

  
  Future<void> checkPermissions() async {
    final hasPermissions = await _alarmService.checkPermissions();
    
    if (!hasPermissions) {
      final openSettings = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'Alarm notifications require permission. Would you like to open settings?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (openSettings == true) {
        await _alarmService.openSettings();
      }
    }
  }

  
  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red[600]!,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  
  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green[600]!,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    );
  }
}


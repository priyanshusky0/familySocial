import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alarm/alarm.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import '../models/alarm_data.dart';



class AlarmService {
  
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Set<int> _scheduledAlarmIds = {};

  
  Future<void> initialize() async {
    await Alarm.init();

    
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    } else if (Platform.isIOS) {
      await _requestIOSPermissions();
    }

    
    Alarm.ringStream.stream.listen((alarmSettings) {
      debugPrint('🔔 Alarm ${alarmSettings.id} is ringing!');
    });
  }

  
  Future<void> _requestAndroidPermissions() async {
    try {
      
      await Permission.notification.request();

      
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }

      
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      debugPrint('Error requesting Android permissions: $e');
    }
  }

  
  Future<void> _requestIOSPermissions() async {
    try {
      final status = await Permission.notification.request();
      if (status.isDenied) {
        debugPrint('⚠️ iOS notification permission denied');
      }
    } catch (e) {
      debugPrint('Error requesting iOS permissions: $e');
    }
  }

  
  Future<String> createAlarm({
    required String familyId,
    required String targetUserId,
    required String createdBy,
    required String createdByName,
    required DateTime scheduledTime,
    required String title,
    required String message,
    List<int> repeatDays = const [],
  }) async {
    final alarmId = _firestore.collection('alarms').doc().id;

    final alarm = AlarmData(
      id: alarmId,
      familyId: familyId,
      targetUserId: targetUserId,
      createdBy: createdBy,
      createdByName: createdByName,
      scheduledTime: scheduledTime,
      title: title,
      message: message,
      repeatDays: repeatDays,
    );

    await _firestore.collection('alarms').doc(alarmId).set(alarm.toMap());
    return alarmId;
  }

  
  Future<void> deleteAlarm(String alarmId) async {
    try {
      final id = alarmId.hashCode;
      await Alarm.stop(id);
      _scheduledAlarmIds.remove(id);
      await _firestore.collection('alarms').doc(alarmId).delete();
    } catch (e) {
      debugPrint('Error deleting alarm: $e');
      rethrow;
    }
  }

  
  Stream<List<AlarmData>> getUserAlarms(String userId) {
    return _firestore
        .collection('alarms')
        .where('targetUserId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AlarmData.fromMap(doc.data())).toList());
  }

  
  Stream<List<AlarmData>> getFamilyAlarms(String familyId) {
    return _firestore
        .collection('alarms')
        .where('familyId', isEqualTo: familyId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AlarmData.fromMap(doc.data())).toList());
  }

  
  Future<void> scheduleAlarm(AlarmData alarm) async {
    final alarmId = alarm.id.hashCode;

    
    if (_scheduledAlarmIds.contains(alarmId)) {
      return;
    }

    
    if (alarm.scheduledTime.isBefore(DateTime.now())) {
      debugPrint('⏰ Alarm time has passed: ${alarm.title}');
      return;
    }

    
    final audioPath = _getAudioPath();

    final alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: alarm.scheduledTime,
      assetAudioPath: audioPath,
      loopAudio: true,
      vibrate: true,
      volumeSettings: VolumeSettings.fixed(volume: 0.8),
      notificationSettings: NotificationSettings(
        title: '${alarm.title} - from ${alarm.createdByName}',
        body: alarm.message.isNotEmpty ? alarm.message : 'Reminder',
        stopButton: 'Stop',
        icon: Platform.isAndroid ? 'notification_icon' : null,
      ),
      warningNotificationOnKill: Platform.isIOS,
      androidFullScreenIntent: Platform.isAndroid,
    );

    try {
      await Alarm.set(alarmSettings: alarmSettings);
      _scheduledAlarmIds.add(alarmId);
      debugPrint('✅ Scheduled: ${alarm.title} at ${alarm.scheduledTime}');
      debugPrint('📱 Platform: ${Platform.isIOS ? "iOS" : "Android"}');
    } catch (e) {
      debugPrint('❌ Failed to schedule alarm: $e');
    }
  }

  
  String _getAudioPath() {
    
    
    if (Platform.isIOS) {
      return 'assets/alarm_sound.caf'; 
    } else {
      return 'assets/alarm_sound.mp3'; 
    }
  }

  
  Future<void> stopAlarm(int alarmId) async {
    await Alarm.stop(alarmId);
    _scheduledAlarmIds.remove(alarmId);
  }

  
  Future<void> stopAllAlarms() async {
    await Alarm.stopAll();
    _scheduledAlarmIds.clear();
  }

  
  Future<bool> isRinging(int alarmId) async {
    final alarms = await Alarm.getAlarms();
    return alarms.any((alarm) => alarm.id == alarmId);
  }

  
  Future<List<AlarmSettings>> getScheduledAlarms() async {
    return await Alarm.getAlarms();
  }

  
  Future<bool> checkPermissions() async {
    if (Platform.isIOS) {
      final notificationStatus = await Permission.notification.status;
      return notificationStatus.isGranted;
    } else {
      final notificationStatus = await Permission.notification.status;
      final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
      return notificationStatus.isGranted && exactAlarmStatus.isGranted;
    }
  }

  
  Future<void> openSettings() async {
    await openAppSettings();
  }

  
  Future<void> updateAlarmStatus(String alarmId, bool isActive) async {
    await _firestore.collection('alarms').doc(alarmId).update({
      'isActive': isActive,
    });

    if (!isActive) {
      
      final id = alarmId.hashCode;
      await Alarm.stop(id);
      _scheduledAlarmIds.remove(id);
    }
  }

  
  Future<void> rescheduleAllAlarms(String userId) async {
    final alarms = await _firestore
        .collection('alarms')
        .where('targetUserId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    for (final doc in alarms.docs) {
      final alarm = AlarmData.fromMap(doc.data());
      await scheduleAlarm(alarm);
    }
  }

  
  void clearCache() {
    _scheduledAlarmIds.clear();
  }
}
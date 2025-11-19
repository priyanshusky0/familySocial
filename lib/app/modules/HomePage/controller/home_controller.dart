import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeController extends GetxController {
  // Reactive states
  final _selectedIndex = 0.obs;
  final _isLoading = true.obs;
  final _userName = 'User'.obs;
  final _familyName = 'Family'.obs;
  final _familyId = 'FamilyId'.obs;
  final _uid = 'Uid'.obs;

  // Getters
  int get selectedIndex => _selectedIndex.value;
  bool get isLoading => _isLoading.value;
  String get userName => _userName.value;
  String get familyName => _familyName.value;
  String get familyId => _familyId.value;
  String get uid => _uid.value;

  // Computed values
  String get userFirstName => _userName.value.split(' ').first;

  @override
  void onInit() {
    super.onInit();
    _fetchUserData();
  }

  /// Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    try {
      _isLoading.value = true;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _handleAuthError();
        return;
      }

      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        _userName.value = data?['name'] ?? 'User';
        _familyName.value = data?['familyName'] ?? 'Family';
        _familyId.value = data?['familyId'] ?? 'FamilyId';
        _uid.value = data?['uid'] ?? user.uid;
      } else {
        debugPrint('User document does not exist');
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      _showError('Failed to load user data');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Handle authentication error
  void _handleAuthError() {
    _isLoading.value = false;
    Get.offAllNamed('/auth');
    _showError('Authentication required. Please sign in again.');
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.offAllNamed('/auth');
      _showSuccess('Logged out successfully');
    } catch (e) {
      debugPrint('Logout error: $e');
      _showError('Logout failed. Please try again.');
    }
  }

  /// Handle bottom navigation
  void handleBottomNavigation(int index) {
    switch (index) {
      case 0:
        // Already on Home
        _selectedIndex.value = 0;
        break;
      case 1:
        // Navigate to Expense screen
        _navigateToExpense();
        break;
      case 3:
        // Navigate to Chat screen (coming soon)
        _showComingSoon('Chat');
        _selectedIndex.value = 0;
        break;
      case 4:
        // Navigate to Profile screen (coming soon)
        _showComingSoon('Profile');
        _selectedIndex.value = 0;
        break;
    }
  }

  /// Navigate to Alarm screen
  void navigateToAlarmScreen() {
    if (_userName.value.isEmpty || _familyId.value.isEmpty) {
      _showError('Unable to load user data. Please try again.');
      return;
    }

    Get.toNamed('/alarm', arguments: {
      'currentUserId': _uid.value,
      'familyId': _familyId.value,
      'currentUserName': _userName.value,
    });
  }

  /// Navigate to Documents screen
  void navigateToDocuments() {
    Get.toNamed('/documents');
  }

  /// Navigate to Expense screen
  void _navigateToExpense() {
    Get.toNamed('/expense', arguments: {
      'familyId': _familyId.value,
      'currentUserId': _uid.value,
    })?.then((_) {
      // Reset to home when coming back
      _selectedIndex.value = 0;
    });
  }

  /// Navigate to Passwords screen
  void navigateToPasswords() {
    Get.toNamed('/passwords');
  }

  /// Navigate to Members screen (coming soon)
  void navigateToMembers() {
    _showComingSoon('Members');
  }

  /// Navigate to Chat screen (coming soon)
  void navigateToChat() {
    _showComingSoon('Chat');
  }

  /// Show coming soon message
  void _showComingSoon(String feature) {
    Get.snackbar(
      'Coming Soon',
      '$feature feature will be available soon!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF2196F3),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 1),
      icon: const Icon(Icons.info_outline, color: Colors.white),
    );
  }

  /// Show error message
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

  /// Show success message
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

  /// Refresh user data
  Future<void> refreshUserData() async {
    await _fetchUserData();
  }
}
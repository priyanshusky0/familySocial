import 'package:family_socail/app/data/services/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Splash Controller
/// Handles authentication state checking and navigation
class SplashController extends GetxController {
  final _isLoading = true.obs;

  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    _checkAuthenticationAndNavigate();
  }

  /// Check authentication status and navigate accordingly
  Future<void> _checkAuthenticationAndNavigate() async {
    try {
      // Wait minimum duration for better UX
      await Future.delayed(const Duration(seconds: 2));

      // Get current user
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        // User not authenticated, go to auth screen
        Get.offAllNamed('/auth');
        return;
      }

      // User is authenticated, check family status
      final hasFamily = await FirebaseAuthService.hasFamilySetup();

      if (hasFamily) {
        // User has family setup, go to home screen
        Get.offAllNamed('/home');
      } else {
        // User doesn't have family, go to create family screen
        Get.offAllNamed('/create-family');
      }
    } catch (e) {
      // On error, default to create family screen for safety
      Get.offAllNamed('/create-family');
    } finally {
      _isLoading.value = false;
    }
  }
}
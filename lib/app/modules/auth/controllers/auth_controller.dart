import 'package:family_socail/app/data/services/firebase_auth.dart';
import 'package:family_socail/app/data/services/google_auth.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';



enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthController extends GetxController {
  // Reactive states
  final _authState = AuthState.initial.obs;
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;
  final _isSignUpMode = false.obs;
  final _obscurePassword = true.obs;

  // Text editing controllers
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController passwordController;

  // Getters for reactive states
  AuthState get authState => _authState.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get isSignUpMode => _isSignUpMode.value;
  bool get obscurePassword => _obscurePassword.value;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    
    // Listen to auth state changes
    _listenToAuthChanges();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// Listen to Firebase Auth state changes
  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _authState.value = AuthState.authenticated;
      } else {
        _authState.value = AuthState.unauthenticated;
      }
    });
  }

  /// Toggle between Sign In and Sign Up modes
  void toggleAuthMode() {
    _isSignUpMode.value = !_isSignUpMode.value;
    _errorMessage.value = ''; // Clear error when switching modes
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    _obscurePassword.value = !_obscurePassword.value;
  }

  /// Validate input fields
  String? _validateInputs() {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      return 'Please fill in all fields';
    }

    if (_isSignUpMode.value && name.isEmpty) {
      return 'Please enter your full name';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }

    // Basic email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Handle Email/Password Authentication
  Future<void> handleEmailAuth() async {
    // Validate inputs
    final validationError = _validateInputs();
    if (validationError != null) {
      _showError(validationError);
      return;
    }

    _setLoading(true);
    _errorMessage.value = '';

    try {
      if (_isSignUpMode.value) {
        // Sign Up
        await FirebaseAuthService.signUpWithEmail(
          email: emailController.text.trim(),
          password: passwordController.text,
          name: nameController.text.trim(),
        );

        _showSuccess('Account created successfully!');
        
        // Navigate to create family screen (new users always need to create family)
        await _navigateToCreateFamily();
      } else {
        // Sign In
        await FirebaseAuthService.signInWithEmail(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        _showSuccess('Signed in successfully!');
        
        // Check family status and navigate accordingly
        await _navigateBasedOnFamilyStatus();
      }
    } on FirebaseAuthException catch (e) {
      _showError(FirebaseAuthService.getErrorMessage(e));
    } catch (e) {
      _showError('An unexpected error occurred');
      debugPrint('Auth Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Handle Google Sign In
  Future<void> handleGoogleSignIn() async {
    _setLoading(true);
    _errorMessage.value = '';

    try {
      final userCredential = await GoogleSignInService.signInWithGoogle();

      if (userCredential != null) {
        _showSuccess('Signed in with Google successfully!');
        
        // Check family status and navigate accordingly
        await _navigateBasedOnFamilyStatus();
      } else {
        _showError('Google sign-in was cancelled');
      }
    } catch (e) {
      _showError('Google sign-in failed. Please try again.');
      debugPrint('Google Sign-In Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Handle Apple Sign In (Placeholder)
  Future<void> handleAppleSignIn() async {
    _showError('Apple Sign-In requires a paid Apple Developer account');
  }

  /// Navigate user based on family setup status
  Future<void> _navigateBasedOnFamilyStatus() async {
    try {
      final hasFamily = await FirebaseAuthService.hasFamilySetup();

      if (hasFamily) {
        // User has family, go to home screen
        Get.offAllNamed('/home');
      } else {
        // User doesn't have family, go to create family screen
        Get.offAllNamed('/create-family');
      }
    } catch (e) {
      debugPrint('Navigation Error: $e');
      // Fallback to create family screen
      Get.offAllNamed('/create-family');
    }
  }

  /// Navigate to create family screen
  Future<void> _navigateToCreateFamily() async {
    Get.offAllNamed('/create-family');
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      _setLoading(true);
      
      // Sign out from both services
      await FirebaseAuthService.signOut();
      await GoogleSignInService.signOut();
      
      // Clear form fields
      _clearForm();
      
      // Navigate to auth screen
      Get.offAllNamed('/auth');
      
      _showSuccess('Signed out successfully');
    } catch (e) {
      _showError('Failed to sign out. Please try again.');
      debugPrint('Sign Out Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Clear form fields
  void _clearForm() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    _errorMessage.value = '';
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading.value = value;
  }

  /// Show error message
  void _showError(String message) {
    _errorMessage.value = message;
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  /// Show success message
  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  /// Get current user
  User? get currentUser => FirebaseAuth.instance.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;
}
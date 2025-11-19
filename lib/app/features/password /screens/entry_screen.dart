import 'package:family_socail/app/features/password%20/screens/password_screen.dart';
import 'package:family_socail/app/features/password%20/services/password_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class VaultUnlockScreen extends StatefulWidget {
  const VaultUnlockScreen({super.key});

  @override
  State<VaultUnlockScreen> createState() => _VaultUnlockScreenState();
}

class _VaultUnlockScreenState extends State<VaultUnlockScreen>
    with SingleTickerProviderStateMixin {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isBiometricsAvailable = false;
  String? _errorMessage;
  String? _familyId;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _setupShakeAnimation();
    _initializeFamilyId();
  }

  Future<void> _initializeFamilyId() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'No user logged in';
          _isLoading = false;
        });
        return;
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        setState(() {
          _errorMessage = 'User data not found';
          _isLoading = false;
        });
        return;
      }

      final familyId = userDoc.data()?['familyId'];
      
      if (familyId == null) {
        setState(() {
          _errorMessage = 'No family assigned to user';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _familyId = familyId;
        _isLoading = false;
      });

      
      _checkFirstTimeSetup();
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading family data: $e';
        _isLoading = false;
      });
    }
  }

  
  Future<bool> _hasMasterPassword() async {
    final masterPassword = await _getMasterPasswordFromFirebase();
    return masterPassword != null;
  }

  
  void _setupShakeAnimation() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticIn,
      ),
    );
  }

  
  Future<void> _checkFirstTimeSetup() async {
    if (_familyId == null) return;
    
    final masterPassword = await _getMasterPasswordFromFirebase();
    if (masterPassword == null) {
      Future.delayed(Duration.zero, () => _showSetupMasterPasswordDialog());
    }
  }

  
  Future<String?> _getMasterPasswordFromFirebase() async {
    if (_familyId == null) return null;
    
    try {
      final doc = await _firestore
          .collection('family_settings')
          .doc(_familyId)
          .get();
      
      if (doc.exists) {
        return doc.data()?['master_password_hash'];
      }
      return null;
    } catch (e) {
      print('Error getting master password: $e');
      return null;
    }
  }

  
  Future<void> _saveMasterPasswordToFirebase(String hashedPassword) async {
    if (_familyId == null) {
      throw Exception('Family ID not set');
    }
    
    try {
      await _firestore
          .collection('family_settings')
          .doc(_familyId)
          .set({
        'master_password_hash': hashedPassword,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('Master password saved successfully');
    } catch (e) {
      print('Error saving master password: $e');
      rethrow;
    }
  }

  
  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _isBiometricsAvailable = canCheck && isDeviceSupported;
      });
    } catch (e) {
      setState(() {
        _isBiometricsAvailable = false;
      });
    }
  }

  
  void _showSetupMasterPasswordDialog() {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool isPasswordVisible = false;
    bool isConfirmVisible = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Column(
            children: [
              Icon(
                Icons.security_rounded,
                color: Color(0xFF4169E1),
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Create Master Password',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This password will be used to unlock your vault. Make sure it\'s strong and memorable.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Master Password',
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                obscureText: !isConfirmVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isConfirmVisible
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        isConfirmVisible = !isConfirmVisible;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a password'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (passwordController.text != confirmController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Passwords do not match'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (passwordController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password must be at least 6 characters'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  
                  final hashedPassword = _hashPassword(passwordController.text);
                  await _saveMasterPasswordToFirebase(hashedPassword);

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Master password created successfully for all family members'),
                        backgroundColor: const Color(0xFF4169E1),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4169E1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Create Password',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  
  Future<void> _authenticateWithBiometrics() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock your password vault',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated && mounted) {
        
        final storedMasterPassword = await _secureStorage.read(
          key: 'cached_master_password_$_familyId',
        );
        
        if (storedMasterPassword == null) {
          setState(() {
            _errorMessage = 'Please unlock with password first to enable biometrics';
            _isLoading = false;
          });
          return;
        }
        
        
        _passwordController.text = storedMasterPassword;
        _unlockVault();
      } else {
        setState(() {
          _errorMessage = 'Authentication failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Biometric authentication error: $e';
        _isLoading = false;
      });
    }
  }

  
  Future<void> _authenticateWithPassword() async {
    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password';
      });
      _shakeController.forward().then((_) => _shakeController.reverse());
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final storedPassword = await _getMasterPasswordFromFirebase();
      
      if (storedPassword == null) {
        setState(() {
          _errorMessage = 'No master password set. Please create one.';
          _isLoading = false;
        });
        _showSetupMasterPasswordDialog();
        return;
      }
      
      final hashedInput = _hashPassword(_passwordController.text);

      if (storedPassword == hashedInput) {
        _unlockVault();
      } else {
        setState(() {
          _errorMessage = 'Incorrect password';
          _passwordController.clear();
          _isLoading = false;
        });
        _shakeController.forward().then((_) => _shakeController.reverse());
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  
  void _unlockVault() async {
    if (_familyId == null) {
      setState(() {
        _errorMessage = 'Family ID not found';
        _isLoading = false;
      });
      return;
    }
    
    try {
      print('Initializing encryption for family: $_familyId');
      
      
      await firebaseService.initializeEncryption(
        _passwordController.text,
        _familyId!,
      );
      
      
      
      await _secureStorage.write(
        key: 'cached_master_password_$_familyId',
        value: _passwordController.text,
      );
      
      print('Vault unlocked successfully');
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const PasswordVaultScreen(),
          ),
        );
      }
    } catch (e) {
      print('Failed to unlock vault: $e');
      setState(() {
        _errorMessage = 'Failed to unlock vault. Please check your password.';
        _isLoading = false;
        _passwordController.clear();
      });
      _shakeController.forward().then((_) => _shakeController.reverse());
    }
  }

  
  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Column(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Colors.orange,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Reset Master Password',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: const Text(
          'Resetting the master password will affect all family members on all devices. This will delete all stored passwords for everyone.\n\nAre you sure you want to continue?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (_familyId != null) {
                  
                  await _firestore
                      .collection('family_settings')
                      .doc(_familyId)
                      .delete();
                  
                  
                  await _secureStorage.delete(
                    key: 'cached_master_password_$_familyId',
                  );
                  
                  
                  final passwords = await _firestore
                      .collection('passwords')
                      .where('familyId', isEqualTo: _familyId)
                      .get();
                  
                  for (var doc in passwords.docs) {
                    await doc.reference.delete();
                  }
                  
                  
                  await firebaseService.resetEncryption();
                  
                  print('Master password and all data deleted successfully');
                }
                
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Master password deleted. Please create a new one.'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  
                  _showSetupMasterPasswordDialog();
                }
              } catch (e) {
                print('Error resetting password: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset & Delete All'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    if (_isLoading && _familyId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4169E1)),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading family vault...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    
    if (_familyId == null && !_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Unable to load family vault',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _initializeFamilyId();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4169E1),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: child,
                );
              },
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4169E1).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        size: 64,
                        color: Color(0xFF4169E1),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Family Password Vault',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Securely access your family\'s shared\npasswords and sensitive information',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 16,
                            color: Color(0xFF4169E1),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'AES-256 encrypted',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your passwords are encrypted and secure',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      onSubmitted: (_) => _authenticateWithPassword(),
                      decoration: InputDecoration(
                        labelText: 'Master Password',
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF6B7280),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: const Color(0xFF6B7280),
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _authenticateWithPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4169E1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_open_rounded),
                                  SizedBox(width: 8),
                                  Text(
                                    'Unlock Vault',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    if (_isBiometricsAvailable) ...[
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or',
                              style: TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _isLoading ? null : _authenticateWithBiometrics,
                        icon: const Icon(Icons.fingerprint_rounded, size: 28),
                        label: const Text(
                          'Use biometrics to unlock',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6B7280),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () async {
                        final hasMasterPassword = await _hasMasterPassword();
                        if (hasMasterPassword) {
                          _showResetPasswordDialog();
                        } else {
                          _showSetupMasterPasswordDialog();
                        }
                      },
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Color(0xFF4169E1),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
}
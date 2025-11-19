import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_socail/app/features/Welcome/screens/code_display.dart';
import 'package:family_socail/app/modules/HomePage/views/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateFamilyScreen extends StatefulWidget {
  const CreateFamilyScreen({super.key});

  @override
  State<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends State<CreateFamilyScreen> {
  final TextEditingController _familyNameController = TextEditingController();
  final TextEditingController _familyCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isJoinMode = false;

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _createFamily() async {
    if (!_formKey.currentState!.validate()) return;

    final familyName = _familyNameController.text.trim();

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final familyRef = FirebaseFirestore.instance.collection('families').doc();

      
      final batch = FirebaseFirestore.instance.batch();

      batch.set(familyRef, {
        'id': familyRef.id,
        'name': familyName,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'members': [user.uid],
      });

      batch.set(
        FirebaseFirestore.instance.collection('users').doc(user.uid),
        {'familyId': familyRef.id, 'familyName': familyName},
        SetOptions(
          merge: true,
        ), 
      );

      await batch.commit();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FamilyCodeScreen(
              familyCode: familyRef.id,
              familyName: familyName,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error creating family: $e");
      if (mounted) {
        _showSnackBar("Something went wrong. Try again.", Colors.red.shade700);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinFamily() async {
    if (!_formKey.currentState!.validate()) return;

    final familyCode = _familyCodeController.text.trim();

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      
      final familyDoc = await FirebaseFirestore.instance
          .collection('families')
          .doc(familyCode)
          .get();

      if (!familyDoc.exists) {
        _showSnackBar(
          "Family not found. Please check the code.",
          Colors.red.shade700,
        );
        setState(() => _isLoading = false);
        return;
      }

      final familyData = familyDoc.data() as Map<String, dynamic>;
      final members = List<String>.from(familyData['members'] ?? []);

      if (members.contains(user.uid)) {
        _showSnackBar(
          "You're already a member of this family!",
          Colors.orange.shade700,
        );
        setState(() => _isLoading = false);
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      batch.update(
        FirebaseFirestore.instance.collection('families').doc(familyCode),
        {
          'members': FieldValue.arrayUnion([user.uid]),
        },
      );

      batch.update(
      FirebaseFirestore.instance.collection('users').doc(user.uid),
      {
        'familyId': familyCode,
        'familyName': familyData['name'], 
      },
    );

      

      await batch.commit();

      if (mounted) {
        _showSnackBar(
          "Successfully joined ${familyData['name']}!",
          Colors.green.shade700,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint("Error joining family: $e");
      if (mounted) {
        _showSnackBar("Something went wrong. Try again.", Colors.red.shade700);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleMode() {
    if (_isLoading) return;
    setState(() {
      _isJoinMode = !_isJoinMode;
      _formKey.currentState?.reset();
    });
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _familyCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),

                  
                  const _FamilyIcon(),

                  const SizedBox(height: 40),

                  
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _isJoinMode ? "Join a Family" : "Create Your Family",
                      key: ValueKey(_isJoinMode),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _isJoinMode
                          ? "Enter the family code to join an existing group"
                          : "Start your family group and invite members to join",
                      key: ValueKey(_isJoinMode ? 'join' : 'create'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  
                  _BuildTextField(
                    controller: _isJoinMode
                        ? _familyCodeController
                        : _familyNameController,
                    isJoinMode: _isJoinMode,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 40),

                  
                  _ActionButton(
                    isJoinMode: _isJoinMode,
                    isLoading: _isLoading,
                    onPressed: _isJoinMode ? _joinFamily : _createFamily,
                  ),

                  const SizedBox(height: 24),

                  
                  TextButton(
                    onPressed: _toggleMode,
                    child: Text(
                      _isJoinMode
                          ? "Don't have a code? Create a new family"
                          : "Already have a family? Join with code",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  
                  _InfoBox(isJoinMode: _isJoinMode),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _FamilyIcon extends StatelessWidget {
  const _FamilyIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 137, 183, 248),
              Colors.blue.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.people_rounded, size: 60, color: Colors.white),
      ),
    );
  }
}

class _BuildTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool isJoinMode;
  final bool isLoading;

  const _BuildTextField({
    required this.controller,
    required this.isJoinMode,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: !isLoading,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return isJoinMode
                ? 'Please enter family code'
                : 'Please enter family name';
          }
          if (!isJoinMode && value.trim().length < 3) {
            return 'Family name must be at least 3 characters';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: isJoinMode ? "Family Code" : "Family Name",
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(
            isJoinMode ? Icons.vpn_key_rounded : Icons.home_rounded,
            color: Colors.blue,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade300, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool isJoinMode;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.isJoinMode,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.blueAccent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                isJoinMode ? "Join Family" : "Create Family",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final bool isJoinMode;

  const _InfoBox({required this.isJoinMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isJoinMode
                  ? "Ask a family member for the family code to join their group"
                  : "You'll be able to invite family members after creating your group",
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade900,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

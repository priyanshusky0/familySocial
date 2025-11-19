import 'package:family_socail/app/data/services/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  
  Future<void> _checkAuthAndNavigate() async {
    
    await Future.delayed(const Duration(seconds: 2));

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
     
      Get.offAllNamed('/auth');
      return;
    }

   
    try {
      final hasFamily = await FirebaseAuthService.hasFamilySetup();

      if (hasFamily) {
        
        Get.offAllNamed('/home');
      } else {
       
        Get.offAllNamed('/create-family');
      }
    } catch (e) {
      debugPrint('Error checking family status: $e');
      
      Get.offAllNamed('/create-family');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0066FF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.people_outline,
                size: 60,
                color: Color(0xFF0066FF),
              ),
            ),
            const SizedBox(height: 24),

           
            const Text(
              'Family Social',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            
            Text(
              'Stay connected with your loved ones',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 48),

           
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
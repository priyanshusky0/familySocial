// import 'package:family_socail/Authentication/Services/firebase_auth_services.dart';
// import 'package:family_socail/Authentication/Services/google_auth_services.dart';
// import 'package:family_socail/Welcome/screens/create_family_screen.dart';
// import 'package:family_socail/home_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class AuthScreen extends StatefulWidget {
//   const AuthScreen({super.key});

//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }

// class _AuthScreenState extends State<AuthScreen> {
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _obscurePassword = true;
//   bool _isSignUp = false;
//   bool _isLoading = false;

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   void _toggleAuthMode() {
//     setState(() {
//       _isSignUp = !_isSignUp;
//     });
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   void _showSuccess(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   /// Navigate user based on family setup status
//   Future<void> _navigateBasedOnFamilyStatus() async {
//     // Check if user has family setup
//     final hasFamily = await FirebaseAuthService.hasFamilySetup();
    
//     if (!mounted) return;

//     if (hasFamily) {
//       // User has family, go to main screen
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const HomeScreen()),
//       );
//     } else {
//       // User doesn't have family, go to create family screen
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const CreateFamilyScreen()),
//       );
//     }
//   }

//   Future<void> _handleAuth() async {
//     if (_emailController.text.trim().isEmpty ||
//         _passwordController.text.isEmpty) {
//       _showError('Please fill in all fields');
//       return;
//     }

//     if (_isSignUp && _nameController.text.trim().isEmpty) {
//       _showError('Please enter your full name');
//       return;
//     }

//     if (_passwordController.text.length < 8) {
//       _showError('Password must be at least 8 characters');
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       if (_isSignUp) {
//         await FirebaseAuthService.signUpWithEmail(
//           email: _emailController.text.trim(),
//           password: _passwordController.text,
//           name: _nameController.text.trim(),
//         );

//         _showSuccess('Account created successfully!');

//         // New users always go to create family screen
//         if (mounted) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => const CreateFamilyScreen()),
//           );
//         }
//       } else {
//         // Sign in existing user
//         await FirebaseAuthService.signInWithEmail(
//           email: _emailController.text.trim(),
//           password: _passwordController.text,
//         );

//         _showSuccess('Signed in successfully!');

//         // Check family status and navigate accordingly
//         await _navigateBasedOnFamilyStatus();
//       }
//     } on FirebaseAuthException catch (e) {
//       _showError(FirebaseAuthService.getErrorMessage(e));
//     } catch (e) {
//       _showError('An unexpected error occurred');
//       print('Error: $e');
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   Future<void> _handleGoogleAuth() async {
//     setState(() => _isLoading = true);

//     try {
//       final userCredential = await GoogleSignInService.signInWithGoogle();

//       if (userCredential != null) {
//         _showSuccess('Signed in with Google successfully!');

//         // Check family status and navigate accordingly
//         await _navigateBasedOnFamilyStatus();
//       }
//     } catch (e) {
//       _showError('Google sign-in failed. Please try again.');
//       print('Google Sign-In Error: $e');
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   Future<void> _handleAppleAuth() async {
//     _showError('Apple Sign-In requires a paid Apple Developer account');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   width: 100,
//                   height: 100,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFE3F0FF),
//                     borderRadius: BorderRadius.circular(50),
//                   ),
//                   child: const Icon(
//                     Icons.people_outline,
//                     size: 45,
//                     color: Color(0xFF0066FF),
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 Text(
//                   _isSignUp ? 'Join Your Family' : 'Welcome Back',
//                   style: const TextStyle(
//                     fontSize: 32,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF2C3E50),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   _isSignUp
//                       ? 'Create an account to get started'
//                       : 'Sign in to your family account',
//                   style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
//                 ),
//                 const SizedBox(height: 20),

//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withValues(alpha: .05),
//                         blurRadius: 20,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   padding: const EdgeInsets.all(28),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Form Title
//                       Text(
//                         _isSignUp ? 'Create Account' : 'Sign In',
//                         style: const TextStyle(
//                           fontSize: 26,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF2C3E50),
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Text(
//                         _isSignUp
//                             ? 'Enter your details to create your family account'
//                             : 'Enter your credentials to access your account',
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                       const SizedBox(height: 20),

//                       if (_isSignUp) ...[
//                         const Text(
//                           'Full Name',
//                           style: TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFF2C3E50),
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         TextField(
//                           controller: _nameController,
//                           decoration: InputDecoration(
//                             hintText: 'John Doe',
//                             hintStyle: TextStyle(
//                               color: Colors.grey.shade400,
//                               fontSize: 15,
//                             ),
//                             prefixIcon: Icon(
//                               Icons.person_outline,
//                               color: Colors.grey.shade500,
//                               size: 22,
//                             ),
//                             filled: true,
//                             fillColor: const Color(0xFFF8F9FA),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide.none,
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide(
//                                 color: Colors.grey.shade200,
//                                 width: 1,
//                               ),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(
//                                 color: Color(0xFF0066FF),
//                                 width: 2,
//                               ),
//                             ),
//                             contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 16,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                       ],

//                       // Email Field
//                       const Text(
//                         'Email',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF2C3E50),
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                       TextField(
//                         controller: _emailController,
//                         keyboardType: TextInputType.emailAddress,
//                         decoration: InputDecoration(
//                           hintText: 'you@example.com',
//                           hintStyle: TextStyle(
//                             color: Colors.grey.shade400,
//                             fontSize: 15,
//                           ),
//                           prefixIcon: Icon(
//                             Icons.email_outlined,
//                             color: Colors.grey.shade500,
//                             size: 22,
//                           ),
//                           filled: true,
//                           fillColor: const Color(0xFFF8F9FA),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide.none,
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide(
//                               color: Colors.grey.shade200,
//                               width: 1,
//                             ),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: const BorderSide(
//                               color: Color(0xFF0066FF),
//                               width: 2,
//                             ),
//                           ),
//                           contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 16,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 20),

//                       // Password Field
//                       const Text(
//                         'Password',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF2C3E50),
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                       TextField(
//                         controller: _passwordController,
//                         obscureText: _obscurePassword,
//                         decoration: InputDecoration(
//                           hintText: _isSignUp
//                               ? 'Create a strong password'
//                               : 'Enter your password',
//                           hintStyle: TextStyle(
//                             color: Colors.grey.shade400,
//                             fontSize: 15,
//                           ),
//                           prefixIcon: Icon(
//                             Icons.lock_outline,
//                             color: Colors.grey.shade500,
//                             size: 22,
//                           ),
//                           suffixIcon: IconButton(
//                             icon: Icon(
//                               _obscurePassword
//                                   ? Icons.visibility_outlined
//                                   : Icons.visibility_off_outlined,
//                               color: Colors.grey.shade500,
//                               size: 22,
//                             ),
//                             onPressed: () {
//                               setState(() {
//                                 _obscurePassword = !_obscurePassword;
//                               });
//                             },
//                           ),
//                           filled: true,
//                           fillColor: const Color(0xFFF8F9FA),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide.none,
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide(
//                               color: Colors.grey.shade200,
//                               width: 1,
//                             ),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: const BorderSide(
//                               color: Color(0xFF0066FF),
//                               width: 2,
//                             ),
//                           ),
//                           contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 16,
//                           ),
//                         ),
//                       ),

//                       if (_isSignUp) ...[
//                         const SizedBox(height: 8),
//                         Text(
//                           'Must be at least 8 characters long',
//                           style: TextStyle(
//                             fontSize: 13,
//                             color: Colors.grey.shade500,
//                           ),
//                         ),
//                       ],
//                       const SizedBox(height: 20),

//                       SizedBox(
//                         width: double.infinity,
//                         height: 54,
//                         child: ElevatedButton(
//                           onPressed: _isLoading ? null : _handleAuth,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF0066FF),
//                             disabledBackgroundColor: Colors.grey.shade400,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             elevation: 0,
//                           ),
//                           child: _isLoading
//                               ? const SizedBox(
//                                   height: 20,
//                                   width: 20,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2,
//                                     valueColor: AlwaysStoppedAnimation<Color>(
//                                       Colors.white,
//                                     ),
//                                   ),
//                                 )
//                               : Text(
//                                   _isSignUp ? 'Create Account' : 'Sign In',
//                                   style: const TextStyle(
//                                     fontSize: 17,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                         ),
//                       ),
//                       const SizedBox(height: 20),

//                       // Divider
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Divider(
//                               color: Colors.grey.shade300,
//                               thickness: 1,
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 14),
//                             child: Text(
//                               'Or continue with',
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: Colors.grey.shade500,
//                               ),
//                             ),
//                           ),
//                           Expanded(
//                             child: Divider(
//                               color: Colors.grey.shade300,
//                               thickness: 1,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),

//                       // Social Login Buttons
//                       Row(
//                         children: [
//                           Expanded(
//                             child: OutlinedButton(
//                               onPressed: _isLoading ? null : _handleGoogleAuth,
//                               style: OutlinedButton.styleFrom(
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 14,
//                                 ),
//                                 side: BorderSide(
//                                   color: Colors.grey.shade300,
//                                   width: 1.5,
//                                 ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 backgroundColor: Colors.white,
//                               ),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   SizedBox(
//                                     height: 20,
//                                     width: 20,
//                                     child: Image.network(
//                                       "https://www.google.com/images/branding/googleg/1x/googleg_standard_color_128dp.png",
//                                       fit: BoxFit.contain,
//                                       errorBuilder:
//                                           (context, error, stackTrace) {
//                                             return const Icon(
//                                               Icons.g_mobiledata,
//                                               size: 20,
//                                             );
//                                           },
//                                     ),
//                                   ),
//                                   SizedBox(width: 10),
//                                   Text(
//                                     'Google',
//                                     style: TextStyle(
//                                       fontSize: 15,
//                                       fontWeight: FontWeight.w500,
//                                       color: Color(0xFF2C3E50),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           Expanded(
//                             child: OutlinedButton(
//                               onPressed: _isLoading ? null : _handleAppleAuth,
//                               style: OutlinedButton.styleFrom(
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 14,
//                                 ),
//                                 side: BorderSide(
//                                   color: Colors.grey.shade300,
//                                   width: 1.5,
//                                 ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 backgroundColor: Colors.white,
//                               ),
//                               child: const Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(
//                                     Icons.apple,
//                                     size: 24,
//                                     color: Color(0xFF2C3E50),
//                                   ),
//                                   SizedBox(width: 10),
//                                   Text(
//                                     'Apple',
//                                     style: TextStyle(
//                                       fontSize: 15,
//                                       fontWeight: FontWeight.w500,
//                                       color: Color(0xFF2C3E50),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),

//                       // Toggle Auth Mode Link
//                       Center(
//                         child: Wrap(
//                           alignment: WrapAlignment.center,
//                           children: [
//                             Text(
//                               _isSignUp
//                                   ? "Already have an account? "
//                                   : "Don't have an account? ",
//                               style: TextStyle(
//                                 fontSize: 15,
//                                 color: Colors.grey.shade600,
//                               ),
//                             ),
//                             GestureDetector(
//                               onTap: _toggleAuthMode,
//                               child: Text(
//                                 _isSignUp ? 'Sign In' : 'Sign Up',
//                                 style: const TextStyle(
//                                   fontSize: 15,
//                                   color: Color(0xFF0066FF),
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 32),

//                 // Secure Connection
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.shield_outlined,
//                       size: 18,
//                       color: Colors.grey.shade500,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       'Secure Connection',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
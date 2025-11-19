// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class FirebaseAuthService {
//   static final FirebaseAuth _auth = FirebaseAuth.instance;
//   static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   static Future<UserCredential> signUpWithEmail({
//     required String email,
//     required String password,
//     required String name,
//   }) async {
//     try {
//       final userCredential = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       await _firestore.collection('users').doc(userCredential.user!.uid).set({
//         'uid': userCredential.user!.uid,
//         'name': name,
//         'email': email,
//         'photoURL': '',
//         'provider': 'email',
//         'familyName': null,
//         'familyId': null,
//         'createdAt': FieldValue.serverTimestamp(),
//       });

//       await userCredential.user!.updateDisplayName(name);

//       return userCredential;
//     } catch (e) {
//       print('Sign up error: $e');
//       rethrow;
//     }
//   }

//   static Future<UserCredential> signInWithEmail({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       final userCredential = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       return userCredential;
//     } catch (e) {
//       print('Sign in error: $e');
//       rethrow;
//     }
//   }

//   static Future<void> signOut() async {
//     try {
//       await _auth.signOut();
//     } catch (e) {
//       print('Error signing out: $e');
//       rethrow;
//     }
//   }

//   static User? getCurrentUser() {
//     return _auth.currentUser;
//   }

//   static bool isSignedIn() {
//     return _auth.currentUser != null;
//   }

//   /// Check if user has family information (familyId or familyName)
//   /// Returns true if user has family setup, false otherwise
//   static Future<bool> hasFamilySetup() async {
//     try {
//       final user = getCurrentUser();
//       if (user == null) return false;

//       final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
//       if (!userDoc.exists) return false;

//       final data = userDoc.data();
//       final familyId = data?['familyId'];
//       final familyName = data?['familyName'];

//       // User has family setup if either familyId or familyName exists and is not null/empty
//       return (familyId != null && familyId.toString().trim().isNotEmpty) ||
//              (familyName != null && familyName.toString().trim().isNotEmpty);
//     } catch (e) {
//       print('Error checking family setup: $e');
//       return false;
//     }
//   }

//   /// Get user's family information
//   static Future<Map<String, dynamic>?> getFamilyInfo() async {
//     try {
//       final user = getCurrentUser();
//       if (user == null) return null;

//       final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
//       if (!userDoc.exists) return null;

//       final data = userDoc.data();
//       return {
//         'familyId': data?['familyId'],
//         'familyName': data?['familyName'],
//       };
//     } catch (e) {
//       print('Error getting family info: $e');
//       return null;
//     }
//   }

//   /// Update user's family information
//   static Future<void> updateFamilyInfo({
//     required String familyId,
//     required String familyName,
//   }) async {
//     try {
//       final user = getCurrentUser();
//       if (user == null) throw Exception('No user signed in');

//       await _firestore.collection('users').doc(user.uid).update({
//         'familyId': familyId,
//         'familyName': familyName,
//       });
//     } catch (e) {
//       print('Error updating family info: $e');
//       rethrow;
//     }
//   }

//   static String getErrorMessage(FirebaseAuthException e) {
//     switch (e.code) {
//       case 'weak-password':
//         return 'The password is too weak';
//       case 'email-already-in-use':
//         return 'An account already exists for this email';
//       case 'user-not-found':
//         return 'No user found with this email';
//       case 'wrong-password':
//         return 'Wrong password';
//       case 'invalid-email':
//         return 'Invalid email address';
//       default:
//         return e.message ?? 'Authentication failed';
//     }
//   }
// }
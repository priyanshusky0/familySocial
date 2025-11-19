// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_sign_in/google_sign_in.dart';

// // Google Sign-In Service Class
// class GoogleSignInService {
//   static final FirebaseAuth _auth = FirebaseAuth.instance;
//   static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
//   static bool isInitialize = false;

//   static Future<void> initSignIn() async {
//     if (!isInitialize) {
//       await _googleSignIn.initialize(
//         serverClientId:
//             '724698434057-9apjng4c352d49v1sdltgf9hlt647211.apps.googleusercontent.com',
//       );
//     }
//     isInitialize = true;
//   }

//   // Sign in with Google
//   static Future<UserCredential?> signInWithGoogle() async {
//     try {
//       await initSignIn();
      
//       final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
//       final idToken = googleUser.authentication.idToken;
//       final authorizationClient = googleUser.authorizationClient;
      
//       GoogleSignInClientAuthorization? authorization = await authorizationClient
//           .authorizationForScopes(['email', 'profile']);
      
//       final accessToken = authorization?.accessToken;
      
//       if (accessToken == null) {
//         final authorization2 = await authorizationClient.authorizationForScopes(
//           ['email', 'profile'],
//         );
//         if (authorization2?.accessToken == null) {
//           throw FirebaseAuthException(code: "error", message: "Missing access token");
//         }
//         authorization = authorization2;
//       }
      
//       final credential = GoogleAuthProvider.credential(
//         accessToken: accessToken,
//         idToken: idToken,
//       );
      
//       final UserCredential userCredential = await _auth.signInWithCredential(credential);
//       final User? user = userCredential.user;
      
//       if (user != null) {
//         final userDoc = _firestore.collection('users').doc(user.uid);
//         final docSnapshot = await userDoc.get();
        
//         // Create user document only if it doesn't exist
//         if (!docSnapshot.exists) {
//           await userDoc.set({
//             'uid': user.uid,
//             'name': user.displayName ?? '',
//             'email': user.email ?? '',
//             'photoURL': user.photoURL ?? '',
//             'provider': 'google',
//             'familyName': null,
//             'familyId': null,
//             'createdAt': FieldValue.serverTimestamp(),
//           });
//           print('Created new user document for ${user.uid}');
//         } else {
//           print('User document already exists for ${user.uid}');
//         }
//       }
      
//       return userCredential;
//     } catch (e) {
//       print('Google Sign-In Error: $e');
//       rethrow;
//     }
//   }

//   // Sign out
//   static Future<void> signOut() async {
//     try {
//       await _googleSignIn.signOut();
//       await _auth.signOut();
//       print('User signed out successfully');
//     } catch (e) {
//       print('Error signing out: $e');
//       rethrow;
//     }
//   }

//   // Get current user
//   static User? getCurrentUser() {
//     return _auth.currentUser;
//   }
  
//   // Check if user is signed in
//   static bool isSignedIn() {
//     return _auth.currentUser != null;
//   }

//   /// Check if user has family information (familyId or familyName)
//   /// Returns true if user has family setup, false otherwise
//   static Future<bool> hasFamilySetup() async {
//     try {
//       final user = getCurrentUser();
//       if (user == null) {
//         print('No user signed in for family check');
//         return false;
//       }

//       final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
//       if (!userDoc.exists) {
//         print('User document does not exist for ${user.uid}');
//         return false;
//       }

//       final data = userDoc.data();
//       if (data == null) {
//         print('User data is null for ${user.uid}');
//         return false;
//       }

//       final familyId = data['familyId'];
//       final familyName = data['familyName'];

//       print('Family check for user ${user.uid}:');
//       print('  familyId: $familyId');
//       print('  familyName: $familyName');

//       // User has family setup if either familyId or familyName exists and is not null/empty
//       final hasFamily = (familyId != null && familyId.toString().trim().isNotEmpty) ||
//                         (familyName != null && familyName.toString().trim().isNotEmpty);
      
//       print('  hasFamily: $hasFamily');
//       return hasFamily;
//     } catch (e) {
//       print('Error checking family setup: $e');
//       return false;
//     }
//   }

//   /// Get user's family information
//   static Future<Map<String, dynamic>?> getFamilyInfo() async {
//     try {
//       final user = getCurrentUser();
//       if (user == null) {
//         print('No user signed in');
//         return null;
//       }

//       final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
//       if (!userDoc.exists) {
//         print('User document does not exist');
//         return null;
//       }

//       final data = userDoc.data();
//       if (data == null) return null;

//       return {
//         'familyId': data['familyId'],
//         'familyName': data['familyName'],
//         'uid': user.uid,
//         'name': data['name'],
//         'email': data['email'],
//         'photoURL': data['photoURL'],
//       };
//     } catch (e) {
//       print('Error getting family info: $e');
//       return null;
//     }
//   }

//   /// Update user's family information
//   /// Call this after user creates or joins a family
//   static Future<void> updateFamilyInfo({
//     required String familyId,
//     required String familyName,
//   }) async {
//     try {
//       final user = getCurrentUser();
//       if (user == null) {
//         throw Exception('No user signed in');
//       }

//       print('Updating family info for user ${user.uid}:');
//       print('  familyId: $familyId');
//       print('  familyName: $familyName');

//       await _firestore.collection('users').doc(user.uid).update({
//         'familyId': familyId,
//         'familyName': familyName,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       print('Family info updated successfully');
//     } catch (e) {
//       print('Error updating family info: $e');
//       rethrow;
//     }
//   }

//   /// Remove user's family information (for leaving family)
//   static Future<void> removeFamilyInfo() async {
//     try {
//       final user = getCurrentUser();
//       if (user == null) {
//         throw Exception('No user signed in');
//       }

//       print('Removing family info for user ${user.uid}');

//       await _firestore.collection('users').doc(user.uid).update({
//         'familyId': null,
//         'familyName': null,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       print('Family info removed successfully');
//     } catch (e) {
//       print('Error removing family info: $e');
//       rethrow;
//     }
//   }

//   /// Get user document stream for real-time updates
//   static Stream<DocumentSnapshot> getUserStream() {
//     final user = getCurrentUser();
//     if (user == null) {
//       return Stream.empty();
//     }
//     return _firestore.collection('users').doc(user.uid).snapshots();
//   }

//   /// Check if user document exists in Firestore
//   static Future<bool> userDocumentExists() async {
//     try {
//       final user = getCurrentUser();
//       if (user == null) return false;

//       final userDoc = await _firestore.collection('users').doc(user.uid).get();
//       return userDoc.exists;
//     } catch (e) {
//       print('Error checking user document: $e');
//       return false;
//     }
//   }
// }
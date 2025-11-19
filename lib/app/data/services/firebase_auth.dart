
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class FirebaseAuthService {
  
  FirebaseAuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
  static const String _usersCollection = 'users';

  
  static Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    
    await _createUserDocument(
      uid: userCredential.user!.uid,
      name: name,
      email: email,
      provider: 'email',
    );

    
    await userCredential.user!.updateDisplayName(name);

    return userCredential;
  }

  
  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  
  static Future<void> _createUserDocument({
    required String uid,
    required String name,
    required String email,
    required String provider,
    String? photoURL,
  }) async {
    await _firestore.collection(_usersCollection).doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'photoURL': photoURL ?? '',
      'provider': provider,
      'familyName': null,
      'familyId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  
  static bool isSignedIn() {
    return _auth.currentUser != null;
  }

  
  
  static Future<bool> hasFamilySetup() async {
    final user = getCurrentUser();
    if (user == null) return false;

    final userDoc = await _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .get();

    if (!userDoc.exists) return false;

    final data = userDoc.data();
    if (data == null) return false;

    final familyId = data['familyId'];
    final familyName = data['familyName'];

    return (familyId != null && familyId.toString().trim().isNotEmpty) ||
        (familyName != null && familyName.toString().trim().isNotEmpty);
  }

  
  static Future<Map<String, dynamic>?> getFamilyInfo() async {
    final user = getCurrentUser();
    if (user == null) return null;

    final userDoc = await _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .get();

    if (!userDoc.exists) return null;

    final data = userDoc.data();
    if (data == null) return null;

    return {
      'familyId': data['familyId'],
      'familyName': data['familyName'],
    };
  }

  
  static Future<void> updateFamilyInfo({
    required String familyId,
    required String familyName,
  }) async {
    final user = getCurrentUser();
    if (user == null) throw Exception('No user signed in');

    await _firestore.collection(_usersCollection).doc(user.uid).update({
      'familyId': familyId,
      'familyName': familyName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  
  static Future<void> removeFamilyInfo() async {
    final user = getCurrentUser();
    if (user == null) throw Exception('No user signed in');

    await _firestore.collection(_usersCollection).doc(user.uid).update({
      'familyId': null,
      'familyName': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  
  static Stream<DocumentSnapshot> getUserStream() {
    final user = getCurrentUser();
    if (user == null) return Stream.empty();

    return _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .snapshots();
  }

  
  static Future<bool> userDocumentExists() async {
    final user = getCurrentUser();
    if (user == null) return false;

    final userDoc = await _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .get();
    return userDoc.exists;
  }

  
  static Future<Map<String, dynamic>?> getUserData() async {
    final user = getCurrentUser();
    if (user == null) return null;

    final userDoc = await _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .get();

    return userDoc.data();
  }

  
  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak';
      case 'email-already-in-use':
        return 'An account already exists for this email';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      case 'operation-not-allowed':
        return 'This operation is not allowed';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
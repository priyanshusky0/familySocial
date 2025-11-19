import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> createUserData({
    required String familyName,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) throw Exception("User not logged in");

    await _db.collection('users').doc(uid).set({
      'familyName': familyName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Fetch user data
  static Future<DocumentSnapshot<Map<String, dynamic>>> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) throw Exception("User not logged in");

    return _db.collection('users').doc(uid).get();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  String? _currentFamilyId;
  
  CollectionReference get passwordsCollection => 
      _firestore.collection('passwords');
  
  late encrypt.Key _key;
  late encrypt.IV _iv;
  bool _isInitialized = false;
  
  String? get familyId => _currentFamilyId;
  
  
  Future<void> initializeEncryption(String masterPassword, String familyId) async {
    if (_isInitialized && _currentFamilyId == familyId) return;
    
    _currentFamilyId = familyId;
    
    try {
      final doc = await _firestore
          .collection('family_settings')
          .doc(familyId)
          .get();
      
      String encryptionKeyBase64;
      String ivBase64;
      
      if (doc.exists && doc.data()?['encryption_key'] != null) {
        
        final encryptedData = doc.data()!['encryption_key'] as String;
        final storedIV = doc.data()!['encryption_iv'] as String;
        
        
        encryptionKeyBase64 = _decryptEncryptionKey(
          encryptedData,
          storedIV,
          masterPassword,
        );
        
        ivBase64 = doc.data()!['data_iv'] as String;
      } else {
        
        _key = encrypt.Key.fromSecureRandom(32);
        encryptionKeyBase64 = _key.base64;
        
        
        final dataIV = encrypt.IV.fromSecureRandom(16);
        ivBase64 = dataIV.base64;
        
        
        final keyEncryptionIV = encrypt.IV.fromSecureRandom(16);
        
        
        final encryptedKey = _encryptEncryptionKey(
          encryptionKeyBase64,
          keyEncryptionIV,
          masterPassword,
        );
        
        await _firestore
            .collection('family_settings')
            .doc(familyId)
            .set({
          'encryption_key': encryptedKey,
          'encryption_iv': keyEncryptionIV.base64, 
          'data_iv': ivBase64, 
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      
      _key = encrypt.Key.fromBase64(encryptionKeyBase64);
      _iv = encrypt.IV.fromBase64(ivBase64);
      _isInitialized = true;
      
    } catch (e) {
      print('Error initializing encryption: $e');
      rethrow;
    }
  }
  
  
  String _encryptEncryptionKey(
    String keyToEncrypt, 
    encrypt.IV iv,
    String masterPassword,
  ) {
    final derivedKey = _deriveKeyFromPassword(masterPassword);
    final encrypter = encrypt.Encrypter(encrypt.AES(derivedKey));
    
    return encrypter.encrypt(keyToEncrypt, iv: iv).base64;
  }
  
  
  String _decryptEncryptionKey(
    String encryptedKey, 
    String ivBase64,
    String masterPassword,
  ) {
    final derivedKey = _deriveKeyFromPassword(masterPassword);
    final encrypter = encrypt.Encrypter(encrypt.AES(derivedKey));
    final iv = encrypt.IV.fromBase64(ivBase64);
    
    return encrypter.decrypt64(encryptedKey, iv: iv);
  }
  
  
  encrypt.Key _deriveKeyFromPassword(String password) {
    
    const salt = 'family_vault_salt_v2_2024';
    
    
    final combined = password + salt;
    
    
    var hash = sha256.convert(utf8.encode(combined));
    
    
    for (int i = 0; i < 10000; i++) {
      hash = sha256.convert(hash.bytes);
    }
    
    return encrypt.Key.fromBase64(base64.encode(hash.bytes));
  }
  
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('Encryption not initialized. Call initializeEncryption() first.');
    }
  }
  
  String _encryptPassword(String password) {
    _ensureInitialized();
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    return encrypter.encrypt(password, iv: _iv).base64;
  }
  
  String _decryptPassword(String encryptedPassword) {
    _ensureInitialized();
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    return encrypter.decrypt64(encryptedPassword, iv: _iv);
  }
  
  
  Future<String> addPassword({
    required String service,
    required String username,
    required String password,
    required String iconName,
    required String colorHex,
  }) async {
    _ensureInitialized();
    
    final encryptedPassword = _encryptPassword(password);
    final encryptedUsername = _encryptPassword(username);
    
    final docRef = await passwordsCollection.add({
      'service': service,
      'username': encryptedUsername,
      'password': encryptedPassword,
      'iconName': iconName,
      'colorHex': colorHex,
      'familyId': familyId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    return docRef.id;
  }
  
  
  Stream<List<Map<String, dynamic>>> getPasswords() {
    _ensureInitialized();
    
    return passwordsCollection
        .where('familyId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        try {
          return {
            'id': doc.id,
            'service': data['service'],
            'username': _decryptPassword(data['username']),
            'password': _decryptPassword(data['password']),
            'iconName': data['iconName'],
            'colorHex': data['colorHex'],
          };
        } catch (e) {
          print('Error decrypting password entry: $e');
          
          return {
            'id': doc.id,
            'service': data['service'],
            'username': '[Decryption Error]',
            'password': '[Decryption Error]',
            'iconName': data['iconName'],
            'colorHex': data['colorHex'],
            'error': true,
          };
        }
      }).toList();
    });
  }
  
  
  Future<void> updatePassword({
    required String id,
    required String service,
    required String username,
    required String password,
  }) async {
    _ensureInitialized();
    
    final encryptedPassword = _encryptPassword(password);
    final encryptedUsername = _encryptPassword(username);
    
    await passwordsCollection.doc(id).update({
      'service': service,
      'username': encryptedUsername,
      'password': encryptedPassword,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  
  Future<void> deletePassword(String id) async {
    await passwordsCollection.doc(id).delete();
  }
  
  
  Future<void> resetEncryption() async {
    _isInitialized = false;
    _currentFamilyId = null;
    await _secureStorage.deleteAll();
  }
}


final firebaseService = FirebaseService();
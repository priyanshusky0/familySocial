import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class FirestoreDocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int maxFileSize = 1 * 1024 * 1024; 

  
  Stream<QuerySnapshot> getDocumentsStream(String familyId) {
    return _firestore
        .collection('documents')
        .where('familyId', isEqualTo: familyId) 
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  
  Future<void> uploadDocument({
    required PlatformFile pickedFile,
    required List<String> tags,
    DateTime? expiryDate,
    required bool isConfidential,
    required String userId,
    required String familyId, 
  }) async {
    try {
      if (pickedFile.size > maxFileSize) {
        throw Exception('File too large! Max ${formatFileSize(maxFileSize)}');
      }

      
      List<int> fileBytes;
      if (pickedFile.bytes != null) {
        
        fileBytes = pickedFile.bytes!;
      } else if (pickedFile.path != null) {
        
        File file = File(pickedFile.path!);
        fileBytes = await file.readAsBytes();
      } else {
        throw Exception('Cannot access file data');
      }

      String base64File = base64Encode(fileBytes);

      await _firestore.collection('documents').add({
        'name': pickedFile.name,
        'data': base64File,
        'size': pickedFile.size,
        'type': path.extension(pickedFile.name).replaceAll('.', '').toUpperCase(),
        'tags': tags,
        'expiryDate': expiryDate,
        'isConfidential': isConfidential,
        'familyId': familyId, 
        'uploadedAt': FieldValue.serverTimestamp(),
        'uploadedBy': userId,
      });
    } catch (e) {
      rethrow;
    }
  }

  
  Future<void> viewDocument(Map<String, dynamic> documentData) async {
    try {
      final base64Data = documentData['data'] as String?;
      if (base64Data == null || base64Data.isEmpty) {
        throw Exception('Document data is missing');
      }

      
      final bytes = base64Decode(base64Data);

      
      final tempDir = await getTemporaryDirectory();
      
      
      final fileName = (documentData['name'] ?? 'document')
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      
      final filePath = '${tempDir.path}/$fileName';

      
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      
      if (!await file.exists()) {
        throw Exception('Failed to create temporary file');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('File is empty');
      }

      
      final result = await OpenFile.open(filePath);
      
      if (result.type != ResultType.done) {
        throw Exception('Cannot open file: ${result.message}');
      }
    } catch (e) {
      rethrow;
    }
  }

  
  Future<void> shareDocument(Map<String, dynamic> documentData) async {
    try {
      final base64Data = documentData['data'] as String?;
      if (base64Data == null || base64Data.isEmpty) {
        throw Exception('Document data is missing');
      }

      
      final bytes = base64Decode(base64Data);

      
      final tempDir = await getTemporaryDirectory();
      
      
      final fileName = (documentData['name'] ?? 'document')
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      
      final filePath = '${tempDir.path}/$fileName';

      
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      
      if (!await file.exists()) {
        throw Exception('Failed to create temporary file');
      }

      
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Sharing: ${documentData['name']}',
      );
    } catch (e) {
      rethrow;
    }
  }

  
  Future<String> downloadDocument(Map<String, dynamic> documentData) async {
    try {
      final base64Data = documentData['data'] as String?;
      if (base64Data == null || base64Data.isEmpty) {
        throw Exception('Document data is missing');
      }

      
      final bytes = base64Decode(base64Data);

      
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        throw Exception('Cannot access storage directory');
      }

      
      final fileName = (documentData['name'] ?? 'document')
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      
      final filePath = '${directory.path}/$fileName';

      
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      return filePath;
    } catch (e) {
      rethrow;
    }
  }

  
  Future<void> deleteDocument(String docId) async {
    try {
      await _firestore.collection('documents').doc(docId).delete();
    } catch (e) {
      rethrow;
    }
  }

  
  Future<List<QueryDocumentSnapshot>> getExpiringDocuments(String familyId) async {
    try {
      final snapshot = await _firestore
          .collection('documents')
          .where('familyId', isEqualTo: familyId)
          .get();

      return snapshot.docs.where((doc) {
        var data = doc.data();
        var expiryDate = data['expiryDate'] as Timestamp?;
        if (expiryDate == null) return false;
        return isExpired(expiryDate.toDate());
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  
  List<QueryDocumentSnapshot> filterDocuments({
    required List<QueryDocumentSnapshot> docs,
    required String searchQuery,
    required String selectedType,
  }) {
    return docs.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      String name = (data['name'] ?? '').toString().toLowerCase();
      String type = (data['type'] ?? '').toString();
      List<String> tags = List<String>.from(data['tags'] ?? []);
      bool isConfidential = data['isConfidential'] ?? false;
      var expiryDate = data['expiryDate'] as Timestamp?;
      bool expired = expiryDate != null && isExpired(expiryDate.toDate());

      bool matchesSearch = searchQuery.isEmpty || 
          name.contains(searchQuery.toLowerCase()) ||
          tags.any((tag) => tag.toLowerCase().contains(searchQuery.toLowerCase()));
      
      bool matchesType = selectedType == 'All' ||
          type == selectedType ||
          (selectedType == 'Insurance' && tags.contains('Insurance')) ||
          (selectedType == 'Confidential' && isConfidential) ||
          (selectedType == 'Expiring' && expired);

      return matchesSearch && matchesType;
    }).toList();
  }

  
  bool isExpired(DateTime? expiryDate) {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate);
  }

  
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  
  String getFileIcon(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':
        return '📄';
      case 'DOC':
      case 'DOCX':
        return '📝';
      case 'TXT':
        return '📃';
      case 'JPG':
      case 'JPEG':
      case 'PNG':
      case 'GIF':
        return '🖼️';
      case 'XLS':
      case 'XLSX':
        return '📊';
      case 'ZIP':
      case 'RAR':
        return '📦';
      default:
        return '📁';
    }
  }

  
  bool isValidFileType(String fileName) {
    final validExtensions = [
      'pdf', 'doc', 'docx', 'txt', 
      'jpg', 'jpeg', 'png', 'gif',
      'xls', 'xlsx', 'zip', 'rar'
    ];
    
    final extension = path.extension(fileName).replaceAll('.', '').toLowerCase();
    return validExtensions.contains(extension);
  }

  
  Future<DocumentSnapshot> getDocument(String docId) async {
    try {
      return await _firestore.collection('documents').doc(docId).get();
    } catch (e) {
      rethrow;
    }
  }

  
  Future<void> updateDocumentMetadata({
    required String docId,
    List<String>? tags,
    DateTime? expiryDate,
    bool? isConfidential,
  }) async {
    try {
      Map<String, dynamic> updateData = {};
      
      if (tags != null) updateData['tags'] = tags;
      if (expiryDate != null) updateData['expiryDate'] = expiryDate;
      if (isConfidential != null) updateData['isConfidential'] = isConfidential;
      
      if (updateData.isNotEmpty) {
        await _firestore.collection('documents').doc(docId).update(updateData);
      }
    } catch (e) {
      rethrow;
    }
  }

  
  Future<int> getDocumentsCount(String familyId) async {
    try {
      final snapshot = await _firestore
          .collection('documents')
          .where('familyId', isEqualTo: familyId)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      rethrow;
    }
  }

  
  Future<int> getTotalStorageUsed(String familyId) async {
    try {
      final snapshot = await _firestore
          .collection('documents')
          .where('familyId', isEqualTo: familyId)
          .get();
      
      int totalSize = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalSize += (data['size'] as int?) ?? 0;
      }
      
      return totalSize;
    } catch (e) {
      rethrow;
    }
  }
}
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;

class DocumentSharingScreen extends StatefulWidget {
  final String familyId; 
  
  const DocumentSharingScreen({
    super.key,
    required this.familyId, 
  });

  @override
  State<DocumentSharingScreen> createState() => _DocumentSharingScreenState();
}

class _DocumentSharingScreenState extends State<DocumentSharingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isUploading = false;
  String _searchQuery = '';
  String _selectedType = 'All';
  
  static const int maxFileSize = 1 * 1024 * 1024;

  Future<void> _showAddDocumentSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddDocumentSheet(
        onUpload: (file, tags, expiryDate, isConfidential) async {
          await _uploadDocument(file, tags, expiryDate, isConfidential);
        },
      ),
    );
  }

  Future<void> _uploadDocument(
    PlatformFile pickedFile,
    List<String> tags,
    DateTime? expiryDate,
    bool isConfidential,
  ) async {
    try {
      if (pickedFile.size > maxFileSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File too large! Max ${_formatFileSize(maxFileSize)}'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      setState(() => _isUploading = true);

      
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
        'familyId': widget.familyId, 
        'uploadedAt': FieldValue.serverTimestamp(),
        'uploadedBy': 'user_id_here', 
      });

      setState(() => _isUploading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  
  Future<void> _viewDocument(Map<String, dynamic> data) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Opening document...'),
              ],
            ),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      final base64Data = data['data'] as String?;
      if (base64Data == null || base64Data.isEmpty) {
        throw Exception('Document data is missing');
      }

      final bytes = base64Decode(base64Data);
      final tempDir = await getTemporaryDirectory();
      final fileName = (data['name'] ?? 'document')
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final filePath = '${tempDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      if (!await file.exists() || await file.length() == 0) {
        throw Exception('Failed to create file');
      }

      final result = await OpenFile.open(filePath);
      
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open file: ${result.message}'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  
  Future<void> _shareDocument(Map<String, dynamic> data) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Preparing to share...'),
              ],
            ),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      final base64Data = data['data'] as String?;
      if (base64Data == null || base64Data.isEmpty) {
        throw Exception('Document data is missing');
      }

      final bytes = base64Decode(base64Data);
      final tempDir = await getTemporaryDirectory();
      final fileName = (data['name'] ?? 'document')
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final filePath = '${tempDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      if (!await file.exists()) {
        throw Exception('Failed to create file');
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Sharing: ${data['name']}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document shared successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteDocument(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firestore.collection('documents').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'DOC':
      case 'DOCX':
        return Icons.description;
      case 'TXT':
        return Icons.text_snippet;
      case 'JPG':
      case 'JPEG':
      case 'PNG':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  bool _isExpired(DateTime? expiryDate) {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate);
  }

  List<QueryDocumentSnapshot> _filterDocuments(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      String name = (data['name'] ?? '').toString().toLowerCase();
      String type = (data['type'] ?? '').toString();
      List<String> tags = List<String>.from(data['tags'] ?? []);
      var expiryDate = data['expiryDate'] as Timestamp?;
      bool isExpired = expiryDate != null && _isExpired(expiryDate.toDate());
      bool isConfidential = data['isConfidential'] ?? false;

      bool matchesSearch = _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));

      bool matchesType = _selectedType == 'All' ||
          type == _selectedType ||
          (_selectedType == 'Confidential' && isConfidential) ||
          (_selectedType == 'Expiring' && isExpired) ||
          (_selectedType == 'Insurance' && tags.contains('Insurance'));

      return matchesSearch && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            
            Container(
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                          maxWidth: 56,
                          maxHeight: 56,
                        ),
                        padding: EdgeInsets.all(screenWidth * 0.025),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.description,
                          color: Colors.blue.shade700,
                          size: math.min(28, 24 + textScaleFactor * 4),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Document Sharing',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: screenHeight * 0.003),
                            Text(
                              'Securely store and share important family documents',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _showAddDocumentSheet,
                      icon: Icon(
                        Icons.add,
                        size: math.min(20, 18 + textScaleFactor * 2),
                      ),
                      label: const Text(
                        'Add Document',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          vertical: math.max(12.0, 12.0 + textScaleFactor * 2),
                        ),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('documents')
                  .where('familyId', isEqualTo: widget.familyId) 
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                var expiringDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  var expiryDate = data['expiryDate'] as Timestamp?;
                  if (expiryDate == null) return false;
                  return _isExpired(expiryDate.toDate());
                }).toList();

                if (expiringDocs.isEmpty) return const SizedBox();

                return Container(
                  margin: EdgeInsets.all(screenWidth * 0.04),
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red.shade700,
                            size: math.min(20, 18 + textScaleFactor * 2),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Expanded(
                            child: Text(
                              'Expiring Documents',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      ...expiringDocs.take(2).map((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        return Padding(
                          padding: EdgeInsets.only(bottom: screenHeight * 0.01),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.02,
                                  vertical: screenHeight * 0.005,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade700,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Expired',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Expanded(
                                child: Text(
                                  data['name'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: screenHeight * 0.01),

            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search documents...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade400,
                    size: math.min(24, 20 + textScaleFactor * 4),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: math.max(12.0, 12.0 + textScaleFactor * 2),
                  ),
                ),
              ),
            ),

            
            Container(
              height: math.max(50.0, 46.0 + textScaleFactor * 8),
              margin: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.015,
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  'All',
                  'PDF',
                  'DOC',
                  'Insurance',
                  'Confidential',
                  'Expiring'
                ].map((type) {
                  bool isSelected = _selectedType == type;
                  return Padding(
                    padding: EdgeInsets.only(right: screenWidth * 0.02),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) =>
                          setState(() => _selectedType = type),
                      backgroundColor: Colors.white,
                      selectedColor: Colors.blue.shade100,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.blue.shade700
                            : Colors.grey.shade700,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.blue.shade300
                            : Colors.grey.shade300,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: screenHeight * 0.008,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('documents')
                    .where('familyId', isEqualTo: widget.familyId) 
                    .orderBy('uploadedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: math.min(80, 60 + textScaleFactor * 20),
                            color: Colors.red.shade300,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: math.min(80, 60 + textScaleFactor * 20),
                            color: Colors.grey.shade300,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            'No documents yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            'Tap "Add Document" to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  var filteredDocs = _filterDocuments(snapshot.data!.docs);

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: math.min(80, 60 + textScaleFactor * 20),
                            color: Colors.grey.shade300,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            'No matching documents',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.01,
                    ),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      var doc = filteredDocs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      var tags = List<String>.from(data['tags'] ?? []);
                      var expiryDate = data['expiryDate'] as Timestamp?;
                      bool isExpired =
                          expiryDate != null && _isExpired(expiryDate.toDate());

                      return Container(
                        margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(screenWidth * 0.035),
                          leading: Container(
                            constraints: BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                              maxWidth: 56,
                              maxHeight: 56,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getFileIcon(data['type'] ?? ''),
                              color: Colors.blue.shade700,
                              size: math.min(24, 20 + textScaleFactor * 4),
                            ),
                          ),
                          title: Text(
                            data['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: screenHeight * 0.008),
                              Row(
                                children: [
                                  if (data['isConfidential'] == true) ...[
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.02,
                                        vertical: screenHeight * 0.004,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: Colors.orange.shade300),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.lock,
                                            size: 12,
                                            color: Colors.orange.shade700,
                                          ),
                                          SizedBox(width: screenWidth * 0.01),
                                          Text(
                                            'Confidential',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.015),
                                  ],
                                  if (data['type'] != null)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.02,
                                        vertical: screenHeight * 0.004,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        data['type'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (tags.isNotEmpty) ...[
                                SizedBox(height: screenHeight * 0.008),
                                Wrap(
                                  spacing: screenWidth * 0.015,
                                  runSpacing: screenHeight * 0.005,
                                  children: tags
                                      .map((tag) => Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: screenWidth * 0.02,
                                              vertical: screenHeight * 0.003,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              tag,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ],
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                'Size: ${_formatFileSize(data['size'] ?? 0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              if (isExpired)
                                Padding(
                                  padding: EdgeInsets.only(
                                      top: screenHeight * 0.005),
                                  child: Text(
                                    '⚠️ Expired',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Container(
                            constraints: BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.more_vert,
                                color: Colors.grey.shade600,
                                size: math.min(24, 20 + textScaleFactor * 4),
                              ),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (context) => SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          margin: EdgeInsets.symmetric(
                                            vertical: screenHeight * 0.015,
                                          ),
                                          width: screenWidth * 0.12,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                        ListTile(
                                          leading: Icon(
                                            Icons.visibility,
                                            color: Colors.blue.shade700,
                                          ),
                                          title: const Text('View'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _viewDocument(data);
                                          },
                                        ),
                                        ListTile(
                                          leading: Icon(
                                            Icons.share,
                                            color: Colors.green.shade700,
                                          ),
                                          title: const Text('Share'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _shareDocument(data);
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          title: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _deleteDocument(doc.id);
                                          },
                                        ),
                                        SizedBox(height: screenHeight * 0.02),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddDocumentSheet extends StatefulWidget {
  final Function(PlatformFile, List<String>, DateTime?, bool) onUpload;

  const AddDocumentSheet({super.key, required this.onUpload});

  @override
  State<AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends State<AddDocumentSheet> {
  PlatformFile? _selectedFile;
  final List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();
  DateTime? _expiryDate;
  bool _isConfidential = false;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png', 'jpeg'],
      );

      if (result != null) {
        setState(() => _selectedFile = result.files.first);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  void _addTag() {
    if (_tagController.text.isNotEmpty) {
      setState(() {
        _tags.add(_tagController.text);
        _tagController.clear();
      });
    }
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Add Document',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    constraints: BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.025),

              
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedFile != null
                          ? Colors.blue.shade300
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedFile != null
                        ? Colors.blue.shade50
                        : Colors.grey.shade50,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null
                            ? Icons.check_circle
                            : Icons.upload_file,
                        size: math.min(48, 40 + textScaleFactor * 8),
                        color: _selectedFile != null
                            ? Colors.blue.shade700
                            : Colors.grey.shade400,
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        _selectedFile?.name ?? 'Tap to select file',
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedFile != null
                              ? Colors.black
                              : Colors.grey.shade600,
                          fontWeight: _selectedFile != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_selectedFile != null) ...[
                        SizedBox(height: screenHeight * 0.008),
                        Text(
                          'Size: ${_formatFileSize(_selectedFile!.size)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.025),

              
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.015,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lock,
                          size: math.min(20, 18 + textScaleFactor * 2),
                          color: Colors.grey.shade700,
                        ),
                        SizedBox(width: screenWidth * 0.025),
                        const Text(
                          'Mark as Confidential',
                          style: TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isConfidential,
                      onChanged: (value) =>
                          setState(() => _isConfidential = value),
                      activeThumbColor: Colors.orange.shade700,
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.025),

              
              InkWell(
                onTap: _selectExpiryDate,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: math.min(20, 18 + textScaleFactor * 2),
                            color: Colors.grey.shade700,
                          ),
                          SizedBox(width: screenWidth * 0.025),
                          Flexible(
                            child: Text(
                              _expiryDate == null
                                  ? 'Set Expiry Date (Optional)'
                                  : 'Expires: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                              style: const TextStyle(fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.025),

              
              const Text(
                'Tags',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: screenHeight * 0.012),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        hintText: 'Add tag (e.g., Important, Insurance)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: math.max(12.0, 12.0 + textScaleFactor * 2),
                        ),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Container(
                    constraints: BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    child: IconButton(
                      onPressed: _addTag,
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              if (_tags.isNotEmpty) ...[
                SizedBox(height: screenHeight * 0.015),
                Wrap(
                  spacing: screenWidth * 0.02,
                  runSpacing: screenHeight * 0.01,
                  children: _tags
                      .map((tag) => Chip(
                            label: Text(tag),
                            deleteIcon: Icon(
                              Icons.close,
                              size: math.min(18, 16 + textScaleFactor * 2),
                            ),
                            onDeleted: () => setState(() => _tags.remove(tag)),
                          ))
                      .toList(),
                ),
              ],

              SizedBox(height: screenHeight * 0.03),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedFile == null
                      ? null
                      : () {
                          widget.onUpload(
                            _selectedFile!,
                            _tags,
                            _expiryDate,
                            _isConfidential,
                          );
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: EdgeInsets.symmetric(
                      vertical: math.max(14.0, 14.0 + textScaleFactor * 2),
                    ),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Upload Document',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;

class DocumentSharingScreen extends StatefulWidget {
  const DocumentSharingScreen({super.key});

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
              content: Text(
                'File too large! Max ${_formatFileSize(maxFileSize)}',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (pickedFile.path == null) {
        throw Exception('Cannot access file path');
      }

      setState(() => _isUploading = true);

      File file = File(pickedFile.path!);
      List<int> fileBytes = await file.readAsBytes();
      String base64File = base64Encode(fileBytes);

      await _firestore.collection('documents').add({
        'name': pickedFile.name,
        'data': base64File,
        'size': pickedFile.size,
        'type': path.extension(pickedFile.name).replaceAll('.', '').toUpperCase(),
        'tags': tags,
        'expiryDate': expiryDate,
        'isConfidential': isConfidential,
        'uploadedAt': FieldValue.serverTimestamp(),
        'uploadedBy': 'user_id_here',
      });

      setState(() => _isUploading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteDocument(String docId) async {
    try {
      await _firestore.collection('documents').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
      
      bool matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());
      bool matchesType = _selectedType == 'All' || type == _selectedType;
      
      return matchesSearch && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            
            Container(
              padding: const EdgeInsets.all(20),
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.description, color: Colors.blue.shade700, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Document Sharing',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            Text(
                              'Securely store and share important family documents',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _showAddDocumentSheet,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Add Document', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
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
              stream: _firestore.collection('documents').snapshots(),
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
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
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
                          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Expiring Documents',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...expiringDocs.take(2).map((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade700,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Expired',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data['name'] ?? '',
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
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
            SizedBox(
              height: 10,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search documents...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['All', 'PDF', 'DOC', 'Insurance', 'Confidential', 'Expiring'].map((type) {
                  bool isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) => setState(() => _selectedType = type),
                      backgroundColor: Colors.white,
                      selectedColor: Colors.blue.shade100,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('documents').orderBy('uploadedAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('No documents yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }

                  var filteredDocs = _filterDocuments(snapshot.data!.docs);

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      var doc = filteredDocs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      var tags = List<String>.from(data['tags'] ?? []);
                      var expiryDate = data['expiryDate'] as Timestamp?;
                      bool isExpired = expiryDate != null && _isExpired(expiryDate.toDate());

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                          contentPadding: const EdgeInsets.all(14),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(_getFileIcon(data['type'] ?? ''), color: Colors.blue.shade700, size: 24),
                          ),
                          title: Text(
                            data['name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (data['isConfidential'] == true) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.orange.shade300),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.lock, size: 12, color: Colors.orange.shade700),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Confidential',
                                            style: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  if (data['type'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        data['type'],
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (tags.isNotEmpty)
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: tags.map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
                                    ),
                                  )).toList(),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                'Size: ${_formatFileSize(data['size'] ?? 0)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                              if (isExpired)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '⚠️ Expired',
                                    style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.visibility),
                                        title: const Text('View'),
                                        onTap: () => Navigator.pop(context),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.share),
                                        title: const Text('Share'),
                                        onTap: () => Navigator.pop(context),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.delete, color: Colors.red),
                                        title: const Text('Delete', style: TextStyle(color: Colors.red)),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _deleteDocument(doc.id);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
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
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Document',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              
              InkWell(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.upload_file, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFile?.name ?? 'Tap to select file',
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedFile != null ? Colors.black : Colors.grey.shade600,
                          fontWeight: _selectedFile != null ? FontWeight.w600 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock, size: 20, color: Colors.grey.shade700),
                        const SizedBox(width: 10),
                        const Text('Mark as Confidential', style: TextStyle(fontSize: 15)),
                      ],
                    ),
                    Switch(
                      value: _isConfidential,
                      onChanged: (value) => setState(() => _isConfidential = value),
                      activeThumbColor: Colors.orange.shade700,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              
              InkWell(
                onTap: _selectExpiryDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 20, color: Colors.grey.shade700),
                          const SizedBox(width: 10),
                          Text(
                            _expiryDate == null
                                ? 'Set Expiry Date (Optional)'
                                : 'Expires: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              
              const Text('Tags', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addTag,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) => Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                  )).toList(),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedFile == null
                      ? null
                      : () {
                          widget.onUpload(_selectedFile!, _tags, _expiryDate, _isConfidential);
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Upload Document', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
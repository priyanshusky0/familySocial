import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PasswordItem {
  final String id;
  final String service;
  final String username;
  final String password;
  final String iconName;
  final String colorHex;

  PasswordItem({
    required this.id,
    required this.service,
    required this.username,
    required this.password,
    required this.iconName,
    required this.colorHex,
  });

  IconData get icon {
    switch (iconName) {
      case 'movie':
        return Icons.movie_rounded;
      case 'wifi':
        return Icons.wifi_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'key':
        return Icons.key_rounded;
      default:
        return Icons.lock_rounded;
    }
  }

  Color get color {
    return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
  }

  Map<String, dynamic> toMap() {
    return {
      'service': service,
      'username': username,
      'password': password,
      'iconName': iconName,
      'colorHex': colorHex,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory PasswordItem.fromFirestore(String id, Map<String, dynamic> data) {
    return PasswordItem(
      id: id,
      service: data['service'] ?? '',
      username: data['username'] ?? '',
      password: data['password'] ?? '',
      iconName: data['iconName'] ?? 'key',
      colorHex: data['colorHex'] ?? '#4169E1',
    );
  }
}

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get passwordsCollection =>
      _firestore.collection('passwords');

  Stream<List<PasswordItem>> getPasswords() {
    return passwordsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PasswordItem.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  Future<void> addPassword(PasswordItem item) async {
    await passwordsCollection.add(item.toMap());
  }

  Future<void> updatePassword(String id, PasswordItem item) async {
    await passwordsCollection.doc(id).update({
      'service': item.service,
      'username': item.username,
      'password': item.password,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePassword(String id) async {
    await passwordsCollection.doc(id).delete();
  }
}

class PasswordVaultScreen extends StatefulWidget {
  const PasswordVaultScreen({super.key});

  @override
  State<PasswordVaultScreen> createState() => _PasswordVaultScreenState();
}

class _PasswordVaultScreenState extends State<PasswordVaultScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  void _showAddPasswordDialog() {
    final serviceController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedIcon = 'key';
    String selectedColor = '#7B68EE';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Add New Password',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: serviceController,
                  decoration: InputDecoration(
                    labelText: 'Service Name',
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.business_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username/Email',
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.person_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.lock_rounded),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Icon: '),
                    const SizedBox(width: 8),
                    ...[
                      ('movie', Icons.movie_rounded),
                      ('wifi', Icons.wifi_rounded),
                      ('shopping', Icons.shopping_bag_rounded),
                      ('key', Icons.key_rounded),
                    ].map((iconData) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedIcon = iconData.$1;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selectedIcon == iconData.$1
                                ? const Color(0xFF4169E1).withOpacity(0.1)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            iconData.$2,
                            color: selectedIcon == iconData.$1
                                ? const Color(0xFF4169E1)
                                : Colors.grey,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (serviceController.text.isNotEmpty &&
                    usernameController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty) {
                  try {
                    await _firebaseService.addPassword(
                      PasswordItem(
                        id: '',
                        service: serviceController.text,
                        username: usernameController.text,
                        password: passwordController.text,
                        iconName: selectedIcon,
                        colorHex: selectedColor,
                      ),
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Password added successfully'),
                          backgroundColor: const Color(0xFF4169E1),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4169E1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPasswordDetails(PasswordItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PasswordDetailsSheet(item: item),
    );
  }

  void _deletePassword(String id) async {
    try {
      await _firebaseService.deletePassword(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password deleted'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password Vault',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          'Passwords & docs',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.search_rounded),
                      color: const Color(0xFF6B7280),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
            StreamBuilder<List<PasswordItem>>(
              stream: _firebaseService.getPasswords(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final passwords = snapshot.data!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Color.fromARGB(255, 130, 167, 232)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Stored Passwords',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${passwords.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.shield_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Your Passwords',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<PasswordItem>>(
                stream: _firebaseService.getPasswords(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final passwords = snapshot.data ?? [];

                  if (passwords.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.lock_open_rounded,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No passwords stored yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: passwords.length,
                    itemBuilder: (context, index) {
                      final item = passwords[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              item.icon,
                              color: item.color,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            item.service,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              item.username,
                              style: const TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          trailing: PopupMenuButton(
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: Colors.grey[400],
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility_rounded, size: 20),
                                    SizedBox(width: 12),
                                    Text('View Details'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_rounded,
                                        size: 20, color: Colors.red),
                                    SizedBox(width: 12),
                                    Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'view') {
                                _showPasswordDetails(item);
                              } else if (value == 'delete') {
                                _deletePassword(item.id);
                              }
                            },
                          ),
                          onTap: () => _showPasswordDetails(item),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPasswordDialog,
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Password',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 4,
      ),
    );
  }
}

class PasswordDetailsSheet extends StatefulWidget {
  final PasswordItem item;

  const PasswordDetailsSheet({super.key, required this.item});

  @override
  State<PasswordDetailsSheet> createState() => _PasswordDetailsSheetState();
}

class _PasswordDetailsSheetState extends State<PasswordDetailsSheet> {
  bool _isPasswordVisible = false;

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        backgroundColor: const Color(0xFF4169E1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: widget.item.color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.item.icon,
                  color: widget.item.color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.service,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Account Details',
                      style: TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildDetailRow(
            'Username',
            widget.item.username,
            Icons.person_outline_rounded,
            () => _copyToClipboard(widget.item.username, 'Username'),
          ),
          const SizedBox(height: 16),
         _buildDetailRow(
            'Password',
            _isPasswordVisible ? widget.item.password : '••••••••',
            Icons.lock_outline_rounded,
            () => _copyToClipboard(widget.item.password, 'Password'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  color: const Color(0xFF4169E1),
                  onPressed: () => _copyToClipboard(widget.item.password, 'Password'),
                ),
                IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: const Color(0xFF4169E1),
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    VoidCallback onCopy, {
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            trailing
          else
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 20),
              color: const Color(0xFF4169E1),
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }
}
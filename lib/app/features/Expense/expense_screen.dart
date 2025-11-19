import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResponsiveHelper {
  final BuildContext context;
  
  ResponsiveHelper(this.context);

  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;
  
  double fontSize(double baseSize) => baseSize * (screenWidth / 375);
  double spacing(double baseSpacing) => baseSpacing * (screenWidth / 375);
  
  EdgeInsets paddingSymmetric({required double horizontal, required double vertical}) {
    return EdgeInsets.symmetric(
      horizontal: spacing(horizontal),
      vertical: spacing(vertical),
    );
  }
  
  EdgeInsets paddingAll(double value) => EdgeInsets.all(spacing(value));
  
  EdgeInsets paddingFromLTRB(double l, double t, double r, double b) {
    return EdgeInsets.fromLTRB(spacing(l), spacing(t), spacing(r), spacing(b));
  }
}

class ExpenseTrackingScreen extends StatefulWidget {
  final String familyId;
  final String currentUserId;

  const ExpenseTrackingScreen({
    super.key,
    required this.familyId,
    required this.currentUserId,
  });

  @override
  State<ExpenseTrackingScreen> createState() => _ExpenseTrackingScreenState();
}

class _ExpenseTrackingScreenState extends State<ExpenseTrackingScreen> {
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF6B7280);

  late FirebaseFirestore _firestore;
  List<Map<String, dynamic>> familyMembers = [];
  bool _isLoadingMembers = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _fetchFamilyMembers();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFamilyMembers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('familyId', isEqualTo: widget.familyId)
          .get();
      
      if (mounted) {
        setState(() {
          familyMembers = snapshot.docs
              .map((doc) => {
                'uid': doc.id,
                'name': doc.data()['name'] ?? 'Unknown',
                'email': doc.data()['email'] ?? '',
              })
              .toList();
          _isLoadingMembers = false;
        });
      }
    } catch (e) {
      print('Error fetching family members: $e');
      if (mounted) {
        setState(() {
          _isLoadingMembers = false;
        });
      }
    }
  }

  void _addExpense() {
    if (_isLoadingMembers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loading family members...', style: GoogleFonts.inter()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (familyMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No family members found', style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddExpenseDialog(
        familyId: widget.familyId,
        currentUserId: widget.currentUserId,
        familyMembers: familyMembers,
      ),
    );
  }

  Future<void> _deleteExpense(String expenseId) async {
    try {
      await _firestore
          .collection('families')
          .doc(widget.familyId)
          .collection('expenses')
          .doc(expenseId)
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense deleted', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: textDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: responsive.spacing(140),
            collapsedHeight: responsive.spacing(140),
            backgroundColor: cardWhite,
            automaticallyImplyLeading: false,
            elevation: 0,
            flexibleSpace: SafeArea(
              child: Padding(
                padding: responsive.paddingFromLTRB(20, 12, 20, 16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expense Tracking',
                                  style: GoogleFonts.inter(
                                    fontSize: responsive.fontSize(18),
                                    fontWeight: FontWeight.w600,
                                    color: textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                SizedBox(height: responsive.spacing(2)),
                                Text(
                                  'Manage family expenses',
                                  style: GoogleFonts.inter(
                                    fontSize: responsive.fontSize(13),
                                    fontWeight: FontWeight.w400,
                                    color: textGrey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: responsive.spacing(40),
                            height: responsive.spacing(40),
                            decoration: BoxDecoration(
                              color: primaryBlue,
                              borderRadius: BorderRadius.circular(responsive.spacing(10)),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.add,
                                size: responsive.fontSize(20),
                              ),
                              color: Colors.white,
                              padding: EdgeInsets.zero,
                              onPressed: _addExpense,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: responsive.spacing(16)),
                      Container(
                        height: responsive.spacing(46),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(responsive.spacing(12)),
                          border: Border.all(color: lightBlue.withOpacity(0.3), width: 1),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Search expenses...",
                            hintStyle: GoogleFonts.inter(fontSize: responsive.fontSize(14), color: textGrey.withOpacity(0.6)),
                            border: InputBorder.none,
                            contentPadding: responsive.paddingSymmetric(horizontal: 16, vertical: 12),
                            prefixIcon: Icon(Icons.search_rounded, color: primaryBlue.withOpacity(0.7), size: responsive.fontSize(22)),
                            prefixIconConstraints: BoxConstraints(minWidth: responsive.spacing(48)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: textGrey, size: responsive.fontSize(20)),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: responsive.paddingAll(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSummaryCard(responsive),
                SizedBox(height: responsive.spacing(24)),
                _buildCategoryBreakdown(responsive),
                SizedBox(height: responsive.spacing(24)),
                Text('Recent Expenses', style: GoogleFonts.inter(fontSize: responsive.fontSize(18), fontWeight: FontWeight.w600, color: textDark)),
                SizedBox(height: responsive.spacing(4)),
                Text('Latest transactions', style: GoogleFonts.inter(fontSize: responsive.fontSize(13), fontWeight: FontWeight.w400, color: textGrey)),
                SizedBox(height: responsive.spacing(16)),
                _buildExpensesList(responsive),
                SizedBox(height: responsive.spacing(30)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ResponsiveHelper responsive) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('families')
          .doc(widget.familyId)
          .collection('expenses')
          .snapshots(),
      builder: (context, snapshot) {
        double total = 0;
        
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['amount'] != null) {
              total += (data['amount'] as num).toDouble();
            }
          }
        }

        return Container(
          padding: responsive.paddingAll(16),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(responsive.spacing(16)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: responsive.spacing(48),
                height: responsive.spacing(48),
                decoration: BoxDecoration(color: lightBlue, borderRadius: BorderRadius.circular(responsive.spacing(12))),
                child: Icon(Icons.account_balance_wallet, color: primaryBlue, size: responsive.fontSize(24)),
              ),
              SizedBox(width: responsive.spacing(16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Text('Total Expenses', style: GoogleFonts.inter(fontSize: responsive.fontSize(13), fontWeight: FontWeight.w500, color: textGrey)), SizedBox(width: responsive.spacing(4)), Icon(total == 0 ? Icons.info_outline : Icons.trending_up, size: responsive.fontSize(14), color: textGrey.withOpacity(0.5))]),
                    SizedBox(height: responsive.spacing(4)),
                    Text(total == 0 ? '\$0.00' : '\$${total.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: responsive.fontSize(24), fontWeight: FontWeight.w700, color: total == 0 ? textGrey : textDark)),
                    SizedBox(height: responsive.spacing(2)),
                    Text(total == 0 ? 'No expenses added yet' : 'Family expenses', style: GoogleFonts.inter(fontSize: responsive.fontSize(12), fontWeight: FontWeight.w400, color: textGrey)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: textGrey.withOpacity(0.3), size: responsive.fontSize(24)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryBreakdown(ResponsiveHelper responsive) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('families')
          .doc(widget.familyId)
          .collection('expenses')
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, double> categoryTotals = {};

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            String category = data['category'] ?? 'Other';
            if (data['amount'] != null) {
              double amount = (data['amount'] as num).toDouble();
              categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
            }
          }
        }

        if (categoryTotals.isEmpty) {
          return Container(
            padding: responsive.paddingAll(24),
            decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(responsive.spacing(16)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))]),
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.category_outlined, size: responsive.fontSize(44), color: textGrey.withOpacity(0.4)),
                SizedBox(height: responsive.spacing(12)),
                Text('Category Breakdown', style: GoogleFonts.inter(fontSize: responsive.fontSize(14), fontWeight: FontWeight.w600, color: textGrey)),
                SizedBox(height: responsive.spacing(6)),
                Text('Add expenses to see breakdown', style: GoogleFonts.inter(fontSize: responsive.fontSize(12), fontWeight: FontWeight.w400, color: textGrey.withOpacity(0.6)), textAlign: TextAlign.center),
              ]),
            ),
          );
        }

        double totalExpense = categoryTotals.values.fold(0, (sum, amount) => sum + amount);

        return Container(
          padding: responsive.paddingAll(16),
          decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(responsive.spacing(16)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category Breakdown', style: GoogleFonts.inter(color: textDark, fontSize: responsive.fontSize(16), fontWeight: FontWeight.w600)),
              SizedBox(height: responsive.spacing(12)),
              ...categoryTotals.entries.map((entry) {
                double percentage = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0;
                return Padding(
                  padding: EdgeInsets.only(bottom: responsive.spacing(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(entry.key, style: GoogleFonts.inter(color: textDark, fontWeight: FontWeight.w600, fontSize: responsive.fontSize(13)), overflow: TextOverflow.ellipsis)), Text('\$${entry.value.toStringAsFixed(2)}', style: GoogleFonts.inter(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: responsive.fontSize(13)))]),
                    SizedBox(height: responsive.spacing(6)),
                    ClipRRect(borderRadius: BorderRadius.circular(responsive.spacing(4)), child: LinearProgressIndicator(value: percentage / 100, minHeight: responsive.spacing(6), backgroundColor: lightBlue, valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue))),
                  ]),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpensesList(ResponsiveHelper responsive) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('families')
          .doc(widget.familyId)
          .collection('expenses')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryBlue));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(children: [
              Icon(Icons.error_outline, size: responsive.fontSize(48), color: Colors.red),
              SizedBox(height: responsive.spacing(12)),
              Text('Error loading expenses', style: GoogleFonts.inter(fontSize: responsive.fontSize(16), color: textGrey, fontWeight: FontWeight.w500))
            ]),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(children: [Icon(Icons.receipt_long, size: responsive.fontSize(48), color: textGrey), SizedBox(height: responsive.spacing(12)), Text('No expenses yet', style: GoogleFonts.inter(fontSize: responsive.fontSize(16), color: textGrey, fontWeight: FontWeight.w500))]),
          );
        }

        
        final filteredDocs = snapshot.data!.docs.where((doc) {
          if (_searchQuery.isEmpty) return true;
          
          try {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toString().toLowerCase();
            final category = (data['category'] ?? '').toString().toLowerCase();
            final memberName = (data['memberName'] ?? data['member'] ?? '').toString().toLowerCase();
            final amount = (data['amount'] ?? 0).toString();
            
            return title.contains(_searchQuery) ||
                   category.contains(_searchQuery) ||
                   memberName.contains(_searchQuery) ||
                   amount.contains(_searchQuery);
          } catch (e) {
            return false;
          }
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(children: [
              Icon(Icons.search_off, size: responsive.fontSize(48), color: textGrey),
              SizedBox(height: responsive.spacing(12)),
              Text('No expenses found', style: GoogleFonts.inter(fontSize: responsive.fontSize(16), color: textGrey, fontWeight: FontWeight.w500)),
              SizedBox(height: responsive.spacing(4)),
              Text('Try a different search term', style: GoogleFonts.inter(fontSize: responsive.fontSize(13), color: textGrey.withOpacity(0.7)))
            ]),
          );
        }

        return Column(
          children: filteredDocs.map((doc) {
            try {
              final expense = Expense.fromFirestore(doc);
              return _buildExpenseItem(responsive, expense, doc.id);
            } catch (e) {
              print('Error parsing expense: $e');
              return SizedBox.shrink();
            }
          }).toList(),
        );
      },
    );
  }

  Widget _buildExpenseItem(ResponsiveHelper responsive, Expense expense, String docId) {
    return Container(
      margin: EdgeInsets.only(bottom: responsive.spacing(12)),
      padding: responsive.paddingAll(16),
      decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(responsive.spacing(14)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Container(width: responsive.spacing(44), height: responsive.spacing(44), decoration: BoxDecoration(color: lightBlue, borderRadius: BorderRadius.circular(responsive.spacing(12))), child: Icon(expense.icon, color: primaryBlue, size: responsive.fontSize(22))),
          SizedBox(width: responsive.spacing(12)),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(expense.title, style: GoogleFonts.inter(color: textDark, fontWeight: FontWeight.w600, fontSize: responsive.fontSize(14)), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: responsive.spacing(4)),
              Row(children: [Expanded(child: Text(expense.category, style: GoogleFonts.inter(color: textGrey, fontSize: responsive.fontSize(12)), overflow: TextOverflow.ellipsis)), SizedBox(width: responsive.spacing(8)), Text('• ${expense.memberName}', style: GoogleFonts.inter(color: textGrey, fontSize: responsive.fontSize(12)), overflow: TextOverflow.ellipsis)]),
            ]),
          ),
          SizedBox(width: responsive.spacing(12)),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${expense.amount.toStringAsFixed(2)}', style: GoogleFonts.inter(color: textDark, fontWeight: FontWeight.bold, fontSize: responsive.fontSize(15))),
            SizedBox(height: responsive.spacing(4)),
            GestureDetector(onTap: () => _confirmDelete(expense, docId), child: Icon(Icons.delete_outline, color: Colors.red.shade600, size: responsive.fontSize(18))),
          ]),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Expense expense, String docId) async {
    final confirm = await showDialog<bool>(context: context, builder: (context) {
      final responsive = ResponsiveHelper(context);
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(responsive.spacing(20))),
        backgroundColor: cardWhite,
        title: Row(children: [Container(width: responsive.spacing(40), height: responsive.spacing(40), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(responsive.spacing(10))), child: Icon(Icons.delete_outline, color: Colors.red.shade600, size: responsive.fontSize(20))), SizedBox(width: responsive.spacing(12)), Expanded(child: Text('Delete Expense?', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: responsive.fontSize(18)), overflow: TextOverflow.ellipsis))]),
        content: Text('Are you sure you want to delete "${expense.title}"?', style: GoogleFonts.inter(fontSize: responsive.fontSize(14), color: textGrey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), style: TextButton.styleFrom(padding: responsive.paddingSymmetric(horizontal: 20, vertical: 12)), child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: responsive.fontSize(14), color: textGrey))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, padding: responsive.paddingSymmetric(horizontal: 20, vertical: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(responsive.spacing(10)))), child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: responsive.fontSize(14), color: Colors.white))),
        ],
      );
    });

    if (confirm == true) {
      await _deleteExpense(docId);
    }
  }
}

class Expense {
  final String title;
  final double amount;
  final String category;
  final String memberName;
  final DateTime createdAt;
  final IconData icon;

  Expense({
    required this.title,
    required this.amount,
    required this.category,
    required this.memberName,
    required this.createdAt,
    required this.icon,
  });

  factory Expense.fromFirestore(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final categoryIcons = {
      'Food': Icons.shopping_cart,
      'Utilities': Icons.electric_bolt,
      'Entertainment': Icons.movie,
      'Transport': Icons.directions_car,
    };

    return Expense(
      title: data['title'] ?? 'Untitled',
      amount: data['amount'] != null ? (data['amount'] as num).toDouble() : 0.0,
      category: data['category'] ?? 'Other',
      memberName: data['memberName'] ?? data['member'] ?? 'Unknown',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      icon: categoryIcons[data['category']] ?? Icons.shopping_cart,
    );
  }
}

class AddExpenseDialog extends StatefulWidget {
  final String familyId;
  final String currentUserId;
  final List<Map<String, dynamic>> familyMembers;

  const AddExpenseDialog({
    super.key,
    required this.familyId,
    required this.currentUserId,
    required this.familyMembers,
  });

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';
  String? _selectedMemberId;
  late FirebaseFirestore _firestore;
  bool _isLoading = false;

  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF6B7280);

  final Map<String, IconData> _categoryIcons = {
    'Food': Icons.shopping_cart,
    'Utilities': Icons.electric_bolt,
    'Entertainment': Icons.movie,
    'Transport': Icons.directions_car,
  };

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    
    if (widget.familyMembers.isNotEmpty) {
      _selectedMemberId = widget.familyMembers[0]['uid']?.toString();
    }
  }

  Future<void> _submitExpense() async {
    if (_titleController.text.trim().isEmpty || _amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields', style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid amount', style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedMemberId == null || _selectedMemberId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a family member', style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final member = widget.familyMembers.firstWhere(
        (m) => m['uid']?.toString() == _selectedMemberId,
        orElse: () => {'uid': _selectedMemberId, 'name': 'Unknown'},
      );
      
      final memberName = member['name'] ?? 'Unknown';
      
      await _firestore
          .collection('families')
          .doc(widget.familyId)
          .collection('expenses')
          .add({
        'title': _titleController.text.trim(),
        'amount': amount,
        'category': _selectedCategory,
        'memberId': _selectedMemberId,
        'memberName': memberName,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': widget.currentUserId,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense added for $memberName', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(responsive.spacing(20))),
      backgroundColor: cardWhite,
      insetPadding: responsive.paddingAll(16),
      child: SingleChildScrollView(
        child: Padding(
          padding: responsive.paddingAll(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: responsive.spacing(48), height: responsive.spacing(48), decoration: BoxDecoration(color: lightBlue, borderRadius: BorderRadius.circular(responsive.spacing(12))), child: Icon(Icons.add_card, color: primaryBlue, size: responsive.fontSize(24))),
              SizedBox(width: responsive.spacing(16)),
              Expanded(child: Text('Add Expense', style: GoogleFonts.inter(color: textDark, fontSize: responsive.fontSize(20), fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
              IconButton(icon: Icon(Icons.close, size: responsive.fontSize(22)), onPressed: () => Navigator.pop(context), color: textGrey),
            ]),
            SizedBox(height: responsive.spacing(24)),
            Text('Expense Title', style: GoogleFonts.inter(fontSize: responsive.fontSize(14), fontWeight: FontWeight.w600, color: textDark)),
            SizedBox(height: responsive.spacing(8)),
            TextField(controller: _titleController, decoration: InputDecoration(hintText: 'e.g., Grocery Shopping', hintStyle: GoogleFonts.inter(fontSize: responsive.fontSize(14), color: textGrey), filled: true, fillColor: backgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(responsive.spacing(12)), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(responsive.spacing(12)), borderSide: const BorderSide(color: primaryBlue, width: 2)), contentPadding: responsive.paddingSymmetric(horizontal: 16, vertical: 14)), style: GoogleFonts.inter(fontSize: responsive.fontSize(15))),
            SizedBox(height: responsive.spacing(16)),
            Text('Amount', style: GoogleFonts.inter(fontSize: responsive.fontSize(14), fontWeight: FontWeight.w600, color: textDark)),
            SizedBox(height: responsive.spacing(8)),
            TextField(controller: _amountController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(hintText: '0.00', prefixText: '\$ ', hintStyle: GoogleFonts.inter(fontSize: responsive.fontSize(14), color: textGrey), filled: true, fillColor: backgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(responsive.spacing(12)), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(responsive.spacing(12)), borderSide: const BorderSide(color: primaryBlue, width: 2)), contentPadding: responsive.paddingSymmetric(horizontal: 16, vertical: 14)), style: GoogleFonts.inter(fontSize: responsive.fontSize(15))),
            SizedBox(height: responsive.spacing(16)),
            Text('Category', style: GoogleFonts.inter(fontSize: responsive.fontSize(14), fontWeight: FontWeight.w600, color: textDark)),
            SizedBox(height: responsive.spacing(8)),
            Container(
              decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(responsive.spacing(12))),
              padding: responsive.paddingSymmetric(horizontal: 12, vertical: 4),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedCategory,
                underline: SizedBox(),
                icon: Icon(Icons.arrow_drop_down, color: primaryBlue, size: responsive.fontSize(24)),
                style: GoogleFonts.inter(fontSize: responsive.fontSize(14), color: textDark),
                dropdownColor: Colors.white,
                items: ['Food', 'Utilities', 'Entertainment', 'Transport'].map((item) => DropdownMenuItem(value: item, child: Text(item, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
            ),
            SizedBox(height: responsive.spacing(16)),
            Text('Member', style: GoogleFonts.inter(fontSize: responsive.fontSize(14), fontWeight: FontWeight.w600, color: textDark)),
            SizedBox(height: responsive.spacing(8)),
            Container(
              decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(responsive.spacing(12))),
              padding: responsive.paddingSymmetric(horizontal: 12, vertical: 4),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedMemberId,
                underline: SizedBox(),
                icon: Icon(Icons.arrow_drop_down, color: primaryBlue, size: responsive.fontSize(24)),
                style: GoogleFonts.inter(fontSize: responsive.fontSize(14), color: textDark),
                dropdownColor: Colors.white,
                items: widget.familyMembers
                    .map((member) => DropdownMenuItem(
                      value: member['uid']?.toString() ?? '',
                      child: Text(member['name'] ?? 'Unknown', overflow: TextOverflow.ellipsis),
                    ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedMemberId = value),
              ),
            ),
            SizedBox(height: responsive.spacing(24)),
            Row(children: [
              Expanded(child: TextButton(onPressed: () => Navigator.pop(context), style: TextButton.styleFrom(padding: responsive.paddingSymmetric(vertical: 14, horizontal: 0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(responsive.spacing(12)))), child: Text('Cancel', style: GoogleFonts.inter(color: textGrey, fontSize: responsive.fontSize(16), fontWeight: FontWeight.w600)))),
              SizedBox(width: responsive.spacing(12)),
              Expanded(flex: 2, child: ElevatedButton.icon(onPressed: _isLoading ? null : _submitExpense, icon: _isLoading ? SizedBox() : Icon(Icons.check, color: Colors.white, size: responsive.fontSize(20)), label: Text(_isLoading ? 'Adding...' : 'Add Expense', style: GoogleFonts.inter(color: Colors.white, fontSize: responsive.fontSize(16), fontWeight: FontWeight.w600)), style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, padding: responsive.paddingSymmetric(vertical: 14, horizontal: 0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(responsive.spacing(12))), elevation: 0))),
            ]),
          ]),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/purchase_management/models/expense.dart';
import 'package:tailoring_web/features/purchase_management/providers/expense_provider.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense;

  const ExpenseFormScreen({super.key, this.expense});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _expenseDate = DateTime.now();
  String _category = 'RENT';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _amountController.text = widget.expense!.expenseAmount;
      _descriptionController.text = widget.expense!.description ?? '';
      _expenseDate = widget.expense!.expenseDate;
      _category = widget.expense!.category;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.expense != null;

    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppTheme.space4),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundGrey,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  Text(
                    isEdit ? 'Edit Expense' : 'New Expense',
                    style: AppTheme.heading3,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.space4),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Expense Date
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Expense Date *',
                            prefixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(
                            _formatDate(_expenseDate),
                            style: AppTheme.bodyMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.space3),

                      // Category
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          prefixIcon: Icon(Icons.category, size: 18),
                        ),
                        style: AppTheme.bodyMedium,
                        items: const [
                          DropdownMenuItem(
                            value: 'RENT',
                            child: Text('🏠 Rent'),
                          ),
                          DropdownMenuItem(
                            value: 'ELECTRICITY',
                            child: Text('⚡ Electricity'),
                          ),
                          DropdownMenuItem(
                            value: 'WATER',
                            child: Text('💧 Water'),
                          ),
                          DropdownMenuItem(
                            value: 'TEA_SNACKS',
                            child: Text('☕ Tea/Snacks'),
                          ),
                          DropdownMenuItem(
                            value: 'TRANSPORT',
                            child: Text('🚗 Transport'),
                          ),
                          DropdownMenuItem(
                            value: 'REPAIRS',
                            child: Text('🔧 Repairs'),
                          ),
                          DropdownMenuItem(
                            value: 'SUPPLIES',
                            child: Text('📦 Supplies'),
                          ),
                          DropdownMenuItem(
                            value: 'MARKETING',
                            child: Text('📢 Marketing'),
                          ),
                          DropdownMenuItem(
                            value: 'OTHER',
                            child: Text('📝 Other'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _category = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: AppTheme.space3),

                      // Amount
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount (₹) *',
                          prefixIcon: Icon(Icons.currency_rupee, size: 18),
                          hintText: '0.00',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.space3),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description, size: 18),
                          hintText: 'Brief description of expense...',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(AppTheme.space4),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundGrey,
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppTheme.space2),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(isEdit ? 'Update Expense' : 'Create Expense'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _expenseDate) {
      setState(() {
        _expenseDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final expense = Expense(
      id: widget.expense?.id,
      expenseDate: _expenseDate,
      category: _category,
      expenseAmount: _amountController.text,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
    );

    final provider = context.read<ExpenseProvider>();

    if (widget.expense != null) {
      // Update
      final success = await provider.updateExpense(
        widget.expense!.id!,
        expense,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (success) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                provider.errorMessage ?? 'Failed to update expense',
              ),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    } else {
      // Create
      final expenseId = await provider.createExpense(expense);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (expenseId != null) {
          Navigator.pop(context, expenseId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                provider.errorMessage ?? 'Failed to create expense',
              ),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    }
  }
}

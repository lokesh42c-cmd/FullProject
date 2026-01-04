import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tailoring_web/core/layouts/main_layout.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/features/purchase_management/providers/expense_provider.dart';
import 'package:tailoring_web/features/purchase_management/widgets/expense_card.dart';
import 'package:tailoring_web/features/purchase_management/screens/expenses/expense_form_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().fetchExpenses(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    return MainLayout(
      currentRoute: '/purchase/expenses',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space5),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundWhite,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                const Text('Expenses', style: AppTheme.heading2),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExpenseFormScreen(),
                      ),
                    );
                    provider.refresh();
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Expense'),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading && provider.expenses.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.expenses.isEmpty
                ? const Center(child: Text('No expenses found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.space5),
                    itemCount: provider.expenses.length,
                    itemBuilder: (context, index) {
                      final expense = provider.expenses[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.space3),
                        child: ExpenseCard(expense: expense),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/budget_category_model.dart';
import '../models/expense_model.dart';
import '../models/trip_model.dart'; // ייבוא מודל הטיול

class BudgetScreen extends StatefulWidget {
  // 1. המסך מקבל כעת אובייקט טיול ופונקציית עדכון
  final Trip trip;
  final Function(Trip) onTripUpdated;

  const BudgetScreen({
    super.key,
    required this.trip,
    required this.onTripUpdated,
  });

  @override
  _BudgetScreenState createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  // 2. הרשימה המקומית מאותחלת מהטיול שקיבלנו
  late List<BudgetCategory> _categories;

  @override
  void initState() {
    super.initState();
    _categories = List<BudgetCategory>.from(widget.trip.budgetCategories);
  }

  // 3. בכל שינוי, אנחנו מעדכנים את הטיול וקוראים לפונקציה כדי שהשינוי יישמר
  void _updateTripData() {
    widget.trip.budgetCategories = _categories;
    widget.onTripUpdated(widget.trip);
  }

  // --- Deletion Logic ---
  void _deleteCategory(int index) {
    setState(() {
      _categories.removeAt(index);
    });
    _updateTripData();
  }

  void _deleteExpense(int categoryIndex, int expenseIndex) {
    setState(() {
      _categories[categoryIndex].expenses.removeAt(expenseIndex);
    });
    _updateTripData();
  }

  Future<void> _showDeleteConfirmationDialog({required String title, required VoidCallback onConfirm}) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('אישור מחיקה'),
          content: SingleChildScrollView(child: ListBody(children: [Text(title)])),
          actions: <Widget>[
            TextButton(child: Text('ביטול'), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              child: Text('מחק', style: TextStyle(color: Colors.red)),
              onPressed: () {
                onConfirm();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- Dialogs to Add Data ---
  void _showAddCategoryDialog() {
    final _nameController = TextEditingController();
    final _amountController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('הוספת קטגוריית תקציב'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'שם הקטגוריה'),
                  validator: (value) => (value == null || value.isEmpty) ? 'יש להזין שם' : null,
                ),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(labelText: 'תקציב מתוכנן'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  validator: (value) => (value == null || value.isEmpty) ? 'יש להזין סכום' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול')),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final newCategory = BudgetCategory(
                  name: _nameController.text,
                  plannedAmount: double.parse(_amountController.text),
                  creationDate: DateTime.now(),
                  expenses: [],
                );
                setState(() {
                  _categories.add(newCategory);
                  _categories.sort((a, b) => b.creationDate.compareTo(a.creationDate));
                });
                _updateTripData();
                Navigator.pop(context);
              }
            },
            child: Text('הוסף'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(int categoryIndex) {
    final _descriptionController = TextEditingController();
    final _amountController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('הוספת הוצאה ל"${_categories[categoryIndex].name}"'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'תיאור ההוצאה'),
                  validator: (value) => (value == null || value.isEmpty) ? 'יש להזין תיאור' : null,
                ),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(labelText: 'סכום'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  validator: (value) => (value == null || value.isEmpty) ? 'יש להזין סכום' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול')),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final newExpense = Expense(
                  description: _descriptionController.text,
                  amount: double.parse(_amountController.text),
                  date: DateTime.now(),
                );
                setState(() {
                  _categories[categoryIndex].expenses.add(newExpense);
                });
                _updateTripData();
                Navigator.pop(context);
              }
            },
            child: Text('הוסף'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('תקציב: ${widget.trip.name}')),
      body: RefreshIndicator(
        onRefresh: () async { /* In the new architecture, refresh is handled by the parent */ },
        child: _categories.isEmpty
            ? Center(child: Text('אין קטגוריות תקציב.\nלחץ על + להוספה.'))
            : ListView.builder(
          itemCount: _categories.length,
          itemBuilder: (context, categoryIndex) {
            final category = _categories[categoryIndex];
            final double progress = category.plannedAmount > 0 ? category.actualAmount / category.plannedAmount : 0;

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Column(
                children: [
                  ExpansionTile(
                    leading: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _showDeleteConfirmationDialog(
                        title: 'האם למחוק את הקטגוריה "${category.name}"?',
                        onConfirm: () => _deleteCategory(categoryIndex),
                      ),
                    ),
                    title: Text(category.name, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('הוצאות: ${category.actualAmount.toStringAsFixed(2)} ₪ / תכנון: ${category.plannedAmount.toStringAsFixed(2)} ₪'),
                        SizedBox(height: 2),
                        Text('נוצר ב: ${DateFormat('dd/MM/yy HH:mm').format(category.creationDate)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.add_card),
                      tooltip: 'הוספת הוצאה',
                      onPressed: () => _showAddExpenseDialog(categoryIndex),
                    ),
                    children: [
                      ...category.expenses.map((expense) {
                        int expenseIndex = category.expenses.indexOf(expense);
                        return ListTile(
                          title: Text(expense.description),
                          subtitle: Text(DateFormat('dd/MM/yy HH:mm').format(expense.date)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${expense.amount.toStringAsFixed(2)} ₪', style: TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: Icon(Icons.delete, size: 20, color: Colors.grey[600]),
                                onPressed: () => _showDeleteConfirmationDialog(
                                  title: 'האם למחוק את ההוצאה "${expense.description}"?',
                                  onConfirm: () => _deleteExpense(categoryIndex, expenseIndex),
                                ),
                              )
                            ],
                          ),
                        );
                      }).toList(),
                      if (category.expenses.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('אין הוצאות בקטגוריה זו', style: TextStyle(color: Colors.grey)),
                        )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[300],
                      color: progress > 1 ? Colors.red : (progress > 0.8 ? Colors.orange : Colors.teal),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: Icon(Icons.add),
        tooltip: 'הוספת קטגוריית תקציב',
      ),
    );
  }
}
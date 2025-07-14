import 'expense_model.dart';

class BudgetCategory {
  final String name;
  final double plannedAmount;
  final List<Expense> expenses;
  final DateTime creationDate; // הוספנו תאריך יצירה

  BudgetCategory({
    required this.name,
    required this.plannedAmount,
    required this.creationDate, // הוספנו לדרישות הקונסטרקטור
    this.expenses = const [],
  });

  double get actualAmount {
    return expenses.fold(0, (sum, item) => sum + item.amount);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'plannedAmount': plannedAmount,
      'expenses': expenses.map((expense) => expense.toJson()).toList(),
      'creationDate': creationDate.toIso8601String(), // הוספנו לשמירה
    };
  }

  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    var expenseList = json['expenses'] as List;
    List<Expense> expenses = expenseList.map((e) => Expense.fromJson(e)).toList();

    return BudgetCategory(
      name: json['name'],
      plannedAmount: json['plannedAmount'],
      expenses: expenses,
      // הוספנו לקריאה, עם ערך ברירת מחדל לתאימות לאחור
      creationDate: json['creationDate'] != null ? DateTime.parse(json['creationDate']) : DateTime.now(),
    );
  }
}
class Expense {
  final String description;
  final double amount;
  final DateTime date;

  Expense({
    required this.description,
    required this.amount,
    required this.date,
  });

  // המרה מאובייקט ל-Map (לצורך שמירת JSON)
  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  // המרה מ-Map לאובייקט (לצורך קריאת JSON)
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      description: json['description'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
    );
  }
}
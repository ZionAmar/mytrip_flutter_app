import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // עבור Formatters
import 'package:intl/intl.dart' show DateFormat; // עבור DateFormat
import 'package:lottie/lottie.dart'; // עבור אנימציות Lottie
import 'package:flutter_animate/flutter_animate.dart'; // עבור אנימציות Flutter Animate

import '../models/budget_category_model.dart';
import '../models/expense_model.dart';
import '../models/trip_model.dart'; // ייבוא מודל הטיול

class BudgetScreen extends StatefulWidget {
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
  late List<BudgetCategory> _categories;

  @override
  void initState() {
    super.initState();
    // מאתחל את רשימת הקטגוריות מהטיול שקיבלנו
    _categories = List<BudgetCategory>.from(widget.trip.budgetCategories);
    _sortCategories(); // ממיין את הקטגוריות בהתחלה
  }

  // ממיין את הקטגוריות לפי תאריך יצירה (החדשות למעלה)
  void _sortCategories() {
    _categories.sort((a, b) => b.creationDate.compareTo(a.creationDate));
  }

  // 3. בכל שינוי, אנחנו מעדכנים את הטיול וקוראים לפונקציה כדי שהשינוי יישמר
  void _updateTripData() {
    widget.trip.budgetCategories = _categories;
    widget.onTripUpdated(widget.trip);
    // אין צורך ב-setState כאן אם זה נקרא מתוך פעולה שכבר עושה setState
    // אבל טוב שיהיה ליתר ביטחון אם הפונקציה נקראת בנפרד.
    _sortCategories(); // ממיין מחדש לאחר עדכון/הוספה/מחיקה
    if (mounted) {
      setState(() {});
    }
  }

  // --- Deletion Logic ---
  void _deleteCategory(int index) {
    setState(() {
      _categories.removeAt(index);
    });
    _updateTripData();
    _showSnackBar('קטגוריה נמחקה בהצלחה!');
  }

  void _deleteExpense(int categoryIndex, int expenseIndex) {
    setState(() {
      _categories[categoryIndex].expenses.removeAt(expenseIndex);
    });
    _updateTripData();
    _showSnackBar('הוצאה נמחקה בהצלחה!');
  }

  Future<void> _showDeleteConfirmationDialog({
    required String title,
    required String contentText,
    required VoidCallback onConfirm,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl, // כיווניות מימין לשמאל
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(contentText),
            actions: <Widget>[
              TextButton(
                child: const Text('ביטול', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('מחק', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onPressed: () {
                  onConfirm();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
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
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl, // כיווניות מימין לשמאל
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('הוספת קטגוריית תקציב', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration('שם הקטגוריה', Icons.category),
                    validator: (value) => (value == null || value.isEmpty) ? 'יש להזין שם קטגוריה' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: _inputDecoration('תקציב מתוכנן', Icons.attach_money),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    validator: (value) => (value == null || value.isEmpty) ? 'יש להזין סכום תקציב' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ביטול', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
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
                  });
                  _updateTripData(); // ימיין וישמור
                  Navigator.pop(context);
                  _showSnackBar('קטגוריה "${newCategory.name}" נוספה בהצלחה!');
                }
              },
              child: const Text('הוסף', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog(int categoryIndex) {
    final _descriptionController = TextEditingController();
    final _amountController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl, // כיווניות מימין לשמאל
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('הוספת הוצאה ל"${_categories[categoryIndex].name}"', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    decoration: _inputDecoration('תיאור ההוצאה', Icons.description),
                    validator: (value) => (value == null || value.isEmpty) ? 'יש להזין תיאור הוצאה' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: _inputDecoration('סכום ההוצאה', Icons.money),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    validator: (value) => (value == null || value.isEmpty) ? 'יש להזין סכום' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ביטול', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
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
                  _updateTripData(); // ישמור וימיין קטגוריות
                  Navigator.pop(context);
                  _showSnackBar('הוצאה "${newExpense.description}" נוספה בהצלחה!');
                }
              },
              child: const Text('הוסף', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper for InputDecoration ---
  InputDecoration _inputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
      ),
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  // --- Helper for SnackBars ---
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, textDirection: TextDirection.rtl), // Ensure RTL for snackbar text
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // משיכת צבעים מה-Theme לשימוש עקבי בעיצוב
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
        appBar: AppBar(
        title: Text('תקציב: ${widget.trip.name}'),
    centerTitle: true,
    backgroundColor: colorScheme.primary,
    foregroundColor: colorScheme.onPrimary,
    elevation: 0,
    automaticallyImplyLeading: false, // מונע הופעת כפתור חזור אוטומטי
    leading: IconButton( // כפתור חזור (בחזית, צד ימין ב-RTL)
    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
    tooltip: 'חזרה למסך הבית',
    onPressed: () {
    Navigator.pop(context); // חוזר למסך הקודם (HomeScreen)
    },
    ),
    actions: [
    IconButton( // כפתור בית (בצד שמאל ב-RTL)
    icon: const Icon(Icons.home_outlined, color: Colors.white),
    tooltip: 'למסך הראשי של הטיולים',
    onPressed: () {
    // מנקה את מחסנית הניווט וחוזר למסך רשימת הטיולים
    Navigator.of(context).popUntil((route) => route.isFirst);
    },
    ),
    // ניתן להוסיף כפתור רענון ידני כאן אם רוצים
    ],
    ),
    body: Directionality( // Ensure entire body is RTL
    textDirection: TextDirection.rtl,
    child: RefreshIndicator( // מאפשר משיכה לרענון
    onRefresh: () async {
    _updateTripData();
    // ניתן להוסיף כאן השהייה קצרה כדי לדמות טעינה (אם אין טעינה אמיתית)
    await Future.delayed(const Duration(milliseconds: 500));
    },
    color: colorScheme.secondary,
    backgroundColor: colorScheme.surface,
    child: _categories.isEmpty
    ? _buildEmptyState(colorScheme)
        : ListView.builder(
    physics: const AlwaysScrollableScrollPhysics(), // חשוב כדי לאפשר משיכה לרענון גם אם התוכן קצר
    padding: const EdgeInsets.all(12.0),
    itemCount: _categories.length,
    itemBuilder: (context, categoryIndex) {
    final category = _categories[categoryIndex];
    final double progress = category.plannedAmount > 0 ? category.actualAmount / category.plannedAmount : 0;

    // מחושב כאן כדי להשתמש בו בתוך ה-Animate
    final double remainingAmount = category.plannedAmount - category.actualAmount;
    Color progressColor;
    String progressText;

    if (remainingAmount < 0) {
    progressColor = colorScheme.error; // אדום לחריגה
    progressText = 'חריגה של: ${remainingAmount.abs().toStringAsFixed(2)} ₪';
    } else if (remainingAmount <= category.plannedAmount * 0.1) { // 10% אחרונים
    progressColor = Colors.orange.shade700; // כתום לאזהרה
    progressText = 'נותרו: ${remainingAmount.toStringAsFixed(2)} ₪ (אזהרה)';
    } else {
    progressColor = colorScheme.tertiary; // ירוק/כחול רגיל
    progressText = 'נותרו: ${remainingAmount.toStringAsFixed(2)} ₪';
    }

    return Card(
    margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
    elevation: 8, // צל עמוק ובולט יותר
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // פינות עגולות יותר
    clipBehavior: Clip.antiAlias, // חשוב לחיתוך נכון של פינות
    child: Column(
    children: [
    ExpansionTile(
    // מפתח לשמירת מצב הפתיחה/סגירה
    key: ValueKey(category.name + category.creationDate.toIso8601String()),
    initiallyExpanded: false, // <--- שינוי: ברירת מחדל מקופלת
    leading: IconButton(
    icon: Icon(Icons.delete_outline, color: colorScheme.onSurface.withOpacity(0.6)), // אייקון עדין יותר
    tooltip: 'מחק קטגוריה',
    onPressed: () => _showDeleteConfirmationDialog(
    title: 'אישור מחיקה',
    contentText: 'האם למחוק את הקטגוריה "${category.name}"? כל ההוצאות בה יימחקו גם כן.',
    onConfirm: () => _deleteCategory(categoryIndex),
    ),
    ),
    title: Text(
    category.name,
    style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 20,
    color: colorScheme.primary, // צבע כותרת
    ),
    ),
    subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const SizedBox(height: 4),
    Text(
    'נוצר ב: ${DateFormat('dd/MM/yy HH:mm').format(category.creationDate)}',
    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
    ),
    const SizedBox(height: 8),
    Text(
    'הוצאות בפועל: ${category.actualAmount.toStringAsFixed(2)} ₪',
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: category.actualAmount > category.plannedAmount ? colorScheme.error : colorScheme.secondary, // אדום אם בחריגה
    ),
    ),
    Text(
    'תקציב מתוכנן: ${category.plannedAmount.toStringAsFixed(2)} ₪',
    style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.8)),
    ),
    ],
    ),
    trailing: IconButton(
    icon: Icon(Icons.add_circle_outline, color: colorScheme.tertiary, size: 28), // אייקון הוספה בולט יותר
    tooltip: 'הוספת הוצאה',
    onPressed: () => _showAddExpenseDialog(categoryIndex),
    ),
    children: [
    Divider(height: 1, thickness: 1, color: Colors.grey.shade200), // מפריד בין כותרת הוצאות לרשימה
    // רשימת הוצאות
    ...category.expenses.isEmpty
    ? [
    Padding(
    padding: const EdgeInsets.all(16.0),
    child: Text('אין הוצאות בקטגוריה זו', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
    )
    ]
        : category.expenses.map((expense) {
    int expenseIndex = category.expenses.indexOf(expense);
    return ListTile(
    tileColor: Colors.grey.shade50, // רקע קל להוצאות
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    title: Text(
    expense.description,
    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
    ),
    subtitle: Text(
    DateFormat('dd/MM/yy HH:mm').format(expense.date),
    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
    ),
    trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    Text(
    '${expense.amount.toStringAsFixed(2)} ₪',
    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.secondary),
    ),
    IconButton(
    icon: Icon(Icons.delete_forever, size: 22, color: Colors.red.shade400),
    tooltip: 'מחק הוצאה',
    onPressed: () => _showDeleteConfirmationDialog(
    title: 'אישור מחיקה',
    contentText: 'האם למחוק את ההוצאה "${expense.description}"?',
    onConfirm: () => _deleteExpense(categoryIndex, expenseIndex),
    ),
    )
    ],
    ),
    );
    }).toList(),
    ],
    ),
    // סרגל התקדמות
    Padding(
    padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    LinearProgressIndicator(
    value: progress.clamp(0.0, 1.0),
    backgroundColor: Colors.grey[300],
    color: progressColor, // צבע מתאים למצב ההתקדמות
    minHeight: 10,
    borderRadius: BorderRadius.circular(8),
    ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1), // אנימציית הופעה
    const SizedBox(height: 8),
    Align(
    alignment: Alignment.centerRight, // יישור לימין
    child: Text(
    progressText,
    style: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: progressColor,
    ),
    ),
    ),
    ],
    ),
    ),
    ],
    ),
    ).animate().fadeIn(duration: 600.ms, delay: (categoryIndex * 100).ms).slideY(begin: 0.1 , // אנימציית הופעה של כרטיס
    );
    },
    ),),),
    floatingActionButton: FloatingActionButton.extended(
    onPressed: _showAddCategoryDialog,
    icon: const Icon(Icons.add_chart),
    label: const Text('הוסף קטגוריה'),
    backgroundColor: colorScheme.secondary,
    foregroundColor: colorScheme.onSecondary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // כפתור מעוגל
    tooltip: 'הוספת קטגוריית תקציב חדשה',
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // ממקם את הכפתור במרכז התחתון
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return SingleChildScrollView( // חשוב למצב ריק כדי לאפשר משיכה לרענון
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/lottie_money.json', // החלף באנימציית כסף/תקציב רלוונטית
                height: 250,
                repeat: true,
                animate: true,
              ),
              const SizedBox(height: 30),
              Text(
                'אין עדיין קטגוריות תקציב',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'לחצו על כפתור "הוסף קטגוריה" כדי להתחיל לתכנן את ההוצאות שלכם!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
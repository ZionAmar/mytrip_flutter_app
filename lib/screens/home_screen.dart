import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import 'activities_screen.dart';
import 'budget_screen.dart';

class HomeScreen extends StatelessWidget {
  final Trip trip;
  final Function(Trip) onTripUpdated;

  const HomeScreen({
    super.key,
    required this.trip,
    required this.onTripUpdated,
  });

  @override
  Widget build(BuildContext context) {
    // רשימה מלאה של כל הפריטים בדשבורד
    final List<DashboardItem> items = [
      DashboardItem(
        icon: Icons.event_note,
        title: 'פעילויות',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivitiesScreen(
                trip: trip,
                onTripUpdated: onTripUpdated,
              ),
            ),
          );
        },
      ),
      DashboardItem(
        icon: Icons.account_balance_wallet,
        title: 'תקציב',
        onTap: () {
          // הפעלנו את הניווט למסך התקציב
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BudgetScreen(
                trip: trip,
                onTripUpdated: onTripUpdated,
              ),
            ),
          );
        },
      ),
      DashboardItem(
        icon: Icons.wb_sunny,
        title: 'מזג אוויר',
        onTap: () { /* נוסיף ניווט בעתיד */ },
      ),
      DashboardItem(
        icon: Icons.assessment,
        title: 'סיכום טיול',
        onTap: () { /* נוסיף ניווט בעתיד */ },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.name),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: 1.2,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 48.0, color: Theme.of(context).primaryColor),
                    SizedBox(height: 12.0),
                    Text(
                      item.title,
                      style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DashboardItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  DashboardItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
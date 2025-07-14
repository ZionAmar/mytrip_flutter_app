// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import 'activities_screen.dart';
import 'budget_screen.dart';
import 'weather_screen.dart';
import 'edit_trip_screen.dart';
import 'map_screen.dart';


// שינוי ל-StatefulWidget
class HomeScreen extends StatefulWidget {
  final Trip trip;
  final Function(Trip) onTripUpdated;

  const HomeScreen({
    super.key,
    required this.trip,
    required this.onTripUpdated,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // שמור עותק של הטיול במצב של ה-StatefulWidget
  late Trip _currentTrip;

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip; // אתחל את הטיול הנוכחי עם הטיול שהתקבל
  }

  // פונקציה לעדכון הטיול וה-UI
  void _updateTripInHomeScreen(Trip updatedTrip) {
    setState(() {
      _currentTrip = updatedTrip; // עדכן את המצב עם הטיול החדש
    });
    // קרא גם ל-onTripUpdated כדי לעדכן את המסך שמעל (רשימת הטיולים)
    widget.onTripUpdated(updatedTrip);
  }

  @override
  Widget build(BuildContext context) {
    final List<DashboardItem> items = [
      DashboardItem(
        icon: Icons.event_note,
        title: 'פעילויות',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivitiesScreen(
                trip: _currentTrip, // העבר את הטיול המעודכן
                onTripUpdated: _updateTripInHomeScreen, // העבר את פונקציית העדכון של ה-HomeScreen
              ),
            ),
          );
        },
      ),
      DashboardItem(
        icon: Icons.account_balance_wallet,
        title: 'תקציב',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BudgetScreen(
                trip: _currentTrip, // העבר את הטיול המעודכן
                onTripUpdated: _updateTripInHomeScreen, // העבר את פונקציית העדכון של ה-HomeScreen
              ),
            ),
          );
        },
      ),
      DashboardItem(
        icon: Icons.wb_sunny,
        title: 'מזג אוויר',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WeatherScreen(trip: _currentTrip), // העבר את הטיול המעודכן
            ),
          );
        },
      ),
      // בתוך ה-List<DashboardItem> items ב-HomeScreen
      DashboardItem(
        icon: Icons.map, // אייקון למפה
        title: 'מפה',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MapScreen(
                trip: _currentTrip, // העבר את אובייקט הטיול
              ),
            ),
          );
        },
      ),
      DashboardItem(
        icon: Icons.info_outline,
        title: 'פרטי טיול',
        onTap: () async {
          final updatedTrip = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditTripScreen(
                trip: _currentTrip, // העבר את הטיול הנוכחי לעריכה
              ),
            ),
          );
          if (updatedTrip != null && updatedTrip is Trip) {
            _updateTripInHomeScreen(updatedTrip); // קרא לפונקציה החדשה לעדכון המצב ב-HomeScreen
          }
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTrip.name), // השתמש בשם מהטיול במצב
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                    const SizedBox(height: 12.0),
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
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
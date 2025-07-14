import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import 'activities_screen.dart';
import 'budget_screen.dart';
import 'weather_screen.dart';
import 'edit_trip_screen.dart';
import 'map_screen.dart';
import 'trip_summary_screen.dart';
import 'checklist_screen.dart'; // <--- NEW: Import your ChecklistScreen

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
  late Trip _currentTrip;

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;
  }

  void _updateTripInHomeScreen(Trip updatedTrip) {
    setState(() {
      _currentTrip = updatedTrip;
    });
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
                trip: _currentTrip,
                onTripUpdated: _updateTripInHomeScreen,
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
                trip: _currentTrip,
                onTripUpdated: _updateTripInHomeScreen,
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
              builder: (context) => WeatherScreen(trip: _currentTrip),
            ),
          );
        },
      ),
      // --- NEW: Dashboard Item for Checklist ---
      DashboardItem(
        icon: Icons.checklist, // A suitable icon for a checklist
        title: 'רשימות',
        onTap: () {
          // If you want a general checklist (not tied to a specific trip):
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChecklistScreen(), // Pass no specific trip
            ),
          );

          // If you want a checklist *specific to this trip*:
          // You would modify ChecklistScreen to accept a Trip ID or Trip object
          // and then load/save checklist items based on that trip.
          // For example:
          /*
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChecklistScreen(tripId: _currentTrip.id),
            ),
          );
          */
        },
      ),
      // --- END NEW ---
      DashboardItem(
        icon: Icons.map,
        title: 'מפה',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MapScreen(
                trip: _currentTrip,
              ),
            ),
          );
        },
      ),
      DashboardItem(
        icon: Icons.summarize,
        title: 'סיכום טיול',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TripSummaryScreen(
                trip: _currentTrip,
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
                trip: _currentTrip,
              ),
            ),
          );
          if (updatedTrip != null && updatedTrip is Trip) {
            _updateTripInHomeScreen(updatedTrip);
          }
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTrip.name),
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
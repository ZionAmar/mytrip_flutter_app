import 'dart:async';
import 'dart:io'; // <-- ייבוא חיוני לעבודה עם קבצים
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/trip_model.dart';
import '../models/memory_item_model.dart';
import 'activities_screen.dart';
import 'budget_screen.dart';
import 'weather_screen.dart';
import 'edit_trip_screen.dart';
import 'map_screen.dart';
import 'trip_summary_screen.dart'; // ישאר כמסך סיכום בלבד
import 'checklist_screen.dart';
import 'memories_screen.dart';

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

  List<String> _backgroundImages = [];
  int _currentBgIndex = 0;
  Timer? _timer;

  final List<String> _defaultImages = [
    'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1770&q=80',
    'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1721&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;
    _setupBackgrounds();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setupBackgrounds() {
    final memoryItems = _currentTrip.memories;
    final List<String> photoUrls = memoryItems
        ?.where((item) => item.type == MemoryType.photo && item.content.isNotEmpty)
        .map((item) => item.content)
        .toList() ?? [];

    if (photoUrls.isNotEmpty) {
      _backgroundImages = photoUrls;
    } else {
      _backgroundImages = _defaultImages;
    }

    _currentBgIndex = _backgroundImages.isNotEmpty ? _currentBgIndex % _backgroundImages.length : 0;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 120), (timer) {
      if (mounted && _backgroundImages.length > 1) {
        setState(() {
          _currentBgIndex = (_currentBgIndex + 1) % _backgroundImages.length;
        });
      }
    });
  }

  Future<void> _handleRefresh() async {
    // במציאות, כאן כדאי לטעון מחדש את ה-trip מה-database
    // כרגע נסתפק בהשהייה ורענון הרקעים
    await Future.delayed(const Duration(seconds: 1));
    if(mounted) {
      setState(() {
        _setupBackgrounds();
      });
    }
  }

  void _updateTripInHomeScreen(Trip updatedTrip) {
    setState(() {
      _currentTrip = updatedTrip;
    });
    _setupBackgrounds();
    widget.onTripUpdated(updatedTrip);
  }

  @override
  Widget build(BuildContext context) {
    final List<DashboardItem> items = [
      DashboardItem(icon: Icons.event_note_rounded, title: 'פעילויות', color: Theme.of(context).colorScheme.primary, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ActivitiesScreen(trip: _currentTrip, onTripUpdated: _updateTripInHomeScreen)))),
      DashboardItem(icon: Icons.account_balance_wallet_rounded, title: 'תקציב', color: Theme.of(context).colorScheme.tertiary, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BudgetScreen(trip: _currentTrip, onTripUpdated: _updateTripInHomeScreen)))),
      DashboardItem(icon: Icons.wb_sunny_rounded, title: 'מזג אוויר', color: Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => WeatherScreen(trip: _currentTrip)))),
      DashboardItem(icon: Icons.checklist_rtl_rounded, title: 'רשימות', color: Colors.lightGreen, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChecklistScreen(tripId: _currentTrip.id)))),
      DashboardItem(icon: Icons.photo_library_rounded, title: 'זיכרונות', color: Colors.purpleAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MemoriesScreen(trip: _currentTrip, onTripUpdated: _updateTripInHomeScreen)))),
      DashboardItem(icon: Icons.map_rounded, title: 'מפה', color: Colors.blueAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MapScreen(trip: _currentTrip)))),
      // חדש: כפתור "פרטי טיול" שיוביל למסך עריכה
      DashboardItem(icon: Icons.edit_note_rounded, title: 'פרטי טיול', color: Theme.of(context).colorScheme.primaryContainer, onTap: () async {
        final updatedTrip = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EditTripScreen(trip: _currentTrip)),
        );
        if (updatedTrip != null && updatedTrip is Trip) {
          _updateTripInHomeScreen(updatedTrip);
        }
      }),
      // חדש: כפתור "סיכום טיול" נפרד שיוביל למסך סיכום בלבד
      DashboardItem(icon: Icons.summarize_rounded, title: 'סיכום טיול', color: Theme.of(context).colorScheme.secondary, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TripSummaryScreen(trip: _currentTrip, )))),
    ];

    ImageProvider imageProvider;
    if (_backgroundImages.isEmpty) {
      imageProvider = NetworkImage(_defaultImages.first);
    } else {
      final currentImageUrl = _backgroundImages[_currentBgIndex];
      if (currentImageUrl.startsWith('http')) {
        imageProvider = NetworkImage(currentImageUrl);
      } else {
        imageProvider = FileImage(File(currentImageUrl));
      }
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // מונע הופעת כפתור חזור אוטומטי
        title: Hero( // Hero animation for the title
            tag: 'trip_title_${_currentTrip.id}',
            child: Material(type: MaterialType.transparency, child: Text(_currentTrip.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)))
        ),
        centerTitle: true,
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        leading: IconButton( // כפתור חזור (בחזית, צד ימין ב-RTL)
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          tooltip: 'חזרה לכל הטיולים',
          onPressed: () {
            Navigator.pop(context); // חוזר למסך הקודם (רשימת הטיולים)
          },
        ),
        actions: [
          IconButton( // כפתור בית (בצד שמאל ב-RTL)
            icon: const Icon(Icons.home_outlined, color: Colors.white),
            tooltip: 'למסך הבית',
            onPressed: () {
              // מנקה את מחסנית הניווט וחוזר למסך רשימת הטיולים
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Hero(
            tag: 'trip_image_${_currentTrip.id}',
            child: AnimatedSwitcher(
              duration: const Duration(seconds: 1),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Container(
                key: ValueKey<String>(_backgroundImages.isNotEmpty ? _backgroundImages[_currentBgIndex] : 'default'),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.40),
          ),
          RefreshIndicator(
            onRefresh: _handleRefresh,
            color: Colors.white,
            backgroundColor: Theme.of(context).primaryColor,
            child: SafeArea(
              child: Directionality( // עוטף את ה-GridView ב-Directionality
                textDirection: TextDirection.rtl, // כדי שהכפתורים יהיו מימין לשמאל
                child: GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Animate(
                      effects: [
                        FadeEffect(delay: (100 * index).ms, duration: 400.ms),
                        MoveEffect(begin: const Offset(0, 50), delay: (100 * index).ms, duration: 400.ms, curve: Curves.easeOutCubic),
                      ],
                      child: Card(
                        elevation: 0,
                        color: Colors.white.withOpacity(0.25),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            side: BorderSide(color: Colors.white.withOpacity(0.25), width: 1)
                        ),
                        child: InkWell(
                          onTap: item.onTap,
                          borderRadius: BorderRadius.circular(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item.icon, size: 40.0, color: item.color),
                              const SizedBox(height: 12.0),
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white, shadows: [const Shadow(blurRadius: 2, color: Colors.black54)]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardItem {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  DashboardItem({required this.icon, required this.title, required this.color, required this.onTap});
}
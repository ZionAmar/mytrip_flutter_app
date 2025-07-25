
-----

# MyTrip App – Personal Trip Planner

A Flutter application for managing your vacation, including budget, activities, flights, hotel, car, packing list, and a summary of your experiences – with full support for local data storage.

-----

## 🧭 Screen List

1.  **`SplashScreen`** – An opening page with a logo and a transition timer.
2.  **`HomeScreen`** – The main menu for navigating between all screens.
3.  **`BudgetScreen`** – Plan your budget and categories.
4.  **`ActivitiesScreen`** – Plan daily activities by type.
5.  **`FlightHotelCarScreen`** – Centralize details for flights, hotel, and car rental.
6.  **`PackingListScreen`** – A packing checklist with tappable items.
7.  **`MapScreen`** – Displays the trip route on a map.
8.  **`TripSummaryScreen`** – A summary of all trip details at the end.
9.  **`BudgetTestScreen`** – An example of saving and loading a budget using `shared_preferences`.

-----

## ⚙️ Key Features

- Detailed budget planning by category.
- Tracking of activities, equipment, and expenses.
- Simple and convenient user interface.
- Full support for local data storage (Offline first).
- A designed splash screen with an animation and logo.
- Uses Google Maps to display the travel route.
- Clear and separated folder structure for screens and services.

-----

## 🧰 User Guide

#### 1\. Install Dependencies

Ensure all packages are installed by running the following command in your terminal:

```sh
flutter pub get
```

#### 2\. Run the Application

To run the app on a simulator or device, use the command:

```sh
flutter run
```

#### 3\. Update the `pubspec.yaml` File

Make sure the following assets and dependencies are defined in your `pubspec.yaml` file:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/logo.png

dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.2
```

#### 4\. Set Up Navigation

In your main file (`lib/main.dart`), configure the navigation between screens:

```dart
class MyApp extends StatelessWidget {
@override
Widget build(BuildContext context) {
return MaterialApp(
initialRoute: '/',
routes: {
'/': (context) => SplashScreen(),
'/home': (context) => HomeScreen(),
'/budget': (context) => BudgetScreen(),
// ... add the rest of your screens here
},
);
}
}
```

-----

**Good luck and have a great trip\!**
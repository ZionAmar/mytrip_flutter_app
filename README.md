# MyTrip App – Personal Trip Planner

A Flutter application designed to help you manage and organize your vacation. It includes comprehensive features for budget planning, activity tracking, flight and hotel details, car rentals, packing lists, and a final trip summary – with full support for local data storage.

---

## 🧭 Screen List

1.  **SplashScreen** – Welcome page with a logo and a timer for navigation.
2.  **HomeScreen** – Main menu for navigating between all screens.
3.  **BudgetScreen** – Budget planning and categories.
4.  **ActivitiesScreen** – Daily activity planning by type.
5.  **FlightHotelCarScreen** – Flight, hotel, and car rental details.
6.  **PackingListScreen** – Packing list with checkbox options.
7.  **MapScreen** – Displaying the trip route on a map.
8.  **TripSummaryScreen** – Summary of all trip details upon completion.
9.  **BudgetTestScreen** – Example of saving and loading budget using `shared_preferences`.

---

## ⚙️ Key Features

-   Budget planning by category
-   Tracking activities, packing items, and expenses
-   Simple interface in Hebrew
-   Support for local data storage without internet connection
-   Designed splash screen with a logo
-   Uses Google Maps to display routes
-   Clear and separated folder structure by screens and services

---

## 🧰 User Guide

1.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

2.  **Run the Application**
    ```bash
    flutter run
    ```

3.  **Update pubspec.yaml file**
    Ensure the following lines exist:
    ```yaml
    assets:
      - assets/images/logo.png

    dependencies:
      shared_preferences: ^2.2.2
    ```

4.  **Configure Navigation**
    In your main.dart file:
    ```dart
    initialRoute: '/',
    routes: {
      '/': (context) => SplashScreen(),
      '/home': (context) => HomeScreen(),
      // ... other routes
    }
    ```

---

Good luck and have a pleasant trip!
// lib/screens/trip_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'show DateFormat; // To format dates
import '../models/trip_model.dart'; // To access trip data
import '../models/weather_model.dart'; // To access weather data
import 'package:percent_indicator/percent_indicator.dart'; // For progress indicators

/// This screen summarizes all aspects of the trip.
class TripSummaryScreen extends StatelessWidget {
  final Trip trip; // Receive the Trip object

  const TripSummaryScreen({
    super.key,
    required this.trip,
  });

  // Helper functions to calculate summary data
  int _getTotalActivities(Trip trip) {
    return trip.activities.length; // Count total activities
  }

  int _getCompletedActivities(Trip trip) {
    // Count activities marked as done
    return trip.activities.where((activity) => activity.isDone).length;
  }

  double _getTotalPlannedBudget(Trip trip) {
    // Sum up planned budget from all categories
    return trip.budgetCategories.fold(0.0, (sum, category) => sum + category.plannedAmount);
  }

  double _getTotalActualSpent(Trip trip) {
    // Sum up actual spending from all categories
    return trip.budgetCategories.fold(0.0, (sum, category) => sum + category.actualAmount);
  }

  // Helper to get a simple weather summary string
  String _getWeatherSummaryText(List<DailyWeather>? forecast) {
    if (forecast == null || forecast.isEmpty) {
      return 'אין נתוני מזג אוויר שמורים.'; // Message if no saved weather
    }

    double avgTemp = forecast.fold(0.0, (sum, daily) => sum + daily.temp) / forecast.length;
    // Get unique descriptions and limit to a few for brevity
    Set<String> uniqueDescriptions = forecast.map((e) => e.description).toSet();
    String commonDescription = uniqueDescriptions.take(3).join(', '); // Take up to 3 descriptions

    String suffix = uniqueDescriptions.length > 3 ? '...' : '';

    return 'טמפ. ממוצעת: ${avgTemp.toStringAsFixed(1)}°C\nתנאים נפוצים: $commonDescription$suffix';
  }

  // Helper to get a representative weather icon
  String _getRepresentativeWeatherIcon(List<DailyWeather>? forecast) {
    if (forecast == null || forecast.isEmpty) {
      return '01d'; // Default icon (clear sky) or a custom "no weather" icon
    }
    // For simplicity, take the icon from the first day or a common one
    return forecast.first.iconCode;
  }


  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final totalActivities = _getTotalActivities(trip); // Get total activities
    final completedActivities = _getCompletedActivities(trip); // Get completed activities
    final totalPlannedBudget = _getTotalPlannedBudget(trip); // Get total planned budget
    final totalActualSpent = _getTotalActualSpent(trip); // Get total actual spent
    final budgetRemaining = totalPlannedBudget - totalActualSpent; // Calculate remaining budget

    // Calculate activity completion percentage safely
    final double activityCompletionPercent = totalActivities > 0 ? completedActivities / totalActivities : 0.0;

    // Calculate budget spent percentage safely
    final double budgetSpentPercent = totalPlannedBudget > 0 ? totalActualSpent / totalPlannedBudget : 0.0;
    Color budgetProgressColor = colorScheme.primary;
    if (budgetRemaining < 0) {
      budgetProgressColor = colorScheme.error; // Red if over budget
    } else if (budgetSpentPercent > 0.8) {
      budgetProgressColor = colorScheme.tertiary; // Orange/Yellow if close to budget
    }


    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Disable default back button
        title: Text(
          'סיכום טיול: ${trip.name}',
          style: TextStyle(color: Colors.white), // Set title color to white
        ),
        centerTitle: true,
        backgroundColor: colorScheme.primary, // Use theme primary color
        elevation: 0, // Remove shadow

        // Back button (leading, typically on the right in RTL)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), // iOS style back arrow
          tooltip: 'חזרה',
          onPressed: () {
            Navigator.of(context).pop(); // Navigates back to the previous screen
          },
        ),
        // Home button (actions, typically on the left in RTL)
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.white), // Outlined home icon
            tooltip: 'למסך הבית',
            onPressed: () {
              // This will pop all routes until the first route (home screen or trips list)
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl, // Ensure RTL layout
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Trip Details Section
              _buildSummaryCard(
                context,
                colorScheme,
                Icons.info_outline,
                'פרטי טיול כלליים',
                [
                  _buildInfoRow(context, 'יעד:', trip.destinationCity, Icons.location_on),
                  _buildInfoRow(context, 'תאריכים:', '${DateFormat('dd/MM/yyyy').format(trip.startDate)} - ${DateFormat('dd/MM/yyyy').format(trip.endDate)}', Icons.calendar_today),
                  _buildInfoRow(context, 'עודכן לאחרונה:', DateFormat('dd/MM/yyyy HH:mm').format(trip.lastModifiedDate), Icons.update),
                ],
              ),
              const SizedBox(height: 20),

              // Activities Summary Section
              _buildSummaryCard(
                context,
                colorScheme,
                Icons.check_circle_outline,
                'סיכום פעילויות',
                [
                  _buildInfoRow(context, 'סה"כ פעילויות:', '$totalActivities', Icons.list),
                  _buildInfoRow(context, 'פעילויות שהושלמו:', '$completedActivities / $totalActivities', Icons.done_all),
                  const SizedBox(height: 10),
                  LinearPercentIndicator(
                    alignment: MainAxisAlignment.center,
                    width: MediaQuery.of(context).size.width - 64, // Card padding (16*2) + screen padding (16*2)
                    lineHeight: 14.0,
                    percent: activityCompletionPercent,
                    backgroundColor: colorScheme.surfaceVariant,
                    progressColor: colorScheme.secondary,
                    barRadius: const Radius.circular(10),
                    animation: true,
                    animationDuration: 800,
                    center: Text(
                      '${(activityCompletionPercent * 100).toStringAsFixed(0)}%',
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSecondary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Budget Summary Section
              _buildSummaryCard(
                context,
                colorScheme,
                Icons.account_balance_wallet_outlined,
                'סיכום תקציב',
                [
                  _buildInfoRow(context, 'תקציב מתוכנן:', '${totalPlannedBudget.toStringAsFixed(2)} ₪', Icons.attach_money),
                  _buildInfoRow(context, 'הוצאות בפועל:', '${totalActualSpent.toStringAsFixed(2)} ₪', Icons.money_off),
                  _buildInfoRow(
                    context,
                    'יתרה:',
                    '${budgetRemaining.toStringAsFixed(2)} ₪',
                    Icons.account_balance,
                    valueColor: budgetRemaining < 0 ? colorScheme.error : colorScheme.primary,
                  ),
                  const SizedBox(height: 10),
                  LinearPercentIndicator(
                    alignment: MainAxisAlignment.center,
                    width: MediaQuery.of(context).size.width - 64, // Card padding (16*2) + screen padding (16*2)
                    lineHeight: 14.0,
                    percent: budgetSpentPercent > 1.0 ? 1.0 : budgetSpentPercent, // Cap at 100% for display
                    backgroundColor: colorScheme.surfaceVariant,
                    progressColor: budgetProgressColor,
                    barRadius: const Radius.circular(10),
                    animation: true,
                    animationDuration: 800,
                    center: Text(
                      '${(budgetSpentPercent * 100).toStringAsFixed(0)}%',
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (budgetRemaining < 0) // Show warning if over budget
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'שימו לב: חרגתם מהתקציב המתוכנן!',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.error, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Weather Summary Section
              _buildSummaryCard(
                context,
                colorScheme,
                Icons.cloud_outlined,
                'סיכום מזג אוויר',
                [
                  Row(
                    children: [
                      // Display representative weather icon if available
                      Image.network(
                        'https://openweathermap.org/img/wn/${_getRepresentativeWeatherIcon(trip.savedWeatherForecast)}@2x.png',
                        width: 50,
                        height: 50,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.cloud_off, color: colorScheme.onSurface.withOpacity(0.5)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getWeatherSummaryText(trip.savedWeatherForecast),
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build each summary card
  Widget _buildSummaryCard(
      BuildContext context,
      ColorScheme colorScheme,
      IconData icon,
      String title,
      List<Widget> children,
      ) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.zero, // Controlled by parent Column's SizedBox
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 28),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            Divider(height: 20, thickness: 1, color: colorScheme.outlineVariant.withOpacity(0.6)),
            ...children, // Spread the children widgets
          ],
        ),
      ),
    );
  }

  // Helper widget to build info rows with icons
  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), size: 20),
          const SizedBox(width: 10),
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          // Changed from Flexible to Expanded to allow text to wrap if needed,
          // giving it more horizontal space.
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
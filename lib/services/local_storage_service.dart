// A simple example service class to handle local storage logic.
// In a real app, this could be extended to use SharedPreferences, SQLite, or Hive.

class LocalStorageService {
  // Simulates saving a value
  void saveData(String key, String value) {
    print('Saved $key: $value');
  }

  // Simulates reading a value
  String readData(String key) {
    print('Reading value for $key');
    return 'Sample Value';
  }
}

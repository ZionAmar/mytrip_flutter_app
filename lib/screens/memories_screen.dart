// lib/screens/memories_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geocoding/geocoding.dart' as geo; // Prefix geocoding to avoid Placemark conflict
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:video_thumbnail/video_thumbnail.dart'; // For video thumbnails
import 'package:flutter_sound/flutter_sound.dart'; // Import flutter_sound
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart'; // For AudioEncoder enum
import 'package:lottie/lottie.dart'; // For Lottie animations
import 'package:flutter_animate/flutter_animate.dart'; // For Flutter Animate effects

import '../models/trip_model.dart';
import '../models/memory_item_model.dart'; // Ensure MemoryType enum is defined here
import '../services/weather_service.dart';

class MemoriesScreen extends StatefulWidget {
  final Trip trip;
  final Function(Trip) onTripUpdated;

  const MemoriesScreen({
    super.key,
    required this.trip,
    required this.onTripUpdated,
  });

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  late Trip _currentTrip;
  final ImagePicker _picker = ImagePicker();
  FlutterSoundRecorder? _audioRecorder;
  bool _isRecorderInitialized = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // For form validation
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  MemoryType? _selectedType;

  String? _currentLocationName;
  double? _currentLatitude;
  double? _currentLongitude;
  String? _currentWeatherDescription;
  double? _currentWeatherTemp;
  bool _isFetchingMomentData = false;
  bool _isRecording = false;
  bool _isShowingAddMemoryDialog = false; // <--- חדש: לניהול אינדיקטור הטעינה

  final WeatherService _weatherService = WeatherService('8c8d50cc8e3c472c07c13bf9a8498eef'); // Replace with your actual API key!

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip.copyWith(memories: widget.trip.memories ?? []); // Ensure memories list is not null
    _initRecorder();
  }

  // --- Initialize FlutterSoundRecorder ---
  Future<void> _initRecorder() async {
    _audioRecorder = FlutterSoundRecorder();
    await _audioRecorder!.openRecorder();
    // Request microphone permission on initialization if not granted
    if (await Permission.microphone.isDenied) {
      await Permission.microphone.request();
    }
    _isRecorderInitialized = true;
    if (mounted) {
      setState(() {}); // Rebuild UI to reflect recorder readiness
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _audioRecorder?.closeRecorder(); // Use null-aware operator for safe close
    _audioRecorder = null;
    super.dispose();
  }

  void _updateTrip(Trip updatedTrip) {
    setState(() {
      _currentTrip = updatedTrip;
      _currentTrip.memories?.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort memories by date, newest first
    });
    widget.onTripUpdated(updatedTrip);
  }

  // Helper for snackbars
  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, textDirection: TextDirection.rtl),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _fetchMomentData() async {
    if (!mounted) return;
    setState(() {
      _isFetchingMomentData = true;
      _currentLocationName = null;
      _currentLatitude = null;
      _currentLongitude = null;
      _currentWeatherDescription = null;
      _currentWeatherTemp = null;
    });

    try {
      var permissionStatus = await Permission.locationWhenInUse.status;
      if (!permissionStatus.isGranted) {
        permissionStatus = await Permission.locationWhenInUse.request();
      }

      if (permissionStatus.isGranted) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;

        List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(position.latitude, position.longitude); // Use prefixed geocoding
        if (placemarks.isNotEmpty) {
          _currentLocationName = placemarks.first.locality ?? placemarks.first.subAdministrativeArea ?? placemarks.first.name;
          if (_currentLocationName == null || _currentLocationName!.isEmpty) {
            _currentLocationName = '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}'; // Fallback to coords
          }
        } else {
          _currentLocationName = 'מיקום לא ידוע';
        }

        // Fetch weather for the current detected location, not trip destination city
        final String weatherUrl = 'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=${_weatherService.apiKey}&units=metric&lang=he';
        final weatherResponse = await http.get(Uri.parse(weatherUrl)).timeout(const Duration(seconds: 10));

        if (weatherResponse.statusCode == 200) {
          final weatherJson = jsonDecode(utf8.decode(weatherResponse.bodyBytes));
          _currentWeatherDescription = weatherJson['weather'][0]['description'];
          _currentWeatherTemp = (weatherJson['main']['temp'] as num).toDouble();
        } else {
          print('Failed to get current weather: ${weatherResponse.statusCode} - ${utf8.decode(weatherResponse.bodyBytes)}');
          _currentWeatherDescription = 'לא זמין (קוד: ${weatherResponse.statusCode})';
          _currentWeatherTemp = null;
        }

      } else {
        _showSnackBar('הרשאת מיקום נדחתה. לא ניתן להוסיף פרטי מיקום.', isError: true);
      }
    } catch (e) {
      print('Error fetching moment data (location/weather): $e');
      _showSnackBar('שגיאה בטעינת פרטי המיקום/מזג אוויר: ${e.toString().contains('timeout') ? 'פג תוקף הבקשה' : e}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingMomentData = false;
        });
      }
    }
  }

  Future<String> _getAppSpecificHiddenDirPath() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String appDocPath = appDocDir.path;
    final Directory memoriesDir = Directory('$appDocPath/.memories');
    if (!await memoriesDir.exists()) {
      await memoriesDir.create(recursive: true);
    }
    return memoriesDir.path;
  }

  // --- Updated: Picking and Saving Media ---
  Future<String?> _pickAndSaveMedia(MemoryType type) async {
    XFile? pickedFile;
    if (type == MemoryType.photo) {
      pickedFile = await _picker.pickImage(source: ImageSource.gallery); // Pick only image
    } else if (type == MemoryType.video) {
      pickedFile = await _picker.pickVideo(source: ImageSource.gallery); // Pick only video
    } else {
      _showSnackBar('סוג מדיה לא נתמך עבור העלאה ישירה.', isError: true);
      return null;
    }

    if (pickedFile != null) {
      try {
        final String appSpecificHiddenDirPath = await _getAppSpecificHiddenDirPath();
        final String fileExtension = pickedFile.path.split('.').last;
        final String fileName = '${const Uuid().v4()}.$fileExtension'; // Use UUID and original extension
        final String newPath = '$appSpecificHiddenDirPath/$fileName';
        final File newFile = File(pickedFile.path);
        await newFile.copy(newPath);
        _showSnackBar('קובץ נשמר בהצלחה!');
        return newPath;
      } catch (e) {
        print('Error saving file permanently: $e');
        _showSnackBar('שגיאה בשמירת הקובץ: $e', isError: true);
        return null;
      }
    }
    return null;
  }

  // --- Updated: Toggle Recording ---
  Future<void> _toggleRecording(Function(Function()) setStateInDialog) async {
    if (_audioRecorder == null || !_isRecorderInitialized) {
      _showSnackBar('מקליט הקול אינו מוכן. נסה שוב מאוחר יותר.', isError: true);
      return;
    }

    if (!await Permission.microphone.isGranted) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _showSnackBar('נדרשת הרשאת מיקרופון להקלטה.', isError: true);
        return;
      }
    }

    if (_isRecording) {
      // Stop recording
      final path = await _audioRecorder!.stopRecorder();
      setStateInDialog(() {
        _isRecording = false;
      });
      if (path != null) {
        try {
          final String appSpecificHiddenDirPath = await _getAppSpecificHiddenDirPath();
          final String fileName = '${const Uuid().v4()}_audio.aac';
          final String newPath = '$appSpecificHiddenDirPath/$fileName';
          final File newFile = File(path);
          await newFile.copy(newPath);
          setStateInDialog(() {
            _contentController.text = newPath; // Set content controller with permanent path
          });
          _showSnackBar('הקלטה נשמרה.');
        } catch (e) {
          print('Error saving recorded audio: $e');
          _showSnackBar('שגיאה בשמירת הקלטת קול: $e', isError: true);
        }
      }
    } else {
      // Start recording
      final appSpecificHiddenDirPath = await _getAppSpecificHiddenDirPath();
      final outputPath = '$appSpecificHiddenDirPath/temp_recording.aac';
      await _audioRecorder!.startRecorder(
        toFile: outputPath,
        codec: Codec.aacADTS,
      );
      setStateInDialog(() {
        _isRecording = true;
        _contentController.text = ''; // Clear content during recording
        _selectedType = MemoryType.audio; // Force type to audio
      });
      _showSnackBar('הקלטה החלה...');
    }
  }

  Future<void> _showAddMemoryDialog() async {
    // Reset form and state variables
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _contentController.clear();
    _selectedType = null;
    _currentLocationName = null;
    _currentLatitude = null;
    _currentLongitude = null;
    _currentWeatherDescription = null;
    _currentWeatherTemp = null;
    _isRecording = false;

    // Show loading indicator before fetching data and showing dialog
    if (!mounted) return;
    setState(() {
      _isShowingAddMemoryDialog = true;
    });

    await _fetchMomentData(); // Fetch moment data immediately

    // Hide loading indicator and then show dialog
    if (!mounted) return;
    setState(() {
      _isShowingAddMemoryDialog = false;
    });

    await showDialog(
      context: context,
      barrierDismissible: false, // Make sure user uses buttons to close
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl, // RTL for the dialog
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('הוסף זיכרון חדש', style: TextStyle(fontWeight: FontWeight.bold)),
            content: StatefulBuilder(
              builder: (context, setStateInDialog) {
                return SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: _inputDecoration('כותרת הזיכרון', Icons.title),
                          validator: (value) => value == null || value.isEmpty ? 'יש להזין כותרת' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: _inputDecoration('תיאור (אופציונלי)', Icons.description),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<MemoryType>(
                          value: _selectedType,
                          hint: const Text('בחר סוג זיכרון'),
                          decoration: _inputDecoration('סוג זיכרון', Icons.category),
                          validator: (value) => value == null ? 'יש לבחור סוג זיכרון' : null,
                          items: MemoryType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(_getMemoryTypeLabel(type)),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setStateInDialog(() {
                              _selectedType = newValue;
                              _contentController.clear(); // Clear content when type changes
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        if (_selectedType == MemoryType.link)
                          TextFormField(
                            controller: _contentController,
                            decoration: _inputDecoration('קישור (URL)', Icons.link),
                            keyboardType: TextInputType.url,
                            validator: (value) => value == null || value.isEmpty ? 'יש להזין קישור' : null,
                          )
                        else if (_selectedType == MemoryType.note)
                          TextFormField(
                            controller: _contentController,
                            decoration: _inputDecoration('תוכן הפתק', Icons.note),
                            maxLines: 5,
                            validator: (value) => value == null || value.isEmpty ? 'יש להזין תוכן לפתק' : null,
                          ),
                        const SizedBox(height: 16),
                        // Media upload/record buttons
                        if (_selectedType == MemoryType.photo || _selectedType == MemoryType.video || _selectedType == MemoryType.audio)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              if (_selectedType == MemoryType.photo || _selectedType == MemoryType.video)
                                Expanded( // Use Expanded for file upload button
                                  child: ElevatedButton.icon(
                                    onPressed: _isFetchingMomentData // Disable if fetching moment data
                                        ? null
                                        : () async {
                                      final savedPath = await _pickAndSaveMedia(_selectedType!);
                                      if (savedPath != null) {
                                        setStateInDialog(() {
                                          _contentController.text = savedPath;
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text('העלה קובץ'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              if (_selectedType == MemoryType.photo || _selectedType == MemoryType.video)
                                const SizedBox(width: 8), // Spacing between buttons
                              if (_selectedType == MemoryType.audio)
                                Expanded( // Use Expanded for record button
                                  child: ElevatedButton.icon(
                                    onPressed: (_isRecorderInitialized && !_isFetchingMomentData) // Ensure recorder is ready
                                        ? () => _toggleRecording(setStateInDialog)
                                        : null,
                                    icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                                    label: Text(_isRecording ? 'הפסק הקלטה' : 'הקלט קול'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isRecording ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.tertiary,
                                      foregroundColor: _isRecording ? Theme.of(context).colorScheme.onError : Theme.of(context).colorScheme.onTertiary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        // Show current file/recording path if selected/recorded
                        if (_contentController.text.isNotEmpty && (_selectedType == MemoryType.photo || _selectedType == MemoryType.video || _selectedType == MemoryType.audio))
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.tertiary, size: 20),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'קובץ נבחר: ${Uri.parse(_contentController.text).pathSegments.last}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Moment data section
                        _isFetchingMomentData
                            ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                            : Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('פרטי המיקום והמזג אוויר הנוכחיים:', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                              const SizedBox(height: 8),
                              _buildMomentDataItem(Icons.location_on, 'מיקום', _currentLocationName ?? 'טוען/לא זמין', Theme.of(context).colorScheme),
                              _buildMomentDataItem(Icons.location_searching, 'קואורדינטות', '${_currentLatitude?.toStringAsFixed(3) ?? 'N/A'}, ${_currentLongitude?.toStringAsFixed(3) ?? 'N/A'}', Theme.of(context).colorScheme),
                              _buildMomentDataItem(Icons.wb_sunny, 'מזג אוויר', _currentWeatherDescription ?? 'טוען/לא זמין', Theme.of(context).colorScheme),
                              if (_currentWeatherTemp != null)
                                _buildMomentDataItem(Icons.thermostat, 'טמפ\'', '${_currentWeatherTemp!.toStringAsFixed(1)}°C', Theme.of(context).colorScheme),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.center,
                                child: TextButton.icon(
                                  onPressed: _fetchMomentData,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('רענן פרטי מיקום/מזג אוויר'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ביטול', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) { // Validate the form
                    // Further content validation based on type
                    String? contentToSave = _contentController.text.trim();
                    String? thumbnailUrlToSave;

                    if (_selectedType == MemoryType.photo || _selectedType == MemoryType.video || _selectedType == MemoryType.audio) {
                      if (contentToSave.isEmpty) {
                        _showSnackBar('אנא העלה או הקלט קובץ.', isError: true);
                        return;
                      }
                      thumbnailUrlToSave = contentToSave; // Default thumbnail is the content path
                      if (_selectedType == MemoryType.video) {
                        try {
                          final thumbPath = await VideoThumbnail.thumbnailFile(
                            video: contentToSave,
                            thumbnailPath: (await _getAppSpecificHiddenDirPath()) + '/thumb_${const Uuid().v4()}.png',
                            imageFormat: ImageFormat.PNG,
                            maxHeight: 150,
                            quality: 75,
                          );
                          thumbnailUrlToSave = thumbPath;
                        } catch (e) {
                          print('Error generating video thumbnail: $e');
                          _showSnackBar('שגיאה ביצירת תמונה ממוזערת לוידאו: $e', isError: true);
                          // Don't return, just proceed without thumbnail if it fails
                        }
                      }
                    } else if (_selectedType == MemoryType.link) {
                      if (!Uri.tryParse(contentToSave ?? '')!.isAbsolute) { // Basic URL validation
                        _showSnackBar('קישור לא תקין. אנא הזן קישור מלא.', isError: true);
                        return;
                      }
                    }

                    final newMemory = MemoryItem(
                      id: const Uuid().v4(),
                      type: _selectedType!,
                      title: _titleController.text.trim(),
                      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
                      content: contentToSave ?? '',
                      timestamp: DateTime.now(),
                      thumbnailUrl: thumbnailUrlToSave,
                      latitude: _currentLatitude,
                      longitude: _currentLongitude,
                      locationName: _currentLocationName,
                      weatherDescription: _currentWeatherDescription,
                      weatherTemp: _currentWeatherTemp,
                    );

                    _updateTrip(_currentTrip.copyWith(
                      memories: [..._currentTrip.memories ?? [], newMemory],
                    ));

                    Navigator.pop(context);
                    _showSnackBar('זיכרון "${newMemory.title}" נוסף בהצלחה!');
                  }
                },
                child: const Text('הוסף', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper for input decoration
  InputDecoration _inputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
    );
  }

  // Helper for moment data display items
  Widget _buildMomentDataItem(IconData icon, String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                Text(value, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Building Memory Cards ---
  Widget _buildMemoryCard(MemoryItem memory) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Animate(
      effects: [
        FadeEffect(duration: 300.ms, delay: 50.ms), // Subtle fade in
        SlideEffect(begin: const Offset(0.05, 0), end: Offset.zero, duration: 300.ms, curve: Curves.easeOut), // Slight slide from right
      ],
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 6, // More prominent shadow
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), // More rounded corners
        clipBehavior: Clip.antiAlias, // Ensures content is clipped to rounded corners
        child: InkWell(
          onTap: () => _handleMemoryTap(memory),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        memory.title,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildMemoryTypeIcon(memory.type),
                  ],
                ),
                if (memory.description != null && memory.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      memory.description!,
                      style: TextStyle(fontSize: 15, color: colorScheme.onSurface.withOpacity(0.8)),
                    ),
                  ),
                const SizedBox(height: 12),
                _buildMemoryContentPreview(memory),
                const SizedBox(height: 12),
                if (memory.locationName != null || memory.weatherDescription != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (memory.locationName != null)
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 18, color: colorScheme.secondary),
                              const SizedBox(width: 8),
                              Flexible(child: Text(memory.locationName!, style: TextStyle(fontSize: 13, color: colorScheme.onSurface))),
                            ],
                          ),
                        if (memory.weatherDescription != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                Icon(Icons.wb_sunny, size: 18, color: colorScheme.tertiary),
                                const SizedBox(width: 8),
                                Text(
                                  '${memory.weatherDescription!} ${memory.weatherTemp != null ? '(${memory.weatherTemp!.toStringAsFixed(1)}°C)' : ''}',
                                  style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.bottomLeft, // Align timestamp to bottom left
                  child: Text(
                    '${_getMemoryTypeLabel(memory.type)} - ${memory.timestamp.toLocal().toString().split(' ')[0]}',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Memory Type Icon & Label Helpers ---
  Widget _buildMemoryTypeIcon(MemoryType type) {
    IconData iconData;
    Color color;
    switch (type) {
      case MemoryType.photo:
        iconData = Icons.image;
        color = Colors.blue.shade700;
        break;
      case MemoryType.video:
        iconData = Icons.videocam;
        color = Colors.red.shade700;
        break;
      case MemoryType.note:
        iconData = Icons.notes;
        color = Colors.green.shade700;
        break;
      case MemoryType.link:
        iconData = Icons.link;
        color = Colors.purple.shade700;
        break;
      case MemoryType.audio:
        iconData = Icons.audiotrack;
        color = Colors.orange.shade700;
        break;
    }
    return Icon(iconData, color: color, size: 28); // Larger icon
  }

  String _getMemoryTypeLabel(MemoryType type) {
    switch (type) {
      case MemoryType.photo: return 'תמונה';
      case MemoryType.video: return 'וידאו';
      case MemoryType.note: return 'פתק';
      case MemoryType.link: return 'קישור';
      case MemoryType.audio: return 'הקלטה';
    }
  }

  // --- Memory Content Preview ---
  Widget _buildMemoryContentPreview(MemoryItem memory) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    switch (memory.type) {
      case MemoryType.photo:
        if (memory.thumbnailUrl != null && File(memory.thumbnailUrl!).existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.file(
              File(memory.thumbnailUrl!),
              height: 200, // Increased height for better preview
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200, width: double.infinity, color: colorScheme.surfaceVariant,
                child: Center(child: Icon(Icons.broken_image, size: 80, color: colorScheme.outline)),
              ),
            ),
          );
        }
        return Text('אין תצוגה מקדימה זמינה לקובץ זה.', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)));
      case MemoryType.video:
        if (memory.thumbnailUrl != null && File(memory.thumbnailUrl!).existsSync()) {
          return Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.file(
                  File(memory.thumbnailUrl!),
                  height: 200, // Increased height
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200, width: double.infinity, color: colorScheme.surfaceVariant,
                    child: Center(child: Icon(Icons.broken_image, size: 80, color: colorScheme.outline)),
                  ),
                ),
              ),
              Icon(Icons.play_circle_fill, size: 70, color: Colors.white.withOpacity(0.8)), // Larger play icon
            ],
          );
        }
        return Text('אין תצוגה מקדימה זמינה לקובץ זה.', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)));
      case MemoryType.note:
        return Text(
          memory.content.length > 200 ? '${memory.content.substring(0, 200)}...' : memory.content,
          style: TextStyle(fontStyle: FontStyle.italic, color: colorScheme.onSurface),
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        );
      case MemoryType.link:
        return Text(
          memory.content,
          style: TextStyle(color: colorScheme.primary, decoration: TextDecoration.underline),
          overflow: TextOverflow.ellipsis,
        );
      case MemoryType.audio:
        return Row(
          children: [
            Icon(Icons.multitrack_audio, size: 30, color: colorScheme.secondary),
            const SizedBox(width: 8),
            Expanded(child: Text('קובץ קול: ${Uri.parse(memory.content).pathSegments.last}', style: TextStyle(color: colorScheme.onSurface))),
          ],
        );
    }
  }

  // --- Memory Item Tap Handler ---
  Future<void> _handleMemoryTap(MemoryItem memory) async {
    try {
      switch (memory.type) {
        case MemoryType.photo:
        case MemoryType.video:
        case MemoryType.audio:
          if (File(memory.content).existsSync()) {
            final result = await OpenFilex.open(memory.content);
            if (result.type != ResultType.done) {
              _showSnackBar('לא ניתן לפתוח את הקובץ: ${result.message}', isError: true);
            }
          } else {
            _showSnackBar('הקובץ לא נמצא במכשיר. ייתכן שנמחק או הועבר.', isError: true);
          }
          break;
        case MemoryType.note:
          showDialog(
            context: context,
            builder: (context) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                title: Text(memory.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                content: SingleChildScrollView(child: Text(memory.content)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('סגור', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          );
          break;
        case MemoryType.link:
          final Uri uri = Uri.parse(memory.content);
          if (await launcher.canLaunchUrl(uri)) {
            await launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication);
          } else {
            _showSnackBar('לא ניתן לפתוח את הקישור: ${memory.content}', isError: true);
          }
          break;
      }
    } catch (e) {
      print('Error handling memory tap: $e');
      _showSnackBar('שגיאה בפתיחת הזיכרון: $e', isError: true);
    }
  }

  // --- Delete Memory Function ---
  Future<void> _deleteMemory(MemoryItem memory) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text('מחיקת זיכרון', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text('האם אתה בטוח שברצונך למחוק את הזיכרון "${memory.title}"?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('ביטול', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('מחק', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );

    if (confirm == true) {
      final updatedMemories = List<MemoryItem>.from(_currentTrip.memories ?? []);
      updatedMemories.removeWhere((item) => item.id == memory.id);
      _updateTrip(_currentTrip.copyWith(memories: updatedMemories));

      // Attempt to delete associated file
      if ((memory.type == MemoryType.photo || memory.type == MemoryType.video || memory.type == MemoryType.audio) &&
          memory.content.isNotEmpty && File(memory.content).existsSync()) {
        try {
          await File(memory.content).delete();
          if (memory.thumbnailUrl != null && File(memory.thumbnailUrl!).existsSync() && memory.thumbnailUrl != memory.content) {
            await File(memory.thumbnailUrl!).delete(); // Delete thumbnail too if it's separate
          }
          print('DEBUG: File(s) deleted from storage: ${memory.content}');
        } catch (e) {
          print('Error deleting file(s) from storage: $e');
          _showSnackBar('שגיאה במחיקת קובץ הזיכרון מהמכשיר.', isError: true);
        }
      }
      _showSnackBar('הזיכרון "${memory.title}" נמחק.');
    }
  }

  Future<void> _refreshMemories() async {
    // Simply re-sort and update the state to reflect any internal changes or just refresh UI
    _updateTrip(_currentTrip.copyWith(memories: _currentTrip.memories));
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'זיכרונות טיול: ${_currentTrip.name}',
          style: TextStyle(color: colorScheme.onPrimary),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
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
        ],
      ),
      body: Stack( // <--- עוטף ב-Stack כדי להציג אינדיקטור טעינה
        children: [
          Directionality(
            textDirection: TextDirection.rtl, // RTL for the body content
            child: _currentTrip.memories == null || _currentTrip.memories!.isEmpty
                ? _buildEmptyState(colorScheme)
                : RefreshIndicator(
              onRefresh: _refreshMemories,
              color: colorScheme.primary,
              backgroundColor: colorScheme.surface,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: _currentTrip.memories!.length,
                itemBuilder: (context, index) {
                  final memory = _currentTrip.memories![index];
                  return Dismissible(
                    key: Key(memory.id), // Unique key for Dismissible
                    direction: DismissDirection.endToStart, // Swipe from right to left
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        borderRadius: BorderRadius.circular(18), // Match card border radius
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Match card margin
                      child: Icon(Icons.delete_forever, color: colorScheme.onError, size: 36),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return Directionality( // RTL for confirm dialog
                            textDirection: TextDirection.rtl,
                            child: AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              title: const Text('מחיקת זיכרון', style: TextStyle(fontWeight: FontWeight.bold)),
                              content: Text('האם אתה בטוח שברצונך למחוק את הזיכרון "${memory.title}"?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('ביטול', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('מחק', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    onDismissed: (direction) {
                      _deleteMemory(memory);
                    },
                    child: _buildMemoryCard(memory),
                  );
                },
              ),
            ),
          ),
          // <--- חדש: אינדיקטור טעינה במרכז המסך
          if (_isShowingAddMemoryDialog)
            Container(
              color: Colors.black.withOpacity(0.5), // רקע עמום
              child: Center(
                child: CircularProgressIndicator(color: colorScheme.secondary),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isShowingAddMemoryDialog ? null : _showAddMemoryDialog, // <--- השתמש באינדיקטור הטעינה
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text('הוסף זיכרון'),
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ).animate().slideY(begin: 0.2, duration: 500.ms).fadeIn(duration: 500.ms), // Animate FAB
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Center the FAB
    );
  }

  // --- Empty State Widget ---
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Animate(
                effects: [
                  FadeEffect(duration: 1000.ms),
                  SlideEffect(begin: const Offset(0, 0.1)),
                ],
                child: Lottie.asset(
                  'assets/lottie_empty_memories.json',
                  height: 250,
                  repeat: true,
                ),
              ),

              const SizedBox(height: 30),
              Text(
                'אין עדיין זיכרונות לטיול זה.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)
                    ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'לחצו על כפתור "הוסף זיכרון" כדי לתעד את הרגעים המיוחדים שלכם!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withOpacity(0.7))
                    ?? const TextStyle(fontSize: 16, color: Colors.grey),
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
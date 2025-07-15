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
import 'package:geocoding/geocoding.dart';
// import 'package:url_launcher/url.dart' as launcher; // Ensure this import is correct as "url.dart"
import 'package:url_launcher/url_launcher.dart' as launcher; // <--- The original one if "url.dart" gives error

import 'package:video_thumbnail/video_thumbnail.dart'; // <--- NEW: For video thumbnails
// import 'package:record/record.dart'; // <--- REMOVE THIS IMPORT
// import 'package:record/record_impl.dart'; // <--- REMOVE THIS IMPORT
import 'package:flutter_sound/flutter_sound.dart'; // <--- NEW: Import flutter_sound
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart'; // <--- NEW: For AudioEncoder enum

import '../models/trip_model.dart';
import '../models/memory_item_model.dart';
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
  FlutterSoundRecorder? _audioRecorder; // <--- CHANGE: Use nullable FlutterSoundRecorder
  bool _isRecorderInitialized = false; // <--- NEW: Track recorder initialization

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

  final WeatherService _weatherService = WeatherService('8c8d50cc8e3c472c07c13bf9a8498eef'); // Replace with your actual API key!

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;
    _currentTrip = _currentTrip.copyWith(memories: _currentTrip.memories ?? []);
    _initRecorder(); // <--- NEW: Initialize recorder
  }

  // --- NEW: Initialize FlutterSoundRecorder ---
  Future<void> _initRecorder() async {
    _audioRecorder = FlutterSoundRecorder();
    await _audioRecorder!.openRecorder();
    _isRecorderInitialized = true;
    setState(() {}); // Rebuild UI to reflect recorder readiness
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    if (_isRecorderInitialized) { // <--- Dispose only if initialized
      _audioRecorder!.closeRecorder();
      _audioRecorder = null;
    }
    super.dispose();
  }

  void _updateTrip(Trip updatedTrip) {
    setState(() {
      _currentTrip = updatedTrip;
    });
    widget.onTripUpdated(updatedTrip);
  }

  Future<void> _fetchMomentData() async {
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

        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          _currentLocationName = placemarks.first.locality ?? placemarks.first.subAdministrativeArea ?? placemarks.first.name;
        } else {
          _currentLocationName = 'מיקום לא ידוע';
        }

        final String weatherUrl = 'https://api.openweathermap.org/data/2.5/weather?q=${widget.trip.destinationCity}&appid=${_weatherService.apiKey}&units=metric&lang=he';
        final weatherResponse = await http.get(Uri.parse(weatherUrl)).timeout(const Duration(seconds: 10));

        if (weatherResponse.statusCode == 200) {
          final weatherJson = jsonDecode(utf8.decode(weatherResponse.bodyBytes));
          _currentWeatherDescription = weatherJson['weather'][0]['description'];
          _currentWeatherTemp = (weatherJson['main']['temp'] as num).toDouble();
        } else {
          print('Failed to get current weather: ${weatherResponse.statusCode} - ${utf8.decode(weatherResponse.bodyBytes)}');
          _currentWeatherDescription = 'לא זמין';
          _currentWeatherTemp = null;
        }

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הרשאת מיקום נדחתה. לא ניתן להוסיף פרטי מיקום.')),
        );
      }
    } catch (e) {
      print('Error fetching moment data (location/weather): $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בטעינת פרטי המיקום/מזג אוויר: ${e.toString().contains('timeout') ? 'פג תוקף הבקשה' : e}')),
      );
    } finally {
      setState(() {
        _isFetchingMomentData = false;
      });
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

  Future<String?> _pickAndSaveMedia(MemoryType type) async {
    XFile? pickedFile;
    if (type == MemoryType.photo || type == MemoryType.video) {
      pickedFile = await _picker.pickMedia();
    } else if (type == MemoryType.audio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('בחר באפשרות הקלטת קול או השתמש בפונקציונליות "העלה קובץ" עבור קבצי אודיו קיימים.')),
      );
      return null;
    }

    if (pickedFile != null) {
      try {
        final String appSpecificHiddenDirPath = await _getAppSpecificHiddenDirPath();
        final String fileName = '${const Uuid().v4()}_${pickedFile.name}';
        final String newPath = '$appSpecificHiddenDirPath/$fileName';
        final File newFile = File(pickedFile.path);
        await newFile.copy(newPath);
        return newPath;
      } catch (e) {
        print('Error saving file permanently: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בשמירת הקובץ: $e')),
        );
        return null;
      }
    }
    return null;
  }

  Future<void> _toggleRecording(Function(Function()) setStateInDialog) async {
    if (_audioRecorder == null || !_isRecorderInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('מקליט הקול אינו מוכן. נסה שוב מאוחר יותר.')),
      );
      return;
    }

    if (_isRecording) {
      // Stop recording
      final path = await _audioRecorder!.stopRecorder(); // <--- Use stopRecorder
      setStateInDialog(() {
        _isRecording = false;
      });
      if (path != null) {
        try {
          final String appSpecificHiddenDirPath = await _getAppSpecificHiddenDirPath();
          final String fileName = '${const Uuid().v4()}_audio.aac'; // Assuming aac, adjust if needed
          final String newPath = '$appSpecificHiddenDirPath/$fileName';
          final File newFile = File(path);
          await newFile.copy(newPath);
          _contentController.text = newPath; // Set content controller with permanent path
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('הקלטה נשמרה.')),
          );
        } catch (e) {
          print('Error saving recorded audio: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('שגיאה בשמירת הקלטת קול: $e')),
          );
        }
      }
    } else {
      // Check permissions
      if (!await Permission.microphone.isGranted) {
        await Permission.microphone.request();
      }

      if (await Permission.microphone.isGranted) {
        final appSpecificHiddenDirPath = await _getAppSpecificHiddenDirPath();
        final outputPath = '$appSpecificHiddenDirPath/temp_recording.aac'; // Temporary path for recording
        await _audioRecorder!.startRecorder( // <--- Use startRecorder
          toFile: outputPath,
          codec: Codec.aacADTS, // <--- Use Codec from flutter_sound_platform_interface
        );
        setStateInDialog(() {
          _isRecording = true;
          _contentController.text = ''; // Clear content during recording
          _selectedType = MemoryType.audio; // Force type to audio
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הקלטה החלה...')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('נדרשת הרשאת מיקרופון להקלטה.')),
        );
      }
    }
  }

  Future<void> _showAddMemoryDialog() async {
    _titleController.clear();
    _descriptionController.clear();
    _contentController.clear();
    _selectedType = null;
    _currentLocationName = null;
    _currentLatitude = null;
    _currentLongitude = null;
    _currentWeatherDescription = null;
    _currentWeatherTemp = null;
    _isRecording = false; // Reset recording state

    // Fetch moment data immediately when dialog opens
    await _fetchMomentData();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('הוסף זיכרון חדש'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'כותרת', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'תיאור (אופציונלי)', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<MemoryType>(
                      value: _selectedType,
                      hint: const Text('בחר סוג זיכרון'),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: MemoryType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_getMemoryTypeLabel(type)),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setStateInDialog(() {
                          _selectedType = newValue;
                          _contentController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    if (_selectedType == MemoryType.link)
                      TextField(
                        controller: _contentController,
                        decoration: const InputDecoration(labelText: 'קישור (URL)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.url,
                      )
                    else if (_selectedType == MemoryType.note)
                      TextField(
                        controller: _contentController,
                        decoration: const InputDecoration(labelText: 'תוכן הפתק', border: OutlineInputBorder()),
                        maxLines: 5,
                      ),
                    const SizedBox(height: 10),
                    // --- START FIX for RenderFlex Overflow ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Flexible( // <--- Wrapped button in Flexible
                          child: ElevatedButton.icon(
                            onPressed: (_selectedType == MemoryType.photo || _selectedType == MemoryType.video)
                                ? () async {
                              final savedPath = await _pickAndSaveMedia(_selectedType!);
                              if (savedPath != null) {
                                setStateInDialog(() {
                                  _contentController.text = savedPath;
                                });
                              }
                            }
                                : null, // Disable if not photo/video
                            icon: const Icon(Icons.upload_file),
                            label: const Text('העלה קובץ'),
                          ),
                        ),
                        // Add spacing only if both buttons might be visible to avoid double spacing
                        // This condition ensures spacing ONLY when the 'Record Audio' button is also present.
                        if (_selectedType == MemoryType.audio) // Only show space if audio button is present
                          const SizedBox(width: 8), // Added spacing

                        if (_selectedType == MemoryType.audio) // Show record button only for audio type
                          Flexible( // <--- Wrapped button in Flexible
                            child: ElevatedButton.icon(
                              onPressed: (_isRecorderInitialized && !_isFetchingMomentData) // Ensure recorder is ready
                                  ? () => _toggleRecording(setStateInDialog)
                                  : null,
                              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                              label: Text(_isRecording ? 'הפסק הקלטה' : 'הקלט קול'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isRecording ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                      ],
                    ),
                    // --- END FIX for RenderFlex Overflow ---
                    // Show current file/recording path if selected/recorded
                    if (_contentController.text.isNotEmpty && (_selectedType == MemoryType.photo || _selectedType == MemoryType.video || _selectedType == MemoryType.audio))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'קובץ נבחר: ${Uri.parse(_contentController.text).pathSegments.last}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 10),
                    _isFetchingMomentData
                        ? const CircularProgressIndicator()
                        : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('פרטי המיקום והמזג אוויר הנוכחיים:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('מיקום: ${_currentLocationName ?? 'טוען/לא זמין'}'),
                        Text('קואורדינטות: ${_currentLatitude?.toStringAsFixed(3) ?? 'N/A'}, ${_currentLongitude?.toStringAsFixed(3) ?? 'N/A'}'),
                        Text('מזג אוויר: ${_currentWeatherDescription ?? 'טוען/לא זמין'}'),
                        if (_currentWeatherTemp != null) Text('טמפ\': ${_currentWeatherTemp!.toStringAsFixed(1)}°C'),
                        TextButton(
                          onPressed: _fetchMomentData,
                          child: const Text('רענן פרטי מיקום/מזג אוויר'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ביטול'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_titleController.text.isEmpty || _selectedType == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('אנא הזן כותרת ובחר סוג זיכרון.')),
                      );
                      return;
                    }

                    String? contentToSave = _contentController.text.trim();
                    String? thumbnailUrlToSave;

                    if (_selectedType == MemoryType.photo || _selectedType == MemoryType.video || _selectedType == MemoryType.audio) {
                      if (contentToSave.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('אנא העלה או הקלט קובץ.')),
                        );
                        return;
                      }
                      thumbnailUrlToSave = contentToSave;
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
                        }
                      }
                    } else if (_selectedType == MemoryType.link || _selectedType == MemoryType.note) {
                      if (contentToSave.isEmpty && _selectedType != MemoryType.note) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('תוכן הזיכרון (קישור/פתק) חסר.')),
                        );
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
                  },
                  child: const Text('הוסף'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMemoryCard(MemoryItem memory) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _handleMemoryTap(memory),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      memory.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildMemoryTypeIcon(memory.type),
                ],
              ),
              if (memory.description != null && memory.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    memory.description!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),
              const SizedBox(height: 8),
              _buildMemoryContentPreview(memory),
              if (memory.locationName != null || memory.weatherDescription != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (memory.locationName != null)
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Flexible(child: Text(memory.locationName!, style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
                          ],
                        ),
                      if (memory.weatherDescription != null)
                        Row(
                          children: [
                            const Icon(Icons.wb_sunny, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${memory.weatherDescription!} ${memory.weatherTemp != null ? '(${memory.weatherTemp!.toStringAsFixed(1)}°C)' : ''}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  '${_getMemoryTypeLabel(memory.type)} - ${memory.timestamp.toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemoryTypeIcon(MemoryType type) {
    IconData iconData;
    Color color;
    switch (type) {
      case MemoryType.photo:
        iconData = Icons.image;
        color = Colors.blue;
        break;
      case MemoryType.video:
        iconData = Icons.videocam;
        color = Colors.red;
        break;
      case MemoryType.note:
        iconData = Icons.notes;
        color = Colors.green;
        break;
      case MemoryType.link:
        iconData = Icons.link;
        color = Colors.purple;
        break;
      case MemoryType.audio:
        iconData = Icons.audiotrack;
        color = Colors.orange;
        break;
    }
    return Icon(iconData, color: color, size: 24);
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

  Widget _buildMemoryContentPreview(MemoryItem memory) {
    switch (memory.type) {
      case MemoryType.photo:
        if (memory.thumbnailUrl != null && File(memory.thumbnailUrl!).existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.file(
              File(memory.thumbnailUrl!),
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80, color: Colors.grey),
            ),
          );
        }
        return const Text('אין תצוגה מקדימה זמינה לקובץ זה.');
      case MemoryType.video:
        if (memory.thumbnailUrl != null && File(memory.thumbnailUrl!).existsSync()) {
          return Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(
                  File(memory.thumbnailUrl!), // Often a frame from the video
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                ),
              ),
              const Icon(Icons.play_circle_fill, size: 60, color: Colors.white70), // Play icon overlay
            ],
          );
        }
        return const Text('אין תצוגה מקדימה זמינה לקובץ זה.');
      case MemoryType.note:
        return Text(
          memory.content.length > 100 ? '${memory.content.substring(0, 100)}...' : memory.content,
          style: const TextStyle(fontStyle: FontStyle.italic),
        );
      case MemoryType.link:
        return Text(
          memory.content,
          style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
          overflow: TextOverflow.ellipsis,
        );
      case MemoryType.audio:
        return const Row(
          children: [
            Icon(Icons.audiotrack, size: 24, color: Colors.grey),
            SizedBox(width: 8),
            Text('קובץ קול'),
          ],
        );
    }
  }

  Future<void> _handleMemoryTap(MemoryItem memory) async {
    try {
      switch (memory.type) {
        case MemoryType.photo:
        case MemoryType.video:
        case MemoryType.audio:
          if (File(memory.content).existsSync()) {
            final result = await OpenFilex.open(memory.content);
            if (result.type != ResultType.done) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('לא ניתן לפתוח את הקובץ: ${result.message}')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('הקובץ לא נמצא במכשיר. ייתכן שנמחק או הועבר.')),
            );
          }
          break;
        case MemoryType.note:
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(memory.title),
              content: SingleChildScrollView(child: Text(memory.content)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('סגור')),
              ],
            ),
          );
          break;
        case MemoryType.link:
          final Uri uri = Uri.parse(memory.content);
          if (await launcher.canLaunchUrl(uri)) {
            await launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('לא ניתן לפתוח את הקישור: ${memory.content}')),
            );
          }
          break;
      }
    } catch (e) {
      print('Error handling memory tap: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בפתיחת הזיכרון: $e')),
      );
    }
  }

  Future<void> _deleteMemory(MemoryItem memory) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('מחיקת זיכרון'),
          content: Text('האם אתה בטוח שברצונך למחוק את הזיכרון "${memory.title}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ביטול'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('מחק'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final updatedMemories = List<MemoryItem>.from(_currentTrip.memories ?? []);
      updatedMemories.removeWhere((item) => item.id == memory.id);
      _updateTrip(_currentTrip.copyWith(memories: updatedMemories));

      if ((memory.type == MemoryType.photo || memory.type == MemoryType.video || memory.type == MemoryType.audio) &&
          memory.content.isNotEmpty && File(memory.content).existsSync()) {
        try {
          await File(memory.content).delete();
          print('DEBUG: File deleted from storage: ${memory.content}');
        } catch (e) {
          print('Error deleting file from storage: $e');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('הזיכרון "${memory.title}" נמחק.')),
      );
    }
  }

  Future<void> _refreshMemories() async {
    setState(() {
      // Re-triggers build to show latest state of _currentTrip.memories
    });
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('זיכרונות טיול: ${_currentTrip.name}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddMemoryDialog,
            tooltip: 'הוסף זיכרון חדש',
          ),
        ],
      ),
      body: _currentTrip.memories == null || _currentTrip.memories!.isEmpty
          ? Center(
        child: Text(
          'אין עדיין זיכרונות לטיול זה.\nהוסף את הזיכרון הראשון שלך!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshMemories,
        color: Theme.of(context).primaryColor,
        child: ListView.builder(
          itemCount: _currentTrip.memories!.length,
          itemBuilder: (context, index) {
            final memory = _currentTrip.memories![index];
            return Dismissible(
              key: Key(memory.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(Icons.delete_forever, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('מחיקת זיכרון'),
                      content: Text('האם אתה בטוח שברצונך למחוק את הזיכרון "${memory.title}"?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('ביטול'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('מחק'),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ],
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
    );
  }
}
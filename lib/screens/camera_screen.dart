import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:kitchen_inventory_app/data/database_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../models/item.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';

class VoiceRecognitionDialog extends StatefulWidget {
  const VoiceRecognitionDialog({super.key});

  @override
  State<VoiceRecognitionDialog> createState() => _VoiceRecognitionDialogState();
}

class _VoiceRecognitionDialogState extends State<VoiceRecognitionDialog> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool isRecording = false;
  bool isProcessing = false;
  String? audioPath;
  bool _isRecorderInitialized = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return;
    }

    await _recorder.openRecorder();
    setState(() {
      _isRecorderInitialized = true;
    });
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recorder not initialized')),
        );
      }
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      audioPath = '${directory.path}/voice_input.aac';

      await _recorder.startRecorder(
        toFile: audioPath,
        codec: Codec.aacADTS,
      );

      setState(() {
        isRecording = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!isRecording) return;

    try {
      await _recorder.stopRecorder();
      
      setState(() {
        isRecording = false;
      });

      if (audioPath != null) {
        await _processAudioFile(audioPath!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
      }
    }
  }

  Future<void> _processAudioFile(String path) async {
    setState(() {
      isProcessing = true;
    });

    try {
      print('Processing audio file: $path');

      final response = await ApiService.sendAudioWithLocation(path, null);

      print('Got response: $response');

      if (response['updates'] != null) {
        List<String> messages = [];

        for (var itemData in response['updates']) {
          if (itemData['status'] == 'success') {
            final item = Item(
              name: itemData['product'],
              location: itemData['location'],
              quantity: itemData['quantity'] ?? 1,
              expiry: itemData['expiry'] != null
                  ? DateTime.parse(itemData['expiry'])
                  : null,
              category: itemData['category'] ?? 'General',
            );

            await DatabaseHelper.instance.insertItem(item);
            
            if (itemData['message'] != null) {
              messages.add(itemData['message']);
            }
          }
        }

        if (mounted) {
          final transcription = response['transcription'] ?? '';
          final summary = messages.join('\n');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎤 Heard: "$transcription"\n\n$summary',
              ),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception('No updates in response');
      }
    } catch (e) {
      print('Error processing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Voice Input'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRecording ? Icons.mic : Icons.mic_none,
            size: 48,
            color: isRecording ? Colors.red : Colors.grey,
          ),
          const SizedBox(height: 12),
          const Text(
            'Auto-classify is enabled',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Text(
            isProcessing
                ? 'Processing with Whisper...'
                : isRecording
                    ? 'Recording...'
                    : 'Tap to start recording',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            'Say: "add 2 apples and remove 3 oranges"',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (isProcessing)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isProcessing ? null : () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isProcessing || !_isRecorderInitialized
              ? null
              : (isRecording ? _stopRecording : _startRecording),
          child: Text(isRecording ? 'Stop & Process' : 'Start Recording'),
        ),
      ],
    );
  }
}

class CameraScreen extends StatefulWidget {
  final void Function(String location)? onNavigateToInventory;

  const CameraScreen({super.key, this.onNavigateToInventory});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  XFile? capturedImage;
  bool isLoading = true;
  String? errorMessage;
  List<DetectedItem> detectedItems = [];
  bool isDetecting = false;
  String detectionMethod = 'hybrid'; // 'mlkit', 'backend', or 'hybrid'

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> requestCameraPermission() async {
    await Permission.camera.request();
    return;
  }

  Future<void> initializeCamera() async {
    try {
      await requestCameraPermission();

      cameras = await availableCameras();
      debugPrint("Available cameras: ${cameras?.length ?? 0}");

      if (cameras != null && cameras!.isNotEmpty) {
        _cameraController = CameraController(
          cameras![0],
          ResolutionPreset.high, // Increased to high for better detection
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
            errorMessage = "No cameras found on this device";
          });
        }
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "Error: $e";
        });
      }
    }
  }

  // Enhanced ML Kit detection with better filtering
  Future<List<DetectedItem>> detectWithMLKit(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final imageLabeler = ImageLabeler(
        options: ImageLabelerOptions(
          confidenceThreshold: 0.4, // Lowered threshold for more detections
        ),
      );
      final labels = await imageLabeler.processImage(inputImage);

      // Common food-related keywords to prioritize
      final foodKeywords = [
        'food', 'fruit', 'vegetable', 'produce', 'apple', 'banana', 'orange',
        'tomato', 'carrot', 'potato', 'onion', 'garlic', 'bread', 'milk',
        'cheese', 'egg', 'meat', 'chicken', 'fish', 'beverage', 'drink',
        'bottle', 'can', 'package', 'container', 'bowl', 'plate', 'dish',
        'ingredient', 'snack', 'meal', 'cuisine', 'natural', 'fresh',
        'organic', 'dairy', 'grain', 'spice', 'herb', 'baked', 'cooked'
      ];

      List<DetectedItem> items = [];
      for (final label in labels) {
        if (label.confidence > 0.4) {
          // Check if label contains food-related keywords
          bool isFoodRelated = foodKeywords.any((keyword) =>
              label.label.toLowerCase().contains(keyword));
          
          items.add(DetectedItem(
            name: label.label,
            confidence: label.confidence,
            source: 'ML Kit',
            isFoodRelated: isFoodRelated,
          ));
        }
      }

      // Sort by food-related first, then by confidence
      items.sort((a, b) {
        if (a.isFoodRelated && !b.isFoodRelated) return -1;
        if (!a.isFoodRelated && b.isFoodRelated) return 1;
        return b.confidence.compareTo(a.confidence);
      });

      imageLabeler.close();
      return items.take(10).toList(); // Return top 10
    } catch (e) {
      debugPrint("ML Kit error: $e");
      return [];
    }
  }

  // Backend API detection using image
  Future<List<DetectedItem>> detectWithBackend(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint("Image file doesn't exist");
        return [];
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/detect-image'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', imagePath));

      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<DetectedItem> items = [];
        
        if (data['items'] != null) {
          for (var item in data['items']) {
            items.add(DetectedItem(
              name: item['name'] ?? item['label'],
              confidence: (item['confidence'] ?? 0.0).toDouble(),
              source: 'Backend AI',
              isFoodRelated: true,
            ));
          }
        }
        return items;
      } else {
        debugPrint("Backend detection failed: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Backend detection error: $e");
      return [];
    }
  }

  // Hybrid detection: combine both methods
  Future<List<DetectedItem>> detectHybrid(String imagePath) async {
    try {
      // Run both detections in parallel
      final results = await Future.wait([
        detectWithMLKit(imagePath),
        detectWithBackend(imagePath),
      ]);

      final mlkitItems = results[0];
      final backendItems = results[1];

      // Combine results, prioritizing backend
      List<DetectedItem> combined = [...backendItems];
      
      // Add ML Kit items that aren't duplicates
      for (var mlItem in mlkitItems) {
        bool isDuplicate = combined.any((item) =>
            item.name.toLowerCase() == mlItem.name.toLowerCase());
        if (!isDuplicate) {
          combined.add(mlItem);
        }
      }

      return combined.take(10).toList();
    } catch (e) {
      debugPrint("Hybrid detection error: $e");
      // Fallback to ML Kit only
      return await detectWithMLKit(imagePath);
    }
  }

  Future<void> detectItems(String imagePath) async {
    setState(() {
      detectedItems = [];
      isDetecting = true;
    });

    List<DetectedItem> items = [];
    
    try {
      switch (detectionMethod) {
        case 'mlkit':
          items = await detectWithMLKit(imagePath);
          break;
        case 'backend':
          items = await detectWithBackend(imagePath);
          break;
        case 'hybrid':
          items = await detectHybrid(imagePath);
          break;
      }
    } catch (e) {
      debugPrint("Detection error: $e");
      // Fallback to ML Kit
      items = await detectWithMLKit(imagePath);
    }

    if (mounted) {
      setState(() {
        detectedItems = items;
        isDetecting = false;
      });
    }
  }

  Future<void> takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        capturedImage = photo;
      });

      // Start detection
      await detectItems(photo.path);
    } catch (e) {
      debugPrint("Error taking photo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  void resetCamera() {
    setState(() {
      capturedImage = null;
      detectedItems = [];
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Scan Camera")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Scan Camera")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });
                  initializeCamera();
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text("Scan Camera")),
        body: const Center(child: Text("Camera not available")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Camera"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            initialValue: detectionMethod,
            onSelected: (String value) {
              setState(() {
                detectionMethod = value;
              });
              if (capturedImage != null) {
                detectItems(capturedImage!.path);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mlkit',
                child: Text('ML Kit Only'),
              ),
              const PopupMenuItem(
                value: 'backend',
                child: Text('Backend AI'),
              ),
              const PopupMenuItem(
                value: 'hybrid',
                child: Text('Hybrid (Best)'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: capturedImage == null
                        ? CameraPreview(_cameraController!)
                        : Image.file(
                            File(capturedImage!.path),
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
                if (isDetecting)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 12),
                          Text(
                            'Detecting items...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (capturedImage != null)
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Method: ${detectionMethod.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (detectedItems.isNotEmpty)
                          Text(
                            '${detectedItems.length} items found',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (detectedItems.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Detected Items:",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...detectedItems.take(5).map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '${(item.confidence * 100).toStringAsFixed(0)}% • ${item.source}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.green),
                                    iconSize: 20,
                                    onPressed: () async {
                                      await _addItemToInventory(item.name);
                                    },
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        child: const Column(
                          children: [
                            Icon(Icons.search_off, size: 32, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              "No items detected. Try retaking with better lighting.",
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: resetCamera,
                            icon: const Icon(Icons.refresh),
                            label: const Text("Retake"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: detectedItems.isEmpty
                                ? null
                                : () async {
                                    await _addItemToInventory(detectedItems.first.name);
                                  },
                            icon: const Icon(Icons.check),
                            label: const Text("Add Top"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (capturedImage == null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Take Photo"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => const VoiceRecognitionDialog(),
                        );
                        
                        if (result == true && mounted) {
                          widget.onNavigateToInventory?.call('fridge');
                        }
                      },
                      icon: const Icon(Icons.mic),
                      label: const Text("Use Voice"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addItemToInventory(String itemName) async {
    final messenger = ScaffoldMessenger.of(context);

    // Show dialog to select location
    final location = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $itemName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select storage location:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.kitchen, color: Colors.blue),
              title: const Text('Fridge'),
              onTap: () => Navigator.pop(context, 'fridge'),
            ),
            ListTile(
              leading: const Icon(Icons.countertops, color: Colors.orange),
              title: const Text('Pantry'),
              onTap: () => Navigator.pop(context, 'pantry'),
            ),
            ListTile(
              leading: const Icon(Icons.ac_unit, color: Colors.lightBlue),
              title: const Text('Freezer'),
              onTap: () => Navigator.pop(context, 'freezer'),
            ),
          ],
        ),
      ),
    );

    if (location == null) return;

    final item = Item(
      name: itemName,
      location: location,
      quantity: 1,
      category: 'General',
    );

    try {
      await DatabaseHelper.instance.insertItem(item);
      if (!mounted) return;
      
      messenger.showSnackBar(
        SnackBar(
          content: Text('✓ Added $itemName to $location'),
          backgroundColor: Colors.green,
        ),
      );
      
      resetCamera();
      widget.onNavigateToInventory?.call(location);
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to add item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Model for detected items
class DetectedItem {
  final String name;
  final double confidence;
  final String source;
  final bool isFoodRelated;

  DetectedItem({
    required this.name,
    required this.confidence,
    required this.source,
    this.isFoodRelated = false,
  });
}
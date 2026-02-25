import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:kitchen_inventory_app/data/database_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'dart:io';
import '../models/item.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;


class VoiceRecognitionDialog extends StatefulWidget {
  const VoiceRecognitionDialog({super.key});

  @override
  State<VoiceRecognitionDialog> createState() => _VoiceRecognitionDialogState();
}

class _VoiceRecognitionDialogState extends State<VoiceRecognitionDialog> {
  late stt.SpeechToText _speechToText;
  bool isListening = false;
  String recognizedText = '';

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required for voice input')),
      );
      return;
    }
    if (!isListening && _speechToText.isAvailable) {
      setState(() {
        isListening = true;
        recognizedText = '';
      });
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            recognizedText = result.recognizedWords;
          });
        },
      );
    }
  }

  void _stopListening() async {
    if (isListening) {
      await _speechToText.stop();
      setState(() {
        isListening = false;
      });
    }
  }

  @override
  void dispose() {
    _speechToText.cancel();
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
            isListening ? Icons.mic : Icons.mic_none,
            size: 48,
            color: isListening ? Colors.red : Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isListening ? 'Listening...' : 'Tap to start speaking',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              recognizedText.isEmpty
                ? (isListening ? 'Listening...' : 'No speech detected')
                : recognizedText,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: isListening ? _stopListening : _startListening,
          child: Text(isListening ? 'Stop' : 'Start'),
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
  List<String> detectedLabels = [];

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> initializeImageLabeler() async {
    // Deprecated: replaced by tflite_flutter
  }

  Future<void> detectLabelsInImage(String imagePath) async {
    // Google ML Kit Image Labeling
    final inputImage = InputImage.fromFilePath(imagePath);
    final imageLabeler = ImageLabeler(options: ImageLabelerOptions());
    final labels = await imageLabeler.processImage(inputImage);

    String? bestLabel;
    double bestScore = 0.0;
    for (final label in labels) {
      if (label.confidence > bestScore) {
        bestScore = label.confidence;
        bestLabel = label.label;
      }
    }

    setState(() {
      detectedLabels = bestLabel != null ? [bestLabel] : [];
    });
    imageLabeler.close();
  }

  Future<void> requestCameraPermission() async {
    await Permission.camera.request();
    return;
  }

  Future<void> initializeCamera() async {
    try {
      // Request camera permission
      await requestCameraPermission();

      cameras = await availableCameras();
      debugPrint("Available cameras: ${cameras?.length ?? 0}");

      if (cameras != null && cameras!.isNotEmpty) {
        _cameraController = CameraController(
          cameras![0],
          ResolutionPreset.high,
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

  Future<void> takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        capturedImage = photo;
      });

      // Run ML Kit image labeling on the captured image
      await detectLabelsInImage(photo.path);

      // Auto-dismiss preview after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && capturedImage != null) {
          resetCamera();
        }
      });
    } catch (e) {
      debugPrint("Error taking photo: $e");
    }
  }

  void resetCamera() {
    setState(() {
      capturedImage = null;
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
              Icon(Icons.block, size: 64, color: Colors.grey),
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
      appBar: AppBar(title: const Text("Scan Camera")),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Live camera feed - 9:16 aspect ratio container
                Center(
                  child: Container(
                    width: 270,
                    height: 480,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: capturedImage == null
                          ? CameraPreview(_cameraController!)
                          : Image.file(
                              File(capturedImage!.path),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
                // Rectangle overlay (9:16 aspect ratio)
                Center(
                  child: Container(
                    width: 270,
                    height: 480,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Captured photo preview info
          if (capturedImage != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Detected labels section
                    if (detectedLabels.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Detected Item:",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              detectedLabels.first,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: const Text(
                          "No items detected",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: resetCamera,
                            child: const Text("Retake Now"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);

                              if (detectedLabels.isEmpty) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('No detected item to add'),
                                  ),
                                );
                                return;
                              }

                              final itemName = detectedLabels.first;

                              final item = Item(
                                name: itemName,
                                location: 'fridge',
                                quantity: 1,
                              );
                              try {
                                await DatabaseHelper.instance.insertItem(item);
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Added item: $itemName'),
                                  ),
                                );
                                widget.onNavigateToInventory?.call('fridge');
                              } catch (e) {
                                print('Error inserting item from camera: $e');
                                if (mounted) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to add item'),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            child: const Text(
                              "Use Photo",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          // Take Photo button
          if (capturedImage == null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: takePhoto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Take Photo",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const VoiceRecognitionDialog(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Use Voice",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

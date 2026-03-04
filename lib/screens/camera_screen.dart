import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:kitchen_inventory_app/data/database_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
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

      // Always auto-classify on backend
      final response = await ApiService.sendAudioWithLocation(path, null);

      print('Got response: $response');

      // Parse response and sync to local database
      if (response['updates'] != null) {
        List<String> messages = [];

        for (var itemData in response['updates']) {
          if (itemData['status'] == 'success') {
            // Add/update in local SQLite database
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
  List<String> detectedLabels = [];

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> detectLabelsInImage(String imagePath) async {
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
      await requestCameraPermission();

      cameras = await availableCameras();
      debugPrint("Available cameras: ${cameras?.length ?? 0}");

      if (cameras != null && cameras!.isNotEmpty) {
        _cameraController = CameraController(
          cameras![0],
          ResolutionPreset.medium,
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

      await detectLabelsInImage(photo.path);

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
      appBar: AppBar(title: const Text("Scan Camera")),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
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
          if (capturedImage != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
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
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => const VoiceRecognitionDialog(),
                    );
                    
                    if (result == true && mounted) {
                      widget.onNavigateToInventory?.call('fridge');
                    }
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

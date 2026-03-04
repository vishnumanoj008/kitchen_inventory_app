import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isInitialized = false;
  String? _currentPath;

  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception("Microphone permission denied");
    }

    await _recorder.openRecorder();
    _isInitialized = true;
  }

  Future<String> start() async {
    await _initialize();

    final dir = await getTemporaryDirectory();
    final path = "${dir.path}/voice.aac";  // Changed extension
    _currentPath = path;

    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.aacADTS,  // Changed from Codec.pcm16
    );

    return path;
  }

  Future<String?> stop() async {
    if (!_isInitialized) return null;
    
    await _recorder.stopRecorder();
    return _currentPath;
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      await _recorder.closeRecorder();
      _isInitialized = false;
    }
  }
}
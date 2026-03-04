import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.1.4:8000";

  static Future<Map<String, dynamic>> sendAudioWithLocation(
    String audioPath,
    String? location,  // Now nullable
  ) async {
    try {
      // Build URL with optional location parameter
      String url = '$baseUrl/voice-audio';
      if (location != null && location.isNotEmpty) {
        url += '?location=$location';
      }
      
      print('Sending audio to: $url');
      print('Audio file path: $audioPath');
      
      final file = File(audioPath);
      if (!await file.exists()) {
        throw Exception('Audio file does not exist');
      }
      
      print('File size: ${await file.length()} bytes');

      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(await http.MultipartFile.fromPath('file', audioPath));

      print('Sending request...');
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - backend not responding');
        },
      );

      print('Got response with status: ${streamedResponse.statusCode}');
      var response = await http.Response.fromStream(streamedResponse);

      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } on SocketException catch (e) {
      throw Exception('Cannot connect to server. Make sure backend is running at $baseUrl. Error: $e');
    } on http.ClientException catch (e) {
      throw Exception('Network error: $e');
    } catch (e) {
      throw Exception('Error processing request: $e');
    }
  }

  static Future<Map<String, dynamic>> sendAudio(String audioPath) async {
    return sendAudioWithLocation(audioPath, null);  // Auto-classify
  }
}
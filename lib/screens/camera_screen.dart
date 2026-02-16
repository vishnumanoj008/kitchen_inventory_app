import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test ML")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final picker = ImagePicker();
            await picker.pickImage(source: ImageSource.gallery);
          },
          child: const Text("Test Button"),
        ),
      ),
    );
  }
}

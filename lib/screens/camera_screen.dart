import 'dart:async';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool isScanning = false;
  bool showResults = false;
  String inputMode = "camera";

  List<Map<String,dynamic>> detectedItems = [];

  void handleScan() {
    setState(()=>isScanning=true);

    Future.delayed(const Duration(seconds:2),(){
      setState(() {
        isScanning=false;
        showResults=true;
        detectedItems=[
          {"name":"Tomatoes","confidence":98,"qty":4,"loc":"fridge"},
          {"name":"Onions","confidence":95,"qty":2,"loc":"pantry"},
        ];
      });
    });
  }

  @override
  Widget build(BuildContext context) {

    if(showResults){
      return Scaffold(
        appBar: AppBar(title: const Text("Results")),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              Card(
                color: Colors.green.shade50,
                child: ListTile(
                  leading: const Icon(Icons.check_circle,color:Colors.green),
                  title: const Text("Detection Complete"),
                  subtitle: Text("${detectedItems.length} items found"),
                ),
              ),

              const SizedBox(height:10),

              Expanded(
                child: ListView.builder(
                  itemCount: detectedItems.length,
                  itemBuilder:(_,i){
                    final item = detectedItems[i];
                    return Card(
                      child: ListTile(
                        title: Text(item["name"]),
                        subtitle: Text(
                          "Qty: ${item["qty"]} • ${item["confidence"]}% match"
                        ),
                      ),
                    );
                  },
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: (){
                        setState(()=>showResults=false);
                      },
                      child: const Text("Scan Again"),
                    ),
                  ),
                  const SizedBox(width:10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (){
                        setState(()=>showResults=false);
                      },
                      child: const Text("Add to Inventory"),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Scan Items")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Card(
              color: Colors.purple,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "AI-Powered Detection\nUse camera or voice input",
                  style: TextStyle(color:Colors.white),
                ),
              ),
            ),

            const SizedBox(height:10),

            // Mode toggle
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: ()=>setState(()=>inputMode="camera"),
                    child: const Text("Camera"),
                  ),
                ),
                const SizedBox(width:10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: ()=>setState(()=>inputMode="voice"),
                    child: const Text("Voice"),
                  ),
                ),
              ],
            ),

            const SizedBox(height:10),

            // Fake camera area
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.black87,
                child: Center(
                  child: isScanning
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:[
                            Icon(Icons.document_scanner,
                                color:Colors.green,size:60),
                            SizedBox(height:10),
                            Text("Scanning...",
                                style:TextStyle(color:Colors.white))
                          ],
                        )
                      : Text(
                          inputMode=="camera"
                            ? "Camera Preview"
                            : "Listening...",
                          style: const TextStyle(color:Colors.white),
                        ),
                ),
              ),
            ),

            const SizedBox(height:10),

            ElevatedButton(
              onPressed: isScanning?null:handleScan,
              child: Text(isScanning?"Scanning...":"Start Scan"),
            ),
          ],
        ),
      ),
    );
  }
}

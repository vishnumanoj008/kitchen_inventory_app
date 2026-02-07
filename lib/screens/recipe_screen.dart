import 'package:flutter/material.dart';

class RecipeScreen extends StatelessWidget {
  const RecipeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final recipes = [
      {"name":"Tomato Pasta","time":"25 min"},
      {"name":"Chicken Stir Fry","time":"30 min"},
      {"name":"Greek Salad","time":"15 min"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Recipes")),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          Card(
            color: Colors.green,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "AI Recipe Generator",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            decoration: InputDecoration(
              hintText: "Search recipes...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          ...recipes.map((r) => Card(
                child: ListTile(
                  title: Text(r["name"]!),
                  subtitle: Text(r["time"]!),
                ),
              )),
        ],
      ),
    );
  }
}

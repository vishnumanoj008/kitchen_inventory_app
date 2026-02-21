import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  late Future<List<dynamic>> mealsFuture;

  @override
  void initState() {
    super.initState();
    mealsFuture = fetchMeals("egg");
  }

  Future<List<dynamic>> fetchMeals(String ingredient) async {
    final url = Uri.parse(
      "https://www.themealdb.com/api/json/v1/1/filter.php?i=$ingredient",
    );

    print("Calling URL: $url");

    final response = await http.get(url);

    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    final data = json.decode(response.body);

    if (data["meals"] == null) {
      print("Meals is NULL");
      return [];
    }

    print("Meals count: ${data["meals"].length}");
    return data["meals"];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MealDB Recipes")),
      body: FutureBuilder<List<dynamic>>(
        future: mealsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No recipes found"));
          }

          final meals = snapshot.data!;

          return ListView.builder(
            itemCount: meals.length,
            itemBuilder: (_, i) {
              final meal = meals[i];
              return Card(
                child: ListTile(
                  leading: Image.network(
                    meal["strMealThumb"],
                    width: 60,
                    fit: BoxFit.cover,
                  ),
                  title: Text(meal["strMeal"]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
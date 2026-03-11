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

  TextEditingController searchController = TextEditingController();

  /// Example pantry items (later connect this with inventory)
  List pantryItems = ["egg", "tomato", "onion"];

  @override
  void initState() {
    super.initState();
    mealsFuture = fetchMeals("egg");
  }

  /// Fetch recipes by ingredient
  Future<List<dynamic>> fetchMeals(String ingredient) async {

    final url = Uri.parse(
      "https://www.themealdb.com/api/json/v1/1/filter.php?i=$ingredient",
    );

    final response = await http.get(url);
    final data = json.decode(response.body);

    if (data["meals"] == null) {
      return [];
    }

    return data["meals"];
  }

  /// Fetch Indian recipes
  Future<List<dynamic>> fetchIndianMeals() async {

    final url = Uri.parse(
      "https://www.themealdb.com/api/json/v1/1/filter.php?a=Indian",
    );

    final response = await http.get(url);
    final data = json.decode(response.body);

    if (data["meals"] == null) {
      return [];
    }

    return data["meals"];
  }

  /// Fetch pantry-based recipes
  Future<List<dynamic>> fetchPantryRecipes() async {

    List<dynamic> combinedMeals = [];

    for (String item in pantryItems) {

      final meals = await fetchMeals(item);
      combinedMeals.addAll(meals);

    }

    /// Remove duplicates
    final uniqueMeals = {for (var meal in combinedMeals) meal["idMeal"]: meal}
        .values
        .toList();

    return uniqueMeals;
  }

  void searchRecipe() {

    String ingredient = searchController.text.trim();

    if (ingredient.isEmpty) return;

    setState(() {
      mealsFuture = fetchMeals(ingredient);
    });
  }

  void loadIndianRecipes() {

    setState(() {
      mealsFuture = fetchIndianMeals();
    });
  }

  void loadPantryRecipes() {

    setState(() {
      mealsFuture = fetchPantryRecipes();
    });
  }

  /// Show recipe details popup
  Future<void> showRecipeDetails(String id) async {

    final url = Uri.parse(
      "https://www.themealdb.com/api/json/v1/1/lookup.php?i=$id",
    );

    final response = await http.get(url);
    final data = json.decode(response.body);

    final recipe = data["meals"][0];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(recipe["strMeal"]),
        content: SingleChildScrollView(
          child: Column(
            children: [

              Image.network(recipe["strMealThumb"]),

              const SizedBox(height: 10),

              Text(
                recipe["strInstructions"] ?? "No instructions available",
              ),

              const SizedBox(height: 10),

              Text(
                "YouTube: ${recipe["strYoutube"] ?? "No video available"}",
                style: const TextStyle(color: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recipe Suggestions"),
      ),

      body: Column(
        children: [

          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: "Search ingredient (e.g. tomato)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                ElevatedButton(
                  onPressed: searchRecipe,
                  child: const Icon(Icons.search),
                )
              ],
            ),
          ),

          /// BUTTONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [

                ElevatedButton(
                  onPressed: loadPantryRecipes,
                  child: const Text("Pantry Recipes"),
                ),

                const SizedBox(width: 10),

                ElevatedButton(
                  onPressed: loadIndianRecipes,
                  child: const Text("Indian Recipes"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// RECIPES LIST
          Expanded(
            child: FutureBuilder<List<dynamic>>(
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
                      margin: const EdgeInsets.all(8),

                      child: ListTile(

                        leading: Image.network(
                          meal["strMealThumb"],
                          width: 60,
                          fit: BoxFit.cover,
                        ),

                        title: Text(meal["strMeal"]),

                        trailing: const Icon(Icons.restaurant_menu),

                        onTap: () {
                          showRecipeDetails(meal["idMeal"]);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
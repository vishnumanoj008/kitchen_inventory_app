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
<<<<<<< HEAD
                  title: Text(meal["strMeal"]),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to recipe detail screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailScreen(
                          mealId: meal["idMeal"],
                          mealName: meal["strMeal"],
                        ),
                      ),
                    );
                  },
=======
>>>>>>> 62dd6df (Updated recipe screen)
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

// New Recipe Detail Screen
class RecipeDetailScreen extends StatefulWidget {
  final String mealId;
  final String mealName;

  const RecipeDetailScreen({
    super.key,
    required this.mealId,
    required this.mealName,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Future<Map<String, dynamic>> mealDetailFuture;

  @override
  void initState() {
    super.initState();
    mealDetailFuture = fetchMealDetail(widget.mealId);
  }

  Future<Map<String, dynamic>> fetchMealDetail(String mealId) async {
    final url = Uri.parse(
      "https://www.themealdb.com/api/json/v1/1/lookup.php?i=$mealId",
    );

    print("Fetching meal details from: $url");

    final response = await http.get(url);

    print("Detail Status Code: ${response.statusCode}");

    if (response.statusCode != 200) {
      throw Exception("Failed to load meal details");
    }

    final data = json.decode(response.body);

    if (data["meals"] == null || data["meals"].isEmpty) {
      throw Exception("Meal not found");
    }

    return data["meals"][0];
  }

  List<String> getIngredients(Map<String, dynamic> meal) {
    List<String> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      final ingredient = meal["strIngredient$i"];
      final measure = meal["strMeasure$i"];
      
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients.add("${measure ?? ''} $ingredient".trim());
      }
    }
    return ingredients;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mealName),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: mealDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("No recipe details found"));
          }

          final meal = snapshot.data!;
          final ingredients = getIngredients(meal);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipe Image
                if (meal["strMealThumb"] != null)
                  Image.network(
                    meal["strMealThumb"],
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recipe Name
                      Text(
                        meal["strMeal"] ?? widget.mealName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Category and Area
                      Row(
                        children: [
                          if (meal["strCategory"] != null) ...[
                            Chip(
                              label: Text(meal["strCategory"]),
                              backgroundColor: Colors.blue.shade100,
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (meal["strArea"] != null)
                            Chip(
                              label: Text(meal["strArea"]),
                              backgroundColor: Colors.green.shade100,
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Ingredients Section
                      const Text(
                        "Ingredients",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: ingredients
                                .map((ingredient) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle,
                                              size: 18,
                                              color: Colors.green),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              ingredient,
                                              style: const TextStyle(
                                                  fontSize: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Instructions Section
                      const Text(
                        "Preparation Instructions",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            meal["strInstructions"] ?? "No instructions available",
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // YouTube Link (if available)
                      if (meal["strYoutube"] != null &&
                          meal["strYoutube"].toString().isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () {
                            // You can implement URL launcher here
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Video: ${meal["strYoutube"]}"),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text("Watch Video Tutorial"),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
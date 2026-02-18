import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final Function(String)? onNavigateToInventory;
  final VoidCallback? onNavigateToCamera;
  final VoidCallback? onNavigateToRecipe;

  const DashboardScreen({
    super.key,
    this.onNavigateToInventory,
    this.onNavigateToCamera,
    this.onNavigateToRecipe,
  });

  @override
  Widget build(BuildContext context) {
    final quickStats = [
      {"label": "Fridge Items", "value": "24", "color": Colors.blue},
      {"label": "Pantry Items", "value": "38", "color": Colors.green},
    ];

    final expiringItems = [
      {"name": "Milk", "location": "Fridge", "days": 2},
      {"name": "Spinach", "location": "Fridge", "days": 1},
      {"name": "Yogurt", "location": "Fridge", "days": 3},
    ];

    final recipes = [
      {"name": "Spaghetti Carbonara", "time": "25 min", "difficulty": "Easy"},
      {"name": "Chicken Stir Fry", "time": "30 min", "difficulty": "Medium"},
      {"name": "Caesar Salad", "time": "15 min", "difficulty": "Easy"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // AI Suggestion Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "AI Recipe Suggestion",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Try making Creamy Tomato Pasta tonight!",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      onNavigateToRecipe?.call();
                    },
                    child: const Text("View Recipe"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Stats Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quickStats.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.8,
              ),
              itemBuilder: (_, i) {
                final stat = quickStats[i];
                return GestureDetector(
                  onTap: () {
                    if (stat["label"] == "Fridge Items") {
                      onNavigateToInventory?.call("fridge");
                    } else if (stat["label"] == "Pantry Items") {
                      onNavigateToInventory?.call("pantry");
                    }
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                (stat["color"] as Color).withOpacity(0.2),
                            child: Text(stat["value"].toString()),
                          ),
                          const SizedBox(height: 6),
                          Text(stat["label"].toString()),
                        ],
                      ),
                    ),
                  ),
                );
              }
            ),

            const SizedBox(height: 20),

            // Expiring Items Label
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Quick Expiry Reminder",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Expiring Items
            Card(
              child: Column(
                children: expiringItems.map((item) {
                  return ListTile(
                    title: Text(item["name"].toString()),
                    subtitle: Text(item["location"].toString()),
                    trailing: Text("${item["days"]}d left"),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Recipes Label
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(Icons.restaurant, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Quick Recipes",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Recipes
            Card(
              child: Column(
                children: recipes.map((r) {
                  return ListTile(
                    title: Text(r["name"].toString()),
                    subtitle: Text("${r["time"]} • ${r["difficulty"]}"),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onNavigateToCamera?.call();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                    child: const Text("Scan Items"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white),
                    child: const Text("Add to List"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

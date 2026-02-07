import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quickStats = [
      {"label": "Fridge Items", "value": "24", "color": Colors.blue},
      {"label": "Pantry Items", "value": "38", "color": Colors.green},
      {"label": "Expiring Soon", "value": "3", "color": Colors.orange},
      {"label": "Shopping List", "value": "12", "color": Colors.purple},
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
                    onPressed: () {},
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
                return Card(
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
                );
              },
            ),

            const SizedBox(height: 20),

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
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    child: const Text("Scan Items"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple),
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

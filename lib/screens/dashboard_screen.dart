import 'package:flutter/material.dart';
import '../models/item.dart';
import '../data/database_helper.dart';

class DashboardScreen extends StatefulWidget {
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
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Item> expiringItems = [];
  int fridgeCount = 0;
  int pantryCount = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final fridgeItems = await DatabaseHelper.instance.getItemsByLocation("fridge");
    final pantryItems = await DatabaseHelper.instance.getItemsByLocation("pantry");

    final now = DateTime.now();
    final limit = now.add(const Duration(days: 7));

    final expiring = [...fridgeItems, ...pantryItems]
        .where((item) =>
            item.expiry != null &&
            item.expiry!.isAfter(now) &&
            item.expiry!.isBefore(limit))
        .toList()
      ..sort((a, b) => a.expiry!.compareTo(b.expiry!)); // lowest days left first

    setState(() {
      fridgeCount = fridgeItems.length;
      pantryCount = pantryItems.length;
      expiringItems = expiring.take(3).toList(); // max 3 items
    });
  }

  @override
  Widget build(BuildContext context) {
    final quickStats = [
      {"label": "Fridge Items", "value": fridgeCount.toString(), "color": Colors.blue},
      {"label": "Pantry Items", "value": pantryCount.toString(), "color": Colors.green},
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
                      widget.onNavigateToRecipe?.call();
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
                      widget.onNavigateToInventory?.call("fridge");
                    } else if (stat["label"] == "Pantry Items") {
                      widget.onNavigateToInventory?.call("pantry");
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

            // Expiring Items - NOW FROM DATABASE
            Card(
              child: expiringItems.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text("No items expiring soon!", style: TextStyle(color: Colors.grey.shade600)),
                    )
                  : Column(
                      children: expiringItems.map((item) {
                        final daysLeft = item.expiry!.difference(DateTime.now()).inDays;
                        return ListTile(
                          title: Text(item.name),
                          subtitle: Text(item.location ?? ""),
                          trailing: Text("${daysLeft}d left"),
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
            // REMOVED:
            // Row(
            //   children: [
            //     Expanded(
            //       child: ElevatedButton(
            //         onPressed: () {
            //           widget.onNavigateToCamera?.call();
            //         },
            //         style: ElevatedButton.styleFrom(
            //             backgroundColor: Colors.green,
            //             foregroundColor: Colors.white),
            //         child: const Text("Scan Items"),
            //       ),
            //     ),
            //     const SizedBox(width: 12),
            //     Expanded(
            //       child: ElevatedButton(
            //         onPressed: () {},
            //         style: ElevatedButton.styleFrom(
            //             backgroundColor: Colors.purple,
            //             foregroundColor: Colors.white),
            //         child: const Text("Add to List"),
            //       ),
            //     ),
            //   ],
            // ),

          ],
        ),
      ),
    );
  }
}

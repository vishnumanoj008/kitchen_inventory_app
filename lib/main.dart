import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/grocery_screen.dart';
import 'screens/recipe_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int index = 0;

  final pages = [
    const DashboardScreen(),
    const RecipeScreen(),
    const CameraScreen(),
    const InventoryScreen(),
    const GroceryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: pages[index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => setState(() => index = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.orange,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book),
              label: "Recipes",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt),
              label: "Scan",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory),
              label: "Inventory",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: "Grocery",
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/item.dart';
import '../data/database_helper.dart';

class InventoryScreen extends StatefulWidget {
  final String initialLocation;
  final VoidCallback? onNavigateToCamera;

  const InventoryScreen({
    super.key,
    this.initialLocation = "fridge",
    this.onNavigateToCamera,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late String activeLocation;
  List<Item> items = [];

  @override
  void initState() {
    super.initState();
    activeLocation = widget.initialLocation;
    loadItems();
  }

  Future<void> loadItems() async {
    final loaded = await DatabaseHelper.instance.getItemsByLocation(activeLocation);
    setState(() {
      items = loaded;
    });
  }

  Color statusColor(String s){
    if(s=="urgent") return Colors.red;
    if(s=="warning") return Colors.orange;
    return Colors.green;
  }

  void showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        onNavigateToCamera: widget.onNavigateToCamera,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // items are loaded from database
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Info
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blue),
              title: const Text("Check inventory to avoid waste"),
            ),
            const SizedBox(height: 16),

            // Search field
            TextField(
              decoration: InputDecoration(
                hintText: "Search ${activeLocation == 'fridge' ? 'fridge' : 'pantry'}...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Grouped Tab Container
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Tab buttons at top
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => activeLocation = "fridge");
                                loadItems();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: activeLocation == "fridge"
                                      ? Colors.blue.shade500
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Fridge",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: activeLocation == "fridge"
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => activeLocation = "pantry");
                                loadItems();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: activeLocation == "pantry"
                                      ? Colors.green.shade500
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Pantry",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: activeLocation == "pantry"
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Divider
                    Divider(
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                    // Item list
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final item = items[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              title: Text(item.name),
                              subtitle: Text(
                                (item.category ?? "") + (item.expiry != null ? " • ${item.expiry!.toLocal().toString().split(' ')[0]}" : ""),
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("Qty: ${item.quantity}"),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Delete Item',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Item'),
                                          content: Text('Are you sure you want to delete "${item.name}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await DatabaseHelper.instance.deleteItem(item.id ?? 0);
                                        loadItems();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Deleted item: ${item.name}')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class AddItemDialog extends StatelessWidget {
  final VoidCallback? onNavigateToCamera;

  const AddItemDialog({super.key, this.onNavigateToCamera});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Item"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              onNavigateToCamera?.call();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.camera_alt, size: 32, color: Colors.blue),
                  const SizedBox(height: 8),
                  const Text("Scan", style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              onNavigateToCamera?.call();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.mic, size: 32, color: Colors.green),
                  const SizedBox(height: 8),
                  const Text("Voice", style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => const ManualEntryDialog(),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.edit, size: 32, color: Colors.orange),
                  const SizedBox(height: 8),
                  const Text("Type", style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}

class ManualEntryDialog extends StatefulWidget {
  const ManualEntryDialog({super.key});

  @override
  State<ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<ManualEntryDialog> {
  late TextEditingController nameController;
  late TextEditingController expiryNumberController;
  String selectedLocation = "Fridge";
  String selectedTimeUnit = "Days";

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    expiryNumberController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    expiryNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Item Manually"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Item Name",
                hintText: "e.g., Milk",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedLocation,
              decoration: InputDecoration(
                labelText: "Location",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(value: "Fridge", child: Text("Fridge")),
                DropdownMenuItem(value: "Pantry", child: Text("Pantry")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedLocation = value ?? "Fridge";
                });
              },
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Expiry", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: expiryNumberController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "e.g., 2",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: selectedTimeUnit,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: "Days", child: Text("Days")),
                          DropdownMenuItem(value: "Months", child: Text("Months")),
                          DropdownMenuItem(value: "Years", child: Text("Years")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedTimeUnit = value ?? "Days";
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Add item to inventory
            Navigator.pop(context);
          },
          child: const Text("Add Item"),
        ),
      ],
    );
  }
}
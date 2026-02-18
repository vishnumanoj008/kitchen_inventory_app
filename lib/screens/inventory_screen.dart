import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    activeLocation = widget.initialLocation;
  }

  final fridgeItems = [
    {"name":"Milk","qty":"1L","expiry":"2 days","cat":"Dairy","status":"warning"},
    {"name":"Eggs","qty":"12","expiry":"1 week","cat":"Dairy","status":"good"},
    {"name":"Spinach","qty":"200g","expiry":"1 day","cat":"Vegetables","status":"urgent"},
  ];

  final pantryItems = [
    {"name":"Pasta","qty":"2 packs","expiry":"6 months","cat":"Grains","status":"good"},
    {"name":"Rice","qty":"5kg","expiry":"1 year","cat":"Grains","status":"good"},
  ];

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
    final items = activeLocation=="fridge" ? fridgeItems : pantryItems;

    return Scaffold(
      appBar: AppBar(title: const Text("Inventory")),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: showAddItemDialog,
        child: const Icon(Icons.add),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Alert
            Card(
              color: Colors.orange.shade50,
              child: const ListTile(
                leading: Icon(Icons.warning, color: Colors.orange),
                title: Text("3 Items Expiring Soon"),
                subtitle: Text("Check inventory to avoid waste"),
              ),
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
                              title: Text(item["name"].toString()),
                              subtitle: Text(
                                "${item["qty"]} • ${item["cat"]}",
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        statusColor(item["status"].toString()),
                                  ),
                                ),
                                child: Text(
                                  item["expiry"].toString(),
                                  style: TextStyle(
                                    color: statusColor(
                                      item["status"].toString(),
                                    ),
                                  ),
                                ),
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
import 'package:flutter/material.dart';

class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {


  List<Map<String, dynamic>> items = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  final List<String> units = ["", "g", "kg", "mg", "ml", "L"];
  final List<String> suggestions = [
    "Onions",
    "Milk",
    "Eggs",
    "Rice",
    "Tomatoes"
  ];

  // ================= CORE =================

  void toggle(int id) {
    setState(() {
      final item = items.firstWhere((e) => e["id"] == id);
      item["checked"] = !item["checked"];
    });
  }

  void delete(int id) {
    final index = items.indexWhere((e) => e["id"] == id);
    if (index != -1) {
      final removedItem = items[index];
      setState(() {
        items.removeAt(index);
        _listKey.currentState?.removeItem(
          index,
          (context, animation) => SizeTransition(
            sizeFactor: animation,
            child: Card(
              child: ListTile(
                title: Text(removedItem["name"]),
              ),
            ),
          ),
        );
      });
    }
  }

  void deleteChecked() {
    setState(() {
      items.removeWhere((e) => e["checked"]);
    });
  }

  void selectAllToggle() {
    bool allSelected =
        items.isNotEmpty && items.every((e) => e["checked"]);
    setState(() {
      for (var item in items) {
        item["checked"] = !allSelected;
      }
    });
  }

  // ================= ADD =================

  void showAddDialog() {
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: "1");

    int selectedNumber = 1;
    String selectedUnit = "";
    bool showWheel = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text("Add Item"),
              content: SizedBox(
                height: showWheel ? 380 : 260,
                child: Column(
                  children: [

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                          labelText: "Item Name"),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Number of"),
                        ElevatedButton(
                          onPressed: () {
                            setModalState(() {
                              showWheel = !showWheel;
                            });
                          },
                          child: Text("$selectedNumber"),
                        ),
                      ],
                    ),

                    if (showWheel)
                      SizedBox(
                        height: 100,
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 35,
                          physics:
                              const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setModalState(() {
                              selectedNumber = index + 1;
                            });
                          },
                          childDelegate:
                              ListWheelChildBuilderDelegate(
                            builder: (context, index) =>
                                Center(
                                    child:
                                        Text("${index + 1}")),
                            childCount: 50,
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyController,
                            keyboardType:
                                TextInputType.number,
                            decoration:
                                const InputDecoration(
                                    labelText: "Quantity"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        DropdownButton<String>(
                          value: selectedUnit,
                          items: units
                              .map((u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(
                                        u.isEmpty
                                            ? "none"
                                            : u),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setModalState(() {
                              selectedUnit = value!;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isEmpty)
                          return;

                        setState(() {
                          items.add({
                            "id": DateTime.now()
                                .millisecondsSinceEpoch,
                            "name": nameController.text,
                            "number": selectedNumber,
                            "quantity": int.tryParse(
                                    qtyController.text) ??
                                1,
                            "unit": selectedUnit,
                            "checked": false
                          });
                        });

                        Navigator.pop(context);
                      },
                      child: const Text("Add"),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= EDIT =================

  void editItem(Map<String, dynamic> item) {
    final nameController =
        TextEditingController(text: item["name"]);
    final qtyController =
        TextEditingController(text: item["quantity"].toString());

    int selectedNumber = item["number"];
    String selectedUnit = item["unit"];
    bool showWheel = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text("Edit Item"),
              content: SizedBox(
                height: showWheel ? 380 : 260,
                child: Column(
                  children: [

                    TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(
                              labelText: "Item Name"),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Number of"),
                        ElevatedButton(
                          onPressed: () {
                            setModalState(() {
                              showWheel = !showWheel;
                            });
                          },
                          child: Text("$selectedNumber"),
                        ),
                      ],
                    ),

                    if (showWheel)
                      SizedBox(
                        height: 100,
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 35,
                          physics:
                              const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setModalState(() {
                              selectedNumber = index + 1;
                            });
                          },
                          childDelegate:
                              ListWheelChildBuilderDelegate(
                            builder: (context, index) =>
                                Center(
                                    child:
                                        Text("${index + 1}")),
                            childCount: 50,
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyController,
                            keyboardType:
                                TextInputType.number,
                            decoration:
                                const InputDecoration(
                                    labelText: "Quantity"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        DropdownButton<String>(
                          value: selectedUnit,
                          items: units
                              .map((u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(
                                        u.isEmpty
                                            ? "none"
                                            : u),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setModalState(() {
                              selectedUnit = value!;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          item["name"] =
                              nameController.text;
                          item["number"] =
                              selectedNumber;
                          item["quantity"] =
                              int.tryParse(
                                      qtyController.text) ??
                                  1;
                          item["unit"] =
                              selectedUnit;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("Save"),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {


    int checked = items.where((e) => e["checked"]).length;
    bool allSelected =
        items.isNotEmpty && items.every((e) => e["checked"]);

    return Scaffold(
      appBar: AppBar(title: const Text("Grocery List")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Card(
              color: Colors.purple,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "$checked of ${items.length} collected",
                      style:
                          const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: items.isEmpty
                          ? 0
                          : checked / items.length,
                      backgroundColor: Colors.white30,
                      color: Colors.white,
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: selectAllToggle,
                  child: Text(
                      allSelected ? "Deselect All" : "Select All"),
                ),
                if (checked > 0)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: deleteChecked,
                  )
              ],
            ),

            const SizedBox(height: 10),

            const SizedBox(height: 10),
            if (suggestions.isNotEmpty)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Smart Suggestions",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: suggestions.map((s) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                if (!items.any((item) => item["name"].toString().toLowerCase() == s.toLowerCase())) {
                                  final newItem = {
                                    "id": DateTime.now().millisecondsSinceEpoch,
                                    "name": s,
                                    "number": 1,
                                    "quantity": 1,
                                    "unit": "",
                                    "checked": false
                                  };
                                  setState(() {
                                    items.add(newItem);
                                    _listKey.currentState?.insertItem(items.length - 1);
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  s,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 10),

            Expanded(
              child: AnimatedList(
                key: _listKey,
                initialItemCount: items.length,
                itemBuilder: (context, index, animation) {
                  // Sort items: unchecked first, checked last
                  final sortedItems = [...items]
                    ..sort((a, b) => (a["checked"] ? 1 : 0) - (b["checked"] ? 1 : 0));
                  final item = sortedItems[index];
                  String subtitle = item["unit"].isEmpty
                      ? "${item["number"]}"
                      : "${item["number"]} x ${item["quantity"]} ${item["unit"]}";
                  return SizeTransition(
                    sizeFactor: animation,
                    child: Card(
                      child: ListTile(
                        leading: Checkbox(
                          value: item["checked"],
                          onChanged: (_) => toggle(item["id"]),
                        ),
                        title: Text(item["name"]),
                        subtitle: Text(subtitle),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => editItem(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => delete(item["id"]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                onPressed: showAddDialog,
                icon: const Icon(Icons.add),
                label: const Text("Add Item"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
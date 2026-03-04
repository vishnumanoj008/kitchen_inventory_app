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
  final List<String> suggestions = ["Onions", "Milk", "Eggs", "Rice", "Tomatoes"];

  // ================= SORT / HELPERS =================

  int _compareItems(Map<String, dynamic> a, Map<String, dynamic> b) {
    final aChecked = (a["checked"] as bool?) ?? false;
    final bChecked = (b["checked"] as bool?) ?? false;

    // unchecked first
    if (aChecked != bChecked) return aChecked ? 1 : -1;

    // then by name
    final aName = (a["name"] ?? "").toString().toLowerCase();
    final bName = (b["name"] ?? "").toString().toLowerCase();
    final byName = aName.compareTo(bName);
    if (byName != 0) return byName;

    // stable tie-break
    final aId = (a["id"] as int?) ?? 0;
    final bId = (b["id"] as int?) ?? 0;
    return aId.compareTo(bId);
  }

  int _findInsertIndex(Map<String, dynamic> item) {
    for (int i = 0; i < items.length; i++) {
      if (_compareItems(item, items[i]) < 0) return i;
    }
    return items.length;
  }

  void _insertSorted(Map<String, dynamic> item) {
    final index = _findInsertIndex(item);
    items.insert(index, item);
    _listKey.currentState?.insertItem(index, duration: const Duration(milliseconds: 250));
  }

  Map<String, dynamic>? _removeAt(int index) {
    if (index < 0 || index >= items.length) return null;
    final removed = Map<String, dynamic>.from(items.removeAt(index));
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: _buildTile(removed),
      ),
      duration: const Duration(milliseconds: 250),
    );
    return removed;
  }

  bool _nameExists(String name) {
    final lower = name.trim().toLowerCase();
    return items.any((e) => e["name"].toString().trim().toLowerCase() == lower);
  }

  Widget _buildTile(Map<String, dynamic> item) {
    final subtitle = (item["unit"] as String).isEmpty
        ? "${item["number"]}"
        : "${item["number"]} x ${item["quantity"]} ${item["unit"]}";

    return Card(
      child: ListTile(
        leading: Checkbox(
          value: item["checked"] as bool? ?? false,
          onChanged: (_) => toggle(item["id"] as int),
        ),
        title: Text(item["name"].toString()),
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
              onPressed: () => delete(item["id"] as int),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CORE =================

  void toggle(int id) {
    setState(() {
      final oldIndex = items.indexWhere((e) => e["id"] == id);
      if (oldIndex == -1) return;

      final current = Map<String, dynamic>.from(items[oldIndex]);
      _removeAt(oldIndex);

      current["checked"] = !(current["checked"] as bool? ?? false);
      _insertSorted(current);
    });
  }

  void delete(int id) {
    final index = items.indexWhere((e) => e["id"] == id);
    if (index == -1) return;

    setState(() {
      _removeAt(index);
    });
  }

  void deleteChecked() {
    setState(() {
      final indices = <int>[];
      for (int i = 0; i < items.length; i++) {
        if ((items[i]["checked"] as bool? ?? false)) indices.add(i);
      }
      indices.sort((a, b) => b.compareTo(a)); // remove from end
      for (final i in indices) {
        _removeAt(i);
      }
    });
  }

  void selectAllToggle() {
    final allSelected = items.isNotEmpty && items.every((e) => e["checked"] == true);
    setState(() {
      for (final item in items) {
        item["checked"] = !allSelected;
      }
      items.sort(_compareItems);
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
                      decoration: const InputDecoration(labelText: "Item Name"),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Number of"),
                        ElevatedButton(
                          onPressed: () {
                            setModalState(() => showWheel = !showWheel);
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
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setModalState(() => selectedNumber = index + 1);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) => Center(child: Text("${index + 1}")),
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
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Quantity"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        DropdownButton<String>(
                          value: selectedUnit,
                          items: units
                              .map((u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u.isEmpty ? "none" : u),
                                  ))
                              .toList(),
                          onChanged: (value) => setModalState(() => selectedUnit = value!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;

                        setState(() {
                          if (_nameExists(name)) return;
                          final newItem = {
                            "id": DateTime.now().millisecondsSinceEpoch,
                            "name": name,
                            "number": selectedNumber,
                            "quantity": int.tryParse(qtyController.text) ?? 1,
                            "unit": selectedUnit,
                            "checked": false,
                          };
                          _insertSorted(newItem);
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
    final nameController = TextEditingController(text: item["name"]);
    final qtyController = TextEditingController(text: item["quantity"].toString());

    int selectedNumber = item["number"] as int;
    String selectedUnit = item["unit"] as String;
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
                      decoration: const InputDecoration(labelText: "Item Name"),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Number of"),
                        ElevatedButton(
                          onPressed: () {
                            setModalState(() => showWheel = !showWheel);
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
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setModalState(() => selectedNumber = index + 1);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) => Center(child: Text("${index + 1}")),
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
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Quantity"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        DropdownButton<String>(
                          value: selectedUnit,
                          items: units
                              .map((u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u.isEmpty ? "none" : u),
                                  ))
                              .toList(),
                          onChanged: (value) => setModalState(() => selectedUnit = value!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {
                        final id = item["id"] as int;
                        final oldIndex = items.indexWhere((e) => e["id"] == id);
                        if (oldIndex == -1) {
                          Navigator.pop(context);
                          return;
                        }

                        setState(() {
                          final updated = Map<String, dynamic>.from(items[oldIndex]);
                          _removeAt(oldIndex);

                          updated["name"] = nameController.text.trim();
                          updated["number"] = selectedNumber;
                          updated["quantity"] = int.tryParse(qtyController.text) ?? 1;
                          updated["unit"] = selectedUnit;

                          _insertSorted(updated);
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
    final checked = items.where((e) => e["checked"] == true).length;
    final allSelected = items.isNotEmpty && items.every((e) => e["checked"] == true);

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
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: items.isEmpty ? 0 : checked / items.length,
                      backgroundColor: Colors.white30,
                      color: Colors.white,
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: selectAllToggle,
                  child: Text(allSelected ? "Deselect All" : "Select All"),
                ),
                if (checked > 0)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: deleteChecked,
                  )
              ],
            ),
            const SizedBox(height: 10),
            if (suggestions.isNotEmpty)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Smart Suggestions", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: suggestions.map((s) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_nameExists(s)) return;
                                    final newItem = {
                                      "id": DateTime.now().millisecondsSinceEpoch,
                                      "name": s,
                                      "number": 1,
                                      "quantity": 1,
                                      "unit": "",
                                      "checked": false
                                    };
                                    _insertSorted(newItem);
                                  });
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
                            );
                          }).toList(),
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
                  final item = items[index]; // no sorting here
                  return SizeTransition(
                    sizeFactor: animation,
                    child: _buildTile(item),
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
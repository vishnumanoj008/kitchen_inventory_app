import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
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
  bool selectionMode = false;
  Set<int> selectedItems = {};
  
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    activeLocation = widget.initialLocation;
    _initNotifications();
    loadItems();
  }

  Future<void> _initNotifications() async {
    // Request notification permission (Android 13+)
    final status = await Permission.notification.request();
    if (status.isDenied) {
      print('Notification permission denied');
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    final initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped: ${response.payload}');
      },
    );

    if (initialized == true) {
      print('Notifications initialized successfully');
    } else {
      print('Failed to initialize notifications');
    }

    // Create notification channel for Android 8.0+
    const androidChannel = AndroidNotificationChannel(
      'inventory_expiry_channel',
      'Inventory Expiry',
      description: 'Notifications for inventory item expiry',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  int _daysUntilExpiry(DateTime? expiry) {
    if (expiry == null) return -9999;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(expiry.year, expiry.month, expiry.day);
    return exp.difference(today).inDays;
  }

  Future<void> _notifyItemExpiry(Item item) async {
    final days = _daysUntilExpiry(item.expiry);

    String body;
    if (item.expiry == null) {
      body = 'No expiry date set.';
    } else if (days < 0) {
      body = 'This item expired ${-days} day${-days == 1 ? '' : 's'} ago.';
    } else if (days == 0) {
      body = 'This item expires today!';
    } else if (days == 1) {
      body = 'This item will expire in 1 day.';
    } else {
      body = 'This item will expire in $days days.';
    }

    const androidDetails = AndroidNotificationDetails(
      'inventory_expiry_channel',
      'Inventory Expiry',
      channelDescription: 'Notifications for inventory item expiry',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      showWhen: true,
    );

    try {
      await _notifications.show(
        item.id ?? item.name.hashCode,
        '${item.name} - Expiry Reminder',
        body,
        const NotificationDetails(android: androidDetails),
      );

      print('Notification sent for ${item.name}');

      // Show snackbar confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📱 Notification sent for ${item.name}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error sending notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> loadItems() async {
    final loaded = await DatabaseHelper.instance.getItemsByLocation(activeLocation);
    setState(() {
      items = loaded;
    });
  }

  String _formatExpiry(DateTime? expiry) {
    if (expiry == null) return "No expiry";

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(expiry.year, expiry.month, expiry.day);
    final daysLeft = exp.difference(today).inDays;

    if (daysLeft < 0) return "Expired";
    if (daysLeft == 0) return "Today";
    if (daysLeft == 1) return "1 day";
    return "$daysLeft days";
  }

  Color statusColor(String s){
    if(s=="urgent") return Colors.red;
    if(s=="warning") return Colors.orange;
    return Colors.green;
  }
  void showAddItemDialog() async {
      showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        onNavigateToCamera: widget.onNavigateToCamera,
        onItemAdded: loadItems,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddItemDialog,
        tooltip: "Add Item",
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blue),
              title: const Text("Check inventory to avoid waste"),
              subtitle: const Text("Double-tap items for expiry reminder", 
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            const SizedBox(height: 16),

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

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
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
                    Divider(
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final item = items[i];
                          return GestureDetector(
                            onDoubleTap: () => _notifyItemExpiry(item),
                            child: Card(
                              color: selectedItems.contains(item.id ?? i)
                                  ? Colors.blue.shade50
                                  : null,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => ManualEntryDialog(
                                      existingItem: item,
                                    ),
                                  ).then((_) => loadItems());
                                },
                                title: Text(item.name),
                                subtitle: Text(
                                  "${item.category ?? "General"} • Expires in: ${_formatExpiry(item.expiry)}",
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [

                                    Text("Qty: ${item.quantity}"),

                                    const SizedBox(width: 8),

                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      tooltip: 'Edit Item',
                                      onPressed: () async {
                                        final result = await showDialog(
                                          context: context,
                                          builder: (context) => ManualEntryDialog(
                                            existingItem: item,
                                          ),
                                        );

                                        if (result == true) {
                                          loadItems();
                                        }
                                      },
                                    ),

                                    const SizedBox(width: 4),

                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Delete Item',
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Delete Item'),
                                            content: Text(
                                                'Are you sure you want to delete "${item.name}"?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context, false),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(context, true),
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await DatabaseHelper.instance
                                              .deleteItem(item.id ?? 0);

                                          loadItems();

                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Deleted item: ${item.name}'),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
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
  final VoidCallback? onItemAdded;
  const AddItemDialog({super.key, this.onNavigateToCamera, this.onItemAdded});

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
              ).then((_) => onItemAdded?.call());
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
  final Item? existingItem;

  const ManualEntryDialog({
    super.key,
    this.existingItem,
  });

  @override
  State<ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<ManualEntryDialog> {
  late TextEditingController nameController;
  late TextEditingController expiryNumberController;

  String selectedLocation = "Fridge";
  String selectedTimeUnit = "Days";

  DateTime? selectedExpiryDate;
  TimeOfDay? selectedExpiryTime;

  bool useSpecificDate = false;

  DateTime _combine(DateTime d, TimeOfDay t) {
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _pickExpiryDateTime() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (d == null) return;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t == null) return;

    setState(() {
      selectedExpiryDate = d;
      selectedExpiryTime = t;
    });
  }

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController();
    expiryNumberController = TextEditingController();

    if (widget.existingItem != null) {
      nameController.text = widget.existingItem!.name;

      selectedLocation =
          widget.existingItem!.location == "pantry" ? "Pantry" : "Fridge";

      if (widget.existingItem!.expiry != null) {
        selectedExpiryDate = widget.existingItem!.expiry;
        selectedExpiryTime = TimeOfDay.fromDateTime(widget.existingItem!.expiry!);
        useSpecificDate = true;
      }
    }
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

            Row(
              children: [
                const Text("Expiry Mode"),
                const SizedBox(width: 10),
                DropdownButton<bool>(
                  value: useSpecificDate,
                  items: const [
                    DropdownMenuItem(value: false, child: Text("Duration")),
                    DropdownMenuItem(value: true, child: Text("Specific Date")),
                  ],
                  onChanged: (v) {
                    setState(() {
                      useSpecificDate = v ?? false;

                      if (useSpecificDate && selectedExpiryDate == null) {
                        selectedExpiryDate =
                            DateTime.now().add(const Duration(days: 1));
                      }

                      if (!useSpecificDate && selectedExpiryDate != null) {
                        final difference =
                            selectedExpiryDate!.difference(DateTime.now()).inDays;

                        if (difference > 0) {
                          expiryNumberController.text = difference.toString();
                          selectedTimeUnit = "Days";
                        }
                      }
                    });
                  },
                )
              ],
            ),

            const SizedBox(height: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "Expiry",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 8),

                useSpecificDate
                    ? ElevatedButton(
                        onPressed: _pickExpiryDateTime,
                        child: Text(
                          selectedExpiryDate == null
                              ? "Pick Expiry Date"
                              : "${selectedExpiryDate!.toLocal()} ${selectedExpiryTime?.format(context) ?? ""}",
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: expiryNumberController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: selectedTimeUnit,
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
          onPressed: () async {
            final name = nameController.text.trim();

            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter item name')),
              );
              return;
            }

            DateTime? expiryDate;

            if (useSpecificDate) {
              if (selectedExpiryDate != null) {
                if (selectedExpiryTime != null) {
                  expiryDate = _combine(selectedExpiryDate!, selectedExpiryTime!);
                } else {
                  expiryDate = selectedExpiryDate!;
                }
              }
            } else {
              final expiryNum = int.tryParse(expiryNumberController.text);

              if (expiryNum != null && expiryNum > 0) {
                expiryDate = DateTime.now();

                if (selectedTimeUnit == "Days") {
                  expiryDate = expiryDate.add(Duration(days: expiryNum));
                } else if (selectedTimeUnit == "Months") {
                  expiryDate = DateTime(
                    expiryDate.year,
                    expiryDate.month + expiryNum,
                    expiryDate.day,
                  );
                } else {
                  expiryDate = DateTime(
                    expiryDate.year + expiryNum,
                    expiryDate.month,
                    expiryDate.day,
                  );
                }
              }
            }

            if (widget.existingItem == null) {
              await DatabaseHelper.instance.insertItem(
                Item(
                  name: name,
                  location: selectedLocation.toLowerCase(),
                  expiry: expiryDate,
                  quantity: 1,
                  category: "General",
                ),
              );
            } else {
              await DatabaseHelper.instance.updateItem(
                Item(
                  id: widget.existingItem!.id,
                  name: name,
                  location: selectedLocation.toLowerCase(),
                  expiry: expiryDate,
                  quantity: 1,
                  category: "General",
                ),
              );
            }

            if (context.mounted) {
              Navigator.pop(context, true);

              final message =
                  widget.existingItem == null ? 'Added $name' : 'Updated $name';

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            }
          },

          child: Text(widget.existingItem == null ? "Add Item" : "Update Item"),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String activeLocation = "fridge";

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

  @override
  Widget build(BuildContext context) {
    final items = activeLocation=="fridge" ? fridgeItems : pantryItems;

    return Scaffold(
      appBar: AppBar(title: const Text("Inventory")),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {},
        child: const Icon(Icons.add),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // Quick stats
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.blue.shade50,
                    child: const ListTile(
                      title: Text("24"),
                      subtitle: Text("Fridge Items"),
                    ),
                  ),
                ),
                const SizedBox(width:10),
                Expanded(
                  child: Card(
                    color: Colors.green.shade50,
                    child: const ListTile(
                      title: Text("38"),
                      subtitle: Text("Pantry Items"),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height:10),

            // Alert
            Card(
              color: Colors.orange.shade50,
              child: const ListTile(
                leading: Icon(Icons.warning,color:Colors.orange),
                title: Text("3 Items Expiring Soon"),
                subtitle: Text("Check inventory to avoid waste"),
              ),
            ),

            const SizedBox(height:10),

            // Search
            TextField(
              decoration: InputDecoration(
                hintText: "Search inventory...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height:10),

            // Tabs
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: (){
                      setState(()=>activeLocation="fridge");
                    },
                    child: const Text("Fridge"),
                  ),
                ),
                const SizedBox(width:10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (){
                      setState(()=>activeLocation="pantry");
                    },
                    child: const Text("Pantry"),
                  ),
                ),
              ],
            ),

            const SizedBox(height:10),

            // Item list
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_,i){
                  final item = items[i];
                  return Card(
                    child: ListTile(
                      title: Text(item["name"].toString()),
                      subtitle: Text(
                        "${item["qty"]} • ${item["cat"]}"
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor(item["status"].toString())
                          )
                        ),
                        child: Text(
                          item["expiry"].toString(),
                          style: TextStyle(
                            color: statusColor(item["status"].toString())
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

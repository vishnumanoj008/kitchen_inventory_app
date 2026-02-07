import 'package:flutter/material.dart';

class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {

  List<Map<String,dynamic>> items = [
    {"id":1,"name":"Milk","cat":"Dairy","qty":"1L","checked":false},
    {"id":2,"name":"Bread","cat":"Bakery","qty":"1 loaf","checked":false},
    {"id":3,"name":"Chicken","cat":"Meat","qty":"500g","checked":true},
    {"id":4,"name":"Tomatoes","cat":"Produce","qty":"6","checked":false},
  ];

  final TextEditingController controller = TextEditingController();

  void addItem(){
    if(controller.text.isEmpty) return;
    setState(() {
      items.add({
        "id":DateTime.now().millisecondsSinceEpoch,
        "name":controller.text,
        "cat":"Other",
        "qty":"1",
        "checked":false
      });
      controller.clear();
    });
  }

  void toggle(int id){
    setState(() {
      final item = items.firstWhere((e)=>e["id"]==id);
      item["checked"]=!item["checked"];
    });
  }

  void delete(int id){
    setState(()=>items.removeWhere((e)=>e["id"]==id));
  }

  @override
  Widget build(BuildContext context){

    int checked = items.where((e)=>e["checked"]).length;
    double progress = items.isEmpty ? 0 : checked/items.length;

    Map<String,List<Map<String,dynamic>>> grouped={};
    for(var i in items){
      grouped.putIfAbsent(i["cat"], ()=>[]);
      grouped[i["cat"]]!.add(i);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Grocery List")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // Progress Card
            Card(
              color: Colors.purple,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children:[
                    Text(
                      "$checked of ${items.length} collected",
                      style: const TextStyle(color:Colors.white),
                    ),
                    const SizedBox(height:10),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white30,
                      color: Colors.white,
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height:10),

            // Add item row
            Row(
              children:[
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText:"Add item..."
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: addItem,
                )
              ],
            ),

            const SizedBox(height:10),

            // ✅ THIS IS THE FIX
            Expanded(
              child: ListView(
                children: grouped.entries.map((entry){
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical:8),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize:18,
                            fontWeight:FontWeight.bold
                          ),
                        ),
                      ),

                      ...entry.value.map((item){
                        return Card(
                          child: ListTile(
                            leading: Checkbox(
                              value: item["checked"],
                              onChanged:(_)=>toggle(item["id"]),
                            ),
                            title: Text(
                              item["name"],
                              style: TextStyle(
                                decoration: item["checked"]
                                  ? TextDecoration.lineThrough
                                  : null
                              ),
                            ),
                            subtitle: Text(item["qty"]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed:()=>delete(item["id"]),
                            ),
                          ),
                        );
                      })
                    ],
                  );
                }).toList(),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

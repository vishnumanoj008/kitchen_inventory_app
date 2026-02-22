class Item {
  int? id;
  String name;
  String location; // "fridge" or "pantry"
  DateTime? expiry;
  int quantity;
  String? category;

  Item({this.id, required this.name, required this.location, this.expiry, this.quantity = 1, this.category});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'expiry': expiry?.toIso8601String(),
      'quantity': quantity,
      'category': category,
    };
  }

  factory Item.fromMap(Map<String, dynamic> m) {
    return Item(
      id: m['id'] as int?,
      name: m['name'] as String,
      location: m['location'] as String,
      expiry: m['expiry'] != null ? DateTime.parse(m['expiry'] as String) : null,
      quantity: (m['quantity'] as int?) ?? 1,
      category: m['category'] as String?,
    );
  }
}

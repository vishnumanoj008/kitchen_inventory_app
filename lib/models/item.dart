class Item {
  final int? id;
  final String name;
  final String location;
  final int quantity;  // Add this field
  final DateTime? expiry;
  final String? category;

  Item({
    this.id,
    required this.name,
    required this.location,
    required this.quantity,  // Add this parameter
    this.expiry,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'quantity': quantity,  // Add this
      'expiry': expiry?.toIso8601String(), // keeps date + time
      'category': category,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      name: map['name'],
      location: map['location'],
      quantity: map['quantity'] ?? 1,  // Add this with default value
      expiry: map['expiry'] != null ? DateTime.parse(map['expiry']) : null,
      category: map['category'],
    );
  }
}

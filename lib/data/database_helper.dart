import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kitchen_inventory.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 2, // Incremented version for unique constraint
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        expiry TEXT,
        category TEXT,
        UNIQUE(name, location)
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop and recreate with unique constraint
      await db.execute('DROP TABLE IF EXISTS items');
      await _createDB(db, newVersion);
    }
  }

  Future<int> insertItem(Item item) async {
    final db = await database;

    try {
      // Check if item exists
      final existing = await db.query(
        'items',
        where: 'name = ? AND location = ?',
        whereArgs: [item.name, item.location],
      );

      if (existing.isNotEmpty) {
        // Item exists - update quantity
        final existingItem = Item.fromMap(existing.first);
        final newQuantity = existingItem.quantity + item.quantity;

        // Use the later expiry date
        DateTime? finalExpiry = item.expiry;
        if (existingItem.expiry != null && item.expiry != null) {
          finalExpiry = existingItem.expiry!.isAfter(item.expiry!)
              ? existingItem.expiry
              : item.expiry;
        }

        return await db.update(
          'items',
          {
            'quantity': newQuantity,
            'expiry': finalExpiry?.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [existingItem.id],
        );
      } else {
        // New item - insert
        return await db.insert('items', item.toMap());
      }
    } catch (e) {
      print('Error inserting/updating item: $e');
      rethrow;
    }
  }

  Future<List<Item>> getItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Item.fromMap(maps[i]));
  }

  Future<List<Item>> getItemsByLocation(String location) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'location = ?',
      whereArgs: [location],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Item.fromMap(maps[i]));
  }

  Future<int> updateItem(Item item) async {
    final db = await database;
    return await db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateQuantity(int id, int newQuantity) async {
    final db = await database;
    if (newQuantity <= 0) {
      return await deleteItem(id);
    }
    return await db.update(
      'items',
      {'quantity': newQuantity},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}

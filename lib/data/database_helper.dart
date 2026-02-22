import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/item.dart';

class DatabaseHelper {
    Future<void> clearAllItems() async {
      final db = await database;
      await db.delete('items');
    }
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _db;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('kitchen.db');
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT NOT NULL,
        expiry TEXT,
        quantity INTEGER,
        category TEXT
      )
    ''');
  }

  Future<Item> insertItem(Item item) async {
    final db = await database;
    final id = await db.insert('items', item.toMap());
    item.id = id;
    return item;
  }

  Future<List<Item>> getItemsByLocation(String location) async {
    final db = await database;
    final maps = await db.query('items', where: 'location = ?', whereArgs: [location], orderBy: 'expiry ASC');
    return maps.map((m) => Item.fromMap(m)).toList();
  }

  Future<int> updateItem(Item item) async {
    final db = await database;
    return db.update('items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}

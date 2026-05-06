import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/stock_history.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_inventory.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        minimumThreshold INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_history (
        id TEXT PRIMARY KEY,
        productId TEXT NOT NULL,
        productName TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        quantityBefore INTEGER NOT NULL,
        quantityAfter INTEGER NOT NULL,
        note TEXT,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');
  }

  // ─── Product CRUD ─────────────────────────────────────────────────────────

  Future<void> insertProduct(Product product) async {
    final db = await database;
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'name ASC');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
    await db.delete(
        'stock_history', where: 'productId = ?', whereArgs: [id]);
  }

  // ─── Stock History ────────────────────────────────────────────────────────

  Future<void> insertHistory(StockHistory history) async {
    final db = await database;
    await db.insert(
      'stock_history',
      history.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StockHistory>> getAllHistory() async {
    final db = await database;
    final maps = await db.query(
      'stock_history',
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => StockHistory.fromMap(map)).toList();
  }

  Future<List<StockHistory>> getHistoryForProduct(String productId) async {
    final db = await database;
    final maps = await db.query(
      'stock_history',
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => StockHistory.fromMap(map)).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

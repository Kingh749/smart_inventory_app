import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/stock_history.dart';
import '../database/supabase_service.dart';

class InventoryProvider extends ChangeNotifier {
  final _db = SupabaseService.instance;
  final _uuid = const Uuid();

  List<Product> _products = [];
  List<StockHistory> _history = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';
  String _categoryFilter = 'All';
  String _statusFilter = 'All';

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<Product> get products => _filteredProducts;
  List<Product> get allProducts => _products;
  List<StockHistory> get history => _history;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get categoryFilter => _categoryFilter;
  String get statusFilter => _statusFilter;

  int get totalProducts => _products.length;
  int get lowStockCount => _products.where((p) => p.isLowStock).length;
  int get outOfStockCount => _products.where((p) => p.isOutOfStock).length;

  List<Product> get recentlyUpdated {
    final sorted = List<Product>.from(_products)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.take(5).toList();
  }

  List<Product> get lowStockProducts =>
      _products.where((p) => p.isLowStock || p.isOutOfStock).toList();

  List<String> get categories {
    final cats = _products.map((p) => p.category).toSet().toList()..sort();
    return ['All', ...cats];
  }

  List<Product> get _filteredProducts {
    return _products.where((p) {
      final matchSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchCategory =
          _categoryFilter == 'All' || p.category == _categoryFilter;

      final matchStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Low' && p.isLowStock) ||
          (_statusFilter == 'Out of Stock' && p.isOutOfStock) ||
          (_statusFilter == 'Normal' && !p.isLowStock && !p.isOutOfStock);

      return matchSearch && matchCategory && matchStatus;
    }).toList();
  }

  // ─── Load Data ────────────────────────────────────────────────────────────

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      _products = await _db.getProducts();
      _history = await _db.getAllHistory();
    } catch (e) {
      _errorMessage = 'Failed to load data: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Product CRUD ─────────────────────────────────────────────────────────

  Future<String?> addProduct({
    required String name,
    required String category,
    required int quantity,
    required int minimumThreshold,
  }) async {
    try {
      final now = DateTime.now();
      final product = Product(
        id: _uuid.v4(),
        name: name.trim(),
        category: category.trim(),
        quantity: quantity,
        minimumThreshold: minimumThreshold,
        createdAt: now,
        updatedAt: now,
      );
      await _db.insertProduct(product);

      if (quantity > 0) {
        final historyEntry = StockHistory(
          id: _uuid.v4(),
          productId: product.id,
          productName: product.name,
          type: 'in',
          quantity: quantity,
          quantityBefore: 0,
          quantityAfter: quantity,
          note: 'Initial stock',
          timestamp: now,
        );
        await _db.insertHistory(historyEntry);
      }

      await loadData();
      return null;
    } catch (e) {
      return 'Error adding product: ${e.toString()}';
    }
  }

  Future<String?> updateProduct(Product updatedProduct) async {
    try {
      updatedProduct.updatedAt = DateTime.now();
      await _db.updateProduct(updatedProduct);
      await loadData();
      return null;
    } catch (e) {
      return 'Error updating product: ${e.toString()}';
    }
  }

  Future<String?> deleteProduct(String id) async {
    try {
      await _db.deleteProduct(id);
      await loadData();
      return null;
    } catch (e) {
      return 'Error deleting product: ${e.toString()}';
    }
  }

  // ─── Stock Operations ─────────────────────────────────────────────────────

  Future<String?> stockIn({
    required String productId,
    required int quantity,
    String? note,
  }) async {
    if (quantity <= 0) return 'Quantity must be greater than 0';

    final productIndex = _products.indexWhere((p) => p.id == productId);
    if (productIndex == -1) return 'Product not found';

    try {
      final product = _products[productIndex];
      final before = product.quantity;
      final after = before + quantity;
      product.quantity = after;
      product.updatedAt = DateTime.now();

      await _db.updateProduct(product);

      final historyEntry = StockHistory(
        id: _uuid.v4(),
        productId: productId,
        productName: product.name,
        type: 'in',
        quantity: quantity,
        quantityBefore: before,
        quantityAfter: after,
        note: note,
        timestamp: DateTime.now(),
      );
      await _db.insertHistory(historyEntry);
      await loadData();
      return null;
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  Future<String?> stockOut({
    required String productId,
    required int quantity,
    String? note,
  }) async {
    if (quantity <= 0) return 'Quantity must be greater than 0';

    final productIndex = _products.indexWhere((p) => p.id == productId);
    if (productIndex == -1) return 'Product not found';

    final product = _products[productIndex];
    if (product.quantity < quantity) {
      return 'Insufficient stock. Available: ${product.quantity}';
    }

    try {
      final before = product.quantity;
      final after = before - quantity;
      product.quantity = after;
      product.updatedAt = DateTime.now();

      await _db.updateProduct(product);

      final historyEntry = StockHistory(
        id: _uuid.v4(),
        productId: productId,
        productName: product.name,
        type: 'out',
        quantity: quantity,
        quantityBefore: before,
        quantityAfter: after,
        note: note,
        timestamp: DateTime.now(),
      );
      await _db.insertHistory(historyEntry);
      await loadData();
      return null;
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  // ─── Filters ──────────────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _categoryFilter = 'All';
    _statusFilter = 'All';
    notifyListeners();
  }
}

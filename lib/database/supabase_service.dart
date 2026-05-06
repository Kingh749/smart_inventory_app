import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/stock_history.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  // ─── Products ─────────────────────────────────────────────────────────────

  Future<void> insertProduct(Product product) async {
    await _client.from('products').insert(product.toMap());
  }

  Future<List<Product>> getProducts() async {
    final data = await _client
        .from('products')
        .select()
        .order('name', ascending: true);
    return (data as List).map((map) => Product.fromMap(map)).toList();
  }

  Future<void> updateProduct(Product product) async {
    await _client
        .from('products')
        .update(product.toMap())
        .eq('id', product.id);
  }

  Future<void> deleteProduct(String id) async {
    // Delete history first (foreign key constraint)
    await _client.from('stock_history').delete().eq('product_id', id);
    await _client.from('products').delete().eq('id', id);
  }

  // ─── Stock History ────────────────────────────────────────────────────────

  Future<void> insertHistory(StockHistory history) async {
    await _client.from('stock_history').insert(history.toMap());
  }

  Future<List<StockHistory>> getAllHistory() async {
    final data = await _client
        .from('stock_history')
        .select()
        .order('timestamp', ascending: false);
    return (data as List).map((map) => StockHistory.fromMap(map)).toList();
  }

  Future<List<StockHistory>> getHistoryForProduct(String productId) async {
    final data = await _client
        .from('stock_history')
        .select()
        .eq('product_id', productId)
        .order('timestamp', ascending: false);
    return (data as List).map((map) => StockHistory.fromMap(map)).toList();
  }
}

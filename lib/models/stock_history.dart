class StockHistory {
  final String id;
  final String productId;
  final String productName;
  final String type; // 'in' or 'out'
  final int quantity;
  final int quantityBefore;
  final int quantityAfter;
  final String? note;
  final DateTime timestamp;

  StockHistory({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.quantityBefore,
    required this.quantityAfter,
    this.note,
    required this.timestamp,
  });

  /// Serialise to Supabase (snake_case columns)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'type': type,
      'quantity': quantity,
      'quantity_before': quantityBefore,
      'quantity_after': quantityAfter,
      'note': note ?? '',
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Deserialise from Supabase row
  factory StockHistory.fromMap(Map<String, dynamic> map) {
    return StockHistory(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      type: map['type'] as String,
      quantity: map['quantity'] as int,
      quantityBefore: map['quantity_before'] as int,
      quantityAfter: map['quantity_after'] as int,
      note: map['note'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

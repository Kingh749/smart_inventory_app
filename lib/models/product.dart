class Product {
  final String id;
  final String name;
  final String category;
  int quantity;
  final int minimumThreshold;
  final DateTime createdAt;
  DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.minimumThreshold,
    required this.createdAt,
    required this.updatedAt,
  });

  String get stockStatus {
    if (quantity <= 0) return 'Out of Stock';
    if (quantity <= minimumThreshold) return 'Low';
    return 'Normal';
  }

  bool get isLowStock => quantity <= minimumThreshold && quantity > 0;
  bool get isOutOfStock => quantity <= 0;
  bool get isCritical => quantity <= (minimumThreshold ~/ 2) && quantity > 0;

  /// Serialise to Supabase (snake_case columns)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'minimum_threshold': minimumThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Deserialise from Supabase row
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      quantity: map['quantity'] as int,
      minimumThreshold: map['minimum_threshold'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    int? quantity,
    int? minimumThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      minimumThreshold: minimumThreshold ?? this.minimumThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

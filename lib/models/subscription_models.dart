class SubscriptionModel {
  final String id;
  final String userId;
  final String productId;
  final String purchaseToken;
  final bool isActive;
  final DateTime createdAt;
  final String taller;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.purchaseToken,
    required this.isActive,
    required this.createdAt,
    required this.taller,
  });

  @override
  String toString() {
    return 'SubscriptionModel(id: $id, userId: $userId, productId: $productId, purchaseToken: $purchaseToken, isActive: $isActive, createdAt: $createdAt, taller: $taller)';
  }

  // Método para crear una instancia desde un Map (útil para bases de datos)
  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      id: map['id'],
      userId: map['user_id'],
      productId: map['product_id'],
      purchaseToken: map['purchase_token'],
      isActive: map['is_active'],
      createdAt: DateTime.parse(map['created_at']),
      taller: map['taller'],
    );
  }

  // Método para convertir una instancia a Map (útil para bases de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'purchase_token': purchaseToken,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'taller': taller,
    };
  }

  // Método copyWith para copiar y modificar instancias
  SubscriptionModel copyWith({
    String? id,
    String? userId,
    String? productId,
    String? purchaseToken,
    bool? isActive,
    DateTime? createdAt,
    String? taller,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      purchaseToken: purchaseToken ?? this.purchaseToken,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      taller: taller ?? this.taller,
    );
  }
}

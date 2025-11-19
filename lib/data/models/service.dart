class Service {
  final String id;
  final String businessId;
  final String name;
  final String? description;
  final int durationMinutes;
  final double price;
  final String currency;
  final bool isActive;
  final String? imageUrl;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  Service({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    required this.durationMinutes,
    required this.price,
    this.currency = 'EUR',
    this.isActive = true,
    this.imageUrl,
    this.orderIndex = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      businessId: json['business_id'],
      name: json['name'],
      description: json['description'],
      durationMinutes: json['duration_minutes'],
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] ?? 'EUR',
      isActive: json['is_active'] ?? true,
      imageUrl: json['image_url'],
      orderIndex: json['order_index'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'description': description,
      'duration_minutes': durationMinutes,
      'price': price,
      'currency': currency,
      'is_active': isActive,
      'image_url': imageUrl,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get formattedPrice => '${price.toStringAsFixed(2)} $currency';
  String get formattedDuration => '${durationMinutes} min';
}
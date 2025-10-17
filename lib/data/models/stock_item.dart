// lib/data/models/stock_item.dart
class StockItem {
  final int id;
  final String name;
  final int quantity;
  final bool isSynced;
  final DateTime lastUpdated;

  StockItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.isSynced,
    required this.lastUpdated,
  });

  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id'] as int,
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      isSynced: map['isSynced'] == 1 || map['isSynced'] == true,
      lastUpdated: DateTime.parse(map['lastUpdated'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'isSynced': isSynced ? 1 : 0,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  StockItem copyWith({
    int? id,
    String? name,
    int? quantity,
    bool? isSynced,
    DateTime? lastUpdated,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      isSynced: isSynced ?? this.isSynced,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

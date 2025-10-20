class Product {
  final String id; // inventory_item_id
  final String title;
  final double price;
  int inventory;
  final List<String> images;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.inventory,
    required this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final variant = json['variants'] != null && (json['variants'] as List).isNotEmpty
        ? json['variants'][0]
        : null;

    return Product(
      id: variant != null ? variant['inventory_item_id'].toString() : '',
      title: json['title'] ?? 'No title',
      price: variant != null ? double.tryParse(variant['price'].toString()) ?? 0 : 0,
      inventory: variant != null ? variant['inventory_quantity'] ?? 0 : 0,
      images: (json['images'] as List?)?.map((i) => i['src'].toString()).toList() ?? [],
    );
  }
}

import 'package:isar/isar.dart';

part 'product_entity.g.dart';

@collection
class ProductEntity {
  // Isar id (autoincrement)
  Id isarId = Isar.autoIncrement;

  /// Shopify inventory_item_id (string)
  @Index(unique: true, replace: true)
  late String productId;

  late String title;
  double price = 0.0;
  int inventory = 0;

  // prima imagine utilă (pentru listări)
  String? imageUrl;

  // când a fost sincronizat ultima dată din Shopify
  DateTime syncedAt = DateTime.now();
}

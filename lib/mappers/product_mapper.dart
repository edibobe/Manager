import 'package:shopify_manager/models/product.dart' as M;
import 'package:shopify_manager/db/models/product_entity.dart';

ProductEntity productToEntity(M.Product p) {
  return ProductEntity()
    ..productId = p.id
    ..title = p.title
    ..price = p.price
    ..inventory = p.inventory
    ..imageUrl = (p.images.isNotEmpty ? p.images.first : null)
    ..syncedAt = DateTime.now();
}

M.Product entityToProduct(ProductEntity e) {
  return M.Product(
    id: e.productId,
    title: e.title,
    price: e.price,
    inventory: e.inventory,
    images: e.imageUrl == null ? [] : [e.imageUrl!],
  );
}

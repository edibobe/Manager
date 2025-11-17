import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shopify_manager/db/models/order_entity.dart';
import 'package:shopify_manager/db/models/product_entity.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  Isar? _isar;

  DatabaseService._internal();

  Future<void> init() async {
    if (_isar != null) return;

    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [
        OrderEntitySchema,
        ProductEntitySchema,
      ],
      directory: dir.path,
    );
  }

  Isar get isar {
    if (_isar == null) {
      throw Exception('Isar DB not initialized. Call init() first.');
    }
    return _isar!;
  }

  /// 🔹 Inserează sau actualizează comenzile
  Future<void> upsertOrders(List<OrderEntity> orders) async {
    final db = isar;
    await db.writeTxn(() async {
      for (final order in orders) {
        final existing = await db.orderEntitys
            .filter()
            .orderIdEqualTo(order.orderId)
            .findFirst();

        if (existing != null) {
          order.isarId = existing.isarId; // păstrează același ID intern
        }

        await db.orderEntitys.put(order);
      }
    });
  }

  /// 🔹 Insereaza sau actualizeaza produsele
  Future<void> upsertProducts(List<ProductEntity> products) async {
    final db = isar;
    await db.writeTxn(() async {
      for (final p in products) {
        final existing = await db.productEntitys
            .filter()
            .productIdEqualTo(p.productId)
            .findFirst();

        if (existing != null) {
          p.isarId = existing.isarId; // pastram acelasi ID intern
        }

        await db.productEntitys.put(p);
      }
    });
  }

  /// 🔹 Returneaza toate produsele salvate local
  Future<List<ProductEntity>> getAllProducts() async {
    final db = isar;
    return db.productEntitys.where().findAll();
  }

  /// 🔹 Returnează suma totală pentru comenzile incasate din Shopify
  Future<double> sumShopifyIncasateTotal() async {
    final db = isar;

    final results = await db.orderEntitys
        .filter()
        .statusEqualTo('incasata')
        .and()
        .not()
        .group((q) => q
        .shippingMethodContains('olx alex', caseSensitive: false)
        .or()
        .shippingMethodContains('olx edi', caseSensitive: false))
        .findAll();

    double sum = 0.0;
    for (final o in results) {
      sum += o.totalPrice;
    }
    return sum;
  }

  Future<double> sumOlxAlexTotal() async {
    final db = isar;
    final results = await db.orderEntitys
        .filter()
        .statusEqualTo('incasata')
        .and()
        .shippingMethodContains('olx alex', caseSensitive: false)
        .findAll();
    double sum = 0.0;
    for (final o in results) {
      sum += o.totalPrice;
    }
    return sum;
  }

  Future<double> sumOlxEdiTotal() async {
    final db = isar;
    final results = await db.orderEntitys
        .filter()
        .statusEqualTo('incasata')
        .and()
        .shippingMethodContains('olx edi', caseSensitive: false)
        .findAll();
    double sum = 0.0;
    for (final o in results) {
      sum += o.totalPrice;
    }
    return sum;
  }
}

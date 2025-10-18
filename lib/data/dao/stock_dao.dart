import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../tables/stock_items.dart';
import '../models/stock_item.dart';

part 'stock_dao.g.dart';

@DriftAccessor(tables: [StockItems])
class StockDao extends DatabaseAccessor<AppDatabase> with _$StockDaoMixin {
  StockDao(AppDatabase db) : super(db);

  Future<List<StockItem>> getAllItems() async {
    final rows = await select(stockItems).get();
    return rows.map((r) => StockItem(
      id: r.id,
      category: r.category,
      aroma: r.aroma,
      quantity: r.quantity,
      updatedAt: r.updatedAt,
    )).toList();
  }

  Future<void> insertOrUpdateItem(StockItem item) async {
    await into(stockItems).insertOnConflictUpdate(
      StockItemsCompanion(
        id: Value(item.id),
        category: Value(item.category),
        aroma: Value(item.aroma),
        quantity: Value(item.quantity),
        updatedAt: Value(item.updatedAt),
      ),
    );
  }

  Future<void> clearAll() => delete(stockItems).go();
}

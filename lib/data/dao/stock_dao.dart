import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/tables/stock_items.dart';

part 'stock_dao.g.dart';

@DriftAccessor(tables: [StockItems])
class StockDao extends DatabaseAccessor<AppDatabase> with _$StockDaoMixin {
  final AppDatabase db;
  StockDao(this.db) : super(db);

  Future<List<StockItem>> getAllItems() => select(stockItems).get();

  Future<int> insertItem(StockItemsCompanion item) =>
      into(stockItems).insert(item, mode: InsertMode.insertOrReplace);

  Future updateItem(StockItemsCompanion item) =>
      update(stockItems).replace(item);

  Future deleteItem(int id) =>
      (delete(stockItems)..where((tbl) => tbl.id.equals(id))).go();
}

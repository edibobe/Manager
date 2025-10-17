// lib/data/database/dao/stock_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/stock_items.dart';
import '../../models/stock_item.dart';

part 'stock_dao.g.dart';

@DriftAccessor(tables: [StockItems])
class StockDao extends DatabaseAccessor<AppDatabase> with _$StockDaoMixin {
  final AppDatabase db;
  StockDao(this.db) : super(db);

  /// Returneaza toate intrarile ca modelul aplicatiei (StockItem)
  Future<List<StockItem>> getAllItems() async {
    final rows = await select(stockItems).get();
    return rows.map((r) => _fromDrift(r)).toList();
  }

  /// Stream pentru UI reactiv
  Stream<List<StockItem>> watchAllItems() {
    return (select(stockItems)).watch().map((rows) => rows.map(_fromDrift).toList());
  }

  /// Inserare noua aroma (foloseste companion)
  Future<int> insertNewItem(String name, {int quantity = 0}) {
    final companion = StockItemsCompanion.insert(
      name: name,
      quantity: Value(quantity),
      // isSynced si lastUpdated au valori default in tabela
    );
    return into(stockItems).insert(companion);
  }

  /// Update cantitate si marcam ca nesincronizat
  Future<void> updateItemQuantityById(int id, int newQuantity) async {
    await (update(stockItems)..where((t) => t.id.equals(id))).write(
      StockItemsCompanion(
        quantity: Value(newQuantity),
        isSynced: const Value(false),
        lastUpdated: Value(DateTime.now()),
      ),
    );
  }

  /// Mark as synced
  Future<void> markAsSyncedById(int id) async {
    await (update(stockItems)..where((t) => t.id.equals(id))).write(
      const StockItemsCompanion(isSynced: Value(true)),
    );
  }

  /// Delete
  Future<int> deleteById(int id) {
    return (delete(stockItems)..where((t) => t.id.equals(id))).go();
  }

  /// Clear all
  Future<void> clearAll() => delete(stockItems).go();

  // --- converters between Drift-generated data class and our app model ---

  StockItem _fromDrift(StockItemsData d) {
    return StockItem(
      id: d.id,
      name: d.name,
      quantity: d.quantity,
      isSynced: d.isSynced,
      lastUpdated: d.lastUpdated,
    );
  }

  StockItemsCompanion _toDriftCompanion(StockItem item) {
    return StockItemsCompanion(
      id: Value(item.id),
      name: Value(item.name),
      quantity: Value(item.quantity),
      isSynced: Value(item.isSynced),
      lastUpdated: Value(item.lastUpdated),
    );
  }

  /// Optional: insert from model
  Future<int> insertFromModel(StockItem item) {
    final comp = _toDriftCompanion(item);
    return into(stockItems).insert(comp);
  }

  /// Optional: replace item (requires full StockItemData equivalence)
  Future<bool> replaceItem(StockItem item) async {
    final comp = _toDriftCompanion(item);
    return update(stockItems).replace(comp);
  }
}

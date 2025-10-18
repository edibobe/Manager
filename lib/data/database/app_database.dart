import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'tables/stock_items.dart';
import '../dao/stock_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [StockItems], daos: [StockDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'stock_manager.sqlite'));
    return NativeDatabase(file);
  });
}

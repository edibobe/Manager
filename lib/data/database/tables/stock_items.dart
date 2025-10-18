import 'package:drift/drift.dart';

class StockItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text()();
  TextColumn get aroma => text()();
  IntColumn get quantity => integer()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

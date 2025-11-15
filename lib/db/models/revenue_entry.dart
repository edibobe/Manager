import 'package:isar/isar.dart';

part 'revenue_entry.g.dart';

@collection
class RevenueEntry {
  Id isarId = Isar.autoIncrement;

  /// "magazin", "olx_alex", "olx_edi"
  @Index(caseSensitive: false)
  late String source;

  /// data agregării (ex. zi/lună)
  @Index()
  late DateTime period;

  /// total încasat (sumă comenzi incasate)
  double total = 0.0;

  /// profit real (ex. pentru easybox; opțional)
  double net = 0.0;

  /// metadate (opțional)
  String? note;
}

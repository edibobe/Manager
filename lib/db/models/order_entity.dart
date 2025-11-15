import 'package:isar/isar.dart';

part 'order_entity.g.dart';

@collection
class OrderEntity {
  Id isarId = Isar.autoIncrement;

  /// Shopify order id (string)
  @Index(unique: true, replace: true)
  late String orderId;

  late String customerName;

  /// status custom: de_impachetat / impachetata / trimisa / ridicata / incasata / retur
  @Index()
  late String status;

  /// total din comanda (RON)
  double totalPrice = 0.0;

  /// shippingMethod: ex. "Livrare Rapida (Fan Courier)...", "Ridicare Personală (EASYBOX BY SAMEDAY)...",
  /// sau "olx alex" / "olx edi" (pentru OLX).
  @Index(caseSensitive: false)
  String? shippingMethod;

  DateTime createdAt = DateTime.now();

  String? email;
  String? phone;

  /// line items embedded
  List<OrderLineItemEmbedded> lineItems = [];

  /// flag-uri utile pentru analytics
  bool isOlxAlex = false;
  bool isOlxEdi = false;
}

@embedded
class OrderLineItemEmbedded {
  String id = '';
  String title = '';
  int quantity = 0;
  double price = 0.0;
}

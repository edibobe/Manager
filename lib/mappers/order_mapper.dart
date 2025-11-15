import 'package:shopify_manager/models/order.dart' as M;
import 'package:shopify_manager/db/models/order_entity.dart';

OrderEntity orderToEntity(M.Order o) {
  final e = OrderEntity()
    ..orderId = o.id
    ..customerName = o.customerName
    ..status = o.status
    ..totalPrice = o.totalPrice
    ..shippingMethod = o.shippingMethod
    ..createdAt = o.createdAt
    ..email = o.email
    ..phone = o.phone
    ..isOlxAlex = (o.shippingMethod?.toLowerCase().contains('olx') ?? false) &&
        (o.shippingMethod!.toLowerCase().contains('alex'))
    ..isOlxEdi = (o.shippingMethod?.toLowerCase().contains('olx') ?? false) &&
        (o.shippingMethod!.toLowerCase().contains('edi'));

  e.lineItems = o.lineItems
      .map((li) => OrderLineItemEmbedded()
    ..id = li.id
    ..title = li.title
    ..quantity = li.quantity
    ..price = li.price)
      .toList();

  return e;
}

M.Order entityToOrder(OrderEntity e) {
  final items = e.lineItems
      .map((li) => M.OrderLineItem(
    id: li.id,
    title: li.title,
    quantity: li.quantity,
    price: li.price,
  ))
      .toList();

  return M.Order(
    id: e.orderId,
    customerName: e.customerName,
    status: e.status,
    totalPrice: e.totalPrice,
    createdAt: e.createdAt,
    lineItems: items,
    email: e.email,
    phone: e.phone,
    shippingAddress: null,
    financialStatus: null,
    fulfillmentStatus: null,
    shippingMethod: e.shippingMethod,
  );
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shopify_manager/models/order.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  final SupabaseClient _client = Supabase.instance.client;

  // ---------- helpers de mapare ----------
  Map<String, dynamic> _orderToRow(Order o) {
    final method = o.shippingMethod?.toLowerCase() ?? '';
    return {
      'id': o.id,
      'source': method.contains('olx') ? 'olx' : 'shopify',
      'status': o.status,
      'total_price': o.totalPrice,
      'shipping_method': o.shippingMethod,
      'customer_name': o.customerName,
      'email': o.email,
      'phone': o.phone,
      'is_olx_alex': method.contains('olx alex'),
      'is_olx_edi': method.contains('olx edi'),
    };
  }

  List<Map<String, dynamic>> _itemsToRows(String orderId, List<OrderLineItem> items) {
    return items.map((li) {
      return {
        'order_id': orderId,
        'title': li.title,
        'quantity': li.quantity,
        'price': li.price,
      };
    }).toList();
  }

  Order _rowToOrder(Map<String, dynamic> r) {
    final itemsRaw = (r['order_items'] as List?) ?? const [];
    final items = itemsRaw.map((it) {
      return OrderLineItem(
        id: (it['id'] ?? '').toString(),
        title: it['title']?.toString() ?? '',
        quantity: (it['quantity'] ?? 0) as int,
        price: double.tryParse('${it['price']}') ?? 0.0,
      );
    }).toList();

    return Order(
      id: (r['id'] ?? '').toString(),
      customerName: r['customer_name']?.toString() ?? 'Unknown',
      status: (r['status'] ?? 'de_impachetat').toString(),
      totalPrice: (r['total_price'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(r['created_at']?.toString() ?? '') ?? DateTime.now(),
      lineItems: items,
      email: r['email']?.toString(),
      phone: r['phone']?.toString(),
      shippingAddress: null,
      financialStatus: null,
      fulfillmentStatus: null,
      shippingMethod: r['shipping_method']?.toString(),
    );
  }

  // ---------- metode INSTANȚĂ ----------
  Future<List<Map<String, dynamic>>> _fetchOrdersRaw() async {
    final data = await _client
        .from('orders')
        .select('*, order_items:order_items(*)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<List<Order>> _fetchOrders() async {
    final raw = await _fetchOrdersRaw();
    return raw.map(_rowToOrder).toList();
  }

  Future<void> _upsertOrders(List<Order> orders) async {
    if (orders.isEmpty) return;

    // upsert orders
    final orderRows = orders.map(_orderToRow).toList();
    await _client.from('orders').upsert(orderRows, onConflict: 'id');

    // upsert items
    for (final o in orders) {
      final itemsRows = _itemsToRows(o.id, o.lineItems);
      if (itemsRows.isEmpty) continue;

      for (final row in itemsRows) {
        await _client.from('order_items').upsert(row, onConflict: 'order_id,title');
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    await _client.from('orders').update({'status': newStatus}).eq('id', orderId);
  }

  // ---------- metode STATICE (compatibile cu provider-ul tău) ----------
  static Future<List<Order>> fetchOrders() => instance._fetchOrders();
  static Future<void> upsertOrders(List<Order> orders) => instance._upsertOrders(orders);
  static Future<void> updateOrderStatus(String orderId, String newStatus) =>
      instance._updateOrderStatus(orderId, newStatus);
}

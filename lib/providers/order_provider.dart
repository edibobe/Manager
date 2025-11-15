import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shopify_manager/models/order.dart';
import 'package:shopify_manager/services/shopify_api.dart';
import 'package:shopify_manager/services/supabase_service.dart';

class OrderProvider extends ChangeNotifier {
  final ShopifyApi api;

  bool loading = false;
  String? error;
  List<Order> orders = [];

  RealtimeChannel? _ordersChannel;

  OrderProvider({required this.api});

  /// Citește din Supabase; dacă e gol, importă din Shopify și urcă în Supabase.
  Future<void> fetchOrders() async {
    loading = true;
    notifyListeners();

    try {
      final supa = await SupabaseService.fetchOrders();
      if (supa.isNotEmpty) {
        orders = supa;
      } else {
        final fetchedOrders = await api.getOrders();
        orders = fetchedOrders;
        await SupabaseService.upsertOrders(orders);
      }
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Update status în memorie + cloud
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;

    orders[index].status = newStatus;
    notifyListeners();

    await SupabaseService.updateOrderStatus(orderId, newStatus);
  }

  /// Compatibilitate cu orders_screen.dart
  Future<void> syncOrderStatus(String orderId, String status) =>
      updateOrderStatus(orderId, status);

  List<Order> getOrdersByStatus(String status) =>
      orders.where((o) => o.status == status).toList();

  List<Order> filterByStatus(String status) {
    if (status == 'all') return orders;
    return orders.where((o) => o.status.toLowerCase().contains(status)).toList();
  }

  /// Re-sync din Shopify și urcă în Supabase
  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    try {
      final fetched = await api.getOrders();
      orders = fetched;
      await SupabaseService.upsertOrders(orders);
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ==========================
  // Realtime (opțional)
  // ==========================
  void startRealtime() {
    stopRealtime(); // oprește dacă era deja activ

    final client = Supabase.instance.client;
    _ordersChannel = client.channel('public:orders');

    // INSERTS
    _ordersChannel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'orders',
      callback: (payload) {
        final row = payload.newRecord;
        final id = (row['id'] ?? '').toString();
        if (id.isEmpty) return;

        final exists = orders.any((o) => o.id == id);
        if (!exists) {
          final totalPrice = _asDouble(row['total_price']);
          final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now();

          orders.insert(
            0,
            Order(
              id: id,
              customerName: row['customer_name']?.toString() ?? 'Unknown',
              status: (row['status'] ?? 'de_impachetat').toString(),
              totalPrice: totalPrice,
              createdAt: createdAt,
              lineItems: const [],
              email: row['email']?.toString(),
              phone: row['phone']?.toString(),
              shippingAddress: null,
              financialStatus: null,
              fulfillmentStatus: null,
              shippingMethod: row['shipping_method']?.toString(),
            ),
          );
          notifyListeners();
        }
      },
    );

    // UPDATES
    _ordersChannel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'orders',
      callback: (payload) {
        final row = payload.newRecord;
        final id = (row['id'] ?? '').toString();
        if (id.isEmpty) return;

        final idx = orders.indexWhere((o) => o.id == id);
        if (idx != -1) {
          final current = orders[idx];
          final newStatus = (row['status'] ?? current.status).toString();
          final newTotal = _asDouble(row['total_price']);

          orders[idx] = Order(
            id: current.id,
            customerName: row['customer_name']?.toString() ?? current.customerName,
            status: newStatus,
            totalPrice: newTotal,
            createdAt: current.createdAt,
            lineItems: current.lineItems,
            email: row['email']?.toString() ?? current.email,
            phone: row['phone']?.toString() ?? current.phone,
            shippingAddress: current.shippingAddress,
            financialStatus: current.financialStatus,
            fulfillmentStatus: current.fulfillmentStatus,
            shippingMethod: row['shipping_method']?.toString() ?? current.shippingMethod,
          );
          notifyListeners();
        }
      },
    );

    // (opțional) DELETE → scoatem comanda din listă
    _ordersChannel!.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'orders',
      callback: (payload) {
        final oldRow = payload.oldRecord;
        final id = (oldRow['id'] ?? '').toString();
        if (id.isEmpty) return;

        final idx = orders.indexWhere((o) => o.id == id);
        if (idx != -1) {
          orders.removeAt(idx);
          notifyListeners();
        }
      },
    );

    _ordersChannel!.subscribe();
  }

  Future<void> stopRealtime() async {
    if (_ordersChannel != null) {
      await _ordersChannel!.unsubscribe();
      _ordersChannel = null;
    }
  }

  // helper sigur pentru dynamic → double
  double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

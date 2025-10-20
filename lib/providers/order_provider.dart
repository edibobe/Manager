import 'package:flutter/material.dart';
import 'package:shopify_manager/models/order.dart';
import 'package:shopify_manager/services/shopify_api.dart';
import 'package:shopify_manager/services/local_storage_service.dart';

class OrderProvider extends ChangeNotifier {
  final ShopifyApi api;
  bool loading = false;
  String? error;
  List<Order> orders = [];

  OrderProvider({required this.api});

  Future<void> fetchOrders() async {
    loading = true;
    notifyListeners();

    try {
      final fetchedOrders = await api.getOrders();

      // 🔹 aplicăm statusurile salvate local (dacă există)
      for (final order in fetchedOrders) {
        final localStatus = await LocalStorageService.getOrderStatus(order.id);
        if (localStatus != null) {
          order.status = localStatus;
        }
      }

      orders = fetchedOrders;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // 🔹 Schimbă statusul unei comenzi și salvează local
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;

    orders[index].status = newStatus;
    await LocalStorageService.saveOrderStatus(orderId, newStatus);
    notifyListeners();
  }

  // 🔹 Filtrează comenzile după status
  List<Order> getOrdersByStatus(String status) {
    return orders.where((o) => o.status == status).toList();
  }

  Future<void> syncOrderStatus(String orderId, String status) async {
    // deocamdată doar afișăm în consolă
    debugPrint('[SYNC] Order $orderId -> Status: $status');
    // în v3 va apela un API pentru a salva permanent
  }

  List<Order> filterByStatus(String status) {
    if (status == 'all') return orders;
    return orders.where((o) => o.status.toLowerCase().contains(status)).toList();
  }

  Future<void> refresh() => fetchOrders();
}

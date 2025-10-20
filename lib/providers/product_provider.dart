import 'package:flutter/material.dart';
import 'package:shopify_manager/services/shopify_api.dart';
import 'package:shopify_manager/models/product.dart';

class ProductProvider extends ChangeNotifier {
  final ShopifyApi api;

  bool loading = false;
  String? error;
  List<Product> products = [];

  // ținem evidența produselor modificate
  final Map<String, int> _pendingUpdates = {};

  ProductProvider({required this.api});

  Future<void> fetchProducts() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      products = await api.getProducts();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // modifică local stocul
  void updateLocalStock(String id, int stock) {
    final idx = products.indexWhere((p) => p.id == id);
    if (idx != -1) {
      products[idx].inventory = stock;
      _pendingUpdates[id] = stock;
      notifyListeners();
    }
  }

  // trimite toate modificările către Shopify
  Future<void> saveAllChanges() async {
    if (_pendingUpdates.isEmpty) return;

    loading = true;
    notifyListeners();

    try {
      for (final entry in _pendingUpdates.entries) {
        await api.updateProductStock(entry.key, entry.value);
      }
      _pendingUpdates.clear();
    } catch (e) {
      error = e.toString();
    } finally {
      if (loading) {
        loading = false;
        notifyListeners();
      }
    }
  }

  bool get hasPendingUpdates => _pendingUpdates.isNotEmpty;

  // actualizează un produs individual în Shopify (alias pentru API direct)
  Future<void> updateProductStock(String id, int stock) async {
    try {
      await api.updateProductStock(id, stock);
    } catch (e) {
      error = e.toString();
      if (loading) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void removePendingUpdate(String id) {
    _pendingUpdates.remove(id);
    notifyListeners();
  }

  Future<bool> hasChangesComparedToShopify() async {
    try {
      final remoteProducts = await api.getProducts();
      final localMap = {for (var p in products) p.id: p.inventory};
      for (final remote in remoteProducts) {
        final localValue = localMap[remote.id];
        if (localValue != null && localValue != remote.inventory) {
          return true; // există diferențe
        }
      }
      return false; // totul e identic
    } catch (e) {
      debugPrint('Check failed: $e');
      return true; // fallback: considerăm că trebuie să afișăm pop-up
    }
  }
}

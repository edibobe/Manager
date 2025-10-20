import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _stockPrefix = 'stock_';
  static const _orderKeyProducts = 'order_products';
  static const _orderPrefixAromas = 'order_aromas_';

  // ===============================
  // 🔹 Stocuri
  // ===============================
  static Future<void> saveStock(String id, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_stockPrefix$id', value);
  }

  static Future<int?> getSavedStock(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_stockPrefix$id');
  }

  static Future<bool> hasLocalChanges() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().any((k) => k.startsWith(_stockPrefix));
  }

  static Future<void> clearLocalChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_stockPrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  // ===============================
  // 🔹 Ordine produse mari
  // ===============================
  static Future<void> saveMainProductOrder(List<String> productTitles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_orderKeyProducts, productTitles);
  }

  static Future<List<String>?> getSavedMainProductOrder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_orderKeyProducts);
  }

  // ===============================
  // 🔹 Ordine arome (per produs)
  // ===============================
  static Future<void> saveAromaOrder(String productTitle, List<String> aromaIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('$_orderPrefixAromas$productTitle', aromaIds);
  }

  static Future<List<String>?> getSavedAromaOrder(String productTitle) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('$_orderPrefixAromas$productTitle');
  }

  static Future<void> saveProductOrder(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('product_order', ids);
  }

  static Future<void> saveOrderStatus(String orderId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('order_status_$orderId', status);
  }

  static Future<String?> getOrderStatus(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('order_status_$orderId');
  }

  static Future<void> clearAllOrderStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('order_status_'));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}

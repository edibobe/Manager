import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shopify_manager/models/product.dart';
import 'package:shopify_manager/models/order.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

class ShopifyApi {
  final String domain;
  final String accessToken;

  ShopifyApi({required this.domain, required this.accessToken}) {
    HttpOverrides.global = MyHttpOverrides();
  }

  String get baseUrl => 'https://$domain/admin/api/2025-07';

  Map<String, String> get _headers =>
      {
        'X-Shopify-Access-Token': accessToken,
        'Content-Type': 'application/json',
      };

  // === Products ===
  Future<List<Product>> getProducts() async {
    final url = Uri.parse('$baseUrl/products.json?limit=250');
    final res = await http.get(url, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Failed to load products: ${res.body}');
    }
    final body = jsonDecode(res.body);
    final List productsJson = body['products'] ?? [];
    return productsJson.map((p) => Product.fromJson(p)).toList();
  }

  Future<void> updateProductStock(String id, int stock) async {
    final locationId = dotenv.env['SHOPIFY_LOCATION_ID'];
    if (locationId == null || locationId.isEmpty) {
      throw Exception('Missing SHOPIFY_LOCATION_ID in .env');
    }

    final url = Uri.parse('$baseUrl/inventory_levels/set.json');
    final body = jsonEncode({
      "location_id": locationId,
      "inventory_item_id": id,
      "available": stock,
    });

    final res = await http.post(url, headers: _headers, body: body);

    if (res.statusCode >= 400) {
      throw Exception('Failed to update stock: ${res.body}');
    }

    print('Updating stock for $id → $stock at location: $locationId');
  }

  // === Orders ===
  Future<List<Order>> getOrders() async {
    final url = Uri.parse('$baseUrl/orders.json?status=any&limit=250');
    final res = await http.get(url, headers: _headers);

    if (res.statusCode != 200) {
      throw Exception('Failed to load orders: ${res.body}');
    }

    final body = jsonDecode(res.body);
    final List ordersJson = body['orders'] ?? [];

    final List<Order> orders = [];

    for (final o in ordersJson) {
      final order = Order.fromJson(o);

      // 🔹 normalizăm metoda de livrare (pentru Fan / Sameday)
      String? shipping = '';
      try {
        if (o['shipping_lines'] != null && o['shipping_lines'] is List && o['shipping_lines'].isNotEmpty) {
          shipping = o['shipping_lines'][0]['title']?.toString() ?? '';
        }
      } catch (_) {}
      order.shippingMethod = shipping;

      // 🔹 convertim comenzile anulate în "retur"
      if ((o['cancelled_at'] != null && o['cancelled_at'].toString().isNotEmpty) ||
          (o['cancel_reason'] != null && o['cancel_reason'].toString().isNotEmpty)) {
        order.status = 'retur';
      }

      // 🔹 dacă nu are status definit, punem "de_impachetat" implicit
      order.status = order.status.isEmpty ? 'de_impachetat' : order.status;

      // 🔹 verificăm să aibă total corect
      if (order.totalPrice == 0) {
        try {
          final rawTotal = o['total_price'] ?? o['current_total_price'] ?? '0';
          final parsed = double.tryParse(rawTotal.toString()) ?? 0;
          order.status = order.status; // doar forțăm rebuild intern
          orders.add(order.copyWith(totalPrice: parsed)); // 👈 îl adăugăm modificat
        } catch (_) {
          orders.add(order);
        }
      } else {
        orders.add(order);
      }

      orders.add(order);
    }

    // 🔹 ordonăm comenzile după data creării (cele mai recente primele)
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return orders;
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
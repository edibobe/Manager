import 'dart:convert';
import 'package:http/http.dart' as http;

class ShopifyService {
  final String shopDomain; // ex: airvapes.myshopify.com
  final String accessToken;

  ShopifyService({required this.shopDomain, required this.accessToken});

  Future<List<dynamic>> fetchProducts() async {
    final url = Uri.https(shopDomain, '/admin/api/2025-10/products.json');
    final response = await http.get(url, headers: {
      'X-Shopify-Access-Token': accessToken,
      'Content-Type': 'application/json'
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['products'] as List<dynamic>;
    } else {
      throw Exception('Failed to load products: ${response.body}');
    }
  }

  Future<String> getDefaultLocationId() async {
    final url = Uri.https(shopDomain, '/admin/api/2025-10/locations.json');
    final response = await http.get(url, headers: {
      'X-Shopify-Access-Token': accessToken,
      'Content-Type': 'application/json'
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch locations: ${response.body}');
    }

    final data = json.decode(response.body);
    final locations = data['locations'] as List<dynamic>;
    if (locations.isEmpty) throw Exception('No locations found');

    final loc = locations.firstWhere((l) => l['active'] == true,
        orElse: () => locations.first);
    return loc['id'].toString();
  }

  // folosim inventory_levels API (inventory_item_id + location_id)
  Future<http.Response> updateInventoryQuantityByInventoryItem(
      String inventoryItemId, int quantity, String locationId) async {
    final url = Uri.https(shopDomain, '/admin/api/2025-10/inventory_levels/set.json');
    final body = json.encode({
      "location_id": locationId,
      "inventory_item_id": inventoryItemId,
      "available": quantity
    });

    final response = await http.post(url, headers: {
      'X-Shopify-Access-Token': accessToken,
      'Content-Type': 'application/json'
    }, body: body);

    return response;
  }
}

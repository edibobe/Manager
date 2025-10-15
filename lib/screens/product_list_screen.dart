import 'package:flutter/material.dart';
import '../services/shopify_service.dart';

class ProductListScreen extends StatefulWidget {
  final String shopDomain;
  final String accessToken;

  ProductListScreen({required this.shopDomain, required this.accessToken});

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late ShopifyService _shopifyService;
  List<dynamic> _products = [];
  bool _loading = true;

  Map<String, int> _modifiedQuantities = {};

  String? _locationId;

  @override
  void initState() {
    super.initState();
    _shopifyService = ShopifyService(
      shopDomain: widget.shopDomain,
      accessToken: widget.accessToken,
    );
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _loading = true);
    try {
      _locationId = await _shopifyService.getDefaultLocationId();
      final products = await _shopifyService.fetchProducts();

      setState(() {
        _products = products;
        _loading = false;

        for (var product in _products) {
          final variant = product['variants'][0];
          _modifiedQuantities[variant['id'].toString()] =
              variant['inventory_quantity'] ?? 0;
        }
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la încărcarea produselor: $e')));
    }
  }

  Future<void> _saveAll() async {
    if (_locationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nu am gasit locatie activa')));
      return;
    }

    bool anyError = false;
    List<String> errorProducts = [];

    for (var product in _products) {
      final variant = product['variants'][0];
      final id = variant['id'].toString();
      final inventoryItemId = variant['inventory_item_id'].toString();
      final newQuantity = _modifiedQuantities[id] ?? 0;

      try {
        await _shopifyService.updateInventoryQuantityByInventoryItem(
            inventoryItemId, newQuantity, _locationId!);
      } catch (e) {
        anyError = true;
        errorProducts.add(product['title']);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(anyError
            ? 'Unele cantități nu au fost actualizate: ${errorProducts.take(5).join(", ")}${errorProducts.length > 5 ? ", ..." : ""}'
            : 'Toate cantitățile au fost actualizate cu succes'),
      ),
    );

    _initData(); // reload produse
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Produse Shopify')),
      backgroundColor: Colors.white,
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _products.length,
              itemBuilder: (_, index) {
                final product = _products[index];
                final variant = product['variants'][0];
                final id = variant['id'].toString();
                final currentQuantity = _modifiedQuantities[id] ?? 0;

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(product['title'],
                        style: TextStyle(color: Colors.black)),
                    subtitle: TextField(
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Cantitate',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(
                          text: currentQuantity.toString()),
                      onChanged: (value) {
                        final intVal = int.tryParse(value) ?? 0;
                        _modifiedQuantities[id] = intVal;
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _saveAll,
              child: Text('Save All'),
            ),
          ),
        ],
      ),
    );
  }
}

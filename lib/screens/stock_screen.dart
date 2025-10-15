import 'package:flutter/material.dart';
import '../services/shopify_service.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({Key? key}) : super(key: key);

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final ShopifyService _shopifyService = ShopifyService();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductsFromShopify();
  }

  Future<void> _loadProductsFromShopify() async {
    try {
      final products = await _shopifyService.fetchProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Eroare la preluarea produselor: $e');
      setState(() => _isLoading = false);
    }
  }

  void _updateQuantity(int productIndex, int variantIndex, int newQty) {
    setState(() {
      _products[productIndex]['variants'][variantIndex]['inventory_quantity'] =
          newQty;
    });
  }

  Future<void> _saveAll() async {
    for (var product in _products) {
      for (var variant in product['variants']) {
        final qty = variant['inventory_quantity'];
        final inventoryItemId = variant['inventory_item_id'];
        final locationId = await _shopifyService.getDefaultLocationId();

        try {
          await _shopifyService.updateInventoryQuantityByInventoryItem(
            inventoryItemId,
            qty,
            locationId,
          );
        } catch (e) {
          print('Eroare la actualizarea ${variant['title']}: $e');
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stocurile au fost actualizate!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Stoc'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, productIndex) {
          final product = _products[productIndex];
          return ExpansionTile(
            title: Text(
              product['title'],
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            children: [
              for (var i = 0; i < product['variants'].length; i++)
                _buildVariantRow(productIndex, i),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
        child: FloatingActionButton.extended(
          onPressed: _saveAll,
          label: const Text('Save Stock'),
          icon: const Icon(Icons.save),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
    );
  }

  Widget _buildVariantRow(int productIndex, int variantIndex) {
    final variant = _products[productIndex]['variants'][variantIndex];
    final controller = TextEditingController(
      text: variant['inventory_quantity'].toString(),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              variant['title'],
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          SizedBox(
            width: 70,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color(0xFF1E1E1E),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final newQty = int.tryParse(value) ?? variant['inventory_quantity'];
                _updateQuantity(productIndex, variantIndex, newQty);
              },
            ),
          ),
          IconButton(
            onPressed: () {
              int newQty = variant['inventory_quantity'] - 1;
              if (newQty < 0) newQty = 0;
              _updateQuantity(productIndex, variantIndex, newQty);
            },
            icon: const Icon(Icons.remove, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              int newQty = variant['inventory_quantity'] + 1;
              _updateQuantity(productIndex, variantIndex, newQty);
            },
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

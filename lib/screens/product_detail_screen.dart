import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:shopify_manager/models/product.dart';
import 'package:shopify_manager/providers/product_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({required this.product, Key? key}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImage = 0;
  late TextEditingController _stockController;

  @override
  void initState() {
    super.initState();
    _stockController = TextEditingController(text: widget.product.inventory.toString());
  }

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }

  void _updateStockLocal(int newStock) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    // Actualizăm UI-ul
    setState(() {
      widget.product.inventory = newStock;
      _stockController.text = newStock.toString();
    });
    // Marcăm modificarea ca pending în provider (NU se trimite încă la Shopify)
    provider.updateLocalStock(widget.product.id, newStock);
  }

  Future<void> _saveAll() async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    try {
      await provider.saveAllChanges();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved to Shopify')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final provider = Provider.of<ProductProvider>(context);
    final hasPending = provider.hasPendingUpdates;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.title),
        actions: [
          if (hasPending)
            TextButton.icon(
              onPressed: provider.loading ? null : _saveAll,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carousel / PageView
            SizedBox(
              height: 250,
              child: product.images.isNotEmpty
                  ? Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  PageView(
                    onPageChanged: (index) {
                      setState(() => _currentImage = index);
                    },
                    children: product.images
                        .map((img) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        img,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ))
                        .toList(),
                  ),
                  if (product.images.length > 1)
                    Positioned(
                      bottom: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          product.images.length,
                              (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImage == index
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              )
                  : Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('No image')),
              ),
            ),
            const SizedBox(height: 16),

            // Preț
            Text(
              'Price: \$${product.price.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Stoc + butoane + edit manual (local-only)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stock: ${product.inventory}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: product.inventory <= 3 ? Colors.red : Colors.green,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (product.inventory > 0) {
                          _updateStockLocal(product.inventory - 1);
                        }
                      },
                    ),
                    SizedBox(
                      width: 56,
                      child: TextField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 6),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed != null && parsed >= 0) {
                            _updateStockLocal(parsed);
                          } else {
                            _stockController.text = product.inventory.toString();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _updateStockLocal(product.inventory + 1),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Hint UX
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blueGrey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasPending
                        ? 'You have unsaved changes. Tap SAVE to sync with Shopify.'
                        : 'No pending changes.',
                    style: TextStyle(color: hasPending ? Colors.orange[800] : Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      // Buton flotant Save (opțional, pe lângă cel din AppBar)
      floatingActionButton: hasPending
          ? FloatingActionButton.extended(
        onPressed: provider.loading ? null : _saveAll,
        icon: const Icon(Icons.cloud_upload),
        label: const Text('Save changes'),
      )
          : null,
    );
  }
}

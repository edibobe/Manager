import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // pentru HapticFeedback
import 'package:provider/provider.dart';
import 'package:shopify_manager/models/product.dart';
import 'package:shopify_manager/providers/product_provider.dart';
import 'package:shopify_manager/services/local_storage_service.dart';

class AromaCard extends StatefulWidget {
  final Product aroma;

  const AromaCard({Key? key, required this.aroma}) : super(key: key);

  @override
  State<AromaCard> createState() => _AromaCardState();
}

class _AromaCardState extends State<AromaCard> {
  late final ValueNotifier<int> _stockNotifier;
  late final TextEditingController _controller;
  bool _highlight = false; // ✨ pentru efect vizual temporar

  @override
  void initState() {
    super.initState();
    _stockNotifier = ValueNotifier<int>(widget.aroma.inventory);
    _controller = TextEditingController(text: widget.aroma.inventory.toString());
  }

  @override
  void dispose() {
    _stockNotifier.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _updateStock(int newStock) async {
    // vibrație tactilă scurtă
    HapticFeedback.selectionClick();

    _stockNotifier.value = newStock;
    _controller.text = newStock.toString();

    final provider = Provider.of<ProductProvider>(context, listen: false);

    // ✨ dacă revine la valoarea originală, eliminăm modificarea
    final originalStock = widget.aroma.inventory;
    if (newStock == originalStock) {
      provider.removePendingUpdate(widget.aroma.id);
    } else {
      provider.updateLocalStock(widget.aroma.id, newStock);
    }

    // salvează local
    await LocalStorageService.saveStock(widget.aroma.id, newStock);

    // ✨ highlight vizual temporar
    if (mounted) {
      setState(() => _highlight = true);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _highlight = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _highlight ? Colors.lightBlue[50] : Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _highlight ? Colors.blueAccent : Colors.grey[300]!,
          width: _highlight ? 1.8 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🔹 zona de drag vizibila, cu chenar
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E1E1E) // fundal gri-inchis in dark mode
                      : Colors.white,             // alb in light mode
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black12),
                ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: const Icon(
                Icons.drag_indicator,
                color: Colors.grey,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // imagine
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.aroma.images.isNotEmpty &&
                  widget.aroma.images.first.startsWith('http')
                  ? widget.aroma.images.first
                  : 'https://via.placeholder.com/60?text=No+Image',
              width: 65,
              height: 65,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, size: 32, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),

          // nume si counter
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.aroma.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                ValueListenableBuilder<int>(
                  valueListenable: _stockNotifier,
                  builder: (context, stock, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildButton('-', () {
                          if (stock > 0) _updateStock(stock - 1);
                        }),
                        const SizedBox(width: 10),

                        // 🔲 chenar pentru numar
                        SizedBox(
                          width: 60,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.blueAccent.withOpacity(0.4),
                                width: 1.3,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: TextField(
                              controller: _controller,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              onSubmitted: (val) {
                                final parsed = int.tryParse(val);
                                if (parsed != null) _updateStock(parsed);
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        _buildButton('+', () {
                          _updateStock(stock + 1);
                        }),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
      ),
    );
  }
}

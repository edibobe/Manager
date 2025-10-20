import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopify_manager/providers/order_provider.dart';
import 'package:shopify_manager/models/order.dart';

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({Key? key}) : super(key: key);

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  bool loading = true;
  bool expandMagazin = false;
  bool expandAlex = false;
  bool expandEdi = false;

  double totalMagazin = 0.0;
  double totalAlex = 0.0;
  double totalEdi = 0.0;

  double baniReali = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateRevenue();
  }

  Future<void> _calculateRevenue() async {
    setState(() => loading = true);

    final provider = Provider.of<OrderProvider>(context, listen: false);
    // ❌ Sterge: await provider.fetchOrders();
    // ✅ Pastreaza comenzile din memorie (modificate local)

    double shopifyTotal = 0.0;
    double alexTotal = 0.0;
    double ediTotal = 0.0;
    double profitReal = 0.0;

    for (final order in provider.orders) {
      // luam doar comenzile marcate ca incasate de utilizator
      if (order.status != 'incasata') continue;

      final total = order.totalPrice;
      final method = order.shippingMethod?.toLowerCase() ?? '';

      // === OLX ===
      if (method.contains('olx')) {
        if (method.contains('edi')) {
          ediTotal += _calcOlxRevenue(order);
        } else if (method.contains('alex')) {
          alexTotal += _calcOlxRevenue(order);
        }
        continue;
      }

      // === SHOPIFY ===
      shopifyTotal += total;

      if (method.contains('easybox')) {
        profitReal += _calcEasyboxProfit(order);
      }
    }

    setState(() {
      totalMagazin = shopifyTotal;
      totalAlex = alexTotal;
      totalEdi = ediTotal;
      baniReali = profitReal;
      loading = false;
    });
  }

  double _calcOlxRevenue(Order order) {
    int qty = 0;
    for (final item in order.lineItems) {
      qty += item.quantity;
    }
    return 60.0 * qty;
  }

  double _calcEasyboxProfit(Order order) {
    int qty = 0;
    for (final item in order.lineItems) {
      qty += item.quantity;
    }

    double deliveryBase = 17.99;
    double rambursFee = qty == 1
        ? 3.05
        : qty == 2
        ? 5.41
        : 3.05 + 2.36 * (qty - 1);

    double totalTransport = deliveryBase + rambursFee;
    final total = double.tryParse(order.totalPrice.toString()) ?? 0.0;
    return total - totalTransport;
  }

  Widget _buildSection({
    required String title,
    required double total,
    required Color color,
    required bool expanded,
    required VoidCallback onToggle,
    Widget? details,
  }) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1F1F1F)
                : const Color(0xFFF6F6F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.8), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "Total: ${total.toStringAsFixed(2)} RON",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: color,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
        if (expanded && details != null) details,
      ],
    );
  }

  Widget _buildMagazinDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2C2C2C)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.withOpacity(0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Bani reali",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Text(
            "${baniReali.toStringAsFixed(2)} RON",
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _calculateRevenue,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _buildSection(
            title: "Magazin",
            total: totalMagazin,
            color: Colors.green,
            expanded: expandMagazin,
            onToggle: () => setState(() => expandMagazin = !expandMagazin),
            details: _buildMagazinDetails(),
          ),
          _buildSection(
            title: "Alex",
            total: totalAlex,
            color: Colors.orangeAccent,
            expanded: expandAlex,
            onToggle: () => setState(() => expandAlex = !expandAlex),
          ),
          _buildSection(
            title: "Edi",
            total: totalEdi,
            color: Colors.blueAccent,
            expanded: expandEdi,
            onToggle: () => setState(() => expandEdi = !expandEdi),
          ),
        ],
      ),
    );
  }
}

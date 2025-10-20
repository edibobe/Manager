import 'package:flutter/material.dart';
import 'package:shopify_manager/models/order.dart';

class RevenueTab extends StatelessWidget {
  final List<Order> orders;

  const RevenueTab({Key? key, required this.orders}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = orders.fold<double>(
      0,
          (sum, order) => sum + order.totalPrice,
    );

    return Center(
      child: Text(
        'Total revenue: \$${total.toStringAsFixed(2)}',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}

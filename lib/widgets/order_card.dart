import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shopify_manager/models/order.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  OrderCard({required this.order});

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('paid')) return Colors.green;
    if (s.contains('pending')) return Colors.orange;
    if (s.contains('cancel')) return Colors.red;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat.yMd().add_jm().format(order.createdAt);
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        title: Text('Order #${order.id}', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${order.customerName}\nTotal: \$${order.total.toStringAsFixed(2)}\n$dateStr'),
        trailing: Text(order.status.toUpperCase(), style: TextStyle(color: _statusColor(order.status))),
      ),
    );
  }
}

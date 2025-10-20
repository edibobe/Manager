// lib/screens/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;
  OrderDetailScreen({required this.order});

  Widget _buildAddress(Map<String, dynamic>? a) {
    if (a == null) return Text('No address');
    final parts = <String>[];
    if (a['name'] != null) parts.add(a['name']);
    if (a['address1'] != null) parts.add(a['address1']);
    if (a['city'] != null) parts.add(a['city']);
    if (a['province'] != null) parts.add(a['province']);
    if (a['zip'] != null) parts.add(a['zip']);
    if (a['country'] != null) parts.add(a['country']);
    return Text(parts.join(', '));
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMd().add_jm().format(order.createdAt);

    return Scaffold(
      appBar: AppBar(title: Text('Order #${order.id}')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(order.customerName),
          if (order.email != null) Text('Email: ${order.email}'),
          if (order.phone != null) Text('Phone: ${order.phone}'),
          SizedBox(height: 12),

          Text('Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Financial: ${order.financialStatus ?? order.status}'),
          if (order.fulfillmentStatus != null) Text('Fulfillment: ${order.fulfillmentStatus}'),
          SizedBox(height: 12),

          Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('\$${order.totalPrice.toStringAsFixed(2)}'),
          SizedBox(height: 12),

          Text('Created at', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(date),
          SizedBox(height: 12),

          Text('Shipping address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          _buildAddress(order.shippingAddress),
          SizedBox(height: 12),

          Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          ...order.lineItems.map((li) => Card(
            margin: EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text(li.title),
              subtitle: Text('Qty: ${li.quantity}  •  \$${li.price.toStringAsFixed(2)}'),
            ),
          )),
        ]),
      ),
    );
  }
}

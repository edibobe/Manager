// lib/models/order.dart

class OrderLineItem {
  final String id;
  final String title;
  final int quantity;
  final double price;

  OrderLineItem({
    required this.id,
    required this.title,
    required this.quantity,
    required this.price,
  });

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    return OrderLineItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      quantity: (json['quantity'] ?? 0) is int
          ? json['quantity']
          : int.tryParse(json['quantity'].toString()) ?? 0,
      price: double.tryParse((json['price'] ?? '0').toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'quantity': quantity,
    'price': price,
  };
}

class Order {
  final String id;
  final String customerName;
  String status;
  final double totalPrice;
  final DateTime createdAt;
  final List<OrderLineItem> lineItems;
  final String? email;
  final String? phone;
  final Map<String, dynamic>? shippingAddress;
  final String? financialStatus;
  final String? fulfillmentStatus;
  String? shippingMethod;

  Order({
    required this.id,
    required this.customerName,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
    required this.lineItems,
    this.email,
    this.phone,
    this.shippingAddress,
    this.financialStatus,
    this.fulfillmentStatus,
    this.shippingMethod,
  });

  double get total => totalPrice;

  // 🧩 copyWith pentru actualizări parțiale
  Order copyWith({
    String? id,
    String? customerName,
    String? status,
    double? totalPrice,
    DateTime? createdAt,
    List<OrderLineItem>? lineItems,
    String? email,
    String? phone,
    Map<String, dynamic>? shippingAddress,
    String? financialStatus,
    String? fulfillmentStatus,
    String? shippingMethod,
  }) {
    return Order(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
      lineItems: lineItems ?? this.lineItems,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      financialStatus: financialStatus ?? this.financialStatus,
      fulfillmentStatus: fulfillmentStatus ?? this.fulfillmentStatus,
      shippingMethod: shippingMethod ?? this.shippingMethod,
    );
  }

  // 🏗 Factory constructor — mapăm datele de la Shopify
  factory Order.fromJson(Map<String, dynamic> json) {
    // === 1. Metoda de livrare ===
    String shippingMethod = '';
    try {
      if (json['shipping_lines'] != null &&
          (json['shipping_lines'] as List).isNotEmpty) {
        shippingMethod =
            json['shipping_lines'][0]['title']?.toString() ?? 'Necunoscut';
      }
    } catch (_) {
      shippingMethod = 'Necunoscut';
    }

    // === 2. Numele clientului ===
    String customerName = 'Unknown';
    try {
      if (json['customer'] != null) {
        final c = json['customer'];
        final first = c['first_name'] ?? '';
        final last = c['last_name'] ?? '';
        if (first.isNotEmpty || last.isNotEmpty) {
          customerName = '$first $last'.trim();
        } else if (c['email'] != null) {
          customerName = c['email'];
        }
      } else if (json['billing_address'] != null) {
        final b = json['billing_address'];
        customerName = (b['name'] ?? '') as String;
      }
    } catch (_) {}

    // === 3. Produsele ===
    final items = <OrderLineItem>[];
    try {
      if (json['line_items'] is List) {
        for (var li in json['line_items']) {
          items.add(OrderLineItem.fromJson(Map<String, dynamic>.from(li)));
        }
      }
    } catch (_) {}

    // === 4. Status ===
    String status =
    (json['financial_status'] ?? json['status'] ?? 'unknown').toString();
    status = status.toLowerCase();

    // === 5. Data comenzii ===
    DateTime created = DateTime.now();
    try {
      if (json['created_at'] != null) {
        created = DateTime.parse(json['created_at']);
      }
    } catch (_) {}

    // === 6. Total ===
    double total = 0;
    try {
      final rawTotal = json['total_price'] ??
          json['current_total_price'] ??
          json['subtotal_price'] ??
          json['total'] ??
          0;
      total = double.tryParse(rawTotal.toString()) ?? 0;
    } catch (_) {
      total = 0;
    }

    // === 7. Debug în consolă (doar la rulare) ===
    // ignore: avoid_print
    print(
        "[DEBUG] Comandă Shopify #${json['id']} - ${customerName} | Total: $total RON | Status: $status | Livrare: $shippingMethod");

    return Order(
      id: json['id']?.toString() ?? '',
      customerName: customerName,
      status: status,
      totalPrice: total,
      createdAt: created,
      lineItems: items,
      email: json['email'],
      phone: json['phone'],
      shippingAddress: json['shipping_address'] != null
          ? Map<String, dynamic>.from(json['shipping_address'])
          : null,
      financialStatus: json['financial_status']?.toString(),
      fulfillmentStatus: json['fulfillment_status']?.toString(),
      shippingMethod: shippingMethod,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'status': status,
      'totalPrice': totalPrice,
      'createdAt': createdAt.toIso8601String(),
      'line_items': lineItems.map((item) => item.toJson()).toList(),
      'email': email,
      'phone': phone,
      'shipping_address': shippingAddress,
      'financial_status': financialStatus,
      'fulfillment_status': fulfillmentStatus,
      'shipping_method': shippingMethod,
    };
  }
}

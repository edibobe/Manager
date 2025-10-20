import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shopify_manager/models/order.dart';
import 'package:shopify_manager/providers/order_provider.dart';
import 'package:shopify_manager/services/local_storage_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  Map<String, List<Order>> shopifyOrders = {};
  Map<String, List<Order>> olxOrders = {};
  bool loading = true;

  final Map<String, Color> statusColors = {
    'de_impachetat': Colors.redAccent,
    'impachetata': Colors.orangeAccent,
    'trimisa': Colors.amberAccent,
    'ridicata': Colors.blueAccent,
    'incasata': Colors.green,
    'retur': Colors.grey,
  };

  final Map<String, String> statusLabels = {
    'de_impachetat': 'De impachetat',
    'impachetata': 'Impachetata',
    'trimisa': 'Trimisa',
    'ridicata': 'Ridicata',
    'incasata': 'Incasata',
    'retur': 'Retur',
  };

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => loading = true);
    final provider = Provider.of<OrderProvider>(context, listen: false);
    await provider.fetchOrders();

    final byCourier = <String, List<Order>>{
      'Fan Curier': [],
      'Sameday EASYBOX': [],
    };

    for (final order in provider.orders) {
      final shipping = (order.shippingMethod ?? '').toLowerCase();

      // 🔹 conversie automată pentru statusurile inițiale
      final financial = (order.financialStatus ?? '').toLowerCase();
      final wasCanceled =
          order.status == 'canceled' ||
              financial == 'voided' ||
              financial == 'refunded' ||
              order.fulfillmentStatus == 'cancelled' ||
              order.toJson().containsKey('cancelled_at');

      if (wasCanceled) {
        order.status = 'retur';
      } else {
        final localStatus = await LocalStorageService.getOrderStatus(order.id);

        if (localStatus != null) {
          // păstrăm statusul salvat local
          order.status = localStatus;
        } else {
          // comenzile vechi = incasata, noile = de impachetat
          final created = order.createdAt;
          final threshold = DateTime.now().subtract(const Duration(days: 2));
          if (created.isBefore(threshold)) {
            order.status = 'incasata';
          } else {
            order.status = 'de_impachetat';
          }
        }
      }

      if (shipping.contains('fan')) {
        byCourier['Fan Curier']!.add(order);
      } else if (shipping.contains('sameday') || shipping.contains('easybox')) {
        byCourier['Sameday EASYBOX']!.add(order);
      }
    }

    // 🔹 Mock OLX orders
    olxOrders = {
      'Edi': [
        Order(
          id: 'olx-edi-1',
          customerName: 'Andrei Popescu',
          status: 'incasata',
          totalPrice: 120.00,
          createdAt: DateTime.now(),
          lineItems: [
            OrderLineItem(
              id: 'edi1',
              title: 'Bang King 85k - Peach Mango',
              quantity: 2,
              price: 60.00,
            ),
          ],
          phone: '0712345678',
        ),
      ],
      'Alex': [
        Order(
          id: 'olx-alex-1',
          customerName: 'Mihai Ionescu',
          status: 'de_impachetat',
          totalPrice: 60.00,
          createdAt: DateTime.now(),
          lineItems: [
            OrderLineItem(
              id: 'alex1',
              title: 'Bang King 50k - Blueberry Ice',
              quantity: 1,
              price: 60.00,
            ),
          ],
          phone: '0799123456',
        ),
      ],
    };

    setState(() {
      shopifyOrders = byCourier;
      loading = false;
    });
  }

  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    setState(() => order.status = newStatus);
    await LocalStorageService.saveOrderStatus(order.id, newStatus);
    final provider = Provider.of<OrderProvider>(context, listen: false);
    await provider.syncOrderStatus(order.id, newStatus);
  }

  Widget _buildOrderCard(Order order, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = statusColors[order.status] ?? Colors.grey;

    // 🔹 Calcul profit + transport
    double total = order.totalPrice;
    double profit = 0;
    double shippingCost = 0;
    int qty = order.lineItems.fold(0, (sum, item) => sum + item.quantity);
    final method = (order.shippingMethod ?? '').toLowerCase();

    if (method.contains('easybox')) {
      double rambursTax = qty == 1
          ? 3.05
          : qty == 2
          ? 5.41
          : 3.05 + (qty - 1) * 2.36;
      shippingCost = 17.99 + rambursTax;
      profit = total - shippingCost;
    } else if (method.contains('fan')) {
      if (qty == 1) {
        profit = 71.85;
      } else if (qty == 2) {
        profit = 130.23;
      } else {
        profit = 71.85 * qty - (qty - 1) * 13.47;
      }
      shippingCost = (total - profit).clamp(0, total);
    } else if (order.id.startsWith('olx')) {
      total = 60.0 * qty;
      shippingCost = 0;
      profit = total;
    } else {
      profit = total;
      shippingCost = 0;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Dropdown status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              border: Border.all(color: color, width: 1.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: statusLabels.containsKey(order.status)
                    ? order.status
                    : 'de_impachetat',
                icon: Icon(Icons.arrow_drop_down, color: color),
                dropdownColor: isDark ? const Color(0xFF2E2E2E) : Colors.white,
                items: statusLabels.entries.map((entry) {
                  final code = entry.key;
                  final label = entry.value;
                  return DropdownMenuItem<String>(
                    value: code,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: statusColors[code],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newStatus) {
                  if (newStatus != null) _updateOrderStatus(order, newStatus);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(order.customerName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              )),
          const SizedBox(height: 4),
          if (order.phone != null)
            Row(
              children: [
                Text("Telefon: ${order.phone}",
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    )),
                const SizedBox(width: 6),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.copy, size: 16, color: color),
                  tooltip: 'Copiaza numarul',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: order.phone ?? ""));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Numar copiat in clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          const SizedBox(height: 8),
          if (order.lineItems.isNotEmpty) ...[
            const Text("Produse:",
                style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            for (final item in order.lineItems)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 3),
                child: Text("- ${item.title} (x${item.quantity})",
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[300] : Colors.black87)),
              ),
          ],
          const SizedBox(height: 6),
          if (!order.id.startsWith('olx'))
            Text(
              "Total: ${total.toStringAsFixed(2)} RON (${profit.toStringAsFixed(2)} + ${shippingCost.toStringAsFixed(2)})",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color),
            )
          else
            Text(
              "Total: ${total.toStringAsFixed(2)} RON",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color),
            ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              icon:
              Icon(Icons.local_shipping_outlined, size: 18, color: color),
              label: Text("Vezi AWB", style: TextStyle(color: color)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor:
                  isDark ? const Color(0xFF2E2E2E) : Colors.white,
                  title: Text("AWB indisponibil",
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black)),
                  content: Text(
                    "Aceasta functionalitate va fi disponibila intr-o versiune viitoare.",
                    style: TextStyle(
                        color:
                        isDark ? Colors.white70 : Colors.black87),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("OK", style: TextStyle(color: color)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildBadges(Map<String, List<Order>> source) {
    int redCount = 0;     // de impachetat / impachetata
    int blueCount = 0;    // trimisa / ridicata
    int greenCount = 0;   // incasata
    int greyCount = 0;    // retur

    for (final orders in source.values) {
      for (final o in orders) {
        switch (o.status) {
          case 'de_impachetat':
          case 'impachetata':
            redCount++;
            break;
          case 'trimisa':
          case 'ridicata':
            blueCount++;
            break;
          case 'incasata':
            greenCount++;
            break;
          case 'retur':
            greyCount++;
            break;
        }
      }
    }

    final badges = <Widget>[];

    if (redCount > 0) {
      badges.add(_buildBadge(redCount.toString(), Colors.redAccent));
    }
    if (blueCount > 0) {
      if (badges.isNotEmpty) badges.add(const SizedBox(width: 6));
      badges.add(_buildBadge(blueCount.toString(), Colors.blueAccent));
    }
    if (greenCount > 0) {
      if (badges.isNotEmpty) badges.add(const SizedBox(width: 6));
      badges.add(_buildBadge(greenCount.toString(), Colors.green));
    }
    if (greyCount > 0) {
      if (badges.isNotEmpty) badges.add(const SizedBox(width: 6));
      badges.add(_buildBadge(greyCount.toString(), Colors.grey));
    }

    return Row(mainAxisSize: MainAxisSize.min, children: badges);
  }

  Widget _buildFloatingSection(String title, Map<String, List<Order>> source) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.5 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Positioned(
              right: 40,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildBadges(source),
              ),
            ),
          ],
        ),
        children: source.entries.map((entry) {
          final name = entry.key;
          final orders = entry.value;

          List<Order> active = [];
          List<Order> finished = [];

          for (int i = orders.length - 1; i >= 0; i--) {
            final o = orders[i];
            if (o.status == 'incasata' || o.status == 'retur') {
              finished.insert(0, o);
            } else {
              active = orders.sublist(0, i + 1);
              break;
            }
          }
          if (active.isEmpty && finished.isEmpty) active = orders;

          return ExpansionTile(
            title: Text(name,
                style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600)),
            children: [
              for (int i = 0; i < active.length; i++)
                _buildOrderCard(active[i], i),
              if (finished.isNotEmpty)
                ExpansionTile(
                  title: const Text("Finalizate",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  children: [
                    for (int i = 0; i < finished.length; i++)
                      _buildOrderCard(finished[i], i),
                  ],
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          _buildFloatingSection("Shopify", shopifyOrders),
          _buildFloatingSection("OLX", olxOrders),
        ],
      ),
    );
  }
}

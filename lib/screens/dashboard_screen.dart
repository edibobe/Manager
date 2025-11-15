import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:shopify_manager/screens/products_screen.dart';
import 'package:shopify_manager/screens/orders_screen.dart';
import 'package:shopify_manager/screens/revenue_screen.dart';
import 'package:shopify_manager/services/theme_service.dart';

// ✅ provider-ele (ca să nu mai dea eroarea "isn't a type")
import 'package:shopify_manager/providers/product_provider.dart';
import 'package:shopify_manager/providers/order_provider.dart';

// ✅ supa din main.dart
import 'package:shopify_manager/main.dart' show supa;
import 'package:shopify_manager/services/supabase_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final p = context.read<OrderProvider>();
    p.startRealtime();
    p.fetchOrders();
    _tabController = TabController(length: 3, vsync: this);

    // încărcăm datele inițiale după primul frame (ca să avem context/Providers)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        context.read<ProductProvider>().fetchProducts(),
        context.read<OrderProvider>().fetchOrders(),
      ]);

      try {
        final orders = context.read<OrderProvider>().orders;
        await SupabaseService.upsertOrders(orders);
        await context.read<OrderProvider>().fetchOrders();
        debugPrint('[Supabase] Upsert orders OK: ${orders.length}');
      } catch (e) {
        debugPrint('[Supabase] Upsert orders ERROR: $e');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    context.read<OrderProvider>().stopRealtime();
    super.dispose();
  }

  void _openSettings() {
    final themeService = Provider.of<ThemeService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    "Setari aplicatie",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Tema intunecata",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Switch(
                    value: themeService.isDarkMode,
                    activeColor: Theme.of(context).colorScheme.secondary,
                    onChanged: (_) => themeService.toggleTheme(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Schimba intre tema deschisa si intunecata. Preferinta este salvata local.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        titleSpacing: 16,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Shopify Manager',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings, size: 24),
              color: theme.colorScheme.primary,
              tooltip: 'Setari',
              onPressed: _openSettings,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: "Products"),
            Tab(text: "Orders"),
            Tab(text: "Revenue"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ProductsScreen(),
          OrdersScreen(),
          RevenueScreen(),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shopify_manager/models/product.dart';
import 'package:shopify_manager/providers/product_provider.dart';
import 'package:shopify_manager/services/local_storage_service.dart';
import 'package:shopify_manager/services/theme_service.dart';
import 'package:shopify_manager/data/aromas_data.dart';
import 'package:shopify_manager/widgets/aroma_card.dart';

enum ProductSortMode {
  nameAsc,
  nameDesc,
  stockAsc,
  stockDesc,
}

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  List<String> mainProducts = [
    'Bang King 50.000 puffs, 2 in 1',
    'Bang King 85.000 puffs, 3 in 1',
    'Fizzy Max III 60.000 puffs, 6 in 1',
  ];

  Map<String, List<Product>> groupedProducts = {};
  Map<String, bool> expanded = {};
  bool refreshing = false;
  bool saving = false;
  bool _showedResumeDialog = false;
  String searchQuery = "";

  late AnimationController _fabPulseController;

  ProductSortMode _sortMode = ProductSortMode.nameAsc;

  @override
  void initState() {
    super.initState();
    _fabPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);

    _loadGroupedProducts();
  }

  @override
  void dispose() {
    _fabPulseController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupedProducts() async {
    if (!mounted) return;

    setState(() => refreshing = true);
    final provider = Provider.of<ProductProvider>(context, listen: false);
    await provider.fetchProducts();

    final savedMainOrder = await LocalStorageService.getSavedMainProductOrder();
    if (savedMainOrder != null && savedMainOrder.isNotEmpty) {
      mainProducts = savedMainOrder;
    }

    final map = <String, List<Product>>{};
    for (final mainProduct in mainProducts) {
      final aromas = productAromas[mainProduct] ?? [];
      final all = <Product>[];

      for (final aromaName in aromas) {
        final match = provider.products.firstWhere(
              (p) => p.title.toLowerCase().contains(aromaName.toLowerCase()),
          orElse: () => Product(
            id: 'missing-$aromaName',
            title: aromaName,
            price: 0,
            inventory: 0,
            images: [],
          ),
        );

        final savedStock = await LocalStorageService.getSavedStock(match.id);
        if (savedStock != null) match.inventory = savedStock;
        all.add(match);
      }

      final savedAromaOrder =
      await LocalStorageService.getSavedAromaOrder(mainProduct);
      if (savedAromaOrder != null && savedAromaOrder.isNotEmpty) {
        all.sort((a, b) =>
            savedAromaOrder.indexOf(a.id).compareTo(savedAromaOrder.indexOf(b.id)));
      }

      map[mainProduct] = all;
      expanded[mainProduct] = false;
    }

    setState(() {
      groupedProducts = map;
      refreshing = false;
    });

    if (!_showedResumeDialog) {
      _showedResumeDialog = true;
      _checkForPendingLocalChanges();
    }
  }

  Future<void> _checkForPendingLocalChanges() async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final hasLocal = await LocalStorageService.hasLocalChanges();
    final hasDiff = await provider.hasChangesComparedToShopify();

    if (mounted && hasLocal && hasDiff) {
      await Future.delayed(const Duration(milliseconds: 400));
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Modificări nesalvate"),
          content: const Text(
              "Dorești să continui modificările locale din sesiunea anterioară?"),
          actions: [
            TextButton(
              child: const Text("Nu, încarcă stocul curent"),
              onPressed: () {
                Navigator.pop(ctx);
                LocalStorageService.clearLocalChanges();
                provider.fetchProducts();
              },
            ),
            TextButton(
              child: const Text("Da, continuă"),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    }
  }

  List<Product> _applySort(List<Product> products) {
    final sorted = List<Product>.from(products);

    switch (_sortMode) {
      case ProductSortMode.nameAsc:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case ProductSortMode.nameDesc:
        sorted.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case ProductSortMode.stockAsc:
        sorted.sort((a, b) => a.inventory.compareTo(b.inventory));
        break;
      case ProductSortMode.stockDesc:
        sorted.sort((a, b) => b.inventory.compareTo(a.inventory));
        break;
    }

    return sorted;
  }

  Future<void> _saveAllChanges() async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    setState(() => saving = true);

    final ok = await provider.saveAllChanges();

    if (ok) {
      await LocalStorageService.clearLocalChanges();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✔ Modificarile au fost salvate in Shopify'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠ Eroare la salvare. Modificarile locale au ramas memorate.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final filteredProducts = searchQuery.isEmpty
        ? mainProducts
        : mainProducts.where((mainProduct) {
      final aromas = groupedProducts[mainProduct] ?? [];
      final hasMatch = aromas.any(
              (a) => a.title.toLowerCase().contains(searchQuery.toLowerCase()));
      if (hasMatch) expanded[mainProduct] = true;
      return hasMatch;
    }).toList();

    return Scaffold(
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadGroupedProducts,
              child: ReorderableListView(
                onReorder: (oldIndex, newIndex) async {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = mainProducts.removeAt(oldIndex);
                    mainProducts.insert(newIndex, item);
                  });
                  await LocalStorageService.saveMainProductOrder(mainProducts);
                },
                children: [
                  for (final title in filteredProducts)
                    _buildMainProductCard(title),
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(
          right: 8,
          bottom: bottomInset > 0 ? bottomInset + 8 : 8,
        ),
        child: provider.hasPendingUpdates
            ? GestureDetector(
          onTap: saving
              ? null
              : () async {
            HapticFeedback.mediumImpact();
            await _saveAllChanges();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              color: saving ? Colors.grey : Colors.greenAccent[700],
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, 3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Text(
              saving ? "Saving..." : "Save Changes",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        )
            : null,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: const Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2, color: Colors.blueAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Products Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              PopupMenuButton<ProductSortMode>(
                tooltip: 'Sorteaza produsele',
                icon: const Icon(Icons.sort, color: Colors.blueAccent),
                onSelected: (mode) {
                  setState(() {
                    _sortMode = mode;
                  });
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(
                    value: ProductSortMode.nameAsc,
                    child: Text('Nume A-Z'),
                  ),
                  PopupMenuItem(
                    value: ProductSortMode.nameDesc,
                    child: Text('Nume Z-A'),
                  ),
                  PopupMenuItem(
                    value: ProductSortMode.stockAsc,
                    child: Text('Stoc crescator'),
                  ),
                  PopupMenuItem(
                    value: ProductSortMode.stockDesc,
                    child: Text('Stoc descrescator'),
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Reincarca produsele',
                icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                onPressed: _loadGroupedProducts,
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            decoration: InputDecoration(
              hintText: 'Cauta aroma...',
              prefixIcon: const Icon(Icons.search),
              contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary, width: 1.4),
              ),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainProductCard(String title) {
    final aromas = groupedProducts[title] ?? [];
    final isExpanded = expanded[title] ?? false;

    List<Product> visibleAromas = searchQuery.isEmpty
        ? aromas
        : aromas
        .where((a) => a.title.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    visibleAromas = _applySort(visibleAromas);

    return Container(
      key: ValueKey(title),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                buildDragHandleMini(),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.expand_more, size: 26),
                  ),
                  onPressed: () {
                    setState(() {
                      expanded[title] = !isExpanded;
                    });
                  },
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: (isExpanded || searchQuery.isNotEmpty)
                ? Column(
              children: visibleAromas
                  .map((aroma) => AromaCard(
                key: ValueKey('${title}_${aroma.id}'),
                aroma: aroma,
              ))
                  .toList(),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget buildDragHandleMini() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
              (_) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              2,
                  (_) => Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

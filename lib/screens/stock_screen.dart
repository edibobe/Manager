import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/shopify_service.dart';

class StockScreen extends StatefulWidget {
  final String shopDomain;
  final String accessToken;

  StockScreen({required this.shopDomain, required this.accessToken});

  @override
  _StockScreenState createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  late ShopifyService _shopifyService;

  final Map<String, List<String>> _categories = {
    'Bang King 50K, 2in1': [
      'Watermelon ice / Blueberry mint',
      'Watermelon ice / Blueberry cherry',
      'Blueberry ice / Peach mango watermelon',
      'Blueberry ice / Peach ice',
      'Blueberry raspberry / Mixed berry',
      'Blueberry raspberry / Grape ice',
      'Redbull / Strawberry banana',
      'Redbull / Blubbery watermelon',
      'Strawberry mango / Watermelon bubble gum',
      'Strawberry mango / Strawberry kiwi',
      'Strawberry watermelon / Black dragon ice',
      'Strawberry watermelon / Kiwi passion fruit guava',
    ],
    'Bang King 85K, 3in1': [
      'Watermelon & Red Bull & Strawberry Kiwi',
      'Lemon Lime & Strawberry Watermelon & Blueberry Ice',
      'Strawberry Banana & Raspberry Watermelon & Pink Lemonade',
      'Blue Razz Cherry & Cool Mint & Peach Mango',
      'Tropical Fruit & Strawberry Watermelon & Lemon Peach',
      'Pineapple Coconut & Strawberry Banana & Blue Razz',
      'Strawberry Watermelon & Triple Melon & Strawberry Ice',
      'Mixed Fruits & Mango Peach & Grape Ice',
      'Strawberry Vanilla Coke & Peach Ice & Black Dragon Ice',
      'Lush Ice & Kiwi Passion Fruit Guava & Straw Mango',
      'Strawberry Watermelon & Watermelon & Blue Razz Ice',
      'Berry Lemonade & Strawberry Red Bull & Strawberry Pomp',
      'Double Apple & Fruity Fusion & Pineapple Ice',
      'Cola Ice & Mr Blue & Cherry Cola',
      'Strawberry Donut & Banana Ice & Love66',
      'Ice Tea Lemon Ice & Mango On Ice & Lychee Ice',
    ],
    'Fizzy Max 60K, 6in1': [
      'Strawberry Raspberry & Mango Peach & Blueberry Watermelon',
      'Mixed Berry & Kiwi Passion Fruit Guava & Strawberry Watermelon',
      'Blueberry Raspberry & Triple Melon & Strawberry Ice',
      'Strawberry Dragon Fruit & Red Bull & Raspberry Watermelon',
      'Strawberry Kiwi & Blueberry Ice & Watermelon Ice',
      'Blueberry Ice & Fizzy Cherry & Raspberry Lemon',
      'Watermelon Ice & Strawberry Vanilla Coke & Mixed',
      'Strawberry Grape & Blueberry Coconut & Peach Lemon',
      'Blue Razz Ice & Strawberry Kiwi & Sour Pineapple Orange',
      'Strawberry Watermelon & Lemon Lime & Blueberry Coconut',
    ],
  };

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _invalid = {};
  Map<String, String> _localValues = {};
  List<dynamic> _shopifyProducts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _shopifyService = ShopifyService(
        shopDomain: widget.shopDomain, accessToken: widget.accessToken);
    _initAll();
  }

  Future<void> _initAll() async {
    setState(() => _loading = true);
    _prepareControllers();
    await _maybeShowLocalChoice();
    setState(() => _loading = false);
  }

  void _prepareControllers() {
    for (final cat in _categories.keys) {
      for (final aroma in _categories[cat]!) {
        final key = _makeKey(cat, aroma);
        if (!_controllers.containsKey(key)) {
          final c = TextEditingController(text: '0');
          c.addListener(() {
            _localValues[key] = c.text;
            _saveLocalInstant();
          });
          _controllers[key] = c;
          _invalid[key] = false;
        }
      }
    }
  }

  String _makeKey(String cat, String aroma) => '$cat|$aroma';

  Future<void> _saveLocalInstant() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_stock_v1', json.encode(_localValues));
  }

  Future<void> _maybeShowLocalChoice() async {
    final prefs = await SharedPreferences.getInstance();
    final localJson = prefs.getString('local_stock_v1');
    await _loadFromShopify();
    if (localJson == null) return;

    final Map<String, String> localMap = Map<String, String>.from(json.decode(localJson));

    bool hasDiff = false;
    for (final key in localMap.keys) {
      if (localMap[key] != _controllers[key]?.text) {
        hasDiff = true;
        break;
      }
    }
    if (!hasDiff) return;

    final useLocal = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Date locale gasite', style: TextStyle(color: Colors.black)),
        content: Text('Exista stocuri salvate local. Ce vrei sa folosesti?',
            style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Deschide stocul curent', style: TextStyle(color: Colors.blue))),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Continua modificarile', style: TextStyle(color: Colors.blue))),
        ],
      ),
    );

    if (useLocal == true) {
      _localValues = localMap;
      for (final entry in _localValues.entries) {
        final k = entry.key;
        if (_controllers.containsKey(k)) _controllers[k]!.text = entry.value;
      }
    } else {
      await prefs.remove('local_stock_v1');
    }
  }

  Future<void> _loadFromShopify() async {
    try {
      _shopifyProducts = await _shopifyService.fetchProducts();
      final Map<String, int> shopifyMap = {};
      for (final p in _shopifyProducts) {
        final title = (p['title'] ?? '').toString().toLowerCase();
        final variants = p['variants'] as List<dynamic>;
        if (variants.isNotEmpty) {
          final inventory = variants[0]['inventory_quantity'] ?? 0;
          for (final cat in _categories.keys) {
            for (final aroma in _categories[cat]!) {
              if (title.contains(aroma.toLowerCase())) {
                shopifyMap[aroma] = inventory;
              }
            }
          }
        }
      }
      for (final cat in _categories.keys) {
        for (final aroma in _categories[cat]!) {
          final key = _makeKey(cat, aroma);
          _controllers[key]!.text = shopifyMap[aroma]?.toString() ?? '0';
        }
      }
    } catch (e) {
      print('Eroare la incarcarea Shopify: $e');
    }
  }

  void _increment(String key) {
    final n = int.tryParse(_controllers[key]!.text.trim()) ?? 0;
    _controllers[key]!.text = (n + 1).toString();
  }

  void _decrement(String key) {
    final n = int.tryParse(_controllers[key]!.text.trim()) ?? 0;
    _controllers[key]!.text = (n - 1 < 0 ? 0 : n - 1).toString();
  }

  Future<void> _saveAll() async {
    setState(() {});
    final Map<String, int> toSend = {};
    final List<String> invalids = [];
    _localValues = {};

    for (final cat in _categories.keys) {
      for (final aroma in _categories[cat]!) {
        final key = _makeKey(cat, aroma);
        final text = _controllers[key]!.text.trim();
        _localValues[key] = text;
        final val = int.tryParse(text);
        if (val == null) {
          _invalid[key] = true;
          invalids.add(aroma);
        } else {
          _invalid[key] = false;
          toSend[key] = val;
        }
      }
    }

    await _saveLocalInstant();

    if (invalids.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Din cauza anumitor valori nu se poate salva stocul"),
        duration: Duration(seconds: 3),
      ));
      setState(() {});
      return;
    }

    String? locationId;
    try {
      locationId = await _shopifyService.getDefaultLocationId();
    } catch (e) {
      print('Eroare la preluare locationId: $e');
    }

    bool anySent = false;
    for (final cat in _categories.keys) {
      for (final aroma in _categories[cat]!) {
        final key = _makeKey(cat, aroma);
        final qty = toSend[key]!;
        final shopProduct =
        _shopifyProducts.firstWhere((p) => (p['title'] ?? '') == aroma, orElse: () => null);
        if (shopProduct == null) continue;
        final variants = shopProduct['variants'] as List<dynamic>;
        if (variants.isEmpty) continue;
        final inventoryItemId = variants[0]['inventory_item_id']?.toString();
        if (inventoryItemId == null) continue;

        try {
          if (locationId != null) {
            final resp = await _shopifyService.updateInventoryQuantityByInventoryItem(
                inventoryItemId, qty, locationId);
            if (resp.statusCode == 200) anySent = true;
          }
        } catch (e) {
          print('Eroare la update aroma $aroma : $e');
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(anySent
          ? "Stocul a fost updatat cu succes"
          : "Din cauza anumitor valori nu se poate salva stocul"),
      duration: Duration(seconds: 3),
    ));
    setState(() {});
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  Widget _buildAromaRow(String cat, String aroma) {
    final key = _makeKey(cat, aroma);
    final ctrl = _controllers[key]!;
    final isInvalid = _invalid[key] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(aroma, style: TextStyle(color: Colors.white))),
          Container(
            width: 100,
            padding: EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isInvalid ? Colors.red : Colors.transparent),
            ),
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                isDense: true,
                hintText: '0',
                hintStyle: TextStyle(color: Colors.white30),
                border: InputBorder.none,
              ),
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 42,
            height: 36,
            child: ElevatedButton(
              onPressed: () => _increment(key),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: Text('+', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(width: 6),
          SizedBox(
            width: 42,
            height: 36,
            child: ElevatedButton(
              onPressed: () => _decrement(key),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: Text('-', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('STOC', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: _categories.keys.map((cat) {
            return ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              collapsedBackgroundColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              title: Text(cat,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              children: _categories[cat]!
                  .map((a) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _buildAromaRow(cat, a),
              ))
                  .toList(),
            );
          }).toList(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saveAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Save Stock', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}

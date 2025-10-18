import 'package:flutter/material.dart';
import '../data/database/app_database.dart';
import '../data/dao/stock_dao.dart';
import 'package:drift/drift.dart' show Value;

class StockScreen extends StatefulWidget {
  const StockScreen({Key? key}) : super(key: key);

  @override
  _StockScreenState createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  late AppDatabase _db;
  late StockDao _stockDao;

  final Map<String, TextEditingController> _controllers = {};
  final List<String> _categories = ['Fruit', 'Dessert', 'Mint'];
  final List<String> _flavors = ['Apple', 'Chocolate', 'Vanilla', 'Mint'];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _db = AppDatabase();
    _stockDao = _db.stockDao;

    _initControllers();
    await _loadLocalFromDb();

    setState(() {
      _loading = false;
    });
  }

  void _initControllers() {
    for (var category in _categories) {
      for (var flavor in _flavors) {
        final key = _makeKey(category, flavor);
        _controllers[key] = TextEditingController(text: '0');
      }
    }
  }

  String _makeKey(String category, String flavor) => '$category-$flavor';

  Future<void> _loadLocalFromDb() async {
    final items = await _stockDao.getAllItems();
    for (final item in items) {
      final key = _makeKey(item.category, item.flavor);
      if (_controllers.containsKey(key)) {
        _controllers[key]!.text = item.quantity.toString();
      }
    }
  }

  void _saveToDb(String category, String flavor, int qty) {
    final item = StockItemsCompanion.insert(
      category: category,
      flavor: flavor,
      quantity: qty,
    );
    _stockDao.insertItem(item);
  }

  void _increment(String category, String flavor) {
    final key = _makeKey(category, flavor);
    final current = int.tryParse(_controllers[key]!.text.trim()) ?? 0;
    final newValue = current + 1;
    _controllers[key]!.text = newValue.toString();
    _saveToDb(category, flavor, newValue);
  }

  void _decrement(String category, String flavor) {
    final key = _makeKey(category, flavor);
    final current = int.tryParse(_controllers[key]!.text.trim()) ?? 0;
    final newValue = (current - 1 < 0) ? 0 : current - 1;
    _controllers[key]!.text = newValue.toString();
    _saveToDb(category, flavor, newValue);
  }

  void _onManualChange(String category, String flavor, String value) {
    final parsed = int.tryParse(value);
    if (parsed != null) {
      _saveToDb(category, flavor, parsed);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _db.close();
    super.dispose();
  }

  Future<void> _onSaveStock() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stock saved to Shopify (mocked)')),
    );
    // aici, ulterior: trimite la Shopify via API
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Manager'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var category in _categories) ...[
            Text(
              category,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (var flavor in _flavors)
              _buildStockRow(category, flavor),
            const SizedBox(height: 24),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onSaveStock,
        label: const Text('Save Stock'),
        icon: const Icon(Icons.cloud_upload),
      ),
    );
  }

  Widget _buildStockRow(String category, String flavor) {
    final key = _makeKey(category, flavor);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(flavor)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => _decrement(category, flavor),
          ),
          Expanded(
            child: TextField(
              controller: _controllers[key],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (val) => _onManualChange(category, flavor, val),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 4),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _increment(category, flavor),
          ),
        ],
      ),
    );
  }
}

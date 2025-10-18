import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/stock_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env"); // sau ".env" dacă folosești direct .env în root
  final shopDomain = dotenv.env['SHOP_URL'];
  final accessToken = dotenv.env['ACCESS_TOKEN'];

  if (shopDomain == null || accessToken == null) {
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'SHOP_URL sau ACCESS_TOKEN lipsesc in .env',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    ));
    return;
  }

  runApp(ShopifyStockApp(shopDomain: shopDomain, accessToken: accessToken));
}

class ShopifyStockApp extends StatelessWidget {
  final String shopDomain;
  final String accessToken;

  ShopifyStockApp({required this.shopDomain, required this.accessToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopify Stock',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      home: const StockScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/stock_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Încarcă variabilele din .env
  await dotenv.load(fileName: "assets/.env");

  final shopDomain = dotenv.env['SHOP_URL'];
  final accessToken = dotenv.env['ACCESS_TOKEN'];

  if (shopDomain == null || accessToken == null) {
    runApp(const EnvErrorApp());
    return;
  }

  runApp(ShopifyManagerApp(
    shopDomain: shopDomain,
    accessToken: accessToken,
  ));
}

class EnvErrorApp extends StatelessWidget {
  const EnvErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: Text(
            'SHOP_URL sau ACCESS_TOKEN lipsesc în .env',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class ShopifyManagerApp extends StatelessWidget {
  final String shopDomain;
  final String accessToken;

  const ShopifyManagerApp({
    super.key,
    required this.shopDomain,
    required this.accessToken,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopify Manager',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: StockScreen(
        shopDomain: shopDomain,
        accessToken: accessToken,
      ),
    );
  }
}

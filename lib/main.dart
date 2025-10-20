import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shopify_manager/providers/product_provider.dart';
import 'package:shopify_manager/providers/order_provider.dart';
import 'package:shopify_manager/services/shopify_api.dart';
import 'package:shopify_manager/screens/dashboard_screen.dart';
import 'package:shopify_manager/services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");

  final shopifyDomain = dotenv.env['SHOPIFY_DOMAIN']!;
  final accessToken = dotenv.env['SHOPIFY_ACCESS_TOKEN']!;
  final api = ShopifyApi(domain: shopifyDomain, accessToken: accessToken);

  runApp(MyApp(api: api));
}

class MyApp extends StatelessWidget {
  final ShopifyApi api;
  const MyApp({Key? key, required this.api}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider(api: api)),
        ChangeNotifierProvider(create: (_) => OrderProvider(api: api)),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Shopify Manager',
            theme: themeService.currentTheme,
            home: const DashboardScreen(),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/shopify_api.dart';
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'services/theme_service.dart';
import 'screens/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) .env
  await dotenv.load(fileName: 'assets/.env');

  // 2) Supabase (fără authOptions care îți dădeau eroare)
  final supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final supabaseAnon = dotenv.env['SUPABASE_ANON_KEY']!;
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnon,
  );

  // 3) Shopify API
  final shopifyDomain = dotenv.env['SHOPIFY_DOMAIN']!;
  final accessToken = dotenv.env['SHOPIFY_ACCESS_TOKEN']!;
  final api = ShopifyApi(domain: shopifyDomain, accessToken: accessToken);

  runApp(MyApp(api: api));
}

// helper global (pt. acces rapid în alte fișiere)
final supa = Supabase.instance.client;

class MyApp extends StatelessWidget {
  final ShopifyApi api;
  const MyApp({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => ProductProvider(api: api)),
        ChangeNotifierProvider(create: (_) => OrderProvider(api: api)),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Shopify Manager',
            theme: ThemeData(
              colorSchemeSeed: Colors.blue,
              brightness: Brightness.light,
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorSchemeSeed: Colors.blue,
              brightness: Brightness.dark,
              useMaterial3: true,
            ),
            themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const DashboardScreen(),
          );
        },
      ),
    );
  }
}

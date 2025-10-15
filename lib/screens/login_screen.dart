import 'package:flutter/material.dart';
import '../screens/product_list_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _shopDomainController = TextEditingController();
  final _accessTokenController = TextEditingController();

  void _login() {
    final shopDomain = _shopDomainController.text;
    final accessToken = _accessTokenController.text;

    if (shopDomain.isNotEmpty && accessToken.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductListScreen(
            shopDomain: shopDomain,
            accessToken: accessToken,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Introduce shop domain și access token')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Shopify Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _shopDomainController,
              decoration: InputDecoration(labelText: 'Shop Domain (ex: myshop.myshopify.com)'),
            ),
            TextField(
              controller: _accessTokenController,
              decoration: InputDecoration(labelText: 'Access Token'),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: Text('Login')),
          ],
        ),
      ),
    );
  }
}

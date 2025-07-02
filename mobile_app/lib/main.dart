import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/map_screen.dart';

void main() {
  runApp(SupMapApp());
}

class SupMapApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'SUPMAP',
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => LoginPage(),
          '/map': (context) => MapScreen(),
        },
      ),
    );
  }
}

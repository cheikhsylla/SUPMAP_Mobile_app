import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';
import 'home_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Center(
        child: auth.user != null
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: () async {
                  try {
                    print("🔵 Connexion via AuthService...");
                    await auth.login();
                    print("🟢 Redirection vers HomePage...");
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                    );
                  } catch (e) {
                    print("🔴 Erreur de connexion : $e");

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur Auth0 : $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Se connecter avec Auth0'),
              ),
      ),
    );
  }
}

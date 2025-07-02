import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      body: Center(
        child: auth.user == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Session expirée'),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    child: const Text('Retour à la connexion'),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Email : ${auth.user?.email ?? "inconnu"}'),
                  const SizedBox(height: 10),
                  Text('Rôle : ${auth.role ?? "chargement..."}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Déconnexion'),
                          content: const Text('Voulez-vous vous déconnecter ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Non'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Oui'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed ?? false) {
                        await auth.logout();
                        Navigator.pushReplacementNamed(context, '/');
                      }
                    },
                    child: const Text('Déconnexion'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/map');
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Voir la carte'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

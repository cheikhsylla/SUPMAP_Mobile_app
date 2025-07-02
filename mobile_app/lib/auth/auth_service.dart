import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AuthService with ChangeNotifier {
  final _auth0 = Auth0(
    'dev-t3o827zzz25i55hk.us.auth0.com',
    'q15Bo7VPPJxAXpjjpn7xdpYxyAfPcDVv',
  );

  Credentials? _credentials;
  UserProfile? _user;
  String? _role;

  UserProfile? get user => _user;
  String? get role => _role;
  bool get isLoggedIn => _credentials != null;

  Future<void> login() async {
    try {
      _credentials = await _auth0
          .webAuthentication(scheme: 'com.supmap.mobile')
          .login(
            redirectUrl: 'com.supmap.mobile://login-callback',
            audience: 'https://supmap/api',
            parameters: {'scope': 'openid profile email'},
          );

      print("✅Connexion réussie !");
      print("🪪 Token : ${_credentials?.idToken}");
      print("👤 Utilisateur : ${_credentials?.user?.name}");
      _user = _credentials?.user;

      await loadUserMetadata();
      await sendIdTokenToBackend();
      notifyListeners();
    } catch (e) {
      print('❌ Login error: $e');
      rethrow;
    }
  }

  Future<void> fetchUserRole() async {
    await loadUserMetadata();
  }

  Future<void> logout() async {
    try {
      final logoutUrl =
          Uri.https('dev-t3o827zzz25i55hk.us.auth0.com', '/v2/logout', {
            'client_id': 'q15Bo7VPPJxAXpjjpn7xdpYxyAfPcDVv',
            'returnTo': 'com.supmap.mobile://login-callback',
          });

      if (await canLaunchUrl(logoutUrl)) {
        await launchUrl(logoutUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Impossible d\'ouvrir l URL de déconnexion.';
      }

      _credentials = null;
      _user = null;
      _role = null;
      notifyListeners();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  Future<void> loadUserMetadata() async {
    if (_credentials == null) return;
    final idToken = _credentials!.idToken;
    final decoded = parseJwt(idToken);
    _role = decoded['https://supmap/roles']?.first ?? 'utilisateur';
    notifyListeners();
  }

  Future<void> sendIdTokenToBackend() async {
    if (_credentials == null) return;

    final idToken = _credentials!.idToken;
    print("📤 Envoi du token au backend : $idToken");

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8001/auth/verify-auth0'),
        body: {'id_token': idToken},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
          '✅ Backend verified. User: ${data['email']} | Role: ${data['role']}',
        );
      } else {
        print(
          '❌ Backend verification failed: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print("❌ Exception lors de la communication avec le backend : $e");
    }
  }

  Map<String, dynamic> parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Invalid JWT');

    final payload = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(payload));
    return json.decode(decoded);
  }
}

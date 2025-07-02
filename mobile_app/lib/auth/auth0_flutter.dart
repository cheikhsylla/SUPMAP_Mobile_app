import 'package:auth0_flutter/auth0_flutter.dart';

final auth0 = Auth0(
  'dev-bm0sid7ybtowbw6r.us.auth0.com',
  '4TmEgsz8unjOFhZBLveyMgilp3bSalva',
);

Future<Credentials?> loginWithAuth0() async {
  try {
    final credentials = await auth0.webAuthentication(
      scheme: 'com.supmap.mobile',
    ).login(
      redirectUrl: 'com.supmap.mobile://login-callback',
      audience: 'https://dev-bm0sid7ybtowbw6r.us.auth0.com/api/v2/',
      scopes: {'openid', 'profile', 'email'},
    );
    return credentials;
  } catch (e) {
    print('Erreur login : $e');
    return null;
  }
}

Future<void> logoutFromAuth0() async {
  try {
    await auth0.webAuthentication(
      scheme: 'com.supmap.mobile',
    ).logout(
      returnTo: 'com.supmap.mobile://login-callback',
    );
  } catch (e) {
    print('Erreur logout : $e');
  }
}
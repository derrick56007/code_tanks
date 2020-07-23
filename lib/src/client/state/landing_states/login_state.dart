import 'dart:async';
import 'dart:html';

import '../state.dart';

class LoginState extends State {
  final InputElement loginUsernameEl = querySelector('#login-username');

  StreamSubscription submitSub;

  LoginState() : super(querySelector('#login-card'));

  @override
  void show() {
    stateElement.style.display = '';

    loginUsernameEl
      ..autofocus = true
      ..select();

    submitSub = window.onKeyPress.listen((KeyboardEvent e) {
      if (e.keyCode == KeyCode.ENTER) {
        submitLogin();
      }
    });
  }

  @override
  void hide() {
    stateElement.style.display = 'none';
    submitSub?.cancel();
  }

  void submitLogin() {
    final username = loginUsernameEl.value.trim();

    if (username.isEmpty) {
      print('Not a valid username');
      return;
    }
    final InputElement loginPassword = querySelector('#login-password');

    final password = loginPassword.value.trim();

    if (password.isEmpty) {
      print('Not a valid password');
    }

    final loginInfo = {'username': username, 'password': password};

    print('attempting login');
    client.send('login', loginInfo);
  }

  void _loginSuccessful(_) {
    print('successfully logged in');

    stateManager.pushState('play');
  }

  void _logoutSuccessful(_) {
    stateManager.pushState('login');
  }

  @override
  void init() {
    client //
      ..on('login_successful', _loginSuccessful)
      ..on('logout_successful', _logoutSuccessful);

    querySelector('#login-btn').onClick.listen((_) {
      submitLogin();
    });

    querySelector('#sign-up-btn').onClick.listen((_) => stateManager.pushState('register'));
  }
}

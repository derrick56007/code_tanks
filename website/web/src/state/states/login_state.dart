import 'dart:async';
import 'dart:html';

import '../../client_web_socket/client_websocket.dart';
import '../state.dart';
import '../state_manager.dart';

class LoginState extends State {
  final Element loginCard = querySelector('#login-card');

  final InputElement loginUsernameEl = querySelector('#login-username');
  final InputElement loginPassword = document.querySelector('#login-password');
  final Element loginBtn = querySelector('#login-btn');

  StreamSubscription submitSub;

  LoginState(ClientWebSocket client) : super(client) {
    client.onClose.listen(_logoutSuccessful);

    client
      ..on('login_successful', _loginSuccessful)
      ..on('logout_successful', _logoutSuccessful);

    loginBtn.onClick.listen((_) {
      loginBtn.blur();
      submitLogin();
    });

    querySelector('#sign-up-btn')
        .onClick
        .listen((_) => StateManager.shared.pushState('register'));
  }

  @override
  void show() {
    loginCard.style.display = '';

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
    loginCard.style.display = 'none';
    submitSub?.cancel();
  }

  void submitLogin() {
    if (!client.isConnected()) {
      print('Not connected');
      return;
    }

    final username = loginUsernameEl.value.trim();

    if (username.isEmpty) {
      print('Not a valid username');
      return;
    }

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

    StateManager.shared.pushState('play');
  }

  void _logoutSuccessful(_) {
    StateManager.shared.pushState('login');

    querySelector('#friends-list').children.clear();
  }
}

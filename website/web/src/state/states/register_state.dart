import 'dart:async';
import 'dart:html';

import '../../client_web_socket/client_websocket.dart';
import '../state.dart';
import '../state_manager.dart';

class RegisterState extends State {
  final Element registerCard = querySelector('#register-card');

  final InputElement registerUsernameEl = querySelector('#register-username');
  final InputElement registerPassword =
      document.querySelector('#register-password');
  final InputElement registerPasswordConfirm =
      document.querySelector('#register-password-confirm');

  final registerBtn = querySelector('#register-btn');

  StreamSubscription submitSub;

  RegisterState(ClientWebSocket client) : super(client) {
    registerBtn.onClick.listen((_) {
      registerBtn.blur();
      submitRegister();
    });

    querySelector('#sign-in-btn')
        .onClick
        .listen((_) => StateManager.shared.pushState('login'));

    client
      ..on('register_successful', _registerSuccessful)
      ..on('register_failure', _registerFailure);
  }

  @override
  void show() {
    registerCard.style.display = '';

    registerUsernameEl
      ..autofocus = true
      ..select();

    submitSub = window.onKeyPress.listen((KeyboardEvent e) {
      if (e.keyCode == KeyCode.ENTER) {
        submitRegister();
      }
    });
  }

  @override
  void hide() {
    registerCard.style.display = 'none';
    submitSub?.cancel();
  }

  void submitRegister() {
    if (!client.isConnected()) {
      print('Not connected');
      return;
    }

    final username = registerUsernameEl.value.trim();
    final password = registerPassword.value.trim();

    if (username.isEmpty || password.isEmpty) {
      print('Not a valid username/password');
      return;
    }

    final passwordConfirm = registerPasswordConfirm.value.trim();

    if (password != passwordConfirm) {
      print('Passwords don\'t match');
      return;
    }

    final loginInfo = {'username': username, 'password': password};

    client.send('register', loginInfo);
  }

  void _registerSuccessful(_) {
    print('register successful');

    StateManager.shared.pushState('login');
  }

  void _registerFailure(data) {
    print('register failure = $data');
  }
}

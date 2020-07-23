import 'dart:async';
import 'dart:html';

import '../state.dart';

class RegisterState extends State {
  final InputElement registerUsernameEl = querySelector('#register-username');

  StreamSubscription submitSub;

  RegisterState() : super(querySelector('#register-card'));

  @override
  void show() {
    stateElement.style.display = '';

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
    stateElement.style.display = 'none';
    submitSub?.cancel();
  }

  void submitRegister() {
    final InputElement registerPassword = document.querySelector('#register-password');
    final InputElement registerPasswordConfirm = document.querySelector('#register-password-confirm');

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

    stateManager.pushState('login');
  }

  void _registerFailure(data) {
    print('register failure = $data');
  }

  @override
  void init() {
    querySelector('#register-btn').onClick.listen((_) {
      submitRegister();
    });

    querySelector('#sign-in-btn').onClick.listen((_) => stateManager.pushState('login'));

    client //
      ..on('register_successful', _registerSuccessful)
      ..on('register_failure', _registerFailure);
  }
}

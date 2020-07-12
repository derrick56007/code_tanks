![Dart CI](https://github.com/Derrick56007/code_tanks/workflows/Dart%20CI/badge.svg)
A library for Dart developers.

Created from templates made available by Stagehand under a BSD-style
[license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).

## Usage

A simple usage example:

```dart
import 'package:code_tanks/code_tanks.dart';

main() {
  var awesome = new Awesome();
}
```

## Local Development

Run redis
docker-compose -f .\docker\authentication_server\docker-compose.yml up redis

Run registry
docker-compose -f .\docker\authentication_server\docker-compose.yml up code_tanks_registry

Start servers
dart .\bin\run_all_servers_test.dart

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme


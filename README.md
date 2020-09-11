![Dart Tests CI](https://github.com/Derrick56007/code_tanks/workflows/Dart%20Tests%20CI/badge.svg)
![Authentication Server Docker Image CI](https://github.com/Derrick56007/code_tanks/workflows/Authentication%20Server%20Docker%20Image%20CI/badge.svg)
![Build Server Docker Image CI](https://github.com/Derrick56007/code_tanks/workflows/Build%20Server%20Docker%20Image%20CI/badge.svg)
![Game Server Docker Image CI](https://github.com/Derrick56007/code_tanks/workflows/Game%20Server%20Docker%20Image%20CI/badge.svg)
![Web Server Docker Image CI](https://github.com/Derrick56007/code_tanks/workflows/Web%20Server%20Docker%20Image%20CI/badge.svg)

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
```
docker-compose -f docker/authentication_server/docker-compose.yml up redis
```
Run registry
```
docker-compose -f docker/authentication_server/docker-compose.yml up code_tanks_registry
```
Start servers
```
dart bin/run_all_servers_test.dart
```
cd website/
webdev serve
```
## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme


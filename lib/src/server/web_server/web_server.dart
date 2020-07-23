import 'dart:async';
import 'dart:io';

import 'package:http_server/http_server.dart';

import '../server_common/base_server.dart';

import '../../../code_tanks_server_common.dart';

class WebServer extends BaseServer {
  final defaultPage = File('website/build/index.html');
  final staticFiles = VirtualDirectory('website/build/');

  WebServer(String address, int port) : super('web', address, port) {
    staticFiles
      ..jailRoot = false
      ..allowDirectoryListing = true
      ..directoryHandler = (dir, request) async {
        final indexUri = Uri.file(dir.path).resolve('index.html');

        var file = File(indexUri.toFilePath());

        if (!(await file.exists())) {
          file = defaultPage;
        }
        staticFiles.serveFile(file, request);
      };

    final current = Directory.current;
    print(current.path);

    print(defaultPage.absolute.path);      
  }

  @override
  Future<void> onRequestPre(HttpRequest req) async {
    req.response.headers.set('cache-control', 'no-cache');
  }

  @override
  Future<void> onRequestPost(HttpRequest req) async {
    await staticFiles.serveRequest(req);
  }

  @override
  void handleSocketDone(HttpRequest req, ServerWebSocket socket) {
  }

  @override
  void handleSocketStart(HttpRequest req, ServerWebSocket socket) {
  }
}

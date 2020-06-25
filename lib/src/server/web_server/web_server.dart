import 'dart:async';
import 'dart:io';

import 'package:code_tanks/src/server/server_common/base_server.dart';
import 'package:http_server/http_server.dart';

import '../../../code_tanks_server_common.dart';

class WebServer extends BaseServer {
  final defaultPage = File('build/index.html');
  final staticFiles = VirtualDirectory('build/');

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

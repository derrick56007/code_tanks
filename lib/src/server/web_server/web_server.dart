import 'dart:async';
import 'dart:io';

import 'package:code_tanks/src/server/server_common/control_server.dart';
import 'package:http_server/http_server.dart';

import '../../../code_tanks_server_common.dart';

class WebServer extends ControlServer {
  final defaultPage = File('build/index.html');
  final staticFiles = VirtualDirectory('build/');

  WebServer(String address, int port, String authenticationServerAddress,
      int authenticationServerPort)
      : super('web', address, port, authenticationServerAddress,
            authenticationServerPort) {
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
  void handleSocketDone(ServerWebSocket socket) {
    // TODO: implement handleSocketDone
  }

  @override
  void handleSocketStart(ServerWebSocket socket) {
    // TODO: implement handleSocketStart
  }
}

// class DerpServer {
//   final String address;
//   final int port;
//   final String authenticationServerUrl;
//   final DummySocket authenticationSocket;

//   HttpServer server;
//   StreamSubscription<HttpRequest> sub;

//   final defaultPage = File('build/index.html');
//   final staticFiles = VirtualDirectory('build/');

//   DerpServer(this.address, this.port, this.authenticationServerUrl)
//       : authenticationSocket = DummySocket(authenticationServerUrl) {
//     staticFiles
//       ..jailRoot = false
//       ..allowDirectoryListing = true
//       ..directoryHandler = (dir, request) async {
//         final indexUri = Uri.file(dir.path).resolve('index.html');

//         var file = File(indexUri.toFilePath());

//         if (!(await file.exists())) {
//           file = defaultPage;
//         }
//         staticFiles.serveFile(file, request);
//       };
//   }

//   void init() async {
//     server = await HttpServer.bind(address, port);
//     server.idleTimeout = null;

//     sub = server.listen(onRequest);

//     print('web server started at $address:$port');

//     await authenticationSocket.start();
//     print('connected to authentication server $authenticationServerUrl');
//     authenticationSocket.send('web_server_handshake');
//     print('sent handshake');
//   }

//   void onRequest(HttpRequest req) async {
//     req.response.headers.set('cache-control', 'no-cache');

//     // handle websocket connection
//     if (WebSocketTransformer.isUpgradeRequest(req)) {
//       final socket = ServerWebSocket.upgradeRequest(req);

//       await socket.start();

//       handleSocketStart(socket);

//       await socket.done;

//       handleSocketDone(socket);

//       return;
//     }

//     await staticFiles.serveRequest(req);
//   }

//   void handleSocketStart(ServerWebSocket socket) {
//     // socket;
//   }

//   void handleSocketDone(ServerWebSocket socket) {}

//   Future close() async {
//     await sub.cancel();

//     print('web server closed at $address:$port');
//   }
// }

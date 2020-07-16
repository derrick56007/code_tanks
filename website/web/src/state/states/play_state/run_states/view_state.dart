import 'dart:async';
import 'dart:html';

import 'package:stagexl/stagexl.dart';

import '../../../../client_web_socket/client_websocket.dart';
import '../../../state.dart';
import '../../../state_manager.dart';

class ViewState extends State {
  static const gameWidth = 800;
  static const gameHeight = 800;

  final Element viewDiv = querySelector('#view-state');
  final ButtonElement closeViewBtn = querySelector('#close-view-btn');

  StreamSubscription closeViewSub;

  final options = StageOptions()
    ..backgroundColor = Color.Black
    ..transparent = true
    ..renderEngine = RenderEngine.WebGL;

  final canvas = querySelector('#stage');
  Stage stage;

  TextureAtlas textureAtlas;

  ViewState(ClientWebSocket client, StateManager stateManager) : super(client, stateManager) {
    client //
      ..on('run_game_response', onRunGameResponse);
  }

  void onRunGameResponse(data) {
    // TODO validate data
    print('received frames');
    print(data);

    // runBtn.disabled = false;

    // buildBtn.disabled = false;
  }

  @override
  void hide() {
    viewDiv.style.display = 'none';

    closeViewSub?.cancel();
  }

  @override
  void show() async {
    viewDiv.style.display = 'flex';

    closeViewSub = closeViewBtn.onClick.listen((event) {
      stateManager.pushState('landing');
    });

    if (stage == null) {
      stage = Stage(canvas, width: 7, height: 7, options: options);

      print(stage.width);
      print(stage.height);

      final renderLoop = RenderLoop();
      renderLoop.addStage(stage);

      final resourceManager = ResourceManager();
      resourceManager.addTextureAtlas(
          'spritesheet', '../../../../../images/allSprites_retina.xml', TextureAtlasFormat.STARLINGXML);
      await resourceManager.load();

      textureAtlas = resourceManager.getTextureAtlas('spritesheet');

      print(Bitmap(textureAtlas.getBitmapData('barrelBlack_side.png')));
    }
  }
}

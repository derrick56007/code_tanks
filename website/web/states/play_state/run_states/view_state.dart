import 'dart:async';
import 'dart:html';

import 'package:code_tanks/code_tanks_client.dart';
import 'package:stagexl/stagexl.dart';

class ViewState extends State {
  static const gameWidth = 800;
  static const gameHeight = 800;

  final ButtonElement closeViewBtn = querySelector('#close-view-btn');

  StreamSubscription closeViewSub;

  final options = StageOptions()
    ..backgroundColor = Color.Black
    ..transparent = true
    ..renderEngine = RenderEngine.WebGL;

  final canvas = querySelector('#stage');
  Stage stage;

  TextureAtlas textureAtlas;

  ViewState(ClientWebSocket client, StateManager stateManager)
      : super(client, stateManager, querySelector('#view-state')) {
    client //
      ..on('run_game_response', onRunGameResponse);
  }

  void onRunGameResponse(data) {
    // TODO validate data
    print('received frames');
    print(data);
  }

  @override
  void hide() {
    stateElement.style.display = 'none';

    closeViewSub?.cancel();
  }

  @override
  void show() async {
    stateElement.style.display = 'flex';

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

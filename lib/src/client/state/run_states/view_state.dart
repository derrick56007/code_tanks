import 'dart:async';
import 'dart:html';

import 'package:quiver/async.dart';

import '../state.dart';
import 'package:stagexl/stagexl.dart';

class ViewState extends State {
  static const gameWidth = 800;
  static const gameHeight = 800;

  final ButtonElement closeViewBtn = querySelector('#close-view-btn');

  final options = StageOptions()
    ..backgroundColor = Color.Black
    ..transparent = true
    ..renderEngine = RenderEngine.WebGL;

  final canvas = querySelector('#stage');
  Stage stage;

  TextureAtlas textureAtlas;

  ViewState() : super(querySelector('#view-state'));

  final entities = {};
  final entitySet = <int>{};

  final newEntitySet = <int>{};
  final newEntities = {};

  void onRunGameResponse(data) async {
    stateManager.pushState('view');

    if (stage == null) {
      stage = Stage(canvas, width: 800, height: 600, options: options);

      final renderLoop = RenderLoop();
      renderLoop.addStage(stage);

      print(stage.width);
      print(stage.height);

      final resourceManager = ResourceManager();
      resourceManager.addTextureAtlas('spritesheet', '/images/allSprites_retina.xml', TextureAtlasFormat.STARLINGXML);
      await resourceManager.load();

      textureAtlas = resourceManager.getTextureAtlas('spritesheet');
    }

    print('received frames');

    for (final frame in data['frames']) {
      newEntitySet.clear();
      newEntities.clear();

      for (final renderable in frame) {
        if (!entitySet.contains(renderable['id'])) {
          // create new
          newEntitySet.add(renderable['id']);

          // TODO initialize different render_type

          final barrel = Bitmap(textureAtlas.getBitmapData('barrelBlack_side.png'));
          barrel
            ..x = renderable['render_info']['x']
            ..y = renderable['render_info']['y']
            ..rotation = renderable['render_info']['rotation']
            ..pivotX = barrel.width / 2
            ..pivotY = barrel.height / 2;

          print('new');
          print(renderable);

          stage.addChild(barrel);

          newEntities[renderable['id']] = barrel;
        } else {
          // update
          // print('update ${renderable['id']}');

          // TODO update different render_type
          final e = entities[renderable['id']];
          e
            ..x = renderable['render_info']['x']
            ..y = renderable['render_info']['y']
            ..rotation = renderable['render_info']['rotation'];

          print(e.rotation);
          newEntities[renderable['id']] = e;
        }

        newEntitySet.add(renderable['id']);
      }

      entitySet.removeAll(newEntitySet);

      for (final id in entitySet) {
        // TODO remove sprite from stage
        final e = entities.remove(id);
        stage.removeChild(e);

        print('remove $id');
      }

      entities //
        ..clear()
        ..addAll(newEntities);

      entitySet //
        ..clear()
        ..addAll(newEntitySet);

      final completer = Completer();

      Timer(const Duration(milliseconds: 16), () {
        completer.complete();
      });

      await completer.future;
    }
  }

  @override
  void hide() {
    stateElement.style.display = 'none';
  }

  @override
  void show() async {
    stateElement.style.display = 'flex';
  }

  @override
  void init() {
    client //
      ..on('run_game_response', onRunGameResponse);

    closeViewBtn?.onClick?.listen((event) {
      stateManager.pushState('landing');
    });
  }
}

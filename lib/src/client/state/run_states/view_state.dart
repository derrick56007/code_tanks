import 'dart:async';
import 'dart:html';

import 'package:code_tanks/code_tanks_common.dart';
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
        final renderType = RenderType.values[renderable['render_type_index']];

        if (!entitySet.contains(renderable['id'])) {
          // create new entity

          newEntitySet.add(renderable['id']);

          final bitmapContainer = BitmapContainer();

          switch (renderType) {
            case RenderType.tank:
              final tankBodyBitmap = Bitmap(textureAtlas.getBitmapData('tankBody_dark_outline.png'));
              tankBodyBitmap
                ..pivotX = tankBodyBitmap.width / 2
                ..pivotY = tankBodyBitmap.height / 2;

              bitmapContainer.addChild(tankBodyBitmap);

              final tankBarrelBitmap = Bitmap(textureAtlas.getBitmapData('tankDark_barrel2_outline.png'));
              tankBarrelBitmap
                ..pivotX = tankBarrelBitmap.width / 2
                ..pivotY = tankBarrelBitmap.width / 2;

              bitmapContainer.addChild(tankBarrelBitmap);

              // TODO add radar bitmap

              break;
            case RenderType.bullet:
              // TODO get bullet bitmap
              break;
            default:
          }

          bitmapContainer
            ..x = renderable['render_info']['x']
            ..y = renderable['render_info']['y']
            ..rotation = renderable['render_info']['rotation'];

          stage.addChild(bitmapContainer);

          newEntities[renderable['id']] = bitmapContainer;
        } else {
          // update
          // print('update ${renderable['id']}');

          // TODO update different render_type
          final bitmapContainer = entities[renderable['id']];
          bitmapContainer
            ..x = renderable['render_info']['x']
            ..y = renderable['render_info']['y']
            ..rotation = renderable['render_info']['rotation'];

          newEntities[renderable['id']] = bitmapContainer;
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

import 'dart:typed_data';
import 'dart:ui';
import 'package:simple_3d/simple_3d.dart';
import 'sp3d_faceobj.dart';
import 'sp3d_paint_image.dart';

/// (en)It is a world class for handling multiple Sp3dObj at once.
///
/// (ja)複数のSp3dObjをまとめて扱うためのワールドクラスです。
///
/// Author Masahide Mori
///
/// First edition creation date 2021-09-30 14:58:34
///
class Sp3dWorld {
  String get className => 'Sp3dWorld';
  String get version => '7';
  List<Sp3dObj> objs;

  // 以下はディープコピーなどが不要な一時変数。
  // コンバートされた各オブジェクトごとの画像情報
  Map<Sp3dObj, Map<int, Image>> convertedImages = {};

  // レンダリング情報を構成するためのイメージのMap。構成に失敗したイメージはnullが入る。
  Map<Sp3dMaterial, Sp3dPaintImage?> paintImages = {};

  // 以下は一次データであるため保存されない。
  // タッチ制御のために保存されるレンダリング座標情報。汎用性のために外部からも参照可能にする。
  List<Sp3dFaceObj> sortedAllFaces = [];

  /// Constructor
  /// * [objs] : World obj.
  Sp3dWorld(this.objs);

  /// Deep copy the world.
  /// Initialization must be performed again.
  /// Also, temporary data is not copied.
  Sp3dWorld deepCopy() {
    List<Sp3dObj> mObjs = [];
    for (Sp3dObj i in objs) {
      mObjs.add(i.deepCopy());
    }
    return Sp3dWorld(mObjs);
  }

  /// Convert to Map.
  Map<String, dynamic> toDict() {
    Map<String, dynamic> d = {};
    d['class_name'] = className;
    d['version'] = version;
    List<Map<String, dynamic>> mObjs = [];
    for (Sp3dObj i in objs) {
      mObjs.add(i.toDict());
    }
    d['objs'] = mObjs;
    return d;
  }

  /// Convert from Map.
  static Sp3dWorld fromDict(Map<String, dynamic> src) {
    List<Sp3dObj> mObjs = [];
    for (Map<String, dynamic> i in src['objs']) {
      mObjs.add(Sp3dObj.fromDict(i));
    }
    return Sp3dWorld(mObjs);
  }

  /// (en)Converts Uint8List to an image class and returns it.
  ///
  /// (ja)Uint8Listを画像クラスに変換して返します。
  Future<Image> _bytesToImage(Uint8List bytes) async {
    Codec codec = await instantiateImageCodec(bytes);
    FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }

  /// (en)Loads and initializes the image file for rendering.
  ///
  /// (ja)レンダリング用の画像ファイルを読み込んで初期化します。
  /// Return : If an error occurs, it returns a list of the objects in which the error occurred.
  /// If normal, an empty array is returned.
  Future<List<Sp3dObj>> initImages() async {
    Map<Sp3dObj, bool> r = {};
    for (Sp3dObj obj in objs) {
      for (Sp3dMaterial m in obj.materials) {
        try {
          if (m.imageIndex != null) {
            Image img = await _bytesToImage(obj.images[m.imageIndex!]);
            if (convertedImages.containsKey(obj)) {
              convertedImages[obj]![m.imageIndex!] = img;
            } else {
              convertedImages[obj] = {m.imageIndex!: img};
            }
            Sp3dPaintImage pImg = Sp3dPaintImage(m);
            pImg.createShader(img);
            paintImages[m] = pImg;
          }
        } catch (e) {
          paintImages[m] = null;
          r[obj] = false;
        }
      }
    }
    return r.keys.toList();
  }

  /// (en)Places the object at the specified coordinates in the world.
  ///
  /// (ja)ワールド内の指定座標にオブジェクトを設置します。
  ///
  /// * [obj] : target obj.
  /// * [coordinate] : paste position.
  void add(Sp3dObj obj, Sp3dV3D coordinate) {
    objs.add(obj.move(coordinate));
  }

  /// (en)Gets the object with the specified id.
  ///
  /// (ja)指定されたidを持つオブジェクトを取得します。
  ///
  /// * [id] : target obj id.
  /// Return : If target does not exist, return null.
  Sp3dObj? get(String id) {
    for (Sp3dObj i in objs) {
      if (i.id == id) {
        return i;
      }
    }
    return null;
  }

  /// (en)Removes the specified object from the world.
  ///
  /// (ja)指定されたオブジェクトをワールドから取り除きます。
  ///
  /// * [obj] : target obj.
  void remove(Sp3dObj obj) {
    objs.remove(obj);
  }

  /// (en)Removes all objects with the specified ID from the world.
  ///
  /// (ja)指定されたIDを持つ全てのオブジェクトをワールドから取り除きます。
  ///
  /// * [id] : target obj.
  void removeAt(String id) {
    for (Sp3dObj i in [...objs]) {
      if (i.id == id) {
        objs.remove(i);
      }
    }
  }
}

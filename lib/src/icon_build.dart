import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:iconfont/models/index.dart';
import 'package:iconfont/src/temp/icon_temp.dart';
import 'package:iconfont/src/temp/pub_temp.dart';
import 'package:iconfont/src/utils.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// IconBuild
class IconBuild {
  /// config
  Config config;

  /// pubspecYaml
  late Map pubspecYaml;

  /// <fontFamily,assetPaths>
  Map<String, List<String>> iconfontMap = {};

  /// 1
  IconBuild(this.config) {
    initPubspecYaml();
  }

  /// 1
  initPubspecYaml() {
    this.pubspecYaml = json
        .decode(json.encode(loadYaml(File("pubspec.yaml").readAsStringSync())));
    return this.pubspecYaml;
  }

  /// build
  build() async {
    await _downloadFromCss();

    await _scanDir(config.readPath);

    iconfontMap.forEach((key, value) async {
      await _addYaml(key, value);
    });
  }

  /// 从css链接 下载ttf
  Future<void> _downloadFromCss() async {
    if (config.dirName.isEmpty || config.css.isEmpty) {
      return;
    }

    Dio dio = Dio();
    var url = Utils.getUrl(config.css);
    if (url.isEmpty) {
      return;
    }

    Response response = await dio.get(url);
    String data = response.data.toString();

    var ttfUrl =
        RegExp(r"//at.alicdn.com/t/font.*\.ttf\?t=[0-9]{13}").stringMatch(data);

    var iconJson = {
      "font_family":
          RegExp(r'font-family: "(.+?)";').firstMatch(data)?.group(1),
      "css_prefix_text": "",
      "glyphs": RegExp(r'\.(.+):before[\S\s]*?content: "\\(.+)";')
          .allMatches(data)
          .map((m) {
        return {
          "font_class": m.group(1),
          "unicode": m.group(2),
          "name": "",
        };
      }).toList()
    };

    var dir = Directory(path.joinAll([config.readPath, config.dirName]));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    File(path.joinAll([dir.path, "iconfont.json"]))
        .writeAsStringSync(json.encode(iconJson));
    File(path.joinAll([dir.path, "iconfont.txt"])).writeAsStringSync(url);

    await dio.download(
        Utils.getUrl(ttfUrl!), path.joinAll([dir.path, "iconfont.ttf"]));
  }

  /// 扫描文件夹
  _scanDir(String dir) {
    if (!Directory(dir).existsSync()) {
      print("not found $dir");
      return;
    }

    var ttfPath = '';
    var jsonPath = '';

    Directory(dir).listSync(recursive: false, followLinks: true).forEach((e) {
      if (FileSystemEntity.isFileSync(e.path)) {
        if (e.path.endsWith('.json')) {
          jsonPath = e.path;
        } else if (e.path.endsWith('.ttf')) {
          ttfPath = e.path;
        } else {
          return;
        }

        if (ttfPath.isNotEmpty && jsonPath.isNotEmpty) {
          var pathList = path.split(e.path.replaceFirst(config.readPath, ''));
          var className = (pathList..removeLast()).last;
          var savePath =
              '${path.joinAll([config.writePath, ...pathList])}.dart';
          _saveIcon(ttfPath, jsonPath, savePath, className);
        }
      }

      if (FileSystemEntity.isDirectorySync(e.path)) {
        _scanDir(e.path);
      }
    });
  }

  /// 保存字体文件
  _saveIcon(
      String ttfPath, String jsonPath, String savePath, String className) {
    var iconFontModel =
        IconModel.fromJson(json.decode(File(jsonPath).readAsStringSync()));
    iconFontModel.package = config.packageName;
    String tmp = IconTemp.build(Utils.formatName(className), iconFontModel);

    if (iconFontModel.fontFamily != null) {
      if (iconfontMap.containsKey(iconFontModel.fontFamily)) {
        iconfontMap[iconFontModel.fontFamily]!.add(ttfPath);
      } else {
        iconfontMap.addAll({
          iconFontModel.fontFamily!: [ttfPath]
        });
      }
    }

    var file = File(savePath);
    bool exists = file.existsSync();
    if (!exists) {
      file.createSync(recursive: true);
    }
    file.writeAsStringSync(tmp);

    print("build $savePath from $ttfPath and $jsonPath");
  }

  // /// 添加字体到 pubspec.yaml 中
  _addYaml(String family, List<String> iconfontPath) async {
    PubTemp.build(family, iconfontPath,
        () => (pubspecYaml['flutter'] as Map<String, dynamic>));
  }

  /// 添加字体到 pubspec.yaml 中
//   _addYaml2(String family, List<String> iconfontPath) async {
//     Map<String, dynamic> flutter =
//     (pubspecYaml.customFields['flutter'] as Map<String, dynamic>);
//     List<Map<String, String>> iconfontPathMap =
//     iconfontPath.map((e) => {"asset": e}).toList();
//
//     if (flutter.containsKey("fonts")) {
//       List<dynamic> fonts = flutter['fonts'];
//
//       List<dynamic> iconfont = fonts
//           .where((e) => e.containsKey("family") && e["family"] == family)
//           .toList();
//
//       if (iconfont.isEmpty) {
//         // 没有导入过iconfont
//         fonts.add({
//           "family": family,
//           "fonts": iconfontPathMap,
//         });
//       } else {
//         // 导入过iconfont
//         iconfont[0].addAll({
//           "fonts": iconfontPathMap,
//         });
//       }
//     } else {
//       flutter.addAll({
//         "fonts": [
//           {
//             "family": family,
//             "fonts": iconfontPathMap,
//           }
//         ]
//       });
//     }
//
//     File(config.pubspecName).writeAsStringSync(pubspecYaml.toYamlString());
// //  }
}

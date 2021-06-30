import 'package:args/args.dart';
import 'package:iconfont/iconfont.dart';

/// main
void main(List<String> args) {
  final ArgParser argParser = ArgParser()
    ..addOption('css',
        abbr: 'c',
        defaultsTo: '',
        help:
            "font css的链接，例如(http://at.alicdn.com/t/font_1500681_sz0skwerbw.css)")
    ..addOption('dir', abbr: 'd', defaultsTo: '', help: "自动生成的assets文件夹名")
    ..addOption('in',
        abbr: 'i', defaultsTo: 'assets/fonts/', help: "iconfont文件所在目录")
    ..addOption('package', abbr: 'p', defaultsTo: '', help: "生成的字体包名")
    ..addOption('out', abbr: 'o', defaultsTo: 'lib/icons/', help: "生成后文件存放目录")
    ..addFlag('help', abbr: 'h', negatable: false, help: "help");

  ArgResults argResults = argParser.parse(args);
  if (argResults['help']) {
    print(argParser.usage);
    return;
  }

  Config config = Config.fromJson({
    "readPath": "assets/fonts/",
    "writePath": "lib/icons/",
    "dirName": "",
    "css": "",
    "package": ""
  });

  config.readPath = argResults['in'];
  config.writePath = argResults['out'];
  config.dirName = argResults['dir'];
  config.css = argResults['css'];
  config.packageName = argResults['package'];

  try {
    IconBuild(config).build();
  } catch (e) {
    print(e.toString());
  }
}

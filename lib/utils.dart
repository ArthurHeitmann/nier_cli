import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crclib/catalog.dart';
import 'package:path/path.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

import '../fileTypeUtils/dat/datExtractor.dart';
import '../fileTypeUtils/utils/ByteDataWrapper.dart';
import 'exception.dart';


const datExtractSubDir = "nier2blender_extracted";
const pakExtractSubDir = "pakExtracted";

const uuidGen = Uuid();

enum HorizontalDirection { left, right }

T clamp<T extends num> (T value, T minVal, T maxVal) {
  return max(min(value, maxVal), minVal);
}

final _crc32 = Crc32();
int crc32(String str) {
  return _crc32.convert(utf8.encode(str)).toBigInt().toInt();
}

bool isInt(String str) {
  return int.tryParse(str) != null;
}

bool isHexInt(String str) {
  return str.startsWith("0x") && int.tryParse(str) != null;
}

bool isDouble(String str) {
  return double.tryParse(str) != null;
}

bool isVector(String str) {
 return str.split(" ").every((val) => isDouble(val));
}

void Function() throttle(void Function() func, int waitMs, { bool leading = true, bool trailing = false }) {
  Timer? timeout;
  int previous = 0;
  void later() {
		previous = leading == false ? 0 : DateTime.now().millisecondsSinceEpoch;
		timeout = null;
		func();
	}
	return () {
		var now = DateTime.now().millisecondsSinceEpoch;
		if (previous != 0 && leading == false)
      previous = now;
		var remaining = waitMs - (now - previous);
		if (remaining <= 0 || remaining > waitMs) {
			if (timeout != null) {
				timeout!.cancel();
				timeout = null;
			}
			previous = now;
			func();
		}
    else if (timeout != null && trailing) {
			timeout = Timer(Duration(milliseconds: remaining), later);
		}
	};
}

void Function() debounce(void Function() func, int waitMs, { bool leading = false }) {
  Timer? timeout;
  return () {
		timeout?.cancel();
		timeout = Timer(Duration(milliseconds: waitMs), () {
			timeout = null;
			if (!leading)
        func();
		});
		if (leading && timeout != null)
      func();
	};
}

String doubleToStr(num d) {
  var int = d.toInt();
    return int == d
      ? int.toString()
      : d.toString();
}

Future<List<String>> getDatFiles(String extractedDir) async {
  var pakInfo = path.join(extractedDir, "dat_info.json");
  if (await File(pakInfo).exists()) {
    var datInfoJson = jsonDecode(await File(pakInfo).readAsString());
    return datInfoJson["files"].cast<String>();
  }
  var fileOrderMetadata = path.join(extractedDir, "file_order.metadata");
  if (await File(fileOrderMetadata).exists()) {
    var filesBytes = await ByteDataWrapper.fromFile(fileOrderMetadata);
    var numFiles = filesBytes.readUint32();
    var nameLength = filesBytes.readUint32();
    List<String> datFiles = List
      .generate(numFiles, (i) => filesBytes.readString(nameLength)
        .split("\u0000")[0]);
    return datFiles;
  }

  return await (Directory(extractedDir).list())
    .where((file) => file is File && path.extension(file.path).length <= 3)
    .map((file) => file.path)
    .toList();
}

Future<Tuple2<String?, String>> getDatNameParts(String extractedDir) async {
  var pakInfo = path.join(extractedDir, "dat_info.json");
  if (await File(pakInfo).exists()) {
    var datInfoJson = jsonDecode(await File(pakInfo).readAsString()) as Map;
    if (datInfoJson.containsKey("basename") && datInfoJson.containsKey("ext"))
      return Tuple2(datInfoJson["basename"], datInfoJson["ext"]);
  }
  return Tuple2(null, "dat");
}

XmlElement makeXmlElement({ required String name, String? text, Map<String, String> attributes = const {}, List<XmlElement> children = const [] }) {
  return XmlElement(
    XmlName(name),
    attributes.entries.map((attr) => XmlAttribute(XmlName(attr.key), attr.value)).toList(),
    <XmlNode>[
      if (text != null)
        XmlText(text),
      ...children,
    ],
  );
}

final _randomGen = Random();
int randomId() {
  return _randomGen.nextInt(0xFFFFFFFF);
}

Future<List<dynamic>> getPakInfoData(String dir) async {
  var pakInfoPath = join(dir, "pakInfo.json");
  if (!await File(pakInfoPath).exists())
    return [];
  Map pakInfoJson = jsonDecode(await File(pakInfoPath).readAsString());
  return pakInfoJson["files"];
}

Future<dynamic> getPakInfoFileData(String path) async {
  var pakInfoPath = join(dirname(path), "pakInfo.json");
  if (!await File(pakInfoPath).exists())
    return null;
  Map pakInfoJson = jsonDecode(await File(pakInfoPath).readAsString());
  var yaxName = "${basenameWithoutExtension(path)}.yax";
  var fileInfoIndex = (pakInfoJson["files"] as List)
    .indexWhere((file) => file["name"] == yaxName);
  if (fileInfoIndex == -1)
    return null;
  return pakInfoJson["files"][fileInfoIndex];
}

Future<void> updatePakInfoFileData(String path, void Function(dynamic data) updater) async {
  var pakInfoPath = join(dirname(path), "pakInfo.json");
  if (!await File(pakInfoPath).exists())
    return;
  Map pakInfoJson = jsonDecode(await File(pakInfoPath).readAsString());
  var yaxName = "${basenameWithoutExtension(path)}.yax";
  var fileInfoIndex = (pakInfoJson["files"] as List)
    .indexWhere((file) => file["name"] == yaxName);
  if (fileInfoIndex == -1)
    return;
  updater(pakInfoJson["files"][fileInfoIndex]);
  await File(pakInfoPath).writeAsString(const JsonEncoder.withIndent("\t").convert(pakInfoJson));
}

Future<void> addPakInfoFileData(String path, int type) async {
  var pakInfoPath = join(dirname(path), "pakInfo.json");
  if (!await File(pakInfoPath).exists())
    return;
  Map pakInfoJson = jsonDecode(await File(pakInfoPath).readAsString());
  var yaxName = "${basenameWithoutExtension(path)}.yax";
  (pakInfoJson["files"] as List).add({
    "name": yaxName,
    "type": type,
  });
  await File(pakInfoPath).writeAsString(const JsonEncoder.withIndent("\t").convert(pakInfoJson));
}

Future<void> removePakInfoFileData(String path) async {
  var pakInfoPath = join(dirname(path), "pakInfo.json");
  if (!await File(pakInfoPath).exists())
    return;
  Map pakInfoJson = jsonDecode(await File(pakInfoPath).readAsString());
  var yaxName = "${basenameWithoutExtension(path)}.yax";
  var fileInfoIndex = (pakInfoJson["files"] as List)
    .indexWhere((file) => file["name"] == yaxName);
  if (fileInfoIndex == -1)
    return;
  (pakInfoJson["files"] as List).removeAt(fileInfoIndex);
  await File(pakInfoPath).writeAsString(const JsonEncoder.withIndent("\t").convert(pakInfoJson));
}

bool isStringAscii(String s) {
  return utf8.encode(s).every((byte) => byte < 128);
}


const _basicFolders = { "ba", "bg", "bh", "em", "et", "it", "pl", "ui", "um", "wp" };
const Map<String, String> _nameStartToFolder = {
  "q": "quest",
  "core": "core",
  "credit": "credit",
  "Debug": "debug",
  "font": "font",
  "misctex": "misctex",
  "subtitle": "subtitle",
  "txt": "txtmess",
};
String getDatFolder(String datName) {
  var c2 = datName.substring(0, 2);
  if (_basicFolders.contains(c2))
    return c2;
  var c1 = datName[0];
  if (c1 == "r")
    return "st${datName[1]}";
  if (c1 == "p")
    return "ph${datName[1]}";
  if (c1 == "g")
    return "wd${datName[1]}";
  
  for (var start in _nameStartToFolder.keys) {
    if (datName.startsWith(start))
      return _nameStartToFolder[start]!;
  }

  if (isInt(c2))
    return path.join("effect", "model");
  
  return path.withoutExtension(datName);
}

Future<List<String>> getDatFileList(String datDir) async {
  var datInfoPath = path.join(datDir, "dat_info.json");
  if (await File(datInfoPath).exists())
    return _getDatFileListFromJson(datInfoPath);
  var metadataPath = path.join(datDir, "file_order.metadata");
  if (await File(metadataPath).exists())
    return _getDatFileListFromMetadata(metadataPath);
  
  throw Exception("No dat_info.json or file_order.metadata found in $datDir");
}

Future<List<String>> _getDatFileListFromJson(String datInfoPath) async {
  var datInfoJson = jsonDecode(await File(datInfoPath).readAsString());
  List<String> files = [];
  var dir = path.dirname(datInfoPath);
  for (var file in datInfoJson["files"]) {
    files.add(path.join(dir, file));
  }
  files = files.toSet().toList();
  files.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  return files;
}

Future<List<String>> _getDatFileListFromMetadata(String metadataPath) async {
  var metadataBytes = await ByteDataWrapper.fromFile(metadataPath);
  var numFiles = metadataBytes.readUint32();
  var nameLength = metadataBytes.readUint32();
  List<String> files = [];
  for (var i = 0; i < numFiles; i++)
    files.add(metadataBytes.readString(nameLength).trimNull());
  files = files.toSet().toList();
  files.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  var dir = path.dirname(metadataPath);
  files = files.map((file) => path.join(dir, file)).toList();

  return files;
}

String pluralStr(int number, String label, [String numberSuffix = ""]) {
  if (number == 1)
    return "$number$numberSuffix $label";
  return "$number$numberSuffix ${label}s";
}

/// https://stackoverflow.com/a/60717480/9819447
extension Iterables<E> on Iterable<E> {
  Map<K, List<E>> groupBy<K>(K Function(E) keyFunction) => fold(
      <K, List<E>>{},
      (Map<K, List<E>> map, E element) =>
          map..putIfAbsent(keyFunction(element), () => <E>[]).add(element));
}

bool between(num val, num min, num max) => val >= min && val <= max;

void revealFileInExplorer(String path) {
  if (Platform.isWindows) {
    Process.run("explorer.exe", ["/select,", path]);
  } else if (Platform.isMacOS) {
    Process.run("open", ["-R", path]);
  } else if (Platform.isLinux) {
    Process.run("xdg-open", [path]);
  }
}

const datExtensions = { ".dat", ".dtt", ".evn", ".eff" };
bool strEndsWithDat(String str) {
  for (var ext in datExtensions) {
    if (str.endsWith(ext))
      return true;
  }
  return false;
}

const bxmExtensions = { ".bxm", ".sar", ".gad", ".seq" };
bool strEndsWithBxm(String str) {
  for (var ext in bxmExtensions) {
    if (str.endsWith(ext))
      return true;
  }
  return false;
}

class SizeInt {
  final int width;
  final int height;

  const SizeInt(this.width, this.height);

  @override
  String toString() => "$width x $height";
}
Future<SizeInt> getDdsFileSize(String path) async {
  var reader = await ByteDataWrapper.fromFile(path);
  reader.position = 0xc;
  var height = reader.readUint32();
  var width = reader.readUint32();
  return SizeInt(width, height);
}

num sum(Iterable<num> values) {
  num sum = 0;
  for (var value in values)
    sum += value;
  return sum;
}

num sumM<T>(Iterable<T> values, num Function(T) mapper) {
  return sum(values.map(mapper));
}

num avr(Iterable<num> values) {
  return sum(values) / values.length;
}

num avrM<T>(Iterable<T> values, num Function(T) mapper) {
  return avr(values.map(mapper));
}

bool isSubtype<S, T>() => <S>[] is List<T>;

List<T> spaceListWith<T>(List<T> list, T Function() generator, [bool outer = false]) {
  var newList = <T>[];
  for (var i = 0; i < list.length; i++) {
    if (i != 0 || outer)
      newList.add(generator());
    newList.add(list[i]);
  }
  if (outer)
    newList.add(generator());
  return newList;
}

Future<void> backupFile(String file) async {
  var backupName = "$file.backup";
  if (!await File(backupName).exists() && await File(file).exists())
    await File(file).copy(backupName);
}

String formatDuration(Duration duration, [bool showMs = false]) {
  var mins = duration.inMinutes.toString().padLeft(2, "0");
  var secs = (duration.inSeconds % 60).toString().padLeft(2, "0");
  if (showMs) {
    var ms = ((duration.inMilliseconds) % 1000).toInt().toString().padLeft(3, "0");
    return "$mins:$secs.$ms";
  }
  return "$mins:$secs";
}

extension StringNullTrim on String {
  String trimNull() => replaceAll(RegExp("\x00+\$"), "");
}

void openInVsCode(String path) {
  if (Platform.isWindows) {
    Process.run("code", [path], runInShell: true);
  } else if (Platform.isMacOS) {
    Process.run("open", ["-a", "Visual Studio Code", path], runInShell: true);
  } else if (Platform.isLinux) {
    Process.run("code", [path], runInShell: true);
  } else {
    throw Exception("Unsupported platform");
  }
}

Future<String?> findDttDir(String extractedDatDir, String datName) async {
  var parentDir = dirname(extractedDatDir);
  var dttDir = join(parentDir, "$datName.dtt");
  if (!await Directory(dttDir).exists()) {
    // try finding DTT file and extract it
    var dttPath = join(dirname(parentDir), "$datName.dtt");
    if (!await File(dttPath).exists())
      return null;
    var dttExtractDir = join(dirname(dttPath), datExtractSubDir, basename(dttPath));
    print("Extracting DTT file to $dttExtractDir");
    await extractDatFiles(dttPath, dttExtractDir);
    if (!await Directory(dttDir).exists())
      return null;
  }
  return dttDir;
}

Future<String?> findWtpPath(String datDir, String wtpName) async {
  var wtpPath = join(datDir, wtpName);
  if (!await FileSystemEntity.isFile(wtpPath)) {
    var dttName = basenameWithoutExtension(datDir);
    var dttDir = await findDttDir(datDir, dttName);
    if (dttDir == null) {
      dttName = basenameWithoutExtension(datDir);
      dttDir = await findDttDir(datDir, dttName);
      if (dttDir == null)
        throw FileHandlingException("Could not find WTP file for $wtpName");
      else
        wtpPath = join(dttDir, wtpName);
    } else {
      wtpPath = join(dttDir, wtpName);
    }
  }
  if (!await FileSystemEntity.isFile(wtpPath))
    return null;
  return wtpPath;
}

const _assetsDirName = "assets";
const _assetsDirSubDirs = { "vgmStream" };
String? _assetsDir;
Future<String> findAssetsDir() async {
  if (_assetsDir != null)
    return _assetsDir!;
  var path = getAppDir();
  // search cwd breadth first
  List<String> searchPathsQueue = [path];
  while (searchPathsQueue.isNotEmpty) {
    path = searchPathsQueue.removeAt(0);
    var subDirs = await Directory(path)
      .list()
      .where((f) => f is Directory)
      .map((f) => f.path)
      .toList();
    var subDirNames = subDirs.map((p) => basename(p)).toSet();
    if (basename(path) == _assetsDirName && _assetsDirSubDirs.every((subDir) => subDirNames.contains(subDir))) {
      _assetsDir = path;
      return path;
    }
    searchPathsQueue.addAll(subDirs);
  }
  throw Exception("Couldn't find assets dir");
}

String getAppDir() {
  var exePath = Platform.executable;
  var currentDir = Directory.current.path;
  if (basename(exePath) == "dart.exe")
    return currentDir;
  return dirname(exePath);
}

int alignTo(int value, int alignment) {
  return ((value + alignment - 1) ~/ alignment) * alignment;
}

int remainingPadding(int value, int alignment) {
  return alignTo(value, alignment) - value;
}

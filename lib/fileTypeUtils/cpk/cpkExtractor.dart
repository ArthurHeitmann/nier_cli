
import 'dart:io';

import 'package:path/path.dart';

import '../utils/ByteDataWrapper.dart';
import 'cpk.dart';

Future<List<String>> extractCpk(String cpkPath, String extractDir) async {
  var cpk = Cpk.read(await ByteDataWrapper.fromFile(cpkPath));
  for (var file in cpk.files) {
    print("Extracting ${file.name}");
    var folder = join(extractDir, file.path);
    var filePath = join(folder, file.name);
    await Directory(folder).create(recursive: true);
    await File(filePath).writeAsBytes(file.getData());
  }
  return cpk.files
    .map((file) => join(extractDir, file.path, file.name))
    .toList();
}

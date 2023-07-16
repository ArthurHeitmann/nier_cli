
import 'dart:io';

import '../../utils.dart';
import 'wtaReader.dart';

Future<void> repackWtaWtp(String wtaPath, String wtpPath, String extractedDir) async {
  var ddsFiles = await Directory(extractedDir)
    .list()
    .where((f) => f is File)
    .map((f) => f.path)
    .where((f) => f.endsWith(".dds"))
    .toList();
  List<({int i, int id, String path})> ddsFilesData = [];
  for (var ddsFile in ddsFiles) {
    var parts = RegExp(r"(\d+)_([0-9a-f]+)\.dds").firstMatch(ddsFile);
    if (parts == null)
      throw Exception("Invalid dds file name: $ddsFile! Expected format: <index>_<hex_id>.dds");
    var i = int.parse(parts.group(1)!);
    var id = int.parse(parts.group(2)!, radix: 16);
    ddsFilesData.add((i: i, id: id, path: ddsFile));
  }
  ddsFilesData.sort((a, b) => a.i.compareTo(b.i));
  
  List<int> textureOffsets = [];
  List<int> textureSizes = [];
  List<int> textureFlags = List.generate(ddsFilesData.length, (_) => 0x20000020);
  List<int> textureIds = [];
  var currentOffset = 0;
  IOSink? wtp;
  try {
    wtp = await File(wtpPath).openWrite();
    for (var ddsFile in ddsFilesData) {
      var bytes = await File(ddsFile.path).readAsBytes();
      wtp.add(bytes);
      textureOffsets.add(currentOffset);
      textureSizes.add(bytes.length);
      textureIds.add(ddsFile.id);
      currentOffset += bytes.length;
      var padding = List.filled(remainingPadding(currentOffset, 16), 0);
      currentOffset += padding.length;
      wtp.add(padding);
    }
    await wtp.flush();
  } finally {
    await wtp?.close();
  }

  var wtaHeader = WtaFileHeader.empty();
  var wtaFile = WtaFile(wtaHeader, textureOffsets, textureSizes, textureFlags, textureIds, []);
  wtaFile.updateHeader();
  await wtaFile.writeToFile(wtaPath);

  print("Repacked $wtaPath and $wtpPath!");
}

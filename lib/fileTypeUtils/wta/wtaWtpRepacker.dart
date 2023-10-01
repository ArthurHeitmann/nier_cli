
import 'dart:io';

import '../../utils.dart';
import 'wtaReader.dart';

Future<void> repackWtaWtp(String wtaPath, String? wtpPath, String extractedDir, { bool isWtb = false }) async {
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
  int currentOffset = 0;
  for (var ddsFile in ddsFilesData) {
    var ddsSize = await File(ddsFile.path).length();
    textureOffsets.add(currentOffset);
    textureSizes.add(ddsSize);
    textureIds.add(ddsFile.id);
    currentOffset += ddsSize;
    var padding = List.filled(remainingPadding(currentOffset, isWtb ? 4096 : 16), 0);
    currentOffset += padding.length;
  }
  
  var wtaHeader = WtaFileHeader.empty();
  var wtaFile = WtaFile(wtaHeader, textureOffsets, textureSizes, textureFlags, textureIds, []);
  wtaFile.updateHeader();
  if (isWtb) {
    int texturesStartOffset = alignTo(wtaHeader.getFileEnd(), 4096);
    for (int i = 0; i < textureOffsets.length; i++) {
      textureOffsets[i] += texturesStartOffset;
    }
  }
  await wtaFile.writeToFile(wtaPath);

  RandomAccessFile? wtp;
  try {
    wtp = await File(isWtb ? wtaPath : wtpPath!).open(mode: isWtb ? FileMode.append : FileMode.write);
    for (int i = 0; i < textureOffsets.length; i++) {
      await wtp.setPosition(textureOffsets[i]);
      var texturePath = ddsFilesData[i].path;
      var textureBytes = await File(texturePath).readAsBytes();
      await wtp.writeFrom(textureBytes);
    }
    var endPadding = await wtp.position() % 4096;
    await wtp.writeFrom(List.filled(endPadding, 0));
  } finally {
    await wtp?.close();
  }

  print("Repacked $wtaPath and $wtpPath!");
}

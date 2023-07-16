
import 'dart:io';

import 'package:path/path.dart';

import 'wtaReader.dart';

Future<void> extractWtaWtp(String wtaPath, String wtpPath, String extractDir) async {
  var wta = await WtaFile.readFromFile(wtaPath);
  var wtp = await File(wtpPath).open();
  try {
    for (int i = 0; i < wta.header.numTex; i++) {
      await wtp.setPosition(wta.textureOffsets[i]);
      var ddsBytes = await wtp.read(wta.textureSizes[i]);
      var ddsFile = File(join(extractDir, "${i}_${wta.textureIdx[i].toRadixString(16).padLeft(8, "0")}.dds"));
      await ddsFile.writeAsBytes(ddsBytes);
    }
  } finally {
    wtp.close();
  }

  print("Extracted ${wta.header.numTex} files.");
}

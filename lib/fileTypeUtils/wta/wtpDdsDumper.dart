
import 'dart:io';

import 'package:path/path.dart';

const _wtpFirstBytes = [0x44, 0x44, 0x53, 0x20];

Future<void> dumpWtpDdsFiles(String wtpPath, String extractDir) async {
  var wtpBytes = await File(wtpPath).readAsBytes();

  // find DDS files in WTP by looking for the first 4 bytes of a DDS file
  List<int> ddsFileOffsets = [];
  for (var i = 0; i < wtpBytes.length - 4; i++) {
    if (wtpBytes[i] == _wtpFirstBytes[0] &&
        wtpBytes[i + 1] == _wtpFirstBytes[1] &&
        wtpBytes[i + 2] == _wtpFirstBytes[2] &&
        wtpBytes[i + 3] == _wtpFirstBytes[3]) {
      ddsFileOffsets.add(i);
    }
  }

  List<int> ddsFileSizes = [];
  for (var i = 0; i < ddsFileOffsets.length - 1; i++) {
    ddsFileSizes.add(ddsFileOffsets[i + 1] - ddsFileOffsets[i]);
  }
  ddsFileSizes.add(wtpBytes.length - ddsFileOffsets.last);

  for (var i = 0; i < ddsFileOffsets.length; i++) {
    var ddsBytes = wtpBytes.sublist(ddsFileOffsets[i], ddsFileOffsets[i] + ddsFileSizes[i]);
    var ddsFile = File(join(extractDir, "$i.dds"));
    await ddsFile.writeAsBytes(ddsBytes);
  }

  print("Extracted ${ddsFileOffsets.length} DDS files from WTP");
}

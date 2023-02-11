
import 'dart:io';

import 'package:path/path.dart';

Future<void> wemToWav(String wemPath, String wavPath, String assetsDir) async {
  var vgmStreamPath = join(assetsDir, "vgmStream", "vgmStream.exe");
  var process = await Process.run(vgmStreamPath, ["-o", wavPath, wemPath]);
  if (process.exitCode != 0) {
    print("stdout: ${process.stdout}");
    print("stderr: ${process.stderr}");
    throw Exception("WemToWav: Process exited with code ${process.exitCode}");
  }
  if (!await File(wavPath).exists()) {
    print("stdout: ${process.stdout}");
    print("stderr: ${process.stderr}");
    throw Exception("WemToWav: File not found ($wavPath)");
  }
}

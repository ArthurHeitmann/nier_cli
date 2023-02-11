
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';

const pythonCmd = "python3";

Future<bool> _processFile(String filePath, String assetsDir, [String pythonCmd = pythonCmd]) async {
  var pyToolPath = join(assetsDir, "MrubyDecompiler", "__init__.py");
  var result = await Process.run(pythonCmd, [pyToolPath, filePath]);
  if (result.exitCode != 0) {
    print("Error while processing file $filePath");
    print(result.stdout);
    print(result.stderr);
  }
  return result.exitCode == 0;
}

Future<bool> binFileToRuby(String filePath, String outPath, String assetsDir, [String pythonCmd = pythonCmd]) async {
  if (!await _processFile(filePath, assetsDir, pythonCmd))
    return false;
  var rbPath = "$filePath.rb";
  await File(rbPath).copy(outPath);
  await File(rbPath).delete();
  return true;
}

Future<bool> rubyFileToBin(String filePath, String outPath, String assetsDir, [String pythonCmd = pythonCmd]) async {
  var result = await _processFile(filePath, assetsDir, pythonCmd);
  if (!result)
    return false;
  // TODO is .bin and not .mrb
  var mrbPath = "$filePath.mrb";
  await File(mrbPath).copy(outPath);
  await File(mrbPath).delete();
  return true;
}


import 'dart:io';

import 'package:path/path.dart';

import 'CliOptions.dart';
import 'fileTypeUtils/audio/bnkExtractor.dart';
import 'fileTypeUtils/audio/bnkIO.dart';
import 'fileTypeUtils/audio/bnkRepacker.dart';
import 'fileTypeUtils/audio/wavToWemConverter.dart';
import 'fileTypeUtils/audio/wemToWavConverter.dart';
import 'fileTypeUtils/bxm/bxmReader.dart';
import 'fileTypeUtils/bxm/bxmWriter.dart';
import 'fileTypeUtils/dat/datExtractor.dart';
import 'fileTypeUtils/dat/datRepacker.dart';
import 'fileTypeUtils/pak/pakExtractor.dart';
import 'fileTypeUtils/pak/pakRepacker.dart';
import 'fileTypeUtils/ruby/pythonRuby.dart';
import 'fileTypeUtils/utils/ByteDataWrapper.dart';
import 'fileTypeUtils/wta/wtaWtpExtractor.dart';
import 'fileTypeUtils/wta/wtpDdsDumper.dart';
import 'fileTypeUtils/yax/xmlToYax.dart';
import 'fileTypeUtils/yax/yaxToXml.dart';
import 'utils.dart';

Future<bool> handleDatExtract(String input, String? output, CliOptions args, bool isFile, bool isDirectory) async {
  if (!args.isDat) {
    if (!strEndsWithDat(input))
      return false;
    if (!isFile)
      return false;
  }
  else {
    if (isDirectory)
      return false;
  }

  output ??= join(dirname(input), datExtractSubDir, basename(input));

  print("Extracting DAT file to $output...");

  await Directory(output).create(recursive: true);
  await extractDatFiles(input, output, shouldExtractPakFiles: args.extractPaksOnDatExtract);

  return true;
}
Future<bool> handleDatRepack(String input, String? output, CliOptions args, bool isFile, bool isDirectory) async {
  if (!args.isDat) {
    if (!strEndsWithDat(input))
      return false;
    if (!isDirectory)
      return false;
  }
  else {
    if (!isDirectory)
      throw Exception("Input DAT file or directory does not exist");
  }

  if (output == null) {
    var nameExt = await getDatNameParts(input);
    if (nameExt.item1 != null)
      output = join(dirname(input), nameExt.item1! + "." + nameExt.item2);
    else
      output = withoutExtension(input) + "." + nameExt.item2;
    if (await FileSystemEntity.isDirectory(output))
      output = withoutExtension(output) + "_repacked." + nameExt.item2;
  }

  print("Repacking DAT file to $output...");

  await repackDat(input, output);
  
  return true;
}
Future<bool> handlePakExtract(String input, String? output, CliOptions args, bool isFile, bool isDirectory) async {
  if (!args.isPak) {
    if (!input.endsWith(".pak"))
      return false;
    if (!isFile)
      return false;
  }
  else {
    if (isDirectory)
      return false;
  }

  output ??= join(dirname(input), pakExtractSubDir, basename(input));

  print("Extracting PAK file to $output...");

  await Directory(output).create(recursive: true);
  await extractPakFiles(input, output);

  return true;
}
Future<bool> handlePakRepack(String input, String? output, CliOptions args, bool isFile, bool isDirectory) async {
  if (!args.isPak) {
    if (!input.endsWith(".pak"))
      return false;
    if (!isDirectory)
      return false;
  }
  else {
    if (!isDirectory)
      throw Exception("Input PAK file or directory does not exist");
  }

  print("Repacking PAK file to $output...");

  await repackPak(input, output);
  return true;
}
Future<bool> handleBxmToXml(String input, String? output, CliOptions args, bool isFile, bool isDirectory) async {
  if (!args.isBxm) {
    if (!strEndsWithBxm(input))
      return false;
    if (!isFile)
      return false;
  }
  else {
    if (input.endsWith(".xml"))
      return false;
    if (!isFile)
      throw Exception("Input BXM file does not exist");
  }

  output ??= input + ".xml";

  print("Converting BXM to XML $output...");

  await convertBxmFileToXml(input, output);
  
  return true;
}
Future<bool> handleXmlToBxm(String input, String? output, CliOptions args, bool isFile, bool isDirectory) async {
  if (!args.isBxm) {
    if (!bxmExtensions.any((ext) => input.endsWith(ext + ".xml"))) {
      if (!isFile)
        return false;
      if (input.endsWith(".xml")) {
        var first3Bytes = await File(input)
          .openRead(0, 3)
          .expand((b) => b)
          .toList();
        var first3Chars = String.fromCharCodes(first3Bytes);
        if (!const { "BXM", "XML" }.contains(first3Chars))
          return false;
      } else {
        return false;
      }
    } else if (!isFile) {
      return false;
    }
  }
  else {
    if (!isFile)
      throw Exception("Input XML file does not exist");
  }

  output ??= withoutExtension(input);
  if (extension(output).isEmpty)
    output += ".bxm";

  print("Converting XML to BXM $output...");

  await convertXmlToBxmFile(input, output);
  
  return true;
}
Future<bool> handleYaxToXml(String input, String? output, CliOptions args, bool isFile, bool isDirectory) async {
  if (!args.isYax) {
    if (!input.endsWith(".yax"))
      return false;
    if (!isFile)
      return false;
  }
  else {
    if (input.endsWith(".xml"))
      return false;
    if (!isFile)
      throw Exception("Input YAX file does not exist");
  }

  output ??= withoutExtension(input) + ".xml";

  print("Converting YAX to XML $output...");

  await yaxFileToXmlFile(input, output);
  
  return true;
}
Future<bool> handleXmlToYax(String input, String? output, CliOptions args, bool isFile, bool isDirectory) async {
  if (!args.isYax) {
    if (!input.endsWith(".xml"))
      return false;
    if (!isFile)
      return false;
    if (!dirname(input).endsWith(".pak"))
      return false;
  }
  else {
    if (!isFile)
      throw Exception("Input XML file does not exist");
  }

  output ??= withoutExtension(input) + ".yax";

  print("Converting XML to YAX $output...");

  await xmlFileToYaxFile(input, output);
  
  return true;
}
Future<bool> handleMrubyDecompile(String input, String? output, CliOptions args, bool isFile, bool isDirectory) async {
  if (!args.isRuby) {
    if (!const { ".mrb", ".bin" }.any((ext) => input.endsWith(ext)))
      return false;
    if (!isFile)
      return false;
  }
  else {
    if (input.endsWith(".rb"))
      return false;
    if (!isFile)
      throw Exception("Input MRuby file does not exist");
  }

  output ??= withoutExtension(input) + ".rb";

  print("Decompiling MRuby to $output...");

  var assetsDir = await findAssetsDir();
  await binFileToRuby(input, output, assetsDir);
  
  return true;
}
Future<bool> handleRubyCompile(String input, String? output, CliOptions args, bool isFile, bool isDirectory) async {
  if (!args.isRuby) {
    if (!input.endsWith(".rb"))
      return false;
    if (!isFile)
      return false;
  }
  else {
    if (!isFile)
      throw Exception("Input Ruby file does not exist");
  }

  output ??= withoutExtension(input) + ".bin";

  print("Compiling Ruby to $output...");

  var assetsDir = await findAssetsDir();
  await rubyFileToBin(input, output, assetsDir);
  
  return true;
}
Future<bool> handleWtaWtpExtract(String input, String? output, CliOptions args, bool isFile, bool isDirectory) async {
  return 
    await handleWtaExtract(input, output, args, isFile, isDirectory) ||
    await handleWtpExtract(input, output, args, isFile, isDirectory);
}
Future<bool> handleWtaExtract(String input, String? output, CliOptions args, bool isFile, bool isDirectory) async {
  if (!args.isWtaWtp) {
    if (!input.endsWith(".wta"))
      return false;
    if (!isFile)
      return false;
  }
  else {
    // if (isDirectory)
    //   return false;
    if (!isFile)
      throw Exception("Input WTA file does not exist");
  }
  var wtpName = basenameWithoutExtension(input) + ".wtp";
  var datDir = dirname(input);
  // try to find wtp file. Multiple approaches:
  // - In same folder
  // - is in DTT
  //   - dtt name is basename of datDir
  //   - dtt name is basename of wta
  //     - dtt is extracted and folder is next to datDir
  //     - dtt is not extracted and 2 parent folders up

  var wtpPath = join(datDir, wtpName);
  if (!await FileSystemEntity.isFile(wtpPath)) {
    var dttName = basenameWithoutExtension(datDir);
    var dttDir = await findDttDir(datDir, dttName);
    if (dttDir == null) {
      dttName = basenameWithoutExtension(input);
      dttDir = await findDttDir(datDir, dttName);
      if (dttDir == null)
        throw Exception("Could not find WTP file for $input");
      else
        wtpPath = join(dttDir, wtpName);
    } else {
      wtpPath = join(dttDir, wtpName);
    }
  }
  if (!await FileSystemEntity.isFile(wtpPath))
    throw Exception("Could not find WTP file for $input");
  print("Found WTP file at $wtpPath");

  var dttDir = dirname(wtpPath);
  output ??= join(dttDir, basename(wtpName) + "_extracted");

  print("Extracting WTA DDS files to $output...");

  await Directory(output).create(recursive: true);
  await extractWtaWtp(input, wtpPath, output);

  return true;
}
Future<bool> handleWtpExtract(String input, String? output, CliOptions args, bool isFile, bool isDirectory) async {
  if (!args.isWtaWtp) {
    if (!input.endsWith(".wtp"))
      return false;
    if (!isFile)
      return false;
  }
  else {
    // if (isDirectory)
    //   return false;
    if (!isFile)
      throw Exception("Input WTP file does not exist");
  }

  output ??= join(dirname(input), basename(input) + "_extracted");

  print("Extracting WTP DDS files to $output...");

  await Directory(output).create(recursive: true);
  await dumpWtpDdsFiles(input, output);

  return true;
}
Future<bool> handleBnkExtract(String input, String? output, CliOptions args, bool isFile, bool isDirectory) async {
  if (!args.isBnk) {
    if (!input.endsWith(".bnk"))
      return false;
    if (!isFile)
      return false;
  }
  else {
    if (isDirectory)
      return false;
    if (!isFile)
      throw Exception("Input BNK file does not exist");
  }

  output ??= join(dirname(input), basename(input) + "_extracted");

  print("Extracting BNK to $output...");

  var bnk = BnkFile.read(await ByteDataWrapper.fromFile(input));
  await Directory(output).create(recursive: true);
  await extractBnkWems(bnk, output);
  
  return true;
}
Future<bool> handleBnkRepack(String input, String? output, CliOptions args, bool isFile, bool isDirectory) async {
  if (!args.isBnk) {
    if (!basename(input).contains(".bnk"))
      return false;
    if (!isDirectory)
      return false;
  }
  else {
    if (!isDirectory)
      throw Exception("Input BNK directory does not exist");
  }
  if (output == null)
    throw Exception("Output BNK file must be specified (for patching)");
  if (!await FileSystemEntity.isFile(output))
    throw Exception("Output BNK file does not exist (for patching)");

  print("Repacking BNK to $output...");

  await repackBnk(output, input);
  
  return true;
}
Future<bool> handleWemToWav(String input, String? output, CliOptions args, bool isFile, bool isDirectory) async {
  if (!args.isWem) {
    if (!input.endsWith(".wem"))
      return false;
    if (!isFile)
      return false;
  }
  else {
    if (input.endsWith(".wav"))
      return false;
    if (!isFile)
      throw Exception("Input WEM file does not exist");
  }

  output ??= withoutExtension(input) + ".wav";

  print("Converting WEM to WAV with VGM Stream $output...");

  var assetsDir = await findAssetsDir();
  await wemToWav(input, output, assetsDir);

  return true;
}
Future<bool> handleWavToWem(String input, String? output, CliOptions args, bool isFile, bool isDirectory) async {
  if (!args.isWem) {
    if (!input.endsWith(".wav"))
      return false;
    if (!isFile)
      return false;
  }
  else {
    if (!isFile)
      throw Exception("Input WAV file does not exist");
  }

  output ??= withoutExtension(input) + ".wem";

  print("Converting WAV to WEM with Wwise $output...");

  var assetsDir = await findAssetsDir();
  var wwiseCliPath = args.wwiseCliPath;
  if (wwiseCliPath == null)
    throw Exception("Wwise CLI path not specified");
  
  input = absolute(input);
  output = absolute(output);
  await wavToWem(input, output, args.isWemBGM, args.wemUsesVolumeNormalization, assetsDir, wwiseCliPath);
  
  return true;
}

const List<Future<bool> Function(String, String?, CliOptions, bool, bool)> _handlers = [
  handleDatExtract,
  handleDatRepack,
  handlePakExtract,
  handlePakRepack,
  handleBxmToXml,
  handleXmlToBxm,
  handleYaxToXml,
  handleXmlToYax,
  handleMrubyDecompile,
  handleRubyCompile,
  handleWtaWtpExtract,
  handleBnkExtract,
  handleBnkRepack,
  handleWemToWav,
  handleWavToWem,
];

Future<void> handleInput(String input, String? output, CliOptions args) async {
  bool isFile = await FileSystemEntity.isFile(input);
  bool isDirectory = await FileSystemEntity.isDirectory(input);
  if (!isFile && !isDirectory)
    throw Exception("Input file or directory does not exist");

  for (var handler in _handlers) {
    if (await handler(input, output, args, isFile, isDirectory)) {
      print("Done :D");
      return;
    }
  }
  throw Exception("Unknown file type");
}

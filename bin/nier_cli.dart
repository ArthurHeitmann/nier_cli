import 'dart:io';

import 'package:args/args.dart';
import 'package:nier_cli/CliOptions.dart';
import 'package:nier_cli/exception.dart';
import 'package:nier_cli/fileTypeHandler.dart';
import 'package:nier_cli/utils.dart';
import 'package:path/path.dart';

Future<void> main(List<String> arguments) async {
  var t1 = DateTime.now();

  // arguments: [input, -o (optional) output, (optional) args]])]
  // arguments: [input1, [input2], [input...], (optional) args]])]
  var configArgs = await readConfig();
  arguments = [...configArgs, ...arguments];
  var argParser = ArgParser();
  argParser.addOption("output", abbr: "o", help: "Output file or folder");
  argParser.addSeparator("Extraction Options:");
  argParser.addFlag("folder", help: "Extract all files in a folder", negatable: false);
  argParser.addFlag("recursive", abbr: "r", help: "Extract all files in a folder and all subfolders", negatable: false);
  argParser.addFlag("autoExtractChildren", help: "When unpacking DAT, CPK, PAK, etc. files automatically process all extracted files", negatable: false);
  argParser.addSeparator("WAV to WEM Conversion Options:");
  argParser.addOption("wwiseCli", help: "Path to WwiseCLI.exe, needed for WAV to WEM conversion");
  argParser.addFlag("wemBGM", help: "When converting WAV to WEM, use music/BGM settings", negatable: false);
  argParser.addFlag("wemVolNorm", help: "When converting WAV to WEM, enable volume normalization", negatable: false);
  argParser.addSeparator("Extraction filters:");
  argParser.addFlag("CPK", help: "Only extract CPK files", negatable: false);
  argParser.addFlag("DAT", help: "Only extract DAT files", negatable: false);
  argParser.addFlag("PAK", help: "Only extract PAK files", negatable: false);
  argParser.addFlag("BXM", help: "Only extract BXM files", negatable: false);
  argParser.addFlag("YAX", help: "Only extract YAX files", negatable: false);
  argParser.addFlag("RUBY", help: "Only extract RUBY files", negatable: false);
  argParser.addFlag("WTA", help: "Only extract WTA files", negatable: false);
  argParser.addFlag("WTP", help: "Only extract WTP files", negatable: false);
  argParser.addFlag("BNK", help: "Only extract BNK files", negatable: false);
  argParser.addFlag("WEM", help: "Only extract WEM files", negatable: false);
  argParser.addFlag("help", abbr: "h", help: "Print this help message", negatable: false);
  var args = argParser.parse(arguments);

  if (arguments.length < 1 || args["help"] == true) {
    printHelp(argParser);
    return;
  }

  var options = CliOptions(
    output: args["output"],
    folderMode: args["folder"], recursiveMode: args["recursive"],
    autoExtractChildren: args["autoExtractChildren"],
    wwiseCliPath: args["wwiseCli"],
    isWemBGM: args["wemBGM"], wemUsesVolumeNormalization: args["wemVolNorm"],
    isCpk: args["CPK"],
    isDat: args["DAT"], isPak: args["PAK"],
    isBxm: args["BXM"], isYax: args["YAX"],
    isRuby: args["RUBY"],
    isWta: args["WTA"], isWtp: args["WTP"],
    isBnk: args["BNK"], isWem: args["WEM"],
  );

  var fileModeOptionsCount = [options.recursiveMode, options.folderMode]
    .where((b) => b)
    .length;
  if (fileModeOptionsCount > 1) {
    print("Only one of --folder, or --recursive can be used at a time");
    return;
  }
  if (fileModeOptionsCount > 0 && options.output != null) {
    print("Cannot use --folder or --recursive with --output");
    return;
  }
  if (args.rest.isEmpty) {
    print("No input files specified");
    return;
  }

  String input = args.rest[0];
  String? output;
  List<String> pendingFiles = [];
  Set<String> processedFiles = {};
  if (options.recursiveMode) {
    pendingFiles.addAll(Directory(input).listSync(recursive: true).where((e) => e is File).map((e) => e.path));
  } else if (options.folderMode) {
    pendingFiles.addAll(Directory(input).listSync().where((e) => e is File).map((e) => e.path));
  } else if (options.output != null) {
    output = options.output;
    pendingFiles.add(options.output!);
  } else {
    pendingFiles.addAll(args.rest);
  }

  List<String> errorFiles = [];
  while (pendingFiles.isNotEmpty) {
    input = pendingFiles.removeAt(0);
    if (processedFiles.contains(input))
      continue;
    try {
      await handleInput(input, output, options, pendingFiles, processedFiles);
      processedFiles.add(input);
      output = null;
    } on FileHandlingException catch (e) {
      print("Invalid input");
      print(e);
      if (pendingFiles.isEmpty && processedFiles.isEmpty) {
        print("Press Enter to exit...");
        stdin.readLineSync();
      }
      errorFiles.add(input);
    } catch (e, stackTrace) {
      print("Failed to process file");
      print(e);
      print(stackTrace);
      if (pendingFiles.isEmpty && processedFiles.isEmpty) {
        print("Press Enter to exit...");
        stdin.readLineSync();
      }
      errorFiles.add(input);
    }
  }

  var tD = DateTime.now().difference(t1);
  if (processedFiles.length == 1)
    print("Done (${timeStr(tD)}) :D");
  else {
    if (errorFiles.isNotEmpty) {
      print("Failed to process ${errorFiles.length} files:");
      for (var f in errorFiles)
        print("- $f");
    }
    print(
      "Processed ${processedFiles.length} files "
      "in ${timeStr(tD)} "
      ":D"
    );
  }
}

void printHelp(ArgParser argParser) {
  print("Usage:");
  print("  nier_cli <input1> [input2] [input...] [options]");
  print("or");
  print("  nier_cli <input> -o <output> [options]");
  print(argParser.usage);
}

String timeStr(Duration d) {
  var ms = d.inMilliseconds;
  if (ms < 1000)
    return "${ms}ms";
  else if (ms < 60000)
    return "${(ms / 1000).toStringAsFixed(2)}s";
  else {
    var m = d.inMinutes;
    var s = (ms / 1000) % 60;
    return "${m}m ${s.toStringAsFixed(2)}s";
  }
}

Future<List<String>> readConfig() async {
  const configName = "config.txt";
  var configPath = join(getAppDir(), configName);
  if (!await File(configPath).exists())
    return [];
  var text = await File(configPath).readAsString();
  var seperator = text.contains("\r\n") ? "\r\n" : "\n";
  var args = text
    .split(seperator)
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty && !e.startsWith("#"))
    .toList();
  return args;
}

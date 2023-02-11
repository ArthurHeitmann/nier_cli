import 'dart:io';

import 'package:args/args.dart';
import 'package:nier_cli/CliOptions.dart';
import 'package:nier_cli/fileTypeHandler.dart';

Future<void> main(List<String> arguments) async {
  // arguments: [input, (optional) output, (optional) args]])]
  var argParser = ArgParser();
  argParser.addOption("wwiseCli", help: "Path to WwiseCLI.exe, needed for WAV to WEM conversion");
  argParser.addFlag("extractPaksWithDat", help: "Extract PAK files when extracting DAT files", negatable: false);
  argParser.addFlag("wemBGM", help: "When converting WAV to WEM, use music/BGM settings", negatable: false);
  argParser.addFlag("wemVolNorm", help: "When converting WAV to WEM, enable volume normalization", negatable: false);
  argParser.addFlag("DAT", help: "Force DAT mode", negatable: false);
  argParser.addFlag("PAK", help: "Force PAK mode", negatable: false);
  argParser.addFlag("BXM", help: "Force BXM mode", negatable: false);
  argParser.addFlag("YAX", help: "Force YAX mode", negatable: false);
  argParser.addFlag("RUBY", help: "Force RUBY mode", negatable: false);
  argParser.addFlag("WTA", help: "Force WTA/WTP mode", negatable: false);
  argParser.addFlag("WTP", help: "Force WTA/WTP mode", negatable: false);
  argParser.addFlag("BNK", help: "Force BNK mode", negatable: false);
  argParser.addFlag("WEM", help: "Force WEM mode", negatable: false);
  argParser.addFlag("help", abbr: "h", help: "Print this help message", negatable: false);
  var args = argParser.parse(arguments);

  if (arguments.length < 1 || args["help"] == true) {
    printHelp(argParser);
    return;
  }

  String input = args.rest[0];
  String? output = args.rest.length > 1 ? args.rest[1] : null;
  var options = CliOptions(
    wwiseCliPath: args["wwiseCli"],
    extractPaksOnDatExtract: args["extractPaksWithDat"],
    isWemBGM: args["wemBGM"], wemUsesVolumeNormalization: args["wemVolNorm"],
    isDat: args["DAT"], isPak: args["PAK"],
    isBxm: args["BXM"], isYax: args["YAX"],
    isRuby: args["RUBY"], isWtaWtp: args["WTA"] || args["WTP"],
    isBnk: args["BNK"], isWem: args["WEM"],
  );

  try {
    await handleInput(input, output, options);
  } catch (e, stackTrace) {
    print("Failed to process input");
    print(e);
    print(stackTrace);

    print("Press Enter...");
    stdin.readLineSync();
  }
}

void printHelp(ArgParser argParser) {
  print("Usage: nier_cli inputFile [outputFile] [options]");
  print(argParser.usage);
}


import 'dart:io';

import 'package:euc/jis.dart';
import 'package:xml/xml.dart';

import '../xml/xmlExtension.dart';

Future<void> decompressZlibXml(String input, String output) async {
  var bytes = await File(input).readAsBytes();
  var decompressed = ZLibDecoder().convert(bytes);
  var str = ShiftJIS().decode(decompressed);
  var xml = XmlDocument.parse(str);
  var xmlStr = xml.toPrettyString();
  await File(output).writeAsString(xmlStr);
}

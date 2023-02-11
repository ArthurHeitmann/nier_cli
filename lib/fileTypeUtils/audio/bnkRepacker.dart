
import 'dart:io';

import 'package:path/path.dart';
import 'package:tuple/tuple.dart';

import '../utils/ByteDataWrapper.dart';
import 'bnkIO.dart';

Future<void> repackBnk(String bnkPath, String bnkExtractedPath) async {
  var wemFiles = await Directory(bnkExtractedPath)
    .list()
    .where((f) => f is File)
    .where((f) => f.path.endsWith('.wem'))
    .toList();
  
  List<Tuple3<String, int, int>> wemsPathIndexId = [];
  // INDEX_..._ID.wem
  for (var wemFile in wemFiles) {
    var wemFileName = basenameWithoutExtension(wemFile.path);
    if (!RegExp(r"^\d+_.*_\d+$").hasMatch(wemFileName)) {
      throw Exception("Invalid wem file name: $wemFileName.bnk. Expected format: INDEX_..._ID.wem");
    }
    var wemFileNameParts = wemFileName.split('_');
    var wemIndex = int.parse(wemFileNameParts.first);
    var wemId = int.parse(wemFileNameParts.last);
    wemsPathIndexId.add(Tuple3(wemFile.path, wemIndex, wemId));
  }
  wemsPathIndexId.sort((a, b) => a.item2.compareTo(b.item2));

  var bnk = BnkFile.read(await ByteDataWrapper.fromFile(bnkPath));
  var didxChunkRes = bnk.chunks.whereType<BnkDidxChunk>();
  var dataChunkRes = bnk.chunks.whereType<BnkDataChunk>();
  if (didxChunkRes.isEmpty && dataChunkRes.isEmpty)
    throw Exception("BNK file is missing DIDX and DATA chunks");
  if (didxChunkRes.isEmpty)
    throw Exception("BNK file is missing DIDX chunk");
  if (dataChunkRes.isEmpty)
    throw Exception("BNK file is missing DATA chunk");
  var didxChunk = didxChunkRes.first;
  var dataChunk = dataChunkRes.first;

  didxChunk.files.clear();
  dataChunk.wemFiles.clear();

  int offset = 0;
  for (var wemInfo in wemsPathIndexId) {
    var wemBytes = await File(wemInfo.item1).readAsBytes();
    dataChunk.wemFiles.add(wemBytes);
    didxChunk.files.add(BnkWemFileInfo(wemInfo.item3, offset, wemBytes.length));
    offset += wemBytes.length;
    offset = (offset + 15) & ~15;
  }

  dataChunk.chunkSize = dataChunk.calculateSize() - 8;
  didxChunk.chunkSize = didxChunk.calculateSize() - 8;

  var bnkBytes = ByteDataWrapper.allocate(bnk.calculateSize());
  bnk.write(bnkBytes);
  await File(bnkPath).writeAsBytes(bnkBytes.buffer.asUint8List());

  print("Repacked ${wemsPathIndexId.length} wem files.");
}

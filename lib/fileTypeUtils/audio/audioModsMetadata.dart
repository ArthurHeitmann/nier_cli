
import 'dart:convert';
import 'dart:io';

class AudioModChunkInfo {
  final int id;
  final String? name;
  final int? timestamp;

  const AudioModChunkInfo(this.id, { this.name, this.timestamp });

  AudioModChunkInfo.fromJSON(Map<String, dynamic> json) :
    id = json["id"],
    name = json["name"],
    timestamp = json["date"];
  
  Map<String, dynamic> toJSON() => {
    "id": id,
    if (name != null)
      "name": name,
    if (timestamp != null)
      "date": timestamp,
  };
}

class AudioModsMetadata {
  String? name;
  final Map<int, AudioModChunkInfo> moddedWaiChunks;
  final Map<int, AudioModChunkInfo> moddedBnkChunks;

  AudioModsMetadata(this.name, this.moddedWaiChunks, this.moddedBnkChunks);

  AudioModsMetadata.fromJSON(Map<String, dynamic> json) :
    name = json["name"],
    moddedWaiChunks = {
      for (var e in (json["moddedWaiChunks"] as Map).values)
        e["id"] : AudioModChunkInfo.fromJSON(e)
    },
    moddedBnkChunks = {
      for (var e in (json["moddedBnkChunks"] as Map).values)
        e["id"] : AudioModChunkInfo.fromJSON(e)
    };
  
  static Future<AudioModsMetadata> fromFile(String path) async {
    if (!await File(path).exists())
      return AudioModsMetadata(null, {}, {});
    var json = jsonDecode(await File(path).readAsString());
    return AudioModsMetadata.fromJSON(json);
  }
  
  Map<String, dynamic> toJSON() => {
    "name": name,
    "moddedWaiChunks": {
      for (var e in moddedWaiChunks.values)
        e.id.toString() : e.toJSON()
    },
    "moddedBnkChunks": {
      for (var e in moddedBnkChunks.values)
        e.id.toString() : e.toJSON()
    },
  };

  Future<void> toFile(String path) async {
    var encoder = const JsonEncoder.withIndent("\t");
    await File(path).writeAsString(encoder.convert(toJSON()));
  }
}

const String audioModsMetadataFileName = "audioModsMetadata.json";

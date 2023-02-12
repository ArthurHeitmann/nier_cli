
class CliOptions {
  final String? output;
  final bool folderMode;
  final bool recursiveMode;
  final bool autoExtractChildren;
  final String? wwiseCliPath;
  final bool isWemBGM;
  final bool wemUsesVolumeNormalization;
  final bool isCpk;
  final bool isDat;
  final bool isPak;
  final bool isBxm;
  final bool isYax;
  final bool isRuby;
  final bool isWta;
  final bool isWtp;
  final bool isBnk;
  final bool isWem;
  final bool fileTypeIsKnown;
  final bool onlyExtract;

  CliOptions({
    required this.output,
    required this.folderMode, required this.recursiveMode,
    required this.autoExtractChildren,
    this.wwiseCliPath,
    required this.isWemBGM, required this.wemUsesVolumeNormalization,
    required this.isCpk,
    required this.isDat, required this.isPak,
    required this.isBxm, required this.isYax,
    required this.isRuby,
    required this.isWta, required this.isWtp,
    required this.isBnk, required this.isWem
  }) :
    fileTypeIsKnown = isCpk || isDat || isPak || isBxm || isYax || isRuby || isWta || isWtp || isBnk || isWem,
    onlyExtract = autoExtractChildren || folderMode || recursiveMode;
}

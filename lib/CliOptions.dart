
class CliOptions {
  final String? wwiseCliPath;
  final bool extractPaksOnDatExtract;
  final bool isWemBGM;
  final bool wemUsesVolumeNormalization;
  final bool isDat;
  final bool isPak;
  final bool isBxm;
  final bool isYax;
  final bool isRuby;
  final bool isWtaWtp;
  final bool isBnk;
  final bool isWem;

  CliOptions({
    this.wwiseCliPath,
    this.extractPaksOnDatExtract = false,
    this.isWemBGM = false, this.wemUsesVolumeNormalization = false,
    this.isDat = false, this.isPak = false,
    this.isBxm = false, this.isYax = false,
    this.isRuby = false, this.isWtaWtp = false,
    this.isBnk = false, this.isWem = false
  });
}

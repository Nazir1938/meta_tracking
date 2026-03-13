import 'package:flutter/foundation.dart';

/// Log seviyyeleri
enum LogSeviyyesi {
  melumat, // INFO
  xeberdarliq, // WARNING
  xeta, // ERROR
  ugur, // SUCCESS
  debug, // DEBUG
}

/// Meta Tracking tetbiq ucun Azerbaycanca Logger
class AppLogger {
  static const String _ayirici = '=======================================';
  static const String _xettAyirici = '---------------------------------------';

  static bool _aktiv = true;
  static bool _zamanGoster = true;
  static bool _yalnizDebug = false;

  /// Logger-i konfiqurasiya et
  static void konfiqurasiya({
    bool aktiv = true,
    bool zamanGoster = true,
    bool yalnizDebug = false,
  }) {
    _aktiv = aktiv;
    _zamanGoster = zamanGoster;
    _yalnizDebug = yalnizDebug;
  }

  // --- Esas log metodlari ---------------------------------------------------

  /// Adi melumat logu
  static void melumat(String modul, String mesaj, {dynamic data}) {
    _log(LogSeviyyesi.melumat, modul, mesaj, data: data);
  }

  /// Ugurlu emeliyyat logu
  static void ugur(String modul, String mesaj, {dynamic data}) {
    _log(LogSeviyyesi.ugur, modul, mesaj, data: data);
  }

  /// Xeberdarliq logu
  static void xeberdarliq(String modul, String mesaj, {dynamic data}) {
    _log(LogSeviyyesi.xeberdarliq, modul, mesaj, data: data);
  }

  /// Xeta logu
  static void xeta(
    String modul,
    String mesaj, {
    dynamic xetaObyekti,
    StackTrace? yiginIzi,
  }) {
    _log(
      LogSeviyyesi.xeta,
      modul,
      mesaj,
      data: xetaObyekti,
      yiginIzi: yiginIzi,
    );
  }

  /// Debug logu (yalniz development modda)
  static void debug(String modul, String mesaj, {dynamic data}) {
    _log(LogSeviyyesi.debug, modul, mesaj, data: data);
  }

  // --- Xususi emeliyyat loglari ---------------------------------------------

  /// Tetbiq baslangiclogi
  static void tetbiqBasladi() {
    if (!_aktiv) return;
    debugPrint(_ayirici);
    debugPrint('>> META TRACKING TETBIQI BASLADI');
    debugPrint('>> Tarix: ${_indikiZaman()}');
    debugPrint('>> Rejim: ${kDebugMode ? "Debug" : "Release"}');
    debugPrint(_ayirici);
  }

  /// Ekran acilis logu
  static void ekranAcildi(String ekranAdi) {
    _log(LogSeviyyesi.melumat, 'NAVIGASIYA', '[ACILDI] Ekran: $ekranAdi');
  }

  /// Ekran baglanis logu
  static void ekranBaglandi(String ekranAdi) {
    _log(LogSeviyyesi.melumat, 'NAVIGASIYA', '[BAGLANDI] Ekran: $ekranAdi');
  }

  /// Heyvan emeliyyat logu
  static void heyvanEmeliyyati(
    String emeliyyat,
    String heyvanAdi, {
    dynamic data,
  }) {
    _log(
      LogSeviyyesi.melumat,
      'HEYVAN',
      '[HEYVAN] $emeliyyat -> $heyvanAdi',
      data: data,
    );
  }

  /// Zona emeliyyat logu
  static void zonaEmeliyyati(String emeliyyat, String zonaAdi, {dynamic data}) {
    _log(
      LogSeviyyesi.melumat,
      'ZONA',
      '[ZONA] $emeliyyat -> $zonaAdi',
      data: data,
    );
  }

  /// Xerite emeliyyat logu
  static void xeriteEmeliyyati(String mesaj, {dynamic data}) {
    _log(LogSeviyyesi.melumat, 'XERITE', '[XERITE] $mesaj', data: data);
  }

  /// Bildiriş emeliyyat logu
  static void bildirisEmeliyyati(String mesaj, {dynamic data}) {
    _log(LogSeviyyesi.melumat, 'BILDIRIŞ', '[BILDIRIŞ] $mesaj', data: data);
  }

  /// Geofence hadise logu
  static void geofenceHadise(String heyvanAdi, String zonaAdi, bool daxilOldu) {
    final status = daxilOldu ? 'daxil oldu' : 'cixdi';
    final prefix = daxilOldu ? '[>>]' : '[<<]';
    _log(
      daxilOldu ? LogSeviyyesi.ugur : LogSeviyyesi.xeberdarliq,
      'GEOFENCE',
      '$prefix $heyvanAdi "$zonaAdi" zonasina $status',
    );
  }

  /// BLoC hadise logu
  static void blocHadise(String blocAdi, String hadiseAdi) {
    _log(LogSeviyyesi.debug, 'BLOC', '[HADISE] $blocAdi -> $hadiseAdi');
  }

  /// BLoC veziyyet logu
  static void blocVeziyyet(String blocAdi, String veziyyetAdi) {
    _log(LogSeviyyesi.debug, 'BLOC', '[VEZIYYET] $blocAdi -> $veziyyetAdi');
  }

  /// API sorgu logu
  static void apiSorgu(String endpoint, {Map<String, dynamic>? parametrler}) {
    _log(LogSeviyyesi.melumat, 'API', '[SORGU] $endpoint', data: parametrler);
  }

  /// API cavab logu
  static void apiCavab(String endpoint, int statusKod, {dynamic data}) {
    final seviyye = statusKod >= 200 && statusKod < 300
        ? LogSeviyyesi.ugur
        : LogSeviyyesi.xeta;
    _log(seviyye, 'API', '[CAVAB $statusKod] $endpoint', data: data);
  }

  /// Performans olcum logu
  static void performans(String emeliyyat, Duration muddet) {
    final ms = muddet.inMilliseconds;
    final seviyye = ms < 500
        ? LogSeviyyesi.ugur
        : ms < 2000
        ? LogSeviyyesi.xeberdarliq
        : LogSeviyyesi.xeta;
    _log(seviyye, 'PERFORMANS', '[MUDDET] $emeliyyat: ${ms}ms');
  }

  /// Ayirici xett cap et
  static void ayirici({String? bashliq}) {
    if (!_aktiv) return;
    if (bashliq != null) {
      debugPrint('$_xettAyirici $bashliq $_xettAyirici');
    } else {
      debugPrint(_xettAyirici);
    }
  }

  // --- Daxili metodlar ------------------------------------------------------

  static void _log(
    LogSeviyyesi seviyye,
    String modul,
    String mesaj, {
    dynamic data,
    StackTrace? yiginIzi,
  }) {
    if (!_aktiv) return;
    if (_yalnizDebug && !kDebugMode) return;
    if (seviyye == LogSeviyyesi.debug && !kDebugMode) return;

    final zaman = _zamanGoster ? '[${_indikiZaman()}] ' : '';
    final ikon = _seviyyeIkonu(seviyye);
    final modulFormatli = '[${modul.padRight(10)}]';

    debugPrint('$zaman$ikon $modulFormatli $mesaj');

    if (data != null) {
      debugPrint('   |-- Data: $data');
    }
    if (yiginIzi != null) {
      debugPrint('   |-- Yigin Izi:\n$yiginIzi');
    }
  }

  static String _indikiZaman() {
    final now = DateTime.now();
    final saat = now.hour.toString().padLeft(2, '0');
    final deqiqe = now.minute.toString().padLeft(2, '0');
    final saniye = now.second.toString().padLeft(2, '0');
    final milisaniye = now.millisecond.toString().padLeft(3, '0');
    return '$saat:$deqiqe:$saniye.$milisaniye';
  }

  static String _seviyyeIkonu(LogSeviyyesi seviyye) {
    switch (seviyye) {
      case LogSeviyyesi.melumat:
        return '[I]';
      case LogSeviyyesi.ugur:
        return '[+]';
      case LogSeviyyesi.xeberdarliq:
        return '[!]';
      case LogSeviyyesi.xeta:
        return '[X]';
      case LogSeviyyesi.debug:
        return '[D]';
    }
  }
}

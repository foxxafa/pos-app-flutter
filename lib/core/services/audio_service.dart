import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Singleton audio service - Ses dosyaları SADECE BİR KEZ yüklenir!
/// Uygulama boyunca aynı instance kullanılır
class AudioService {
  // Singleton pattern
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  static AudioService get instance => _instance;

  AudioService._internal();

  // Audio players - LOW_LATENCY mode
  final AudioPlayer _audioPlayerBeepK = AudioPlayer(playerId: 'global_beepk');
  final AudioPlayer _audioPlayerBoopK = AudioPlayer(playerId: 'global_boopk');
  final AudioPlayer _audioPlayerDit = AudioPlayer(playerId: 'global_ditdit');
  final AudioPlayer _audioPlayerWrong = AudioPlayer(playerId: 'global_wrongk');

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  /// Ses dosyalarını yükle (sadece ilk çağrıda yüklenir!)
  Future<void> ensureLoaded() async {
    if (_isLoaded) {
      print('🎵 Ses dosyaları zaten yüklü (cache\'ten kullanılıyor)');
      return;
    }

    print('⏳ Ses dosyaları yükleniyor...');

    // Volume ayarları
    _audioPlayerBeepK.setVolume(0.8);
    _audioPlayerBoopK.setVolume(0.8);
    _audioPlayerDit.setVolume(0.8);
    _audioPlayerWrong.setVolume(0.8);

    // 🚀 Ses dosyalarını SIRALI yükle (timeout ve retry mekanizması ile)
    try {
      await _loadAudioWithRetry(_audioPlayerBeepK, 'beepk.mp3');
      await _loadAudioWithRetry(_audioPlayerBoopK, 'boopk.mp3');
      await _loadAudioWithRetry(_audioPlayerDit, 'ditdit.mp3');
      await _loadAudioWithRetry(_audioPlayerWrong, 'wrongk.mp3');
    } catch (e) {
      print('❌ Ses dosyaları yüklenemedi (tüm denemeler başarısız): $e');
      _isLoaded = false; // Tekrar denenebilsin
      rethrow; // Hatayı yukarı ilet ki cart_view.dart catch bloğu yakalasın
    }

    // Source set edildikten SONRA player mode ve release mode ayarla
    _audioPlayerBeepK.setPlayerMode(PlayerMode.lowLatency);
    _audioPlayerBoopK.setPlayerMode(PlayerMode.lowLatency);
    _audioPlayerDit.setPlayerMode(PlayerMode.lowLatency);
    _audioPlayerWrong.setPlayerMode(PlayerMode.lowLatency);

    // ReleaseMode.stop: Ses bitince durur, tekrar çalmaya hazır olur
    _audioPlayerBeepK.setReleaseMode(ReleaseMode.stop);
    _audioPlayerBoopK.setReleaseMode(ReleaseMode.stop);
    _audioPlayerDit.setReleaseMode(ReleaseMode.stop);
    _audioPlayerWrong.setReleaseMode(ReleaseMode.stop);

    _isLoaded = true;
    print('🎵 Tüm ses dosyaları yüklendi ve LOW_LATENCY mode aktif!');
  }

  /// Ses dosyasını timeout ve retry mekanizması ile yükle
  Future<void> _loadAudioWithRetry(
    AudioPlayer player,
    String assetName, {
    int maxRetries = 3,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🔄 $assetName yükleniyor (deneme $attempt/$maxRetries)...');

        // Her denemede player'ı temizle (timeout sonrası state problemi olabilir)
        if (attempt > 1) {
          await player.stop();
          await player.release();
          print('🔧 Player reset edildi');
        }

        await player.setSource(AssetSource(assetName)).timeout(
          timeout,
          onTimeout: () {
            throw TimeoutException(
              '$assetName yüklenirken timeout ($timeout)',
              timeout,
            );
          },
        );

        print('✅ $assetName loaded');
        return; // Başarılı, fonksiyondan çık
      } catch (e) {
        print('⚠️ $assetName hata (deneme $attempt/$maxRetries): $e');

        if (attempt == maxRetries) {
          throw Exception('$assetName $maxRetries denemeden sonra yüklenemedi: $e');
        }

        // Kısa bir bekleme süresi ekle (exponential backoff)
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      }
    }
  }

  /// İlk okutma sesi (beepk.mp3)
  Future<void> playBeepK() async {
    await _audioPlayerBeepK.stop();
    await _audioPlayerBeepK.resume();
  }

  /// Tekrar okutma sesi (boopk.mp3)
  Future<void> playBoopK() async {
    await _audioPlayerBoopK.stop();
    await _audioPlayerBoopK.resume();
  }

  /// Suspended ürün sesi (ditdit.mp3)
  Future<void> playDit() async {
    await _audioPlayerDit.stop();
    await _audioPlayerDit.resume();
  }

  /// Hata sesi (wrongk.mp3)
  Future<void> playWrong() async {
    await _audioPlayerWrong.stop();
    await _audioPlayerWrong.resume();
  }

  /// Dispose - Sadece uygulama kapanırken çağrılır!
  void dispose() {
    _audioPlayerBeepK.dispose();
    _audioPlayerBoopK.dispose();
    _audioPlayerDit.dispose();
    _audioPlayerWrong.dispose();
  }
}

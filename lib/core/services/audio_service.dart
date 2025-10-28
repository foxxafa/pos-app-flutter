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

  // Track loading state per audio file
  bool _beepKLoaded = false;
  bool _boopKLoaded = false;
  bool _ditLoaded = false;
  bool _wrongLoaded = false;

  bool get isLoaded => _beepKLoaded && _boopKLoaded && _ditLoaded && _wrongLoaded;

  /// Lazy load: Her ses dosyası ilk çalındığında yükle
  Future<void> _ensureAudioLoaded(
    AudioPlayer player,
    String assetName,
    bool Function() isLoadedGetter,
    void Function(bool) isLoadedSetter,
  ) async {
    if (isLoadedGetter()) return; // Zaten yüklü

    try {
      print('🔄 $assetName lazy loading...');

      // Volume ve mode ayarları
      player.setVolume(0.8);

      // Ses dosyasını yükle (timeout: 3 saniye - daha agresif)
      await player.setSource(AssetSource(assetName)).timeout(
        Duration(seconds: 3),
        onTimeout: () {
          throw TimeoutException('$assetName timeout', Duration(seconds: 3));
        },
      );

      // Source set edildikten SONRA player mode ve release mode ayarla
      player.setPlayerMode(PlayerMode.lowLatency);
      player.setReleaseMode(ReleaseMode.stop);

      isLoadedSetter(true);
      print('✅ $assetName loaded');
    } catch (e) {
      print('⚠️ $assetName yüklenemedi: $e');
      isLoadedSetter(false);
      // Hata fırlatma - sessiz devam et
    }
  }

  /// İlk okutma sesi (beepk.mp3)
  Future<void> playBeepK() async {
    await _ensureAudioLoaded(
      _audioPlayerBeepK,
      'beepk.mp3',
      () => _beepKLoaded,
      (val) => _beepKLoaded = val,
    );
    if (!_beepKLoaded) return; // Yüklenemedi, sessiz devam et
    await _audioPlayerBeepK.stop();
    await _audioPlayerBeepK.resume();
  }

  /// Tekrar okutma sesi (boopk.mp3)
  Future<void> playBoopK() async {
    await _ensureAudioLoaded(
      _audioPlayerBoopK,
      'boopk.mp3',
      () => _boopKLoaded,
      (val) => _boopKLoaded = val,
    );
    if (!_boopKLoaded) return; // Yüklenemedi, sessiz devam et
    await _audioPlayerBoopK.stop();
    await _audioPlayerBoopK.resume();
  }

  /// Suspended ürün sesi (ditdit.mp3)
  Future<void> playDit() async {
    await _ensureAudioLoaded(
      _audioPlayerDit,
      'ditdit.mp3',
      () => _ditLoaded,
      (val) => _ditLoaded = val,
    );
    if (!_ditLoaded) return; // Yüklenemedi, sessiz devam et
    await _audioPlayerDit.stop();
    await _audioPlayerDit.resume();
  }

  /// Hata sesi (wrongk.mp3)
  Future<void> playWrong() async {
    await _ensureAudioLoaded(
      _audioPlayerWrong,
      'wrongk.mp3',
      () => _wrongLoaded,
      (val) => _wrongLoaded = val,
    );
    if (!_wrongLoaded) return; // Yüklenemedi, sessiz devam et
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

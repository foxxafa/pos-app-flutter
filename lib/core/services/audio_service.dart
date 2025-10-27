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

    print('⏳ Ses dosyaları yükleniyor (LOW_LATENCY mode - ilk kez)...');

    // ⚡ LOW_LATENCY mode: Ses dosyaları hafızada tutulur, anında çalınır!
    _audioPlayerBeepK.setPlayerMode(PlayerMode.lowLatency);
    _audioPlayerBoopK.setPlayerMode(PlayerMode.lowLatency);
    _audioPlayerDit.setPlayerMode(PlayerMode.lowLatency);
    _audioPlayerWrong.setPlayerMode(PlayerMode.lowLatency);

    _audioPlayerBeepK.setVolume(0.8);
    _audioPlayerBoopK.setVolume(0.8);
    _audioPlayerDit.setVolume(0.8);
    _audioPlayerWrong.setVolume(0.8);

    // 🚀 Ses dosyalarını SIRALI yükle (paralel yükleme sorun çıkarıyordu)
    try {
      await _audioPlayerBeepK.setSource(AssetSource('beepk.mp3'));
      print('✅ beepk.mp3 loaded');

      await _audioPlayerBoopK.setSource(AssetSource('boopk.mp3'));
      print('✅ boopk.mp3 loaded');

      await _audioPlayerDit.setSource(AssetSource('ditdit.mp3'));
      print('✅ ditdit.mp3 loaded');

      await _audioPlayerWrong.setSource(AssetSource('wrongk.mp3'));
      print('✅ wrongk.mp3 loaded');
    } catch (e) {
      print('⚠️ Ses dosyaları yüklenirken hata: $e');
      // Ses yükleme başarısız olsa bile devam et
      _isLoaded = false; // Tekrar denenebilsin
      rethrow; // Hatayı yukarı ilet ki cart_view.dart catch bloğu yakalasın
    }

    // ReleaseMode.stop: Ses bitince durur, tekrar çalmaya hazır olur
    _audioPlayerBeepK.setReleaseMode(ReleaseMode.stop);
    _audioPlayerBoopK.setReleaseMode(ReleaseMode.stop);
    _audioPlayerDit.setReleaseMode(ReleaseMode.stop);
    _audioPlayerWrong.setReleaseMode(ReleaseMode.stop);

    _isLoaded = true;
    print('🎵 Tüm ses dosyaları yüklendi ve cache\'lendi!');
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

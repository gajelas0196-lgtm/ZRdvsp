import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dashboard_page.dart';

class VideoSplashPage extends StatefulWidget {
  final Map<String, dynamic> dashboardArgs;

  const VideoSplashPage({super.key, required this.dashboardArgs});

  @override
  State<VideoSplashPage> createState() => _VideoSplashPageState();
}

class _VideoSplashPageState extends State<VideoSplashPage>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _navigated = false;

  // --- Hanya untuk animasi tampilan (tidak memengaruhi logika navigasi) ---
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _initVideo();
  }

  void _initVideo() async {
    _controller = VideoPlayerController.asset('assets/videos/login.mp4');

    try {
      await _controller.initialize();
      await _controller.setVolume(1.0);
      await _controller.setLooping(false);

      _controller.addListener(_onVideoEnd);
      await _controller.play();

      if (mounted) {
        setState(() => _isInitialized = true);
        _fadeController.forward();
      }
    } catch (e) {
      _goToDashboard();
    }
  }

  void _onVideoEnd() {
    if (!_navigated &&
        _controller.value.position >= _controller.value.duration &&
        _controller.value.duration > Duration.zero) {
      _goToDashboard();
    }
  }

  void _goToDashboard() {
    if (_navigated) return;
    _navigated = true;

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(
            username: widget.dashboardArgs['username'],
            password: widget.dashboardArgs['password'],
            role: widget.dashboardArgs['role'],
            sessionKey: widget.dashboardArgs['key'],
            expiredDate: widget.dashboardArgs['expiredDate'],
            uid: widget.dashboardArgs['uid'], // ✅ Tambahkan UID
            listBug: List<Map<String, dynamic>>.from(
                widget.dashboardArgs['listBug'] ?? []),
            listDoos: List<Map<String, dynamic>>.from(
                widget.dashboardArgs['listDoos'] ?? []),
            news: List<Map<String, dynamic>>.from(
                widget.dashboardArgs['news'] ?? []),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoEnd);
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Palet warna: biru malam gelap + hitam pekat, aksen biru elektrik tipis
    const Color kDeepNavy = Color(0xFF040711);
    const Color kMidnightBlue = Color(0xFF0A1128);
    const Color kAccentBlue = Color(0xFF3E7BFA);
    const Color kAccentCyan = Color(0xFF5CC8FF);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ============================================================
          // LAPISAN 0 — Latar dasar (fallback sebelum video siap)
          // ============================================================
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kDeepNavy, Colors.black],
              ),
            ),
          ),

          // ============================================================
          // LAPISAN 1 — Video full layar
          // ============================================================
          if (_isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: kAccentBlue.withOpacity(0.25),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kAccentBlue.withOpacity(0.25),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(kAccentCyan),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'MEMUAT PENGALAMAN...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),

          // ============================================================
          // LAPISAN 2 — Vignette halus di tepi (biar tidak terlalu terang
          // / mencolok, memberi kesan sinematik & elegan)
          // ============================================================
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.35),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),

          // ============================================================
          // LAPISAN 3 — Gradient tipis di atas (menyatukan status bar
          // dengan tombol skip agar tidak "melayang" terlalu kontras)
          // ============================================================
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: IgnorePointer(
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ============================================================
          // LAPISAN 4 — Gradient bawah agar teks & tombol tetap terbaca,
          // dibuat lembut dengan nuansa biru gelap (bukan hitam polos)
          // ============================================================
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 240,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      kMidnightBlue.withOpacity(0.55),
                      Colors.black.withOpacity(0.92),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // ============================================================
          // LAPISAN 5 — Brand "RDVSP PROJECT" + garis aksen + tagline kecil
          // ============================================================
          Positioned(
            left: 0,
            right: 0,
            bottom: 96,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Garis aksen kecil di atas judul
                    Container(
                      width: 36,
                      height: 2.5,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(
                          colors: [kAccentBlue, kAccentCyan],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kAccentCyan.withOpacity(0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, kAccentCyan],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: const Text(
                        'RDVSP PROJECT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 9,
                          height: 1.0,
                          shadows: [
                            Shadow(
                              color: kAccentBlue,
                              blurRadius: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SISTEM TERINTEGRASI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ============================================================
          // LAPISAN 6 — Tombol "SKIP INTRO" bergaya glass, biru elegan,
          // tidak mencolok (opacity rendah, border tipis, glow lembut)
          // ============================================================
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: _goToDashboard,
                  splashColor: kAccentBlue.withOpacity(0.25),
                  highlightColor: kAccentBlue.withOpacity(0.08),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: kAccentBlue.withOpacity(0.35),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kAccentBlue.withOpacity(0.18),
                          blurRadius: 14,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SKIP INTRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.skip_next_rounded,
                          color: kAccentCyan,
                          size: 17,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ============================================================
          // LAPISAN 7 — Indikator progres video minimalis di dasar layar
          // (murni dekoratif, tidak mengubah logika apapun)
          // ============================================================
          if (_isInitialized)
            Positioned(
              left: 24,
              right: 24,
              bottom: 60,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) {
                    final duration = value.duration.inMilliseconds;
                    final position = value.position.inMilliseconds;
                    final progress = duration > 0
                        ? (position / duration).clamp(0.0, 1.0)
                        : 0.0;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 2.4,
                        backgroundColor: Colors.white.withOpacity(0.10),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          kAccentBlue,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
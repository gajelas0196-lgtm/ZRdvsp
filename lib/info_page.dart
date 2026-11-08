import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart'

// ============ PALET WARNA HITAM ELEGAN ============
const Color _bgDeep = Color(0xFF030303);
const Color _bgCard = Color(0xFF0A0A0A);
const Color _bgSurface = Color(0xFF141414);
const Color _bgElevated = Color(0xFF1E1E1E);
const Color _accentColor = Color(0xFF00E5FF);
const Color _accentSecondary = Color(0xFF2979FF);
const Color _textLight = Color(0xFFEEEEEE);
const Color _textSub = Color(0xFF7A7A7A);
const Color _textMuted = Color(0xFF444444);
const Color _border = Color(0x12FFFFFF);
const Color _borderAccent = Color(0x20FFFFFF);
const Color _shadowColor = Color(0x90000000);
const Color _redAccent = Color(0xFFFF1744);
// =================================================

class InfoPage extends StatefulWidget {
  final String sessionKey;

  const InfoPage({super.key, required this.sessionKey});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> with TickerProviderStateMixin {
  Map<String, dynamic>? serverInfo;
  bool isLoading = true;

  bool isApiOnline = false;
  int apiPingMs = 0;
  Color apiStatusColor = Colors.grey;
  String apiStatusText = "Checking...";
  Timer? _pingTimer;

  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _shimmerController;
  late AnimationController _flickerController;
  late AnimationController _staticController;
  late AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _fetchServerInfo();
    _startApiPingLoop();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    )..repeat();

    _staticController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _entranceController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _shimmerController.dispose();
    _flickerController.dispose();
    _staticController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  Future<void> _fetchServerInfo() async {
    try {
      final res = await http.get(
        Uri.parse(
            '$baseUrl/getServerInfo?key=${widget.sessionKey}'),
      );
      if (res.statusCode == 200) {
        setState(() {
          serverInfo = jsonDecode(res.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _startApiPingLoop() {
    _checkApiPing();
    _pingTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _checkApiPing());
  }

  Future<void> _checkApiPing() async {
    final start = DateTime.now();
    try {
      final res = await http.get(
        Uri.parse(
            '$baseUrl/ping?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 3));
      final end = DateTime.now();
      final duration = end.difference(start).inMilliseconds;
      if (res.statusCode == 200) {
        setState(() {
          isApiOnline = true;
          apiPingMs = duration;
          if (duration < 200) {
            apiStatusColor = _accentColor;
          } else if (duration < 500) {
            apiStatusColor = _accentSecondary;
          } else {
            apiStatusColor = _textMuted;
          }
          apiStatusText = "Online (${duration}ms)";
        });
      } else {
        throw Exception("Failed");
      }
    } catch (e) {
      setState(() {
        isApiOnline = false;
        apiPingMs = 0;
        apiStatusColor = _textMuted;
        apiStatusText = "Offline";
      });
    }
  }

  Widget _staggeredItem(
      {required int index, required Widget child, int total = 12}) {
    final double start = (index * 0.6 / total).clamp(0.0, 0.85);
    final double end = (start + 0.40).clamp(0.0, 1.0);
    final Animation<double> animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final double value = animation.value;
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 28),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: _bgDeep,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            "INFO",
            style: TextStyle(
              color: _textLight,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              fontSize: 15,
            ),
          ),
        ),
        body: Stack(
          children: [
            _buildBackgroundDecor(),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, _) {
                      final double glow =
                          0.20 + (_glowController.value * 0.40);
                      return Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _accentColor.withOpacity(0.3), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: _accentColor.withOpacity(glow),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                            BoxShadow(
                              color: _accentSecondary.withOpacity(glow * 0.4),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            color: _accentColor,
                            strokeWidth: 2.5,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: _flickerController,
                    builder: (context, _) {
                      final double t = _flickerController.value;
                      final bool blink = (t * 18).floor() % 9 == 0;
                      return Text(
                        "INITIALIZING...",
                        style: TextStyle(
                          color: blink
                              ? _accentColor.withOpacity(0.8)
                              : _textMuted,
                          fontSize: 11,
                          letterSpacing: 4,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, _) {
                      return SizedBox(
                        width: 120,
                        child: LinearProgressIndicator(
                          value: _shimmerController.value,
                          backgroundColor: _bgSurface,
                          color: _accentColor.withOpacity(0.5),
                          minHeight: 1.5,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final List<Map<String, dynamic>> rulesList = [
      {
        "title": "Larangan Barter Akun",
        "desc":
            "Akun tidak boleh ditukar dengan barang, jasa, atau akun lain dalam bentuk apa pun.",
        "icon": Icons.swap_horiz_rounded,
      },
      {
        "title": "Larangan Membagikan Akun",
        "desc":
            "Setiap akun bersifat pribadi dan hanya boleh digunakan oleh pemilik akun yang terdaftar.",
        "icon": Icons.no_accounts_rounded,
      },
      {
        "title": "Larangan Menjual Akun",
        "desc":
            "Member TIDAK diperbolehkan menjual akun. Penjualan akun hanya boleh dilakukan oleh role yang diizinkan secara resmi.",
        "icon": Icons.block_rounded,
      },
      {
        "title": "Larangan Jual Durasi Ilegal",
        "desc":
            "Dilarang menjual akses harian, mingguan, trial, atau sejenisnya di luar ketentuan yang telah ditetapkan.",
        "icon": Icons.timer_off_rounded,
      },
      {
        "title": "Larangan Banting Harga",
        "desc":
            "Dilarang merusak atau menurunkan harga yang telah ditentukan (banting harga) di bawah ketentuan RDVSP.",
        "icon": Icons.price_change_rounded,
      },
    ];

    return Scaffold(
      backgroundColor: _bgDeep,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        titleSpacing: 0,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _flickerController,
              builder: (context, _) {
                final double t = _flickerController.value;
                final bool glitch = (t * 25).floor() % 60 == 0;
                return Text(
                  "PERATURAN & INFO",
                  style: TextStyle(
                    color: glitch
                        ? _accentColor.withOpacity(0.7)
                        : _textLight.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 20,
                    height: 0.5,
                    color: _accentColor.withOpacity(0.3)),
                const SizedBox(width: 8),
                Text(
                  "RDVSP PROJECT",
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 8.5,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                    width: 20,
                    height: 0.5,
                    color: _accentColor.withOpacity(0.3)),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, _) {
              return Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin:
                        Alignment(-1 + _shimmerController.value * 2.5, 0),
                    end: Alignment(1 + _shimmerController.value * 2.5, 0),
                    colors: [
                      Colors.transparent,
                      _accentColor.withOpacity(0.4),
                      _accentSecondary.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildBackgroundDecor(),
          // Scan line effect
          AnimatedBuilder(
            animation: _scanLineController,
            builder: (context, _) {
              final double y = _scanLineController.value *
                  MediaQuery.of(context).size.height;
              return Positioned(
                top: y - 1,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        _accentColor.withOpacity(0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // API Status Card
                  _staggeredItem(index: 0, child: _buildApiStatusCard()),
                  const SizedBox(height: 20),

                  // Header Peraturan
                  _staggeredItem(index: 1, child: _buildSectionHeader()),
                  const SizedBox(height: 8),
                  _staggeredItem(
                    index: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 18),
                      child: Text(
                        "Wajib dibaca dan dipatuhi oleh seluruh pengguna RDVSP App. Pelanggaran akan dikenakan sanksi tegas.",
                        style: TextStyle(
                          color: _textSub,
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),

                  // List Peraturan
                  ...rulesList.asMap().entries.map((entry) {
                    int index = entry.key + 1;
                    Map<String, dynamic> rule = entry.value;
                    return _staggeredItem(
                      index: index + 2,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildRuleCard(index, rule),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 8),

                  // Sanksi Card
                  _staggeredItem(
                      index: rulesList.length + 3, child: _buildSanksiCard()),

                  const SizedBox(height: 32),

                  // Footer
                  _staggeredItem(
                      index: rulesList.length + 4, child: _buildFooter()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= BACKGROUND =================
  Widget _buildBackgroundDecor() {
    return IgnorePointer(
      child: Stack(
        children: [
          // Subtle grid pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(
                color: _textMuted.withOpacity(0.04),
                spacing: 40,
              ),
            ),
          ),
          // Vignette
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.5),
                  radius: 1.5,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          // Top-left glow
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _accentColor.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Bottom-right glow
          Positioned(
            bottom: -100,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _accentSecondary.withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Noise
          AnimatedBuilder(
            animation: _staticController,
            builder: (context, _) {
              return Positioned.fill(
                child: CustomPaint(
                  painter: _StaticNoisePainter(
                    seed: _staticController.value,
                    color: _textSub.withOpacity(0.015),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= SECTION HEADER =================
  Widget _buildSectionHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, _) {
              final double glow = 0.15 + (_glowController.value * 0.25);
              return Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: _accentColor.withOpacity(0.35), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withOpacity(glow),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(Icons.gavel_rounded,
                    color: _accentColor.withOpacity(0.8), size: 18),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PERATURAN PENGGUNA",
                  style: TextStyle(
                    color: _textLight,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "User Terms & Conditions",
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 9,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _bgSurface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _accentColor.withOpacity(0.25)),
            ),
            child: Text(
              "×5",
              style: TextStyle(
                color: _accentColor.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= RULE CARD =================
  Widget _buildRuleCard(int index, Map<String, dynamic> rule) {
    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border, width: 0.8),
        boxShadow: [
          BoxShadow(
              color: _shadowColor, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Accent line kiri
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _accentColor.withOpacity(0.6),
                      _accentSecondary.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Watermark angka
            Positioned(
              right: 4,
              bottom: -12,
              child: Text(
                "$index".padLeft(2, '0'),
                style: TextStyle(
                  color: _textLight.withOpacity(0.025),
                  fontSize: 80,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                ),
              ),
            ),
            // Corner marks
            Positioned(
              top: 6,
              right: 6,
              child: _CornerMark(size: 8, color: _accentColor.withOpacity(0.12)),
            ),
            Positioned(
              bottom: 6,
              left: 6,
              child: _CornerMark(
                  size: 8,
                  color: _accentColor.withOpacity(0.12),
                  flipX: true,
                  flipY: true),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Number badge
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _bgDeep,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                              color: _accentColor.withOpacity(0.3), width: 0.8),
                        ),
                        child: Text(
                          "$index",
                          style: TextStyle(
                            color: _accentColor.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          rule['title'] as String,
                          style: TextStyle(
                            color: _textLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: _bgSurface,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: _border),
                        ),
                        child: Icon(
                          rule['icon'] as IconData,
                          color: _accentColor.withOpacity(0.5),
                          size: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Divider
                  Row(
                    children: [
                      Container(
                          width: 24,
                          height: 0.5,
                          color: _accentColor.withOpacity(0.2)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                            height: 0.5, color: _border),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    rule['desc'] as String,
                    style: TextStyle(
                      color: _textSub,
                      fontSize: 12.5,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SANKSI CARD =================
  Widget _buildSanksiCard() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final double glow = 0.10 + (_glowController.value * 0.18);
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: _redAccent.withOpacity(0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: _redAccent.withOpacity(glow * 0.4),
                blurRadius: 30,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // Red gradient overlay at top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _redAccent.withOpacity(0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Corner marks
                Positioned(
                  top: 8,
                  left: 8,
                  child:
                      _CornerMark(size: 10, color: _redAccent.withOpacity(0.25)),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _CornerMark(
                      size: 10,
                      color: _redAccent.withOpacity(0.25),
                      flipX: true),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: _CornerMark(
                      size: 10,
                      color: _redAccent.withOpacity(0.25),
                      flipY: true),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _CornerMark(
                      size: 10,
                      color: _redAccent.withOpacity(0.25),
                      flipX: true,
                      flipY: true),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _redAccent.withOpacity(0.08),
                          border: Border.all(
                              color: _redAccent.withOpacity(0.3), width: 1),
                        ),
                        child: Icon(Icons.warning_amber_rounded,
                            color: _redAccent.withOpacity(0.8), size: 24),
                      ),
                      const SizedBox(height: 14),
                      // Title
                      Text(
                        "SANKSI PELANGGARAN",
                        style: TextStyle(
                          color: _textLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "VIOLATION PENALTY",
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 8,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Divider
                      Row(
                        children: [
                          Expanded(
                              child: Container(
                                  height: 0.5, color: _border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.diamond_outlined,
                                color: _redAccent.withOpacity(0.3), size: 6),
                          ),
                          Expanded(
                              child: Container(
                                  height: 0.5, color: _border)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Jika pengguna terbukti melanggar salah satu peraturan yang berlaku:",
                        style: TextStyle(
                            color: _textSub, fontSize: 12, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Penalty box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _bgSurface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _redAccent.withOpacity(0.2), width: 0.8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _redAccent.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Akun akan DIHAPUS secara permanen",
                                    style: TextStyle(
                                      color: _textLight,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Icon(Icons.close_rounded,
                                    color: _redAccent.withOpacity(0.6), size: 18),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: _redAccent.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: _redAccent.withOpacity(0.15)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      color: _redAccent.withOpacity(0.5),
                                      size: 14),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Tanpa pengembalian akun, saldo, atau kompensasi apa pun.",
                                      style: TextStyle(
                                        color: _redAccent.withOpacity(0.7),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= FOOTER =================
  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          // Shield icon
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final double glow = 0.15 + (_pulseController.value * 0.20);
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _bgCard,
                  border: Border.all(
                      color: _accentColor.withOpacity(0.2), width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withOpacity(glow),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(Icons.shield_moon_rounded,
                    color: _accentColor.withOpacity(0.6), size: 24),
              );
            },
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Peraturan ini dibuat untuk menjaga keamanan, kenyamanan, dan kestabilan ekosistem RDVSP App. Dengan menggunakan aplikasi ini, pengguna dianggap telah menyetujui seluruh peraturan yang berlaku.",
              style: TextStyle(
                color: _textMuted,
                fontSize: 11,
                fontStyle: FontStyle.italic,
                height: 1.65,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          // Gradient line
          Container(
            height: 0.5,
            width: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _accentColor.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "RDVSP • SECURE ECOSYSTEM",
            style: TextStyle(
              color: _textMuted.withOpacity(0.5),
              fontSize: 8,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "© ${DateTime.now().year} All rights reserved",
            style: TextStyle(
              color: _textMuted.withOpacity(0.3),
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ================= API STATUS CARD =================
  Widget _buildApiStatusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border, width: 0.8),
        boxShadow: [
          BoxShadow(
              color: _shadowColor, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final double pulse = isApiOnline ? _pulseController.value : 0.0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (isApiOnline)
                    Container(
                      width: 8 + (pulse * 14),
                      height: 8 + (pulse * 14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: apiStatusColor.withOpacity((1 - pulse) * 0.3),
                      ),
                    ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: apiStatusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: apiStatusColor.withOpacity(0.6),
                            blurRadius: 6)
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SYSTEM STATUS",
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  apiStatusText.toUpperCase(),
                  style: TextStyle(
                    color: _textLight.withOpacity(0.85),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          if (isApiOnline && apiPingMs > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _accentColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded,
                      color: _accentColor.withOpacity(0.7), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    "${apiPingMs}ms",
                    style: TextStyle(
                      color: _accentColor.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else if (!isApiOnline)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _textMuted.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _textMuted.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded,
                      color: _textSub.withOpacity(0.6), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    "OFFLINE",
                    style: TextStyle(
                      color: _textSub.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ================= CORNER MARK WIDGET =================
class _CornerMark extends StatelessWidget {
  final double size;
  final Color color;
  final bool flipX;
  final bool flipY;

  const _CornerMark({
    required this.size,
    required this.color,
    this.flipX = false,
    this.flipY = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerMarkPainter(color: color, flipX: flipX, flipY: flipY),
      ),
    );
  }
}

class _CornerMarkPainter extends CustomPainter {
  final Color color;
  final bool flipX;
  final bool flipY;

  _CornerMarkPainter(
      {required this.color, required this.flipX, required this.flipY});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    double sx = flipX ? size.width : 0;
    double sy = flipY ? size.height : 0;
    double ex = flipX ? 0 : size.width;
    double ey = flipY ? 0 : size.height;

    canvas.drawLine(Offset(sx, sy), Offset(ex, sy), paint);
    canvas.drawLine(Offset(sx, sy), Offset(sx, ey), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerMarkPainter oldDelegate) => false;
}

// ================= GRID PAINTER =================
class _GridPainter extends CustomPainter {
  final Color color;
  final double spacing;

  _GridPainter({required this.color, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}

// ================= STATIC NOISE PAINTER =================
class _StaticNoisePainter extends CustomPainter {
  final double seed;
  final Color color;
  const _StaticNoisePainter({required this.seed, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final math.Random rnd = math.Random((seed * 100000).toInt());

    for (int i = 0; i < 60; i++) {
      final double x = rnd.nextDouble() * size.width;
      final double y = rnd.nextDouble() * size.height;
      final double w = rnd.nextDouble() * 1.5 + 0.5;
      canvas.drawRect(Rect.fromLTWH(x, y, w, w), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StaticNoisePainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}
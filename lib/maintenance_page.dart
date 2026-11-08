import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MaintenancePage extends StatefulWidget {
  final String message;
  final String username;
  final String password;
  final String androidId;
  final String baseUrl;

  const MaintenancePage({
    super.key,
    required this.message,
    required this.username,
    required this.password,
    required this.androidId,
    required this.baseUrl,
  });

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glitchController;
  late AnimationController _scanController;
  late Animation<double> _pulseAnim;
  late Animation<double> _glitchAnim;
  late Animation<double> _scanAnim;

  Timer? _checkTimer;
  bool _checking = false;

  // Palet warna
  static const Color bgMain = Color(0xFF060608);
  static const Color accentRed = Color(0xFFFF1744);
  static const Color accentOrange = Color(0xFFFF6D00);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color textDim = Color(0x80FFFFFF);
  static const Color textHint = Color(0x40FFFFFF);
  static const Color borderDim = Color(0x15FFFFFF);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startPolling();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _pulseAnim = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    _glitchAnim = CurvedAnimation(
      parent: _glitchController,
      curve: Curves.linear,
    );
    _scanAnim = CurvedAnimation(
      parent: _scanController,
      curve: Curves.linear,
    );
  }

  void _startPolling() {
    // Cek tiap 15 detik apakah maintenance sudah selesai
    _checkTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkMaintenance();
    });
  }

  Future<void> _checkMaintenance() async {
    if (_checking) return;
    setState(() => _checking = true);

    try {
      final res = await http
          .get(Uri.parse("${widget.baseUrl}/maintenanceStatus"))
          .timeout(const Duration(seconds: 8));
      final data = jsonDecode(res.body);

      if (data['maintenance'] == false && mounted) {
        _checkTimer?.cancel();
        // Maintenance selesai — balik ke login
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    } catch (_) {
      // server down / timeout, tunggu aja
    }

    if (mounted) setState(() => _checking = false);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glitchController.dispose();
    _scanController.dispose();
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // blokir tombol back
      child: Scaffold(
        backgroundColor: bgMain,
        body: Stack(
          children: [
            // Background scan line animation
            AnimatedBuilder(
              animation: _scanAnim,
              builder: (_, __) {
                final y = _scanAnim.value * MediaQuery.of(context).size.height;
                return Positioned(
                  left: 0,
                  right: 0,
                  top: y,
                  child: Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          accentCyan.withOpacity(0.08),
                          accentCyan.withOpacity(0.15),
                          accentCyan.withOpacity(0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Background grid sangat halus
            Positioned.fill(
              child: CustomPaint(painter: _FaintGridPainter()),
            ),

            // Glow merah di tengah
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) {
                return Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentRed.withOpacity(0.06 + 0.04 * _pulseAnim.value),
                          blurRadius: 120 + 40 * _pulseAnim.value,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Konten utama
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon maintenance + ring animasi
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 110 + 8 * _pulseAnim.value,
                                height: 110 + 8 * _pulseAnim.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: accentRed.withOpacity(0.15 + 0.1 * _pulseAnim.value),
                                    width: 1,
                                  ),
                                ),
                              ),
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: accentRed.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  color: accentRed.withOpacity(0.08),
                                ),
                                child: Icon(
                                  Icons.construction_rounded,
                                  color: accentRed.withOpacity(0.8 + 0.2 * _pulseAnim.value),
                                  size: 40,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 36),

                      // Badge STATUS
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accentRed.withOpacity(0.3)),
                          color: accentRed.withOpacity(0.07),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (_, __) => Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accentRed.withOpacity(0.5 + 0.5 * _pulseAnim.value),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "SISTEM OFFLINE",
                              style: TextStyle(
                                color: accentRed.withOpacity(0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Title
                      const Text(
                        "MAINTENANCE",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                          height: 1.1,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "DALAM PERBAIKAN",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: accentRed.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Divider dengan icon
                      Row(
                        children: [
                          Expanded(child: Container(height: 1, color: borderDim)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: Colors.white.withOpacity(0.15),
                              size: 14,
                            ),
                          ),
                          Expanded(child: Container(height: 1, color: borderDim)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Pesan maintenance
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderDim),
                          color: Colors.white.withOpacity(0.025),
                        ),
                        child: Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: textDim,
                            fontSize: 14,
                            height: 1.7,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Indikator auto-check
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_checking)
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation(
                                  accentCyan.withOpacity(0.5),
                                ),
                              ),
                            )
                          else
                            AnimatedBuilder(
                              animation: _glitchAnim,
                              builder: (_, __) => Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accentCyan.withOpacity(0.2 + 0.3 * _glitchAnim.value),
                                ),
                              ),
                            ),
                          const SizedBox(width: 10),
                          Text(
                            _checking
                                ? "Memeriksa status server..."
                                : "Auto-refresh setiap 15 detik",
                            style: TextStyle(
                              color: textHint,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),

                      // Footer brand
                      Text(
                        "XENTRA'X EXECUTION",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.08),
                          fontSize: 9,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.018)
      ..strokeWidth = 0.4
      ..style = PaintingStyle.stroke;

    const spacing = 48.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

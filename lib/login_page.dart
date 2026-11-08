import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'video_splash_page.dart';
import 'maintenance_page.dart';
import 'api_config.dart'

const String baseUrl = "$baseUrl";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final userController = TextEditingController();
  final passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool _obscurePassword = true;
  String? androidId;

  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _glowPulse;
  late Animation<double> _scaleAnim;

  // ===== PALET WARNA HITAM ELEGAN =====
  static const Color bgMain = Color(0xFF0A0A0A);
  static const Color bgSurface = Color(0xFF141414);
  static const Color bgCard = Color(0xFF1A1A1A);
  static const Color bgInput = Color(0xFF111111);
  static const Color accentColor = Color(0xFF00BCD4);
  static const Color accentDark = Color(0xFF00838F);
  static const Color accentLight = Color(0xFF4DD0E1);
  static const Color secondaryText = Color(0xFF888888);
  static const Color borderDim = Color(0x20FFFFFF);
  static const Color borderInput = Color(0x40FFFFFF);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textHint = Color(0x60FFFFFF);
  // =================================================

  @override
  void initState() {
    super.initState();
    _initAnim();
    initLogin();
  }

  void _initAnim() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _glowPulse = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );

    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  void _navigateToVideoSplash(Map<String, dynamic> args) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VideoSplashPage(dashboardArgs: args),
      ),
    );
  }

  Map<String, dynamic> _buildArgs(
      dynamic data, String username, String password) {
    return {
      "username": username,
      "password": password,
      "role": data['role'],
      "key": data['key'],
      "expiredDate": data['expiredDate'],
      "uid": data['uid'], // ✅ Tambahkan UID
      "listBug": (data['listBug'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      "listDoos": (data['listDDoS'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      "news": (data['news'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    };
  }

  Future<void> initLogin() async {
    androidId = await getAndroidId();
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey = prefs.getString("key");

    if (savedUser != null && savedPass != null && savedKey != null) {
      final uri = Uri.parse(
          "$baseUrl/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey");
      try {
        final res = await http.get(uri);
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          // Cek maintenance
          try {
            final maintRes = await http.get(Uri.parse("$baseUrl/maintenanceStatus"));
            final maintData = jsonDecode(maintRes.body);
            if (maintData['maintenance'] == true && mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => MaintenancePage(
                    message: maintData['message'] ?? 'Aplikasi sedang maintenance.',
                    username: savedUser,
                    password: savedPass,
                    androidId: androidId ?? 'unknown',
                    baseUrl: baseUrl,
                  ),
                ),
              );
              return;
            }
          } catch (_) {}
          _navigateToVideoSplash(_buildArgs(data, savedUser, savedPass));
        }
      } catch (_) {}
    }
  }

  Future<String> getAndroidId() async {
    final deviceInfo = DeviceInfoPlugin();
    final android = await deviceInfo.androidInfo;
    return android.id ?? "unknown_device";
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    final username = userController.text.trim();
    final password = passController.text.trim();
    setState(() => isLoading = true);

    try {
      final validate = await http.post(
        Uri.parse("$baseUrl/validate"),
        body: {
          "username": username,
          "password": password,
          "androidId": androidId ?? "unknown_device",
        },
      );
      final validData = jsonDecode(validate.body);

      if (validData['expired'] == true) {
        _showPopup(
          title: "Access Expired",
          message: "Masa akses Anda telah habis.\nSilakan perpanjang akses.",
          showContact: true,
        );
      } else if (validData['valid'] != true) {
        final String errorMsg = (validData['message'] ?? "").toLowerCase();
        if (errorMsg.contains("perangkat") ||
            errorMsg.contains("device") ||
            errorMsg.contains("another")) {
          _showPopup(
            title: "Sesi Aktif",
            message:
                "Akun ini sedang login di perangkat lain.\nSilakan logout di perangkat lama.",
          );
        } else {
          _showPopup(
            title: "Login Gagal",
            message: "Username atau password salah.",
          );
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("username", username);
        prefs.setString("password", password);
        prefs.setString("key", validData['key']);
        // Cek maintenance sebelum masuk dashboard
        try {
          final maintRes = await http.get(Uri.parse("$baseUrl/maintenanceStatus"));
          final maintData = jsonDecode(maintRes.body);
          if (maintData['maintenance'] == true && mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => MaintenancePage(
                  message: maintData['message'] ?? 'Aplikasi sedang maintenance.',
                  username: username,
                  password: password,
                  androidId: androidId ?? 'unknown',
                  baseUrl: baseUrl,
                ),
              ),
            );
            setState(() => isLoading = false);
            return;
          }
        } catch (_) {}
        _navigateToVideoSplash(_buildArgs(validData, username, password));
      }
    } catch (e) {
      _showPopup(
        title: "Connection Error",
        message: "Gagal terhubung ke server.",
      );
    }

    setState(() => isLoading = false);
  }

  void _showPopup({
    required String title,
    required String message,
    bool showContact = false,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (_) => AlertDialog(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accentColor.withOpacity(0.2), width: 1),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: accentLight, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                  color: accentLight, fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: secondaryText, fontSize: 14, height: 1.5),
        ),
        actions: [
          if (showContact)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: accentColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () async {
                  await launchUrl(Uri.parse(""),
                      mode: LaunchMode.externalApplication);
                },
                child: const Text(
                  "Contact Admin",
                  style: TextStyle(
                      color: accentLight, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: TextStyle(color: secondaryText.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bgMain,
      body: Stack(
        children: [
          // Lapisan 1: Background Glow & Partikel
          Positioned.fill(
            child: CustomPaint(
              painter: _DarkAmbientPainter(
                glowValue: _glowPulse.value,
                accentColor: accentColor,
              ),
            ),
          ),

          // Lapisan 2: Grid Overlay sangat halus
          Positioned.fill(
            child: CustomPaint(
              painter: _SubtleGridPainter(),
            ),
          ),

          // Lapisan 3: Vignette
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.7,
                  colors: [
                    bgMain.withOpacity(0.0),
                    bgMain.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),

          // Konten Utama
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.04,
                  vertical: size.height * 0.03,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- KOMPONEN UTAMA: CARD MENYATU DENGAN LOGO ---
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 400),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                accentColor.withOpacity(0.15),
                                accentDark.withOpacity(0.05),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgCard.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(27),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.6),
                                  blurRadius: 50,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 25),
                                ),
                              ],
                            ),
                            child: Stack(
                              clipBehavior: Clip.antiAlias,
                              children: [
                                // Ornamen sudut
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: _buildCorner(topLeft: true),
                                ),
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: _buildCorner(topRight: true),
                                ),
                                Positioned(
                                  bottom: 16,
                                  left: 16,
                                  child: _buildCorner(bottomLeft: true),
                                ),
                                Positioned(
                                  bottom: 16,
                                  right: 16,
                                  child: _buildCorner(bottomRight: true),
                                ),

                                // Konten Form
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 28, vertical: 36),
                                  child: Column(
                                    children: [
                                      // Area Logo
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            width: 110,
                                            height: 110,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: accentColor.withOpacity(0.1),
                                                  width: 1),
                                            ),
                                          ),
                                          Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color:
                                                      accentColor.withOpacity(0.15),
                                                  blurRadius: 40,
                                                  spreadRadius: 10,
                                                )
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 90,
                                            height: 90,
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color:
                                                      accentColor.withOpacity(0.3),
                                                  width: 1.5),
                                              color: bgMain,
                                            ),
                                            child: ClipOval(
                                              child: Image.asset(
                                                'assets/images/logo.png',
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 8),

                                      const Text(
                                        "AUTHENTICATION REQUIRED",
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: textHint,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 3,
                                        ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 24),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                height: 1,
                                                color: borderDim,
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 16),
                                              child: Icon(
                                                Icons.fingerprint,
                                                color:
                                                    accentColor.withOpacity(0.5),
                                                size: 18,
                                              ),
                                            ),
                                            Expanded(
                                              child: Container(
                                                height: 1,
                                                color: borderDim,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      Form(
                                        key: _formKey,
                                        child: Column(
                                          children: [
                                            _buildInput(
                                              controller: userController,
                                              hint: "Username",
                                              icon: Icons.person_outline_rounded,
                                              obscure: false,
                                            ),
                                            const SizedBox(height: 16),
                                            _buildInput(
                                              controller: passController,
                                              hint: "Password",
                                              icon: Icons.lock_outline_rounded,
                                              obscure: _obscurePassword,
                                              suffix: IconButton(
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons
                                                          .visibility_off_outlined
                                                      : Icons
                                                          .visibility_outlined,
                                                  color: secondaryText
                                                      .withOpacity(0.3),
                                                  size: 18,
                                                ),
                                                onPressed: () {
                                                  setState(() =>
                                                      _obscurePassword =
                                                          !_obscurePassword);
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 32),

                                      _buildLoginButton(),

                                      const SizedBox(height: 24),

                                      // Link beli akses
                                      GestureDetector(
                                        onTap: () async {
                                          final url =
                                              Uri.parse("https://t.me/karzKyzen");
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url,
                                                mode: LaunchMode
                                                    .externalApplication);
                                          }
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Need access?",
                                              style: TextStyle(
                                                color: secondaryText
                                                    .withOpacity(0.4),
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: accentColor
                                                        .withOpacity(0.2)),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                "Get Premium",
                                                style: TextStyle(
                                                  color: accentLight,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1,
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
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- FOOTER ---
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              5,
                              (index) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4),
                                child: Container(
                                  width: index == 2 ? 12 : 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: index == 2
                                        ? accentColor.withOpacity(0.5)
                                        : secondaryText.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Secured Connection Established",
                            style: TextStyle(
                              color: textHint,
                              fontSize: 9,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "v7.5",
                            style: TextStyle(
                              color: accentColor.withOpacity(0.4),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _CornerPainter(
          color: accentColor.withOpacity(0.3),
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgInput.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderInput.withOpacity(0.3), width: 0.5),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(
              color: textWhite,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: accentColor,
            cursorWidth: 1.5,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: textHint,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(icon, color: secondaryText.withOpacity(0.5), size: 20),
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  accentColor.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: isLoading
            ? []
            : [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor, accentDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          if (!isLoading)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: isLoading ? null : login,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white70),
                        ),
                      )
                    : const Text(
                        "PROCEED",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== PAINTER: Background Ambient Gelap =====
class _DarkAmbientPainter extends CustomPainter {
  final double glowValue;
  final Color accentColor;

  _DarkAmbientPainter({required this.glowValue, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Glow utama atas
    final paint1 = Paint()
      ..color = accentColor.withOpacity(0.08 * glowValue)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);
    canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.1), 200 * glowValue, paint1);

    // Glow bawah kiri
    final paint2 = Paint()
      ..color = accentColor.withOpacity(0.06 * glowValue)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.9),
        150 * glowValue, paint2);

    // Glow bawah kanan
    final paint3 = Paint()
      ..color = accentColor.withOpacity(0.04 * glowValue)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.8),
        120 * glowValue, paint3);

    // Partikel mengambang
    final random = Random(42);
    for (int i = 0; i < 25; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.2 + 0.3;
      final opacity = (random.nextDouble() * 0.2 + 0.05) * glowValue;

      final dotPaint = Paint()
        ..color = accentColor.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DarkAmbientPainter oldDelegate) {
    return oldDelegate.glowValue != glowValue;
  }
}

// ===== PAINTER: Grid Sangat Halus =====
class _SubtleGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.3
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    const spacing = 40.0;

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

// ===== PAINTER: Ornamen Sudut (Corner Bracket) - DIPERBAIKI =====
class _CornerPainter extends CustomPainter {
  final Color color;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  _CornerPainter({
    required this.color,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Hitung posisi di dalam paint, bukan di const
    final double halfW = size.width / 2;
    final double halfH = size.height / 2;

    if (topLeft) {
      canvas.drawLine(Offset(0, halfH), const Offset(0, 0), paint);
      canvas.drawLine(const Offset(0, 0), Offset(halfW, 0), paint);
    }
    if (topRight) {
      canvas.drawLine(Offset(size.width, halfH), Offset(size.width, 0), paint);
      canvas.drawLine(Offset(size.width, 0), Offset(halfW, 0), paint);
    }
    if (bottomLeft) {
      canvas.drawLine(Offset(0, halfH), Offset(0, size.height), paint);
      canvas.drawLine(Offset(0, size.height), Offset(halfW, size.height), paint);
    }
    if (bottomRight) {
      canvas.drawLine(Offset(size.width, halfH), Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(size.width, size.height), Offset(halfW, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
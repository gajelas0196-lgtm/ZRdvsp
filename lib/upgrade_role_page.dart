// ============================================================
//  UPGRADE ROLE PAGE — AI ASSISTED + QRIS PAYMENT
//  RDVSP PROJECT — @karzKyzen
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// ── Groq config (sama persis dengan ai_page.dart) ──────────
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Ambil API key dari .env
final String groqApiKey = dotenv.env['GROQ_API_KEY'] ?? '';

// Ganti pemanggilan API di kodemu menggunakan variabel groqApiKey
// Contoh: headers: {'Authorization': 'Bearer $groqApiKey'}
// ── Palet — ikutin dashboard ────────────────────────────────
const Color _bgDeep        = Color(0xFF050505);
const Color _bgCard        = Color(0xFF0F0F0F);
const Color _bgSurface     = Color(0xFF1A1A1A);
const Color _accentColor   = Color(0xFF00E5FF);
const Color _accentSec     = Color(0xFF2979FF);
const Color _textLight     = Color(0xFFFFFFFF);
const Color _textSub       = Color(0xFF8A8A8A);
const Color _textMuted     = Color(0xFF555555);
const Color _border        = Color(0x1FFFFFFF);
const Color _borderAccent  = Color(0x33FFFFFF);
const Color _neonGreen     = Color(0xFF34D399);
const Color _neonOrange    = Color(0xFFFB923C);
const Color _neonRed       = Color(0xFFE8364F);
const Color _neonPurple    = Color(0xFFB388FF);

// ── Data paket role ─────────────────────────────────────────
class _RolePackage {
  final String role;
  final String label;
  final String price;
  final String priceNum;   // harga bersih (untuk AI)
  final String duration;
  final IconData icon;
  final Color color;
  final List<String> features;
  final String qrisData;   // string QRIS dummy — ganti sesuai asli

  const _RolePackage({
    required this.role,
    required this.label,
    required this.price,
    required this.priceNum,
    required this.duration,
    required this.icon,
    required this.color,
    required this.features,
    required this.qrisData,
  });
}

const List<_RolePackage> _packages = [
  _RolePackage(
    role: 'seller',
    label: 'SELLER',
    price: 'Rp 25.000',
    priceNum: '25000',
    duration: '30 hari',
    icon: Icons.storefront_rounded,
    color: Color(0xFF34D399),
    features: [
      'Akses Seller Panel',
      'Kelola produk & transaksi',
      'Dashboard penjualan',
      'Support prioritas',
    ],
    qrisData: '00020101021226570011ID.DANA.WWW011893600914313828282202081308282802051.0.00303UMI51440014ID.CO.QRIS.WWW0215ID10220410456780303UMI5204539953033605409250000005802ID5914LYNISXTEAM BOT6007JAKARTA62070503***6304',
  ),
  _RolePackage(
    role: 'reseller',
    label: 'RESELLER',
    price: 'Rp 40.000',
    priceNum: '40000',
    duration: '30 hari',
    icon: Icons.inventory_2_rounded,
    color: Color(0xFF00E5FF),
    features: [
      'Semua fitur Seller',
      'Komisi resale lebih besar',
      'Akses panel reseller',
      'Stock prioritas',
    ],
    qrisData: '00020101021226570011ID.DANA.WWW011893600914313828282202081308282802051.0.00303UMI51440014ID.CO.QRIS.WWW0215ID10220410456780303UMI5204539953033605409400000005802ID5914LYNISXTEAM BOT6007JAKARTA62070503***6304',
  ),
  _RolePackage(
    role: 'moderator',
    label: 'MODERATOR',
    price: 'Rp 60.000',
    priceNum: '60000',
    duration: '30 hari',
    icon: Icons.gavel_rounded,
    color: Color(0xFFFB923C),
    features: [
      'Moderator Panel',
      'Kelola member & laporan',
      'Akses konten moderasi',
      'Notifikasi moderasi real-time',
    ],
    qrisData: '00020101021226570011ID.DANA.WWW011893600914313828282202081308282802051.0.00303UMI51440014ID.CO.QRIS.WWW0215ID10220410456780303UMI5204539953033605409600000005802ID5914LYNISXTEAM BOT6007JAKARTA62070503***6304',
  ),
  _RolePackage(
    role: 'partner',
    label: 'PARTNER',
    price: 'Rp 100.000',
    priceNum: '100000',
    duration: '30 hari',
    icon: Icons.handshake_rounded,
    color: Color(0xFFB388FF),
    features: [
      'Partner Panel eksklusif',
      'Semua akses moderator',
      'Revenue sharing program',
      'Badge partner resmi',
    ],
    qrisData: '00020101021226570011ID.DANA.WWW011893600914313828282202081308282802051.0.00303UMI51440014ID.CO.QRIS.WWW0215ID10220410456780303UMI52045399530336054091000000005802ID5914LYNISXTEAM BOT6007JAKARTA62070503***6304',
  ),
];

// ============================================================
//  MAIN WIDGET
// ============================================================
class UpgradeRolePage extends StatefulWidget {
  final String username;
  final String sessionKey;
  final String currentRole;

  const UpgradeRolePage({
    super.key,
    required this.username,
    required this.sessionKey,
    required this.currentRole,
  });

  @override
  State<UpgradeRolePage> createState() => _UpgradeRolePageState();
}

class _UpgradeRolePageState extends State<UpgradeRolePage>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isAiLoading = false;
  String _aiAdvice = '';
  bool _aiLoaded = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    // auto-load AI advice on open
    _loadAiAdvice();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Minta AI recommendation berdasarkan role sekarang ─────
  Future<void> _loadAiAdvice() async {
    setState(() {
      _isAiLoading = true;
      _aiLoaded = false;
      _aiAdvice = '';
    });

    try {
      final res = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqKey',
        },
        body: jsonEncode({
          'model': _groqMdl,
          'messages': [
            {
              'role': 'system',
              'content':
                  'Kamu adalah asisten AI dari aplikasi LynisXTeam. '
                  'Tugasmu menjelaskan keuntungan upgrade role secara singkat dan persuasif '
                  'dalam bahasa Indonesia informal. Jawab maksimal 3 kalimat pendek. '
                  'Jangan pakai emoji berlebihan. Langsung ke poin.',
            },
            {
              'role': 'user',
              'content':
                  'User ${widget.username} saat ini punya role "${widget.currentRole}". '
                  'Rekomendasikan kenapa dia harus upgrade rolenya sekarang. '
                  'Sebut 1-2 role yang paling worth untuk diambil dari: seller, reseller, moderator, partner.',
            },
          ],
          'temperature': 0.8,
          'max_tokens': 200,
        }),
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final reply =
            data['choices']?[0]?['message']?['content'] ?? 'Upgrade sekarang untuk akses lebih!';
        setState(() {
          _aiAdvice = reply.trim();
          _aiLoaded = true;
        });
      } else {
        setState(() {
          _aiAdvice = 'Upgrade rolenya sekarang — makin banyak fitur yang bisa kamu akses!';
          _aiLoaded = true;
        });
      }
    } catch (_) {
      setState(() {
        _aiAdvice = 'Koneksi bermasalah. Tapi jangan tunda upgrade rolenya ya!';
        _aiLoaded = true;
      });
    }

    setState(() => _isAiLoading = false);
  }

  // ── Ask AI tentang package specific ───────────────────────
  Future<String> _askAiAboutPackage(_RolePackage pkg) async {
    try {
      final res = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqKey',
        },
        body: jsonEncode({
          'model': _groqMdl,
          'messages': [
            {
              'role': 'system',
              'content':
                  'Kamu AI advisor dari LynisXTeam. Jawab singkat, informal, bahasa Indonesia. '
                  'Maksimal 2 kalimat. Tidak perlu emoji.',
            },
            {
              'role': 'user',
              'content':
                  'Jelaskan kenapa role ${pkg.label} seharga ${pkg.price} worth it untuk '
                  'user yang sekarang masih "${widget.currentRole}".',
            },
          ],
          'temperature': 0.7,
          'max_tokens': 120,
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['choices']?[0]?['message']?['content'] ??
            'Role ini buka akses lebih banyak fitur eksklusif.';
      }
    } catch (_) {}
    return 'Role ini memberi kamu akses panel eksklusif dan fitur premium.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────
          SliverAppBar(
            backgroundColor: _bgDeep,
            expandedHeight: 120,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textLight),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0A0A1A), _bgDeep],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    // decorative grid lines
                    Positioned.fill(
                      child: CustomPaint(painter: _GridPainter()),
                    ),
                    const Positioned(
                      bottom: 20,
                      left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UPGRADE ACCESS',
                            style: TextStyle(
                              color: _textLight,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Orbitron',
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'AI-powered role recommendations',
                            style: TextStyle(
                              color: _accentColor,
                              fontSize: 11,
                              fontFamily: 'ShareTechMono',
                              letterSpacing: 1,
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

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Hero Banner Image ───────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        Image.asset(
                          'assets/images/upgrade_role_banner.jpg',
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                        // gradient overlay biar text readable
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.55),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.4),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                        // badge atas kiri
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB388FF).withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome,
                                    color: Colors.white, size: 11),
                                SizedBox(width: 5),
                                Text(
                                  'AI-POWERED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    fontFamily: 'Orbitron',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // badge bawah kanan
                        Positioned(
                          bottom: 14,
                          right: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFF00E5FF)
                                      .withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              'QRIS · INSTANT',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // ─────────────────────────────────────────────

                // ── AI Info Banner ──────────────────────────
                _buildAiBanner(),
                const SizedBox(height: 20),

                // ── Current Role Badge ─────────────────────
                _buildCurrentRoleBadge(),
                const SizedBox(height: 24),

                // ── Package Cards ──────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PILIH PAKET UPGRADE',
                        style: TextStyle(
                          color: _textSub,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_packages.length, (i) {
                        return _buildPackageCard(_packages[i], i);
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Payment Button ─────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildPayButton(),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── AI Banner ─────────────────────────────────────────────
  Widget _buildAiBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _neonPurple.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _neonPurple.withValues(alpha: 0.08),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI icon animated
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _neonPurple.withValues(alpha: _pulseAnim.value * 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _neonPurple.withValues(alpha: _pulseAnim.value),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: _neonPurple,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'AI ADVISOR',
                        style: TextStyle(
                          color: _neonPurple,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _neonGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: _neonGreen.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'ONLINE',
                          style: TextStyle(
                            color: _neonGreen,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_isAiLoading)
                    Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: _neonPurple.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Menganalisis akunmu...',
                          style: TextStyle(
                            color: _textSub,
                            fontSize: 12,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      _aiAdvice.isEmpty
                          ? 'Tap refresh untuk saran AI.'
                          : _aiAdvice,
                      style: const TextStyle(
                        color: _textLight,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isAiLoading ? null : _loadAiAdvice,
              child: Icon(
                Icons.refresh_rounded,
                color: _isAiLoading
                    ? _textMuted
                    : _neonPurple.withValues(alpha: 0.7),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Current Role Badge ────────────────────────────────────
  Widget _buildCurrentRoleBadge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_outline, color: _textSub, size: 16),
            const SizedBox(width: 10),
            Text(
              'Role sekarang: ',
              style: const TextStyle(color: _textSub, fontSize: 13),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _accentColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                widget.currentRole.toUpperCase(),
                style: const TextStyle(
                  color: _accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontFamily: 'ShareTechMono',
                ),
              ),
            ),
            const Spacer(),
            Text(
              '@${widget.username}',
              style: const TextStyle(
                color: _textMuted,
                fontSize: 11,
                fontFamily: 'ShareTechMono',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Package Card ──────────────────────────────────────────
  Widget _buildPackageCard(_RolePackage pkg, int index) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? pkg.color.withValues(alpha: 0.08)
              : _bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? pkg.color.withValues(alpha: 0.5)
                : _border,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: pkg.color.withValues(alpha: 0.15),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: pkg.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: pkg.color.withValues(alpha: 0.25)),
                  ),
                  child: Icon(pkg.icon, color: pkg.color, size: 22),
                ),
                const SizedBox(width: 14),
                // label + duration
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pkg.label,
                        style: TextStyle(
                          color: isSelected ? pkg.color : _textLight,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pkg.duration,
                        style: const TextStyle(
                          color: _textSub,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      pkg.price,
                      style: TextStyle(
                        color: pkg.color,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: pkg.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'DIPILIH',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                // radio
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? pkg.color : _textMuted,
                      width: 2,
                    ),
                    color: isSelected
                        ? pkg.color.withValues(alpha: 0.2)
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: pkg.color, size: 12)
                      : null,
                ),
              ],
            ),
            // features
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: isSelected
                  ? Column(
                      children: [
                        const SizedBox(height: 14),
                        Container(
                          height: 1,
                          color: pkg.color.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 14),
                        ...pkg.features.map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: pkg.color,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    f,
                                    style: const TextStyle(
                                      color: _textLight,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        // AI detail button
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _showAiPackageDetail(pkg),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: _neonPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color:
                                      _neonPurple.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome,
                                    color: _neonPurple, size: 13),
                                SizedBox(width: 6),
                                Text(
                                  'Tanya AI soal paket ini',
                                  style: TextStyle(
                                    color: _neonPurple,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pay Button ────────────────────────────────────────────
  Widget _buildPayButton() {
    final pkg = _packages[_selectedIndex];
    return GestureDetector(
      onTap: () => _showPaymentSheet(pkg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              pkg.color,
              pkg.color.withValues(alpha: 0.7),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: pkg.color.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_2_rounded,
                color: Colors.black, size: 22),
            const SizedBox(width: 10),
            Column(
              children: [
                const Text(
                  'BAYAR VIA QRIS',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Orbitron',
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '${pkg.price} — ${pkg.label}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── AI Package Detail Dialog ──────────────────────────────
  void _showAiPackageDetail(_RolePackage pkg) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _AiDetailDialog(pkg: pkg, fetcher: _askAiAboutPackage),
    );
  }

  // ── Payment Bottom Sheet ──────────────────────────────────
  void _showPaymentSheet(_RolePackage pkg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentSheet(pkg: pkg, username: widget.username),
    );
  }
}

// ============================================================
//  AI DETAIL DIALOG
// ============================================================
class _AiDetailDialog extends StatefulWidget {
  final _RolePackage pkg;
  final Future<String> Function(_RolePackage) fetcher;
  const _AiDetailDialog({required this.pkg, required this.fetcher});

  @override
  State<_AiDetailDialog> createState() => _AiDetailDialogState();
}

class _AiDetailDialogState extends State<_AiDetailDialog> {
  bool _loading = true;
  String _text = '';

  @override
  void initState() {
    super.initState();
    widget.fetcher(widget.pkg).then((v) {
      if (mounted) setState(() { _text = v; _loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _neonPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: _neonPurple, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI tentang ${widget.pkg.label}',
                    style: const TextStyle(
                      color: _textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: _textMuted, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _neonPurple,
                  ),
                ),
              )
            else
              Text(
                _text,
                style: const TextStyle(
                  color: _textLight,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.pkg.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: widget.pkg.color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Oke, mengerti',
                  style: TextStyle(
                    color: widget.pkg.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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

// ============================================================
//  PAYMENT BOTTOM SHEET — QRIS
// ============================================================
class _PaymentSheet extends StatefulWidget {
  final _RolePackage pkg;
  final String username;
  const _PaymentSheet({required this.pkg, required this.username});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final pkg = widget.pkg;
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              // handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: pkg.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(pkg.icon, color: pkg.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UPGRADE KE ${pkg.label}',
                        style: const TextStyle(
                          color: _textLight,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        pkg.price,
                        style: TextStyle(
                          color: pkg.color,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // QRIS placeholder visual
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      'SCAN QRIS UNTUK BAYAR',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // QR visual placeholder
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black12, width: 1),
                      ),
                      child: CustomPaint(
                        painter: _QrPlaceholderPainter(pkg.color),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Nominal: ${pkg.price}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'LynisXTeam',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // copy QRIS string button
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: pkg.qrisData));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('QRIS string disalin!'),
                      backgroundColor: pkg.color,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _bgSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy_rounded, color: _textSub, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Salin String QRIS',
                        style: TextStyle(color: _textSub, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // instructions
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CARA PEMBAYARAN',
                      style: TextStyle(
                        color: _textSub,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontFamily: 'ShareTechMono',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _stepItem('1', 'Scan QR code di atas via e-wallet apapun'),
                    _stepItem('2', 'Bayar sesuai nominal yang tertera'),
                    _stepItem('3', 'Screenshot bukti pembayaran'),
                    _stepItem('4', 'Kirim ke admin lewat menu Contact / WhatsApp'),
                    _stepItem('5', 'Role aktif dalam 1×24 jam (biasanya instant)'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // confirm paid button
              if (!_confirmed)
                GestureDetector(
                  onTap: () => _handleConfirmPayment(pkg),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [pkg.color, pkg.color.withValues(alpha: 0.6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: pkg.color.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            color: Colors.black, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'SUDAH BAYAR — KONFIRMASI',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            fontFamily: 'Orbitron',
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _buildConfirmedState(pkg),
            ],
          ),
        ),
      ),
    );
  }

  void _handleConfirmPayment(_RolePackage pkg) {
    setState(() => _confirmed = true);
  }

  Widget _buildConfirmedState(_RolePackage pkg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _neonGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _neonGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: _neonGreen, size: 36),
          const SizedBox(height: 10),
          const Text(
            'Konfirmasi diterima!',
            style: TextStyle(
              color: _textLight,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Kirim bukti bayar ke admin.\nRole akan aktif setelah verifikasi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSub, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            '${pkg.label} — ${pkg.price}',
            style: TextStyle(
              color: pkg.color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepItem(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              num,
              style: const TextStyle(
                color: _accentColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _textLight,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  CUSTOM PAINTERS
// ============================================================

/// Background grid lines — cyberpunk vibe
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.04)
      ..strokeWidth = 1;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// QR placeholder — looks like a real QR minus actual data
class _QrPlaceholderPainter extends CustomPainter {
  final Color accent;
  _QrPlaceholderPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final black = Paint()..color = Colors.black;
    final accentPaint = Paint()..color = accent.withValues(alpha: 0.3);
    final s = size.width;

    void drawSquare(double x, double y, double w, {bool filled = true}) {
      canvas.drawRect(Rect.fromLTWH(x, y, w, w), filled ? black : accentPaint);
    }

    // corner markers
    for (final corner in [
      [0.0, 0.0],
      [s - s * 0.22, 0.0],
      [0.0, s - s * 0.22],
    ]) {
      final cx = corner[0], cy = corner[1];
      final cw = s * 0.22;
      drawSquare(cx, cy, cw);
      drawSquare(cx + cw * 0.15, cy + cw * 0.15, cw * 0.7,
          filled: false);
      drawSquare(cx + cw * 0.3, cy + cw * 0.3, cw * 0.4);
    }

    // random data dots
    final rng = [
      [0.32, 0.08], [0.42, 0.08], [0.52, 0.08], [0.62, 0.08],
      [0.32, 0.18], [0.52, 0.18], [0.62, 0.18],
      [0.32, 0.28], [0.42, 0.28], [0.52, 0.28],
      [0.08, 0.32], [0.18, 0.32], [0.28, 0.32], [0.38, 0.32],
      [0.48, 0.32], [0.58, 0.32], [0.68, 0.32], [0.78, 0.32],
      [0.08, 0.42], [0.28, 0.42], [0.58, 0.42], [0.78, 0.42],
      [0.08, 0.52], [0.18, 0.52], [0.38, 0.52], [0.48, 0.52],
      [0.68, 0.52], [0.78, 0.52], [0.88, 0.52],
      [0.28, 0.62], [0.38, 0.62], [0.58, 0.62], [0.68, 0.62],
      [0.38, 0.72], [0.48, 0.72], [0.68, 0.72], [0.78, 0.72],
      [0.28, 0.82], [0.48, 0.82], [0.58, 0.82], [0.78, 0.82],
      [0.38, 0.92], [0.58, 0.92], [0.68, 0.92], [0.88, 0.92],
    ];
    for (final pt in rng) {
      canvas.drawRect(
        Rect.fromLTWH(pt[0] * s, pt[1] * s, s * 0.08, s * 0.08),
        black,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

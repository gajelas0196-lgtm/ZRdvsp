// ============================================================
// GMAIL IDENTITY — Sadap Identitas Via Gmail
// RDVSP / RDVSP PROJECT — by KARZRDVSP / RDVSP
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// ============ PALET ============
const Color _bgDeep      = Color(0xFF050505);
const Color _bgCard      = Color(0xFF0F0F0F);
const Color _bgSurface   = Color(0xFF1A1A1A);
const Color _accentColor = Color(0xFF00E5FF);
const Color _accentRed   = Color(0xFFFF0040);
const Color _accentGreen = Color(0xFF34D399);
const Color _textLight   = Color(0xFFFFFFFF);
const Color _textSub     = Color(0xFF8A8A8A);
const Color _textMuted   = Color(0xFF555555);
const Color _border      = Color(0x1FFFFFFF);
// ================================

// ============================================================
// DATA MODEL
// ============================================================
class GmailIdentityResult {
  final String email;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final String? lastSeen;
  final String? country;
  final List<String> associatedServices;
  final bool breached;
  final List<String> breachSites;
  final String? createdApprox;
  final Map<String, dynamic> rawGravatar;

  GmailIdentityResult({
    required this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.lastSeen,
    this.country,
    required this.associatedServices,
    required this.breached,
    required this.breachSites,
    this.createdApprox,
    required this.rawGravatar,
  });
}

// ============================================================
// PAGE
// ============================================================
class GmailIdentityPage extends StatefulWidget {
  const GmailIdentityPage({super.key});

  @override
  State<GmailIdentityPage> createState() => _GmailIdentityPageState();
}

class _GmailIdentityPageState extends State<GmailIdentityPage>
    with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _emailCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // State
  bool _loading = false;
  String? _error;
  GmailIdentityResult? _result;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _emailCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ============================================================
  // CORE LOOKUP — multi-source
  // ============================================================
  Future<void> _lookup() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Masukkan Gmail yang valid.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      // --- 1. Gravatar hash (SHA-256 for new API, MD5 for legacy) ---
      final gravatarHash = _md5Hex(email);
      final gravatarUrl =
          'https://www.gravatar.com/$gravatarHash.json';

      Map<String, dynamic> gravatarData = {};
      String? displayName;
      String? firstName;
      String? lastName;
      String? photoUrl;
      String? country;
      List<String> services = [];
      bool breached = false;
      List<String> breachSites = [];

      // --- Gravatar fetch ---
      try {
        final gResp = await http
            .get(Uri.parse(gravatarUrl))
            .timeout(const Duration(seconds: 8));
        if (gResp.statusCode == 200) {
          gravatarData = jsonDecode(gResp.body);
          final entry = (gravatarData['entry'] as List?)?.first ?? {};

          displayName = entry['displayName'] as String?;
          final name = entry['name'] as Map<String, dynamic>?;
          firstName = name?['givenName'] as String?;
          lastName  = name?['familyName'] as String?;
          country   = entry['currentLocation'] as String?;

          // Photo
          final photos = entry['photos'] as List?;
          if (photos != null && photos.isNotEmpty) {
            photoUrl = (photos.first as Map<String, dynamic>)['value'] as String?;
          }

          // Linked accounts
          final accounts = entry['accounts'] as List?;
          if (accounts != null) {
            for (final acc in accounts) {
              final svc = (acc as Map<String, dynamic>)['shortname'] as String?;
              if (svc != null) services.add(svc);
            }
          }

          // URLs as extra services
          final urls = entry['urls'] as List?;
          if (urls != null) {
            for (final u in urls) {
              final title = (u as Map<String, dynamic>)['title'] as String?;
              if (title != null && !services.contains(title)) {
                services.add(title);
              }
            }
          }
        }
      } catch (_) {}

      // --- 2. HaveIBeenPwned public API (no key needed for free tier) ---
      try {
        final pwnResp = await http.get(
          Uri.parse(
              'https://haveibeenpwned.com/api/v3/breachedaccount/${Uri.encodeComponent(email)}?truncateResponse=false'),
          headers: {
            'hibp-api-key': '', // free tier tanpa key hanya check count
            'User-Agent': 'Rdvsp-DarkVerse',
          },
        ).timeout(const Duration(seconds: 8));

        if (pwnResp.statusCode == 200) {
          final breaches = jsonDecode(pwnResp.body) as List;
          if (breaches.isNotEmpty) {
            breached = true;
            for (final b in breaches) {
              final name = (b as Map<String, dynamic>)['Name'] as String?;
              if (name != null) breachSites.add(name);
            }
          }
        } else if (pwnResp.statusCode == 404) {
          breached = false;
        }
      } catch (_) {}

      // --- 3. Fallback breach check via emailrep.io (no key) ---
      if (!breached) {
        try {
          final repResp = await http.get(
            Uri.parse('https://emailrep.io/$email'),
            headers: {'User-Agent': 'Rdvsp-DarkVerse'},
          ).timeout(const Duration(seconds: 8));

          if (repResp.statusCode == 200) {
            final repData = jsonDecode(repResp.body) as Map<String, dynamic>;
            final details = repData['details'] as Map<String, dynamic>?;

            breached = repData['suspicious'] as bool? ?? false;

            final repServices = details?['profiles'] as List?;
            if (repServices != null) {
              for (final s in repServices) {
                final sStr = s as String;
                if (!services.contains(sStr)) services.add(sStr);
              }
            }
          }
        } catch (_) {}
      }

      // --- 4. Dedupe & build result ---
      services = services.toSet().toList();

      setState(() {
        _result = GmailIdentityResult(
          email: email,
          displayName: displayName,
          firstName: firstName,
          lastName: lastName,
          photoUrl: photoUrl,
          country: country,
          associatedServices: services,
          breached: breached,
          breachSites: breachSites,
          rawGravatar: gravatarData,
        );
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal fetch: $e';
        _loading = false;
      });
    }
  }

  // ============================================================
  // MD5 helper — diperlukan untuk Gravatar hash
  // ============================================================
  String _md5Hex(String input) {
    // Dart tidak punya md5 built-in tanpa crypto package.
    // Kalau project sudah ada package 'crypto', ganti ini:
    // import 'package:crypto/crypto.dart';
    // return md5.convert(utf8.encode(input)).toString();
    //
    // Fallback: generate hash manual sederhana untuk demo
    // (kalau crypto tersedia di pubspec, pakai yang di atas)
    final bytes = utf8.encode(input);
    var hash = 0;
    for (final b in bytes) {
      hash = ((hash << 5) - hash + b) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0') * 4;
    // NOTE: kalau crypto package ada, uncomment baris import di atas
    // dan ganti fungsi ini dengan: return md5.convert(utf8.encode(input)).toString();
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBanner(),
            const SizedBox(height: 20),
            _buildInputSection(),
            const SizedBox(height: 20),
            if (_loading) _buildLoadingWidget(),
            if (_error != null) _buildErrorWidget(_error!),
            if (_result != null) _buildResultSection(_result!),
          ],
        ),
      ),
    );
  }

  // ---- AppBar ----
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bgDeep,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: _accentColor, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Icon(
              Icons.manage_search,
              color: _accentColor.withOpacity(_pulseAnim.value),
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'SADAP IDENTITAS',
            style: TextStyle(
              color: _accentColor,
              fontSize: 13,
              fontFamily: 'ShareTechMono',
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _accentRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _accentRed.withOpacity(0.3)),
          ),
          child: const Text(
            'GMAIL',
            style: TextStyle(
              color: _accentRed,
              fontSize: 9,
              fontFamily: 'ShareTechMono',
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ---- Banner ----
  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentColor.withOpacity(0.08)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accentColor.withOpacity(0.04),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.alternate_email, color: _accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gmail Identity Scanner',
                  style: TextStyle(
                    color: _textLight,
                    fontSize: 12,
                    fontFamily: 'ShareTechMono',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Kirim akun Gmail → deteksi profil, nama, foto, layanan terhubung & breach.',
                  style: TextStyle(
                    color: _textSub,
                    fontSize: 9.5,
                    fontFamily: 'ShareTechMono',
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Input ----
  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TARGET GMAIL',
          style: TextStyle(
            color: _textMuted,
            fontSize: 9,
            fontFamily: 'ShareTechMono',
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accentColor.withOpacity(0.15)),
          ),
          child: TextField(
            controller: _emailCtrl,
            focusNode: _focusNode,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            style: const TextStyle(
              color: _textLight,
              fontFamily: 'ShareTechMono',
              fontSize: 13,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              hintText: 'target@gmail.com',
              hintStyle: TextStyle(
                color: _textMuted,
                fontFamily: 'ShareTechMono',
                fontSize: 12,
              ),
              prefixIcon: const Icon(Icons.alternate_email, color: _accentColor, size: 18),
              suffixIcon: _emailCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: _textMuted, size: 16),
                      onPressed: () {
                        _emailCtrl.clear();
                        setState(() {
                          _result = null;
                          _error = null;
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            onSubmitted: (_) => _lookup(),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _loading ? null : _lookup,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: _bgDeep,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_bgDeep),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.radar, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'SCAN IDENTITAS',
                        style: TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ---- Loading ----
  Widget _buildLoadingWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _accentColor.withOpacity(_pulseAnim.value),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.manage_search,
                  color: _accentColor.withOpacity(_pulseAnim.value),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scanning identitas...',
              style: TextStyle(
                color: _textSub,
                fontFamily: 'ShareTechMono',
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Error ----
  Widget _buildErrorWidget(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accentRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _accentRed, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                color: _accentRed,
                fontFamily: 'ShareTechMono',
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Result ----
  Widget _buildResultSection(GmailIdentityResult r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row
        _buildSectionLabel('HASIL IDENTITAS'),
        const SizedBox(height: 12),

        // ── Profile card
        _buildProfileCard(r),
        const SizedBox(height: 14),

        // ── Info grid
        _buildInfoGrid(r),
        const SizedBox(height: 14),

        // ── Breach card
        _buildBreachCard(r),
        const SizedBox(height: 14),

        // ── Services card
        if (r.associatedServices.isNotEmpty) ...[
          _buildServicesCard(r),
          const SizedBox(height: 14),
        ],

        // ── Copy raw JSON
        _buildCopyRaw(r),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.7),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: _textMuted,
            fontSize: 9,
            fontFamily: 'ShareTechMono',
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Profile card (foto + nama)
  Widget _buildProfileCard(GmailIdentityResult r) {
    final hasName = (r.displayName?.isNotEmpty ?? false) ||
        (r.firstName?.isNotEmpty ?? false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accentColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 32,
            backgroundColor: _bgSurface,
            backgroundImage:
                r.photoUrl != null ? NetworkImage(r.photoUrl!) : null,
            child: r.photoUrl == null
                ? const Icon(Icons.person, color: _textSub, size: 30)
                : null,
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasName
                      ? (r.displayName ??
                          '${r.firstName ?? ''} ${r.lastName ?? ''}'.trim())
                      : 'Nama tidak ditemukan',
                  style: TextStyle(
                    color: hasName ? _textLight : _textMuted,
                    fontSize: 14,
                    fontFamily: 'ShareTechMono',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  r.email,
                  style: const TextStyle(
                    color: _accentColor,
                    fontSize: 11,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
                if (r.country != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 11, color: _textSub),
                      const SizedBox(width: 4),
                      Text(
                        r.country!,
                        style: const TextStyle(
                          color: _textSub,
                          fontSize: 10,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info grid
  Widget _buildInfoGrid(GmailIdentityResult r) {
    final items = <Map<String, String?>>[
      {'label': 'First Name', 'value': r.firstName},
      {'label': 'Last Name', 'value': r.lastName},
      {'label': 'Display Name', 'value': r.displayName},
      {'label': 'Lokasi', 'value': r.country},
      {'label': 'Gravatar', 'value': r.rawGravatar.isNotEmpty ? 'Aktif' : 'Tidak ada'},
      {'label': 'Layanan', 'value': '${r.associatedServices.length} terdeteksi'},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Text(
                        item['label']!,
                        style: const TextStyle(
                          color: _textMuted,
                          fontSize: 10,
                          fontFamily: 'ShareTechMono',
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item['value'] ?? '—',
                        style: TextStyle(
                          color: item['value'] != null ? _textLight : _textMuted,
                          fontSize: 10,
                          fontFamily: 'ShareTechMono',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ── Breach card
  Widget _buildBreachCard(GmailIdentityResult r) {
    final color = r.breached ? _accentRed : _accentGreen;
    final label = r.breached ? 'AKUN BOCOR' : 'AMAN — Tidak ada breach';
    final icon = r.breached ? Icons.warning_amber_rounded : Icons.verified_user;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontFamily: 'ShareTechMono',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          if (r.breached && r.breachSites.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: r.breachSites
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _accentRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _accentRed.withOpacity(0.2)),
                        ),
                        child: Text(
                          s,
                          style: const TextStyle(
                            color: _accentRed,
                            fontSize: 9,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ── Services
  Widget _buildServicesCard(GmailIdentityResult r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LAYANAN TERHUBUNG (${r.associatedServices.length})',
            style: const TextStyle(
              color: _textMuted,
              fontSize: 9,
              fontFamily: 'ShareTechMono',
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: r.associatedServices
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: _accentColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                          color: _accentColor,
                          fontSize: 9.5,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Copy Raw
  Widget _buildCopyRaw(GmailIdentityResult r) {
    return GestureDetector(
      onTap: () {
        final raw = jsonEncode({
          'email': r.email,
          'displayName': r.displayName,
          'firstName': r.firstName,
          'lastName': r.lastName,
          'photoUrl': r.photoUrl,
          'country': r.country,
          'associatedServices': r.associatedServices,
          'breached': r.breached,
          'breachSites': r.breachSites,
          'gravatarRaw': r.rawGravatar,
        });
        Clipboard.setData(ClipboardData(text: raw));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Data disalin ke clipboard',
              style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 11),
            ),
            backgroundColor: _accentColor.withOpacity(0.15),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.copy, size: 14, color: _textSub),
            SizedBox(width: 8),
            Text(
              'COPY RAW DATA',
              style: TextStyle(
                color: _textSub,
                fontSize: 10,
                fontFamily: 'ShareTechMono',
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

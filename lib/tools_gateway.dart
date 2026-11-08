import 'dart:ui';
import 'package:flutter/material.dart';
import 'manage_server.dart';
import 'wifi_internal.dart';
import 'wifi_external.dart';
import 'ddos_panel.dart';
import 'nik_check.dart';
import 'tiktok_page.dart';
import 'instagram_page.dart';
import 'qr_gen.dart';
import 'domain_page.dart';
import 'spam_ngl.dart';
import 'anime.dart';
import 'hentai_page.dart' as hentai;

// ============ TOOLS BARU ============
import 'FreeFireLagServer.dart';
import 'mlbb_lag_page.dart';
import 'encryption_base64.dart';
import 'iqc_page.dart';
import 'comic.dart';
import 'ddos_cloudflare.dart';
import 'tourl.dart';
import 'converter_page.dart';
import 'ai_page.dart';
import 'fake_identity.dart';
import 'whois_page.dart';
import 'web_scanner.dart';
import 'tiktok_booster.dart';
import 'ip_geo.dart';
import 'speed_test.dart';
import 'gmail_identity.dart';
// HAPUS: import 'wifi_crackers.dart';
// ====================================

// ============ PALET WARNA DARI DASHBOARD ============
const Color _bgDeep = Color(0xFF050505);
const Color _bgCard = Color(0xFF0F0F0F);
const Color _bgSurface = Color(0xFF1A1A1A);
const Color _bgElevated = Color(0xFF252525);
const Color _accentColor = Color(0xFF00E5FF);
const Color _accentSecondary = Color(0xFF2979FF);
const Color _textLight = Color(0xFFFFFFFF);
const Color _textSub = Color(0xFF8A8A8A);
const Color _textMuted = Color(0xFF555555);
const Color _border = Color(0x1FFFFFFF);
const Color _borderAccent = Color(0x33FFFFFF);
const Color _shadowColor = Color(0x80000000);
// =================================================

class ToolsPage extends StatelessWidget {
  final String sessionKey;
  final String userRole;
  final List<Map<String, dynamic>> listDoos;

  const ToolsPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
    required this.listDoos,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      body: SafeArea(
        child: Stack(
          children: [
            // Background ambient glow layers
            Positioned(
              top: -120,
              right: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _accentColor.withOpacity(0.06),
                      _accentColor.withOpacity(0.02),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -100,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _accentColor.withOpacity(0.04),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
            // Main scrollable content
            ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                _buildStatBar(),
                const SizedBox(height: 20),
                _buildSectionLabel("ATTACK & INFRASTRUCTURE"),
                const SizedBox(height: 10),
                _buildToolsGrid([
                  _buildToolCard(
                    context: context,
                    icon: Icons.flash_on,
                    label: "Attack Panel",
                    badge: "LIVE",
                    badgeColor: Colors.redAccent,
                    desc: "Launch & monitor attacks",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AttackPanel(
                            sessionKey: sessionKey,
                            listDoos: listDoos,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildToolCard(
                    context: context,
                    icon: Icons.dns,
                    label: "Manage Server",
                    desc: "Control your botnet nodes",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManageServerPage(keyToken: sessionKey),
                        ),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 22),
                _buildSectionLabel("GAME LAG TOOLS"),
                const SizedBox(height: 10),
                _buildToolsGrid([
                  _buildToolCard(
                    context: context,
                    icon: Icons.sports_esports,
                    label: "Free Fire Lag",
                    badge: "GAME",
                    badgeColor: Colors.orangeAccent,
                    desc: "Lag server Free Fire",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FreeFireLagServerPage(),
                        ),
                      );
                    },
                  ),
                  _buildToolCard(
                    context: context,
                    icon: Icons.games,
                    label: "MLBB Lag",
                    badge: "GAME",
                    badgeColor: Colors.blueAccent,
                    desc: "Lag server Mobile Legends",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MlbbLagPage(sessionKey: sessionKey),
                        ),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 22),
                _buildSectionLabel("NETWORK OPERATIONS"),
                const SizedBox(height: 10),
                _buildToolsGrid([
                  _buildToolCard(
                    context: context,
                    icon: Icons.newspaper_outlined,
                    label: "Spam NGL",
                    badge: "NEW",
                    badgeColor: _accentColor,
                    desc: "Send anonymous messages",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NglPage()));
                    },
                  ),
                  _buildToolCard(
                    context: context,
                    icon: Icons.wifi_off,
                    label: "WiFi Killer",
                    desc: "Internal network disruptor",
                    subLabel: "Internal",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const WifiKillerPage()));
                    },
                  ),
                  if (userRole == "vip" || userRole == "owner")
                    _buildToolCard(
                      context: context,
                      icon: Icons.router,
                      label: "WiFi Killer",
                      badge: "VIP",
                      badgeColor: Colors.amber,
                      desc: "External network attack",
                      subLabel: "External",
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => WifiInternalPage(sessionKey: sessionKey)));
                      },
                    ),
                  _buildToolCard(
                    context: context,
                    icon: Icons.vpn_key,
                    label: "WiFi Scanner",
                    locked: true,
                    desc: "Scan nearby networks",
                    onTap: () => _showComingSoon(context),
                  ),
                ]),
                const SizedBox(height: 22),
                _buildSectionLabel("OSINT & INVESTIGATION"),
                const SizedBox(height: 10),
                _buildToolsGrid([
                  _buildToolCard(
                    context: context,
                    icon: Icons.badge,
                    label: "NIK Detail",
                    desc: "Lookup KTP information",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NikCheckerPage()));
                    },
                  ),
                  _buildToolCard(
                    context: context,
                    icon: Icons.domain,
                    label: "Domain OSINT",
                    desc: "Domain reconnaissance",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DomainOsintPage()));
                    },
                  ),
                  _buildToolCard(
                    context: context,
                    icon: Icons.person_search,
                    label: "Phone Lookup",
                    locked: true,
                    desc: "Number intelligence",
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildToolCard(
                    context: context,
                    icon: Icons.alternate_email,
                    label: "Email OSINT",
                    badge: "LIVE",
                    badgeColor: Color(0xFFFF0040),
                    desc: "Email breach lookup",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GmailIdentityPage(),
                        ),
                      );
                    },
                  ),
                  _buildToolCard(
                    context: context,
                    icon: Icons.manage_search,
                    label: "Sadap Identitas",
                    badge: "NEW",
                    badgeColor: Color(0xFF00E5FF),
                    desc: "Deteksi identitas via Gmail",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GmailIdentityPage(),
                        ),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 22),
                _buildSectionLabel("SOCIAL MEDIA DOWNLOADER"),
                const SizedBox(height: 10),
                _buildToolsGrid([
                  _buildToolCard(
                    context: context,
                    icon: Icons.video_library,
                    label: "TikTok Downloader",
                    desc: "Save videos without watermark",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TiktokDownloaderPage()));
                    },
                  ),
                  _buildToolCard(
                    context: context,
                    icon: Icons.camera_alt,
                    label: "Instagram Downloader",
                    desc: "Reels, stories & posts",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const InstagramDownloaderPage()));
                    },
                  ),
                  _buildToolCard(
                    context: context,
                    icon: Icons.play_circle_outline,
                    label: "YouTube Downloader",
                    locked: true,
                    desc: "Video & audio extraction",
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildToolCard(
                    context: context,
                    icon: Icons.music_note,
                    label: "Spotify Downloader",
                    locked: true,
                    desc: "Song & playlist saver",
                    onTap: () => _showComingSoon(context),
                  ),
                ]),
                const SizedBox(height: 22),
                _buildSectionLabel("UTILITIES & EXTRA TOOLS"),
                const SizedBox(height: 10),
                _buildToolsGrid([
                  _buildToolCard(
                    context: context,
                    icon: Icons.qr_code,
                    label: "QR Generator",
                    desc: "Create custom QR codes",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const QrGeneratorPage()));
                    },
                  ),
                  _buildToolCard(
                    context: context,
                    icon: Icons.security,
                    label: "IP Scanner",
                    locked: true,
                    desc: "Network host discovery",
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildToolCard(
                    context: context,
                    icon: Icons.network_check,
                    label: "Port Scanner",
                    locked: true,
                    desc: "Service enumeration",
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildToolCard(
                    context: context,
                    icon: Icons.password,
                    label: "Password Gen",
                    locked: true,
                    desc: "Secure random passwords",
                    onTap: () => _showComingSoon(context),
                  ),
                ]),
                const SizedBox(height: 22),
                _buildSectionLabel("RANDOM TOOLS"),
                const SizedBox(height: 10),
                _buildToolsGrid([
                  // ============ 1 ============
                  _buildToolCard(
                    context: context,
                    icon: Icons.cloud_off,
                    label: "DDoS Cloudflare",
                    badge: "NEW",
                    badgeColor: _accentColor,
                    desc: "Bypass CF & DDoS attack",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DDoSCloudflarePage(),
                        ),
                      );
                    },
                  ),
                  // ============ 2 ============
                  _buildToolCard(
                    context: context,
                    icon: Icons.upload_file,
                    label: "Upload Media",
                    desc: "Upload ke Catbox & get URI",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CatboxUploaderPage(
                            username: sessionKey,
                            role: userRole,
                            totalTools: listDoos.length,
                          ),
                        ),
                      );
                    },
                  ),
                  // ============ 3 ============
                  _buildToolCard(
                    context: context,
                    icon: Icons.code,
                    label: "Base64 Encrypt",
                    badge: "NEW",
                    badgeColor: _accentColor,
                    desc: "Encode & decode Base64",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EncryptionRavenClawx(),
                        ),
                      );
                    },
                  ),
                  // ============ 4 ============
                  _buildToolCard(
                    context: context,
                    icon: Icons.psychology,
                    label: "IQC Screenshot",
                    desc: "Create WhatsApp screenshot",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IQCScreen(),
                        ),
                      );
                    },
                  ),
                  // ============ 5 ============
                  _buildToolCard(
                    context: context,
                    icon: Icons.calculate,
                    label: "Converter",
                    badge: "NEW",
                    badgeColor: _accentColor,
                    desc: "Currency & unit converter",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ConverterPage(),
                        ),
                      );
                    },
                  ),
                  // ============ 6 ============
                  _buildToolCard(
                    context: context,
                    icon: Icons.bolt,
                    label: "Xentra'X Ai",
                    badge: "AI",
                    badgeColor: Colors.purpleAccent,
                    desc: "AI assistant with Groq",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AIPage(
                            username: sessionKey,
                            sessionKey: sessionKey,
                          ),
                        ),
                      );
                    },
                  ),
                  // ============ 7 ============
                  _buildToolCard(
                    context: context,
                    icon: Icons.person_add_alt_1,
                    label: "Fake Identity",
                    badge: "NEW",
                    badgeColor: Colors.orangeAccent,
                    desc: "Generate dummy identity",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FakeIdentityPage(),
                        ),
                      );
                    },
                  ),
                  // ============ 8 ============
                  _buildToolCard(
                    context: context,
                    icon: Icons.manage_search,
                    label: "WHOIS Lookup",
                    badge: "NEW",
                    badgeColor: const Color(0xFF00FF41),
                    desc: "Domain registration info",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WhoisPage(),
                        ),
                      );
                    },
                  ),
                  // ============ 9 ============
                  _buildToolCard(
                    context: context,
                    icon: Icons.search,
                    label: "Web Scanner",
                    badge: "NEW",
                    badgeColor: const Color(0xFFFFD600),
                    desc: "Website security scanner",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WebScannerPage(),
                        ),
                      );
                    },
                  ),
                  // ============ 10 ============
                  _buildToolCard(
                    context: context,
                    icon: Icons.location_searching,
                    label: "IP Geolocation",
                    badge: "NEW",
                    badgeColor: const Color(0xFF00E5FF),
                    desc: "Trace IP location & ISP",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IpGeoPage(),
                        ),
                      );
                    },
                  ),
                  // ============ 11 ============
                  _buildToolCard(
                    context: context,
                    icon: Icons.speed,
                    label: "Speed Test",
                    badge: "NEW",
                    badgeColor: const Color(0xFF00E676),
                    desc: "Test ping & internet speed",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SpeedTestPage(),
                        ),
                      );
                    },
                  ),
                  // ============ 12 ============
                  _buildToolCard(
                    context: context,
                    icon: Icons.flash_on,
                    label: "TikTok Booster",
                    badge: "VIP",
                    badgeColor: const Color(0xFFE91E63),
                    desc: "Boost followers & likes",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TikTokBooster(
                            sessionKey: sessionKey,
                            role: userRole,
                          ),
                        ),
                      );
                    },
                  ),
                  // =====================================
                ]),
                const SizedBox(height: 22),
                _buildSectionLabel("ENTERTAINMENT & MEDIA"),
                const SizedBox(height: 10),
                _buildToolsGrid([
                  _buildToolCard(
                    context: context,
                    icon: Icons.live_tv,
                    label: "Anime Streaming",
                    desc: "Watch anime for free",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeAnimePage()));
                    },
                  ),
                  _buildToolCard(
                    context: context,
                    icon: Icons.local_fire_department,
                    label: "Hentai Media",
                    badge: "18+",
                    badgeColor: Colors.pinkAccent,
                    desc: "Adult content library",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const hentai.HomeScreen()));
                    },
                  ),
                  _buildToolCard(
                    context: context,
                    icon: Icons.book,
                    label: "Comic Reader",
                    badge: "NEW",
                    badgeColor: Colors.purpleAccent,
                    desc: "Read comics online",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ComicPage(),
                        ),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 28),
                _buildFooter(),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============ HEADER ============
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accentColor.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.06),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Shield icon with glow ring
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _accentColor.withOpacity(0.4),
                      _accentSecondary.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _bgCard,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shield, color: _accentColor, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_accentColor, _accentSecondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "XENTRA'X EXECUTION",
                        style: TextStyle(
                          color: _bgDeep,
                          fontSize: 16,
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 1,
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "TOOLS DASHBOARD",
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 10,
                            fontFamily: 'ShareTechMono',
                            letterSpacing: 2.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _accentColor.withOpacity(0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _accentColor.withOpacity(0.6),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      userRole.toUpperCase(),
                      style: TextStyle(
                        color: _accentColor,
                        fontSize: 9,
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Divider with dot
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _accentColor.withOpacity(0.0),
                        _accentColor.withOpacity(0.15),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _accentColor.withOpacity(0.15),
                        _accentColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quick stats row
          Row(
            children: [
              _buildHeaderStat(
                icon: Icons.flash_on,
                value: "${listDoos.length}",
                label: "Methods",
              ),
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 28,
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 12),
              _buildHeaderStat(
                icon: Icons.grid_view,
                value: "32",
                label: "Tools",
              ),
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 28,
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 12),
              _buildHeaderStat(
                icon: Icons.lock_outline,
                value: "4",
                label: "Locked",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: _accentColor.withOpacity(0.5), size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: _textLight,
                  fontSize: 14,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 8,
                  fontFamily: 'ShareTechMono',
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ STAT BAR ============
  Widget _buildStatBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          _buildStatChip(
            icon: Icons.bolt,
            label: "${listDoos.length} Methods Active",
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            icon: Icons.shield_outlined,
            label: userRole.toUpperCase(),
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            icon: Icons.update,
            label: "v2.0 Stable",
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _accentColor.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _accentColor.withOpacity(0.55), size: 13),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: _textSub,
                  fontSize: 9,
                  fontFamily: 'ShareTechMono',
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ SECTION LABEL ============
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: _textMuted,
              fontSize: 10,
              fontFamily: 'ShareTechMono',
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _accentColor.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ TOOLS GRID ============
  Widget _buildToolsGrid(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.05,
      children: children,
    );
  }

  // ============ TOOL CARD ============
  Widget _buildToolCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    String? subLabel,
    String? desc,
    String? badge,
    Color? badgeColor,
    bool locked = false,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accentColor.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: _accentColor.withOpacity(0.08),
          highlightColor: _accentColor.withOpacity(0.04),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: icon + badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: locked
                            ? _textMuted.withOpacity(0.08)
                            : _accentColor.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: locked
                              ? _textMuted.withOpacity(0.06)
                              : _accentColor.withOpacity(0.12),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: locked
                            ? _textMuted.withOpacity(0.25)
                            : _accentColor.withOpacity(0.75),
                        size: 18,
                      ),
                    ),
                    if (badge != null)
                      _buildMiniBadge(badge, color: badgeColor ?? _accentColor),
                  ],
                ),
                const Spacer(),
                // Label
                Text(
                  label,
                  style: TextStyle(
                    color: locked ? _textMuted.withOpacity(0.35) : _textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subLabel != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subLabel,
                    style: TextStyle(
                      color: locked
                          ? _textMuted.withOpacity(0.2)
                          : _accentColor.withOpacity(0.5),
                      fontSize: 8,
                      fontFamily: 'ShareTechMono',
                      letterSpacing: 1,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                // Desc
                Text(
                  desc ?? "",
                  style: TextStyle(
                    color: locked
                        ? _textMuted.withOpacity(0.2)
                        : _textMuted.withOpacity(0.7),
                    fontSize: 9,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Bottom indicator
                Row(
                  children: [
                    if (locked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _textMuted.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline, color: _textMuted.withOpacity(0.35), size: 8),
                            const SizedBox(width: 3),
                            Text(
                              "LOCKED",
                              style: TextStyle(
                                color: _textMuted.withOpacity(0.35),
                                fontSize: 7,
                                fontFamily: 'ShareTechMono',
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "OPEN",
                            style: TextStyle(
                              color: _accentColor.withOpacity(0.4),
                              fontSize: 7,
                              fontFamily: 'ShareTechMono',
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: locked
                          ? _textMuted.withOpacity(0.15)
                          : _accentColor.withOpacity(0.25),
                      size: 10,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ MINI BADGE ============
  Widget _buildMiniBadge(String text, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 7,
          fontFamily: 'Orbitron',
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ============ FOOTER ============
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accentColor.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        _accentColor.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, color: _accentColor.withOpacity(0.25), size: 12),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accentColor, _accentSecondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "XENTRA'X EXECUTION",
                  style: TextStyle(
                    color: _bgDeep,
                    fontSize: 8,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "v2.0",
                style: TextStyle(
                  color: _textMuted.withOpacity(0.4),
                  fontSize: 8,
                  fontFamily: 'ShareTechMono',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "All tools are for educational purposes only.",
            style: TextStyle(
              color: _textMuted.withOpacity(0.35),
              fontSize: 8,
              fontFamily: 'ShareTechMono',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============ COMING SOON DIALOG ============
  void _showComingSoon(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.78,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accentColor.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: _accentColor.withOpacity(0.04),
                  blurRadius: 40,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon container
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.06),
                    shape: BoxShape.circle,
                    border: Border.all(color: _accentColor.withOpacity(0.12)),
                  ),
                  child: Icon(Icons.lock_clock, color: _accentColor, size: 26),
                ),
                const SizedBox(height: 18),
                Text(
                  "COMING SOON",
                  style: TextStyle(
                    color: _textLight,
                    fontFamily: 'Orbitron',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 30,
                  height: 2,
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "Fitur ini masih dalam tahap pengembangan.\nNantikan update selanjutnya.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textSub,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 22),
                // Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_accentColor, _accentSecondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(context),
                      splashColor: Colors.white.withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            "UNDERSTOOD",
                            style: TextStyle(
                              color: _bgDeep,
                              fontFamily: 'Orbitron',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack).value,
          child: child,
        );
      },
    );
  }
}
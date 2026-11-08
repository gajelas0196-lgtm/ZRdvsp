import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'api_config.dart'

// ============ PALET WARNA HITAM ELEGAN (SAMA SEPERTI DASHBOARD) ============
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

// Warna tambahan untuk tipe aktivitas
const Color _success = Color(0xFF2EE6A6);
const Color _warning = Color(0xFFFFD700);
const Color _danger = Color(0xFFFF5C7A);
// =================================================

class RiwayatPage extends StatefulWidget {
  final String sessionKey;
  final String role;

  const RiwayatPage({
    super.key,
    required this.sessionKey,
    required this.role,
  });

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage>
    with SingleTickerProviderStateMixin {
  List<ActivityModel> activities = [];
  bool isLoading = true;

  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _loadActivities();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    const baseUrl = "$baseUrl";

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getMyActivity?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid']) {
          List<dynamic> rawList = data['activities'];

          setState(() {
            activities = rawList.map((item) {
              return ActivityModel(
                type: item['type'] ?? 'system',
                title: item['title'] ?? 'Aktivitas',
                description: item['description'] ?? '-',
                timestamp: DateTime.fromMillisecondsSinceEpoch(
                    item['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
              );
            }).toList();
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        debugPrint("Server Error: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
      setState(() => isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  String _dateSectionLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return "HARI INI";
    if (diff == 1) return "KEMARIN";
    return DateFormat('dd MMMM yyyy').format(date).toUpperCase();
  }

  Map<String, List<ActivityModel>> _groupedActivities() {
    final Map<String, List<ActivityModel>> grouped = {};
    for (final a in activities) {
      final key = _dateSectionLabel(a.timestamp);
      grouped.putIfAbsent(key, () => []).add(a);
    }
    return grouped;
  }

  int _countByType(String type) =>
      activities.where((a) => a.type == type).length;

  ({Color iconColor, IconData icon, String label, Color badgeBg, Color badgeText})
      _typeStyle(String type) {
    switch (type) {
      case 'login':
        return (
          iconColor: _success,
          icon: Icons.login_rounded,
          label: "LOGIN",
          badgeBg: _success.withOpacity(0.10),
          badgeText: _success,
        );
      case 'bug':
        return (
          iconColor: _danger,
          icon: Icons.gpp_maybe_rounded,
          label: "ATTACK",
          badgeBg: _danger.withOpacity(0.10),
          badgeText: _danger,
        );
      case 'create':
        return (
          iconColor: _warning,
          icon: Icons.person_add_alt_1_rounded,
          label: "ACCOUNT",
          badgeBg: _warning.withOpacity(0.10),
          badgeText: _warning,
        );
      default:
        return (
          iconColor: _accentColor,
          icon: Icons.info_outline_rounded,
          label: "SYSTEM",
          badgeBg: _accentColor.withOpacity(0.08),
          badgeText: _accentColor,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _GridGlowPainter(
                    glow: _glowController.value,
                    accentColor: _accentColor,
                    border: _border,
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    _bgDeep.withOpacity(0.8),
                    _bgDeep,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: isLoading
                ? _buildLoadingState()
                : activities.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadActivities,
                        color: _accentColor,
                        backgroundColor: _bgCard,
                        strokeWidth: 2.5,
                        child: _buildActivityList(),
                      ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bgCard,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.only(left: 8),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _textLight, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [_accentColor, _accentSecondary],
            ).createShader(bounds),
            child: const Text(
              "ACTIVITY LOG",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "SYSTEM HISTORY TRACE",
            style: TextStyle(
              color: _textMuted,
              fontSize: 9,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: isLoading ? null : _loadActivities,
          icon: Icon(
            Icons.refresh_rounded,
            color: isLoading ? _textMuted : _accentColor,
            size: 20,
          ),
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                _accentColor.withOpacity(0.35),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(color: _accentColor, strokeWidth: 2.5),
                Icon(Icons.shield_moon_outlined, color: _accentColor.withOpacity(0.5), size: 20),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "MEMUAT DATA AKTIVITAS...",
            style: TextStyle(
              color: _textMuted,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 90, horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.04),
                  shape: BoxShape.circle,
                  border: Border.all(color: _accentColor.withOpacity(0.10), width: 2),
                  boxShadow: [
                    BoxShadow(color: _accentColor.withOpacity(0.06), blurRadius: 30, spreadRadius: 0),
                  ],
                ),
                child: Icon(Icons.history_toggle_off, size: 52, color: _accentColor.withOpacity(0.25)),
              ),
              const SizedBox(height: 28),
              Text(
                "NO ACTIVITY YET",
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Belum ada catatan aktivitas.\nPastikan server aktif.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _loadActivities,
                icon: Icon(Icons.refresh_rounded, size: 16, color: _accentColor),
                label: Text(
                  "MUAT ULANG",
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _accentColor.withOpacity(0.35)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityList() {
    final grouped = _groupedActivities();
    int runningIndex = 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _buildSummaryHeader(),
        const SizedBox(height: 22),
        for (final entry in grouped.entries) ...[
          _buildSectionDivider(entry.key, entry.value.length),
          const SizedBox(height: 10),
          for (final activity in entry.value) ...[
            _buildActivityCard(activity, runningIndex++),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildSummaryHeader() {
    final total = activities.length;
    final stats = [
      (_typeStyle('login'), _countByType('login')),
      (_typeStyle('bug'), _countByType('bug')),
      (_typeStyle('create'), _countByType('create')),
      (_typeStyle('system'), _countByType('system')),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_bgCard, _bgSurface],
        ),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _accentColor.withOpacity(0.18)),
                ),
                child: FaIcon(FontAwesomeIcons.satelliteDish, size: 16, color: _accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$total",
                      style: const TextStyle(
                        color: _textLight,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      "TOTAL AKTIVITAS TERCATAT",
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: _success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: _success.withOpacity(0.6), blurRadius: 8, spreadRadius: 1),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: _border, height: 1),
          const SizedBox(height: 14),
          Row(
            children: stats.map((s) {
              final style = s.$1;
              final count = s.$2;
              return Expanded(
                child: Column(
                  children: [
                    Icon(style.icon, color: style.iconColor.withOpacity(0.85), size: 16),
                    const SizedBox(height: 6),
                    Text(
                      "$count",
                      style: TextStyle(
                        color: _textLight.withOpacity(0.9),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      style.label,
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 8,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(String label, int count) {
    return Row(
      children: [
        Icon(Icons.chevron_right_rounded, size: 14, color: _accentColor.withOpacity(0.6)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: _accentColor,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_border, Colors.transparent],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "$count",
          style: TextStyle(
            color: _textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(ActivityModel activity, int index) {
    final style = _typeStyle(activity.type);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (index % 6) * 60),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: _shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      style.iconColor.withOpacity(0.9),
                      style.iconColor.withOpacity(0.15),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: style.iconColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: style.iconColor.withOpacity(0.15)),
                        ),
                        child: Icon(style.icon, color: style.iconColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        "#${(index + 1).toString().padLeft(2, '0')}",
                                        style: TextStyle(
                                          color: _textMuted,
                                          fontSize: 10,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          activity.title,
                                          style: const TextStyle(
                                            color: _textLight,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: style.badgeBg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: style.badgeText.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    style.label,
                                    style: TextStyle(
                                      color: style.badgeText,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: _bgSurface.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _border),
                              ),
                              child: Text(
                                activity.description,
                                style: TextStyle(
                                  color: _textSub,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.schedule_rounded, size: 13, color: _textMuted),
                                const SizedBox(width: 5),
                                Text(
                                  _formatDate(activity.timestamp),
                                  style: TextStyle(
                                    color: _textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.circle, size: 4, color: style.iconColor.withOpacity(0.5)),
                                const SizedBox(width: 4),
                                Text(
                                  activity.type.toUpperCase(),
                                  style: TextStyle(
                                    color: style.iconColor.withOpacity(0.55),
                                    fontSize: 9,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridGlowPainter extends CustomPainter {
  final double glow;
  final Color accentColor;
  final Color border;

  _GridGlowPainter({
    required this.glow,
    required this.accentColor,
    required this.border,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = border.withOpacity(0.35)
      ..strokeWidth = 0.6;

    const spacing = 34.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withOpacity(0.10 + 0.05 * glow),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.8, size.height * 0.05),
          radius: 260 + 30 * glow,
        ),
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
  }

  @override
  bool shouldRepaint(covariant _GridGlowPainter oldDelegate) =>
      oldDelegate.glow != glow;
}

class ActivityModel {
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;

  ActivityModel({
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
  });
}
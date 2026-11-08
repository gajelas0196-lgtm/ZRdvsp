import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'api_config.dart'

class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late VideoPlayerController _videoController;
  String selectedBugId = "";

  String _selectedBugMode = "number";
  String _senderMode = "private";
  int _privateSenderCount = 0;
  int _globalSenderCount = 0;
  bool _isSending = false;

  bool _showSenderPopup = false;
  bool _showTargetPopup = false;
  bool _isPrivateActive = true;

  static const Color _bgDeep = Color(0xFF050505);
  static const Color _bgCard = Color(0xFF0F0F0F);
  static const Color _bgSurface = Color(0xFF1A1A1A);
  static const Color _bgElevated = Color(0xFF252525);
  static const Color _accentColor = Color(0xFF00E5FF);
  static const Color _accentSecondary = Color(0xFF2979FF);
  static const Color _textLight = Color(0xFFFFFFFF);
  static const Color _textSub = Color(0xFF8A8A8A);
  static const Color _textMuted = Color(0xFF555555);
  static const Color _border = Color(0x1FFFFFFF);
  static const Color _borderAccent = Color(0x33FFFFFF);
  static const Color _shadowColor = Color(0x80000000);
  static const Color _activeGreen = Color(0xFF00E676);
  static const Color _inactiveRed = Color(0xFFFF1744);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _videoController = VideoPlayerController.asset('assets/videos/bug.mp4')
      ..initialize().then((_) {
        setState(() {});
        _videoController.setLooping(true);
        _videoController.setVolume(1.0);
        _videoController.play();
      }).catchError((e) {
        debugPrint("Video init error: $e");
      });

    if (widget.listBug.isNotEmpty) {
      final initialBugs = _getFilteredBugs();
      if (initialBugs.isNotEmpty) {
        selectedBugId = initialBugs[0]['bug_id'];
      }
    }

    _fetchSenderStats();
  }

  List<Map<String, dynamic>> _getFilteredBugs() {
    if (_selectedBugMode == "group") {
      return widget.listBug.where((b) => b['bug_id'].contains('_group')).toList();
    } else {
      return widget.listBug.where((b) => !b['bug_id'].contains('_group')).toList();
    }
  }

  Future<void> _fetchSenderStats() async {
    try {
      final res = await http.get(Uri.parse(
          "$baseUrl/getSenderStats?key=${widget.sessionKey}"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          setState(() {
            _privateSenderCount = data['private'] ?? 0;
            _globalSenderCount = data['global'] ?? 0;
            _isPrivateActive = data['private_active'] ?? true;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching sender stats: $e");
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _videoController.dispose();
    targetController.dispose();
    super.dispose();
  }

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+') || cleaned.length < 8) return null;
    return cleaned;
  }

  bool isValidGroupLink(String input) {
    return input.contains('chat.whatsapp.com') && input.contains('https://');
  }

  Future<void> _sendBug() async {
    final rawInput = targetController.text.trim();
    final key = widget.sessionKey;

    if (_selectedBugMode == "number") {
      final target = formatPhoneNumber(rawInput);
      if (target == null || key.isEmpty) {
        _showAlert("Invalid Number", "Gunakan nomor internasional (misal: +62, 1, 44), bukan 08xxx.");
        return;
      }
    } else {
      if (!isValidGroupLink(rawInput)) {
        _showAlert("Invalid Link", "Masukkan link group WA yang valid (contoh: https://chat.whatsapp.com/...).");
        return;
      }
    }

    final currentBugs = _getFilteredBugs();
    if (!currentBugs.any((b) => b['bug_id'] == selectedBugId)) {
      if (currentBugs.isNotEmpty) {
        setState(() { selectedBugId = currentBugs[0]['bug_id']; });
      } else {
        _showAlert("Error", "Tidak ada bug tersedia untuk mode ini.");
        return;
      }
    }

    setState(() { _isSending = true; });

    final effectiveSenderMode = (widget.role == 'owner' || widget.role == 'vip') ? _senderMode : 'private';

    try {
      final res = await http.get(Uri.parse(
          "$baseUrl/sendBug?key=$key&target=$rawInput&bug=$selectedBugId&senderMode=$effectiveSenderMode"));
      final data = jsonDecode(res.body);

      if (data["cooldown"] == true) {
        _showAlert("⏳ Cooldown", "Tunggu beberapa saat sebelum mengirim lagi.");
      } else if (data["valid"] == false) {
        _showAlert("❌ Key Invalid", "Sesi Anda tidak valid. Silakan login ulang.");
      } else if (data["sended"] == false) {
        _showAlert("⚠️ Gagal", "Server sedang maintenance atau terjadi kegagalan.");
      } else {
        _showAlert("✅ Berhasil", "Bug sukses dikirim ke target!");
        targetController.clear();
        _fetchSenderStats();
      }
    } catch (_) {
      _showAlert("❌ Error", "Terjadi kesalahan pada sistem. Coba lagi nanti.");
    } finally {
      setState(() { _isSending = false; });
    }
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: _borderAccent, width: 1),
        ),
        title: Text(title, style: const TextStyle(color: _textLight, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(msg, style: const TextStyle(color: _textSub, fontSize: 14)),
        actions: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [_accentColor, _accentSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: _bgDeep, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================
  Widget _glassContainer({required Widget child, double borderRadius = 20, Color? borderColor, double borderWidth = 0.8}) {
    return Container(
      decoration: BoxDecoration(
        color: _bgSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? _border, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _subtleDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, _border, Colors.transparent],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: _textSub, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _cornerAccent({required Alignment alignment}) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: alignment == Alignment.topLeft ? Radius.circular(20) : Radius.zero,
            topRight: alignment == Alignment.topRight ? Radius.circular(20) : Radius.zero,
            bottomLeft: alignment == Alignment.bottomLeft ? Radius.circular(20) : Radius.zero,
            bottomRight: alignment == Alignment.bottomRight ? Radius.circular(20) : Radius.zero,
          ),
          border: Border(
            top: alignment == Alignment.topLeft || alignment == Alignment.topRight ? BorderSide(color: _accentColor.withValues(alpha: 0.12), width: 1) : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight ? BorderSide(color: _accentColor.withValues(alpha: 0.12), width: 1) : BorderSide.none,
            left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? BorderSide(color: _accentColor.withValues(alpha: 0.12), width: 1) : BorderSide.none,
            right: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? BorderSide(color: _accentColor.withValues(alpha: 0.12), width: 1) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _microDot({Color? color}) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: color ?? _accentColor.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
    );
  }

  // ==================== POPUP SENDER SELECTION ====================
  void _showSenderSelectionPopup() {
    if (widget.role != 'owner' && widget.role != 'vip') {
      _showAlert("Akses Terbatas", "Mode pengirim global hanya untuk Owner/VIP.");
      return;
    }
    setState(() { _showSenderPopup = true; });
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBottomSheet) {
          return Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 30, offset: const Offset(0, -10)),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _textMuted, borderRadius: BorderRadius.circular(4)))),
                const SizedBox(height: 16),
                const Center(child: Text("PILIH SENDER", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textLight, letterSpacing: 2))),
                const SizedBox(height: 20),
                _subtleDivider(),
                const SizedBox(height: 12),
                _buildSenderOption(
                  context: context,
                  setStateBS: setStateBottomSheet,
                  mode: "private",
                  icon: Icons.lock_outline,
                  title: "PRIVATE",
                  isActive: _isPrivateActive,
                  count: _privateSenderCount,
                ),
                const SizedBox(height: 10),
                _buildSenderOption(
                  context: context,
                  setStateBS: setStateBottomSheet,
                  mode: "global",
                  icon: Icons.public,
                  title: "GLOBAL",
                  isActive: _globalSenderCount > 0,
                  count: _globalSenderCount,
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSenderOption({required BuildContext context, required StateSetter setStateBS, required String mode, required IconData icon, required String title, required bool isActive, required int count}) {
    final selected = _senderMode == mode;
    return GestureDetector(
      onTap: () {
        setStateBS(() { _senderMode = mode; _showSenderPopup = false; });
        setState(() {});
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? _bgElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _accentColor.withValues(alpha: 0.6) : _border, width: selected ? 1.5 : 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: (isActive ? _activeGreen : _inactiveRed).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: isActive ? _activeGreen : _inactiveRed, size: 18),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textLight)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: isActive ? _activeGreen : _inactiveRed, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text("${isActive ? 'Active' : 'Inactive'} • $count Sender", style: TextStyle(fontSize: 12, color: (isActive ? _activeGreen : _inactiveRed).withValues(alpha: 0.8))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (selected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: _accentColor, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== POPUP TARGET SELECTION ====================
  void _showTargetSelectionPopup() {
    setState(() { _showTargetPopup = true; });
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBottomSheet) {
          return Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 30, offset: const Offset(0, -10)),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _textMuted, borderRadius: BorderRadius.circular(4)))),
                const SizedBox(height: 16),
                const Center(child: Text("PILIH TARGET", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textLight, letterSpacing: 2))),
                const SizedBox(height: 20),
                _subtleDivider(),
                const SizedBox(height: 12),
                _buildTargetOption(
                  context: context,
                  setStateBS: setStateBottomSheet,
                  mode: "number",
                  icon: Icons.person_rounded,
                  title: "BUG NOMOR",
                  desc: "Kirim bug ke nomor personal",
                ),
                const SizedBox(height: 10),
                _buildTargetOption(
                  context: context,
                  setStateBS: setStateBottomSheet,
                  mode: "group",
                  icon: Icons.group_rounded,
                  title: "BUG GROUP",
                  desc: "Kirim bug ke link grup",
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTargetOption({required BuildContext context, required StateSetter setStateBS, required String mode, required IconData icon, required String title, required String desc}) {
    final selected = _selectedBugMode == mode;
    return GestureDetector(
      onTap: () {
        setStateBS(() {
          _selectedBugMode = mode;
          _showTargetPopup = false;
          targetController.clear();
          final newBugs = _getFilteredBugs();
          if (newBugs.isNotEmpty) selectedBugId = newBugs[0]['bug_id'];
        });
        setState(() {});
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? _bgElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _accentColor.withValues(alpha: 0.6) : _border, width: selected ? 1.5 : 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: _accentColor, size: 18),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textLight)),
                    const SizedBox(height: 3),
                    Text(desc, style: const TextStyle(fontSize: 12, color: _textMuted)),
                  ],
                ),
              ],
            ),
            if (selected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: _accentColor, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== WIDGET: STATISTIK ====================
  Widget _buildStatsWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: _bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 0.6),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(widget.listBug.length.toString(), "Total Bugs", Icons.bug_report_outlined),
          Container(width: 1, height: 32, color: _border),
          _buildStatItem("GACOR", "Success Rate", Icons.trending_up_rounded),
          Container(width: 1, height: 32, color: _border),
          _buildStatItem("ACTIVE", "Status", Icons.radio_button_checked_rounded),
        ],
      ),
    );
  }

  Widget _buildStatItem(String mainText, String subtitle, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: _accentColor, size: 18),
        ),
        const SizedBox(height: 7),
        Text(mainText, style: const TextStyle(color: _textLight, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: _textMuted, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      ],
    );
  }

  // ==================== WIDGET: TOP APP BAR ====================
  Widget _buildTopAppBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_accentColor, _accentSecondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: _accentColor.withValues(alpha: 0.25), blurRadius: 12, spreadRadius: 1),
              ],
            ),
            child: const Text("Xantra'X Execution", style: TextStyle(color: _bgDeep, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 2.0)),
          ),
        ],
      ),
    );
  }

  // ==================== WIDGET: HEADER CARD (ROMBAK TOTAL) ====================
  Widget _buildTopHeader() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_bgElevated, _bgSurface]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border, width: 0.6),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              // Animated ring avatar
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, _) {
                  final glowVal = (_glowController.value * 2 * 3.14159) % (2 * 3.14159);
                  return Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          _accentColor.withValues(alpha: 0.0),
                          _accentColor.withValues(alpha: 0.3 + 0.15 * (_glowController.value)),
                          _accentColor.withValues(alpha: 0.0),
                        ],
                        transform: GradientRotation(glowVal),
                        startAngle: 0,
                        endAngle: 2 * 3.14159,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _bgSurface,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_accentColor.withValues(alpha: 0.12), _accentColor.withValues(alpha: 0.04)]),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bug_report_rounded, color: _accentColor, size: 22),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("WHATSAPP CRASH", style: TextStyle(color: _textLight, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _microDot(color: _activeGreen.withValues(alpha: 0.6)),
                        const SizedBox(width: 6),
                        const Text("Advanced Payload Injection", style: TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Inline detail chips
                    Row(
                      children: [
                        _buildMiniChip(Icons.shield_outlined, widget.role.toUpperCase(), _accentColor.withValues(alpha: 0.5)),
                        const SizedBox(width: 8),
                        _buildMiniChip(Icons.timer_outlined, widget.expiredDate, _textMuted),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Corner accents
        _cornerAccent(alignment: Alignment.topLeft),
        _cornerAccent(alignment: Alignment.topRight),
        _cornerAccent(alignment: Alignment.bottomLeft),
        _cornerAccent(alignment: Alignment.bottomRight),
        // Subtle scan line
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, _) {
                final pos = _glowController.value;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: 1,
                      child: Container(
                        margin: EdgeInsets.only(top: pos * 200),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              _accentColor.withValues(alpha: 0.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        ],
      ),
    );
  }

  // ==================== WIDGET: VIDEO BOX (ROMBAK TOTAL) ====================
  Widget _buildVideoBox() {
    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border, width: 0.8),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 28, offset: const Offset(0, 10)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: _videoController.value.isInitialized
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController.value.size.width,
                          height: _videoController.value.size.height,
                          child: VideoPlayer(_videoController),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator(color: _accentColor, strokeWidth: 2)),
              ),
              // Multi-layer vignette
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                        stops: const [0.0, 0.15, 0.75, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              // Side vignettes
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Subtle noise texture overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.white.withValues(alpha: 0.01),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Top-left live badge
        Positioned(
          top: 10,
          left: 10,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55 + _pulseController.value * 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _inactiveRed.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _inactiveRed,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: _inactiveRed.withValues(alpha: 0.5), blurRadius: 5)],
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  ],
                ),
              );
            },
          ),
        ),
        // Top-right frame counter deco
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.high_quality_outlined, color: _accentColor.withValues(alpha: 0.5), size: 12),
                const SizedBox(width: 4),
                const Text("HD", style: TextStyle(color: _textMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
        // Bottom-left timecode deco
        Positioned(
          bottom: 10,
          left: 10,
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, _) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _microDot(color: _accentColor.withValues(alpha: 0.5)),
                    const SizedBox(width: 5),
                    Text(
                      "REC ${_glowController.value.toStringAsFixed(2)}s",
                      style: TextStyle(color: _textMuted.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Corner brackets on video
        Positioned(top: 6, left: 6, child: _videoCorner(top: true, left: true)),
        Positioned(top: 6, right: 6, child: _videoCorner(top: true, left: false)),
        Positioned(bottom: 6, left: 6, child: _videoCorner(top: false, left: true)),
        Positioned(bottom: 6, right: 6, child: _videoCorner(top: false, left: false)),
      ],
    );
  }

  Widget _videoCorner({required bool top, required bool left}) {
    final w = 18.0;
    final h = 18.0;
    final color = _accentColor.withValues(alpha: 0.2);
    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(
        painter: _CornerPainter(color: color, topLeft: top && left, topRight: top && !left, bottomLeft: !top && left, bottomRight: !top && !left),
      ),
    );
  }

  // ==================== WIDGET: SELECTOR CARDS (ROMBAK) ====================
  Widget _buildTargetTypeSelector() {
    return InkWell(
      onTap: _showTargetSelectionPopup,
      borderRadius: BorderRadius.circular(20),
      splashColor: _accentColor.withValues(alpha: 0.03),
      child: _glassContainer(
        borderRadius: 20,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accentColor.withValues(alpha: 0.1), width: 0.5),
                    ),
                    child: Icon(_selectedBugMode == "number" ? Icons.phone_android_rounded : Icons.group_rounded, color: _accentColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("TARGET TYPE", style: TextStyle(color: _textMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(_selectedBugMode == "number" ? "BUG NOMOR" : "BUG GROUP", style: const TextStyle(color: _textLight, fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _accentColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _accentColor.withValues(alpha: 0.15), width: 0.5),
                              ),
                              child: Text(_selectedBugMode == "number" ? "Personal" : "Group", style: TextStyle(color: _accentColor.withValues(alpha: 0.7), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(9), border: Border.all(color: _border, width: 0.5)),
                    child: const Icon(Icons.unfold_more_rounded, color: _textMuted, size: 16),
                  ),
                ],
              ),
            ),
            _cornerAccent(alignment: Alignment.topLeft),
            _cornerAccent(alignment: Alignment.bottomRight),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderModeSelector() {
    final isActive = _senderMode == "private" ? _isPrivateActive : _globalSenderCount > 0;
    final count = _senderMode == "private" ? _privateSenderCount : _globalSenderCount;
    final statusColor = isActive ? _activeGreen : _inactiveRed;

    return InkWell(
      onTap: _showSenderSelectionPopup,
      borderRadius: BorderRadius.circular(20),
      splashColor: _accentColor.withValues(alpha: 0.03),
      child: _glassContainer(
        borderRadius: 20,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.12), width: 0.5),
                    ),
                    child: Icon(_senderMode == "private" ? Icons.lock_outline_rounded : Icons.public_rounded, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text("SENDER MODE", style: TextStyle(color: _textMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 0.5),
                              ),
                              child: Text(isActive ? "Active" : "Inactive", style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(_senderMode == "private" ? "PRIVATE SENDER" : "GLOBAL SENDER", style: const TextStyle(color: _textLight, fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _microDot(color: statusColor.withValues(alpha: 0.5)),
                            const SizedBox(width: 5),
                            Text("$count Sender Active", style: TextStyle(color: statusColor.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(9), border: Border.all(color: _border, width: 0.5)),
                    child: const Icon(Icons.unfold_more_rounded, color: _textMuted, size: 16),
                  ),
                ],
              ),
            ),
            _cornerAccent(alignment: Alignment.topLeft),
            _cornerAccent(alignment: Alignment.bottomRight),
          ],
        ),
      ),
    );
  }

  // ==================== WIDGET: INPUT PANEL (ROMBAK) ====================
  Widget _buildInputPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(_selectedBugMode == "number" ? "TARGET NUMBER" : "WHATSAPP GROUP LINK"),
        Container(
          decoration: BoxDecoration(
            color: _bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border, width: 0.8),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 5)),
            ],
          ),
          child: Stack(
            children: [
              TextField(
                controller: targetController,
                style: const TextStyle(color: _textLight, fontSize: 14, fontWeight: FontWeight.w500),
                cursorColor: _accentColor,
                keyboardType: _selectedBugMode == "number" ? TextInputType.phone : TextInputType.url,
                decoration: InputDecoration(
                  hintText: _selectedBugMode == "number" ? "e.g. +628xxxxxxxx" : "e.g. https://chat.whatsapp.com/...",
                  hintStyle: const TextStyle(color: _textMuted, fontSize: 13, fontWeight: FontWeight.w400),
                  border: InputBorder.none,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Icon(_selectedBugMode == "number" ? Icons.phone_android_rounded : Icons.link_rounded, color: _textMuted, size: 18),
                  ),
                  suffixIcon: targetController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () => setState(() => targetController.clear()),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(Icons.close_rounded, color: _textMuted.withValues(alpha: 0.5), size: 16),
                          ),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
              _cornerAccent(alignment: Alignment.topLeft),
              _cornerAccent(alignment: Alignment.bottomRight),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Input format hint
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: _textMuted.withValues(alpha: 0.4), size: 11),
              const SizedBox(width: 4),
              Text(
                _selectedBugMode == "number" ? "Format: +[kode negara][nomor]" : "Paste link grup WhatsApp yang valid",
                style: TextStyle(color: _textMuted.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== WIDGET: PAYLOAD DROPDOWN (ROMBAK) ====================
  Widget _buildPayloadDropdown() {
    final availableBugs = _getFilteredBugs();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("SELECT PAYLOAD BUG"),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: _bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border, width: 0.8),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 5)),
            ],
          ),
          child: Stack(
            children: [
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: _bgCard,
                  value: selectedBugId.isNotEmpty ? selectedBugId : null,
                  isExpanded: true,
                  icon: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border, width: 0.5)),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: _textMuted, size: 18),
                  ),
                  style: const TextStyle(color: _textLight, fontSize: 13, fontWeight: FontWeight.w600),
                  items: availableBugs.map((bug) {
                    return DropdownMenuItem<String>(
                      value: bug['bug_id'],
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(color: _accentColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _accentColor.withValues(alpha: 0.3), blurRadius: 3)]),
                          ),
                          const SizedBox(width: 10),
                          Text(bug['bug_name']),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() { selectedBugId = value ?? ""; });
                  },
                ),
              ),
              _cornerAccent(alignment: Alignment.topLeft),
              _cornerAccent(alignment: Alignment.bottomRight),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            children: [
              Icon(Icons.layers_outlined, color: _textMuted.withValues(alpha: 0.4), size: 11),
              const SizedBox(width: 4),
              Text("${availableBugs.length} payload tersedia untuk mode ini", style: TextStyle(color: _textMuted.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== WIDGET: LAUNCH BUTTON (ROMBAK TOTAL) ====================
  Widget _buildLaunchButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withValues(alpha: 0.05 + _pulseController.value * 0.05),
                blurRadius: 24 + _pulseController.value * 8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendBug,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _bgElevated,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                    side: BorderSide(color: _accentColor.withValues(alpha: 0.25), width: 1),
                    disabledBackgroundColor: _bgElevated,
                  ),
                  child: _isSending
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: _accentColor, strokeWidth: 2, strokeCap: StrokeCap.round)),
                            const SizedBox(width: 10),
                            const Text("PROCESSING...", style: TextStyle(color: _textSub, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 2)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _accentColor.withValues(alpha: 0.2), width: 0.5),
                              ),
                              child: const Icon(Icons.send_rounded, color: _accentColor, size: 16),
                            ),
                            const SizedBox(width: 10),
                            const Text("LAUNCH ATTACK", style: TextStyle(color: _textLight, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 2.5)),
                          ],
                        ),
                ),
              ),
              _cornerAccent(alignment: Alignment.topLeft),
              _cornerAccent(alignment: Alignment.topRight),
              _cornerAccent(alignment: Alignment.bottomLeft),
              _cornerAccent(alignment: Alignment.bottomRight),
            ],
          ),
        );
      },
    );
  }

  // ==================== WIDGET: FOOTER INFO (ROMBAK) ====================
  Widget _buildFooterInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _bgSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 0.4),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(7)),
            child: Icon(Icons.key_rounded, color: _accentColor.withValues(alpha: 0.4), size: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Session: ${widget.expiredDate}  •  P($_privateSenderCount)  G($_globalSenderCount)",
              style: const TextStyle(color: _textMuted, fontSize: 9, fontWeight: FontWeight.w500, letterSpacing: 0.3),
            ),
          ),
          // Uptime indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _activeGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _activeGreen.withValues(alpha: 0.15), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 4, height: 4, decoration: BoxDecoration(color: _activeGreen, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _activeGreen.withValues(alpha: 0.4), blurRadius: 3)])),
                const SizedBox(width: 4),
                const Text("ONLINE", style: TextStyle(color: _activeGreen, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MAIN BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              _buildTopAppBar(),
              const SizedBox(height: 14),
              _buildTopHeader(),
              const SizedBox(height: 16),
              _buildVideoBox(),
              const SizedBox(height: 16),
              _buildStatsWidget(),
              const SizedBox(height: 16),
              _buildTargetTypeSelector(),
              const SizedBox(height: 10),
              _buildSenderModeSelector(),
              const SizedBox(height: 16),
              _buildInputPanel(),
              const SizedBox(height: 16),
              _buildPayloadDropdown(),
              const SizedBox(height: 20),
              _buildLaunchButton(),
              const SizedBox(height: 16),
              _buildFooterInfo(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== CUSTOM PAINTER: Corner Brackets ====================
class _CornerPainter extends CustomPainter {
  final Color color;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  _CornerPainter({required this.color, required this.topLeft, required this.topRight, required this.bottomLeft, required this.bottomRight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 10.0;

    if (topLeft) {
      canvas.drawLine(const Offset(0, len), const Offset(0, 0), paint);
      canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);
    }
    if (topRight) {
      canvas.drawLine(Offset(size.width - len, 0), Offset(size.width, 0), paint);
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);
    }
    if (bottomLeft) {
      canvas.drawLine(Offset(0, size.height - len), Offset(0, size.height), paint);
      canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    }
    if (bottomRight) {
      canvas.drawLine(Offset(size.width - len, size.height), Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(size.width, size.height - len), Offset(size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => false;
}
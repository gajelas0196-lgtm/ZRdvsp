import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
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

// Warna tambahan
const Color _danger = Color(0xFFFF5C7A);
const Color _dangerSoft = Color(0xFFFF9BB0);
const Color _success = Color(0xFF2EE6A6);
const Color _successSoft = Color(0xFF8FF5D3);
// =================================================

class BugSenderPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;

  const BugSenderPage({
    super.key,
    required this.sessionKey,
    required this.username,
    required this.role,
  });

  @override
  State<BugSenderPage> createState() => _BugSenderPageState();
}

class _BugSenderPageState extends State<BugSenderPage>
    with TickerProviderStateMixin {
  List<dynamic> senderList = [];
  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _listSlideController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.15, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _listSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fetchSenders();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _listSlideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchSenders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
            "$baseUrl/mySender?key=${widget.sessionKey}"),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["valid"] == true) {
          if (mounted) {
            setState(() {
              senderList = data["connections"] ?? [];
            });
            _listSlideController.forward(from: 0);
          }
        } else {
          if (mounted) {
            setState(() => errorMessage = data["message"] ?? "Failed to fetch");
          }
        }
      } else {
        if (mounted) {
          setState(() => errorMessage = "Server error: ${response.statusCode}");
        }
      }
    } catch (e) {
      if (mounted) setState(() => errorMessage = "Connection failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshSenders() async {
    setState(() => isRefreshing = true);
    await _fetchSenders();
  }

  void _showAddSenderDialog() {
    final phoneController = TextEditingController();
    final focusNode = FocusNode();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) {
        final scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(
              parent: ModalRoute.of(context)!.animation!,
              curve: Curves.easeOutCubic),
        );
        return ScaleTransition(
          scale: scaleAnim,
          child: AlertDialog(
            backgroundColor: _bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: _borderAccent),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                    boxShadow: [
                      BoxShadow(
                        color: _shadowColor,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(Icons.add_link_rounded,
                      color: _accentColor, size: 22),
                ),
                const SizedBox(width: 14),
                const SizedBox(height: 18),
                const Text(
                  "New Sender",
                  style: TextStyle(
                    color: _textLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Masukkan nomor WhatsApp target yang ingin dihubungkan sebagai Sender Node.",
                  style: TextStyle(
                      color: _textMuted, fontSize: 13, height: 1.65),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _bgSurface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                    boxShadow: [
                      BoxShadow(
                        color: _shadowColor,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: phoneController,
                    focusNode: focusNode,
                    keyboardType: TextInputType.phone,
                    cursorColor: _accentColor,
                    style: const TextStyle(
                      color: _textLight,
                      fontSize: 15,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      labelStyle:
                          TextStyle(color: _textMuted, fontSize: 11, letterSpacing: 0.5),
                      hintText: "628xxx...",
                      hintStyle:
                          TextStyle(color: _textMuted.withOpacity(0.4), fontSize: 14, letterSpacing: 0.5),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _bgSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _border),
                        ),
                        child: Icon(Icons.phone_android,
                            color: _accentColor, size: 16),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: _textMuted.withOpacity(0.5), size: 13),
                      const SizedBox(width: 6),
                      Text(
                        "Gunakan format kode negara tanpa +",
                        style: TextStyle(color: _textMuted.withOpacity(0.5), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _bgSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Batal",
                          style: TextStyle(
                            color: _textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_accentColor, _accentSecondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _accentColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            final number = phoneController.text.trim();
                            if (number.isEmpty) {
                              Navigator.pop(context);
                              _showSnackBar(
                                  "Number cannot be empty",
                                  isError: true);
                              return;
                            }
                            Navigator.pop(context);
                            await _addSender(number);
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bolt_rounded,
                                  color: _bgDeep, size: 16),
                              SizedBox(width: 6),
                              Text(
                                "Generate Pairing",
                                style: TextStyle(
                                  color: _bgDeep,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addSender(String number) async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(
          "$baseUrl/getPairing?key=${widget.sessionKey}&number=$number"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["valid"] == true) {
          _showPairingCodeDialog(number, data['pairingCode']);
          _showSnackBar("Pairing sequence generated!", isError: false);
        } else {
          _showSnackBar(data['message'] ?? "Pairing failed", isError: true);
        }
      } else {
        _showSnackBar("Server Error: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      _showSnackBar("Connection Fault: $e", isError: true);
    } finally {
      setState(() => isLoading = false);
      _fetchSenders();
    }
  }

  void _showPairingCodeDialog(String number, String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.82),
      builder: (context) {
        final scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
          CurvedAnimation(
              parent: ModalRoute.of(context)!.animation!,
              curve: Curves.easeOutBack),
        );
        return ScaleTransition(
          scale: scaleAnim,
          child: AlertDialog(
            backgroundColor: _bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: _borderAccent),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _bgSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: _border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _shadowColor,
                        blurRadius: 30,
                        spreadRadius: -2,
                      ),
                      BoxShadow(
                        color: _success.withOpacity(0.04),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(Icons.qr_code_scanner_rounded,
                      color: _accentColor, size: 38),
                ),
                const SizedBox(height: 22),
                const Text(
                  "Pairing Required",
                  style: TextStyle(
                    color: _textLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Masukkan kode ini ke perangkat target",
                  style: TextStyle(color: _textMuted, fontSize: 12, height: 1.5),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _bgSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_android_rounded,
                          color: _textMuted, size: 13),
                      const SizedBox(width: 8),
                      Text(
                        number,
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 11,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  decoration: BoxDecoration(
                    color: _bgSurface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _borderAccent, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _shadowColor,
                        blurRadius: 32,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          code.length,
                          (i) => Padding(
                            padding: EdgeInsets.only(
                                right: i < code.length - 1 ? 10 : 0),
                            child: Container(
                              width: 38,
                              height: 52,
                              decoration: BoxDecoration(
                                color: _bgSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _borderAccent),
                                boxShadow: [
                                  BoxShadow(
                                    color: _shadowColor,
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                code[i],
                                style: const TextStyle(
                                  color: _textLight,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _bgSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _borderAccent),
                    boxShadow: [
                      BoxShadow(
                        color: _shadowColor,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: code));
                        _showSnackBar(
                            "Sequence copied to clipboard!", isError: false);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.copy_all_rounded,
                              color: _accentColor, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            "Copy to Clipboard",
                            style: TextStyle(
                              color: _accentColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accentColor, _accentSecondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _fetchSenders();
                  },
                  child: const Text(
                    "Close & Refresh",
                    style: TextStyle(
                      color: _bgDeep,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteSender(String senderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.82),
      builder: (context) {
        final scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(
              parent: ModalRoute.of(context)!.animation!,
              curve: Curves.easeOutCubic),
        );
        return ScaleTransition(
          scale: scaleAnim,
          child: AlertDialog(
            backgroundColor: _bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: _danger.withOpacity(0.12)),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _danger.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: _danger.withOpacity(0.06),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(Icons.warning_amber_rounded,
                      color: _danger, size: 22),
                ),
                const SizedBox(width: 14),
                const Text(
                  "Hapus Node",
                  style: TextStyle(
                    color: _textLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Apakah Anda yakin ingin menghapus Sender Node ini selamanya?",
                  style: TextStyle(
                      color: _textMuted, fontSize: 13, height: 1.65),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _danger.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: _danger.withOpacity(0.6), size: 14),
                      const SizedBox(width: 8),
                      Text(
                        "Proses ini tidak dapat dibatalkan",
                        style: TextStyle(
                          color: _danger.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _bgSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          "Batal",
                          style: TextStyle(
                            color: _textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_danger, _dangerSoft],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _danger.withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.pop(context, true),
                          child: const Center(
                            child: Text(
                              "Hapus",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      setState(() => isLoading = true);
      try {
        final response = await http.delete(Uri.parse(
            "$baseUrl/deleteSender?key=${widget.sessionKey}&id=$senderId"));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data["valid"] == true) {
            _showSnackBar("Node berhasil dihapus.", isError: false);
            _fetchSenders();
          } else {
            _showSnackBar(
                data["message"] ?? "Failed to purge node", isError: true);
          }
        } else {
          _showSnackBar("Server error: ${response.statusCode}", isError: true);
        }
      } catch (e) {
        _showSnackBar("Connection failed: $e", isError: true);
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isError
                    ? _danger.withOpacity(0.12)
                    : _success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: isError ? _danger : _success,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError ? _danger : _success,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: isError
                  ? _danger.withOpacity(0.12)
                  : _success.withOpacity(0.12)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  Widget _buildSenderCard(Map<String, dynamic> sender, int index) {
    final name = sender['sessionName'] ?? 'WhatsApp Sender';
    final idStr = sender['id']?.toString() ?? '';
    final shortId = idStr.length >= 8 ? idStr.substring(0, 8) : idStr;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _listSlideController,
        curve: Interval(
          (index * 0.08).clamp(0.0, 0.6),
          1.0,
          curve: Curves.easeOutCubic,
        ),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _listSlideController,
          curve: Interval(
            (index * 0.08).clamp(0.0, 0.6),
            1.0,
            curve: Curves.easeOut,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: _shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _borderAccent),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _borderAccent.withOpacity(0.3),
                              _border.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _bgSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _border),
                          ),
                          child: Icon(Icons.hub_outlined,
                              color: _accentColor, size: 21),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.toUpperCase(),
                              style: const TextStyle(
                                color: _textLight,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _bgSurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _border),
                              ),
                              child: Text(
                                "ID: $shortId",
                                style: TextStyle(
                                  color: _textMuted,
                                  fontSize: 10,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: _success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _success.withOpacity(0.12)),
                          boxShadow: [
                            BoxShadow(
                              color: _success.withOpacity(0.05),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: _success,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _success.withOpacity(
                                            _pulseAnimation.value),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 7),
                            Text(
                              "Online",
                              style: TextStyle(
                                color: _success,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        _border.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            splashColor:
                                _textLight.withOpacity(0.03),
                            highlightColor:
                                _textLight.withOpacity(0.02),
                            onTap: () => _refreshSenders(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.sync_rounded,
                                      size: 14, color: _textMuted),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Sync",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: _textMuted,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          color: _border),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            splashColor:
                                _danger.withOpacity(0.03),
                            highlightColor:
                                _danger.withOpacity(0.02),
                            onTap: () => _deleteSender(sender['id']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_outline_rounded,
                                      size: 14, color: _danger),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Hapus",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: _danger,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeController,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _border.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: _shadowColor,
                      blurRadius: 40,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _bgSurface,
                    border: Border.all(color: _border),
                    boxShadow: [
                      BoxShadow(
                        color: _shadowColor,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _bgCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: _borderAccent),
                    ),
                    child: Icon(Icons.router_outlined,
                        color: _accentColor, size: 28),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              const Text(
                "Belum Ada Node",
                style: TextStyle(
                  color: _textLight,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Sistem tidak mendeteksi koneksi pengirim.\nTambahkan WhatsApp node pertama Anda.",
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 13,
                  height: 1.75,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accentColor, _accentSecondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _showAddSenderDialog,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_link_rounded,
                            color: _bgDeep, size: 20),
                        SizedBox(width: 10),
                        Text(
                          "Tambah Sender",
                          style: TextStyle(
                            color: _bgDeep,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: -0.3,
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
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _danger.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: _danger.withOpacity(0.12)),
                boxShadow: [
                  BoxShadow(
                    color: _danger.withOpacity(0.06),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(Icons.wifi_off_rounded,
                  color: _danger, size: 38),
            ),
            const SizedBox(height: 32),
            const Text(
              "Koneksi Gagal",
              style: TextStyle(
                color: _textLight,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? "Unknown connection error occurred",
              style: TextStyle(
                color: _textMuted,
                fontSize: 13,
                height: 1.65,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_accentColor, _accentSecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _fetchSenders,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh_rounded,
                          color: _bgDeep, size: 18),
                      SizedBox(width: 10),
                      Text(
                        "Coba Lagi",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _bgDeep,
                          fontSize: 14,
                          letterSpacing: -0.3,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      body: FadeTransition(
        opacity: _fadeController,
        child: SafeArea(
          child: Column(
            children: [
              // === HEADER ===
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: BoxDecoration(
                  color: _bgCard.withOpacity(0.85),
                  border: Border(
                    bottom: BorderSide(color: _border, width: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _shadowColor,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _bgSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border),
                        boxShadow: [
                          BoxShadow(
                            color: _shadowColor,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: _textSub, size: 14),
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Sender Nodes",
                            style: TextStyle(
                              color: _textLight,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: _textMuted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Kelola perangkat pengirim",
                                style: TextStyle(
                                  color: _textMuted,
                                  fontSize: 11,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _bgSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border),
                        boxShadow: [
                          BoxShadow(
                            color: _shadowColor,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.sync_rounded,
                          color: isLoading ? _textMuted.withOpacity(0.3) : _accentColor,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: isLoading ? null : _refreshSenders,
                      ),
                    ),
                  ],
                ),
              ),

              // === STATS BAR ===
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _bgCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _border),
                          boxShadow: [
                            BoxShadow(
                              color: _shadowColor,
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: _bgSurface,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(color: _border),
                              ),
                              child: Icon(Icons.devices_rounded,
                                  color: _accentColor, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${senderList.length}",
                                  style: const TextStyle(
                                    color: _textLight,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  "Node Aktif",
                                  style: TextStyle(
                                    color: _textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _bgCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _border),
                          boxShadow: [
                            BoxShadow(
                              color: _shadowColor,
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: _bgSurface,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(color: _border),
                              ),
                              child: Icon(Icons.shield_outlined,
                                  color: _accentColor, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.role.toUpperCase(),
                                    style: const TextStyle(
                                      color: _textLight,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    "Akses Level",
                                    style: TextStyle(
                                      color: _textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
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

              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _border.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              if (senderList.isNotEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                  child: Row(
                    children: [
                      Text(
                        "TERHUBUNG",
                        style: TextStyle(
                          color: _textMuted.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: _border.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "${senderList.length} UNIT",
                        style: TextStyle(
                          color: _textMuted.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

              // === CONTENT ===
              Expanded(
                child: isLoading && senderList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _bgSurface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _border),
                              ),
                              child: CircularProgressIndicator(
                                color: _accentColor,
                                strokeWidth: 2.5,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              "Memuat data...",
                              style: TextStyle(
                                color: _textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      )
                    : errorMessage != null && senderList.isEmpty
                        ? _buildErrorState()
                        : senderList.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                color: _accentColor,
                                backgroundColor: _bgCard,
                                onRefresh: _refreshSenders,
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(
                                      top: 6, bottom: 100),
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: senderList.length,
                                  itemBuilder: (context, index) =>
                                      _buildSenderCard(
                                          Map<String, dynamic>.from(
                                              senderList[index]),
                                          index),
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: senderList.isNotEmpty
          ? Container(
              height: 54,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_accentColor, _accentSecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: _showAddSenderDialog,
                backgroundColor: Colors.transparent,
                elevation: 0,
                highlightElevation: 0,
                icon: const Icon(Icons.add_rounded,
                    color: _bgDeep, size: 20),
                label: const Text(
                  "Tambah Node",
                  style: TextStyle(
                    color: _bgDeep,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
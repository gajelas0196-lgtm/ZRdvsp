import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

// Warna tambahan untuk status/aksi
const Color _danger = Color(0xFFFF5C7A);
const Color _dangerSoft = Color(0xFFFF9BB0);
const Color _success = Color(0xFF2EE6A6);
const Color _successSoft = Color(0xFF8FF5D3);
// =================================================

class AdminPage extends StatefulWidget {
  final String sessionKey;

  const AdminPage({super.key, required this.sessionKey});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with TickerProviderStateMixin {
  late String sessionKey;
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];

  final List<String> roleOptions = ['developer','moderator','admin','owner','reseller', 'member'];
  String selectedRole = 'member';

  int currentPage = 1;
  int itemsPerPage = 25;

  final deleteController = TextEditingController();
  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  String newUserRole = 'member';
  bool isLoading = false;

  // ===== Controller animasi (khusus lapisan visual, tidak mengubah logika) =====
  late final AnimationController _entranceCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _headerFade = CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic)));

    _fetchUsers();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _glowCtrl.dispose();
    _shimmerCtrl.dispose();
    deleteController.dispose();
    createUsernameController.dispose();
    createPasswordController.dispose();
    createDayController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/listUsers?key=$sessionKey'),
      );
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['authorized'] == true) {
        fullUserList = data['users'] ?? [];
        _filterAndPaginate();
      } else {
        _alert(
          "⚠️ Error",
          data['message'] ?? 'Tidak diizinkan melihat daftar user.',
        );
      }
    } catch (_) {
      _alert("🌐 Error", "Gagal memuat user list.");
    }
    setState(() => isLoading = false);
  }

  void _filterAndPaginate() {
    setState(() {
      currentPage = 1;
      filteredList = fullUserList
          .where((u) => u['role'] == selectedRole)
          .toList();
    });
  }

  List<dynamic> _getCurrentPageData() {
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage);
    return filteredList.sublist(
      start,
      end > filteredList.length ? filteredList.length : end,
    );
  }

  int get totalPages => (filteredList.length / itemsPerPage).ceil();

  Future<void> _deleteUser() async {
    final username = deleteController.text.trim();
    if (username.isEmpty) {
      _alert("⚠️ Error", "Masukkan username yang ingin dihapus.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(
          '$baseUrl/deleteUser?key=$sessionKey&username=$username',
        ),
      );
      final data = jsonDecode(res.body);
      if (data['deleted'] == true) {
        _alert(
          "✅ Berhasil",
          "User '${data['user']['username']}' telah dihapus.",
        );
        deleteController.clear();
        _fetchUsers();
      } else {
        _alert("❌ Gagal", data['message'] ?? 'Gagal menghapus user.');
      }
    } catch (_) {
      _alert("🌐 Error", "Tidak dapat menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  Future<void> _createAccount() async {
    final username = createUsernameController.text.trim();
    final password = createPasswordController.text.trim();
    final day = createDayController.text.trim();

    if (username.isEmpty || password.isEmpty || day.isEmpty) {
      _alert("⚠️ Error", "Semua field wajib diisi.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
        '$baseUrl/userAdd?key=$sessionKey&username=$username&password=$password&day=$day&role=$newUserRole',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['created'] == true) {
        _alert(
          "✅ Sukses",
          "Akun '${data['user']['username']}' berhasil dibuat.",
        );
        createUsernameController.clear();
        createPasswordController.clear();
        createDayController.clear();
        newUserRole = 'member';
        _fetchUsers();
      } else {
        _alert("❌ Gagal", data['message'] ?? 'Gagal membuat akun.');
      }
    } catch (_) {
      _alert("🌐 Error", "Gagal menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  // ================= UI HELPERS (VISUAL LAYER ONLY) =================

  void _alert(String title, String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1.0),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                decoration: BoxDecoration(
                  color: _bgCard.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _borderAccent, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: _shadowColor,
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: _accentColor.withOpacity(0.08),
                      blurRadius: 50,
                      spreadRadius: -6,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_accentColor, _accentSecondary]),
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: [
                              BoxShadow(color: _accentColor.withOpacity(0.35), blurRadius: 16, spreadRadius: 1),
                            ],
                          ),
                          child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: _textLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 49),
                      child: Container(height: 2, width: 32, decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_accentColor, Colors.transparent]),
                        borderRadius: BorderRadius.circular(2),
                      )),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(color: _textSub, fontSize: 13, height: 1.65),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_accentColor, _accentSecondary]),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(color: _accentColor.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(13),
                            onTap: () => Navigator.pop(context),
                            child: const Center(
                              child: Text(
                                "MENGERTI",
                                style: TextStyle(
                                  color: _bgDeep,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  letterSpacing: 1.4,
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _bgSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        cursorColor: _accentColor,
        style: const TextStyle(color: _textLight, fontSize: 14, letterSpacing: 0.2),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 4, right: 4),
            child: Icon(icon, color: _accentColor.withOpacity(0.7), size: 17),
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _sectionHeaderIcon(IconData icon) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (context, child) {
        final glow = 0.15 + (_glowCtrl.value * 0.20);
        return Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: _bgSurface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(color: _accentColor.withOpacity(glow), blurRadius: 16, spreadRadius: 0.5),
            ],
          ),
          child: Icon(icon, color: _accentColor, size: 18),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    int animIndex = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 650 + (animIndex * 140)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 22),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _shadowColor,
              blurRadius: 34,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _bgCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _border, width: 1),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _bgCard,
                    Color.lerp(_bgCard, _bgSurface, 0.35)!,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _sectionHeaderIcon(icon),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: _textLight,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: _textMuted,
                                fontSize: 11,
                                letterSpacing: 0.4,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          _border,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required VoidCallback? onPressed,
    required String text,
    required IconData icon,
    bool isDestructive = false,
  }) {
    final Color btnColor = isDestructive ? _danger : _accentColor;
    final Color btnColor2 = isDestructive ? _dangerSoft : _accentSecondary;
    final Color textColor = isDestructive ? Colors.white : _bgDeep;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [btnColor, btnColor2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: btnColor.withOpacity(0.32),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          splashColor: Colors.white.withOpacity(0.15),
          highlightColor: Colors.white.withOpacity(0.08),
          child: Center(
            child: isLoading && !isDestructive
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _bgDeep,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: textColor),
                      const SizedBox(width: 10),
                      Text(
                        text,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserItem(Map user, int index) {
    final bool isReseller = user['role'] == 'reseller';
    final Color roleColor = isReseller ? _accentColor : _accentSecondary;

    return TweenAnimationBuilder<double>(
      key: ValueKey('user_${user['username']}_$index'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 420 + (index * 45).clamp(0, 500)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset((1 - value) * 18, 0), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _bgSurface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border, width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [roleColor.withOpacity(0.22), roleColor.withOpacity(0.06)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: roleColor.withOpacity(0.35), width: 1.2),
                boxShadow: [
                  BoxShadow(color: roleColor.withOpacity(0.15), blurRadius: 10, spreadRadius: 0.5),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                user['username'].toString().substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['username'],
                    style: const TextStyle(
                      color: _textLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: roleColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(color: roleColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              user['role'].toString().toUpperCase(),
                              style: TextStyle(
                                color: roleColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.schedule_rounded, size: 11, color: _textMuted.withOpacity(0.7)),
                      const SizedBox(width: 3),
                      Text(
                        "${user['expiredDate']}",
                        style: const TextStyle(color: _textMuted, fontSize: 11, letterSpacing: 0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.account_tree_outlined, size: 11, color: _textMuted.withOpacity(0.4)),
                      const SizedBox(width: 4),
                      Text(
                        "${user['parent'] ?? 'SYSTEM'}",
                        style: TextStyle(color: _textMuted.withOpacity(0.55), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: _danger.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: _danger.withOpacity(0.3), width: 1),
              ),
              child: IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: _danger, size: 18),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    barrierColor: Colors.black.withOpacity(0.65),
                    builder: (_) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: _bgCard.withOpacity(0.94),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: _danger.withOpacity(0.32), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: _shadowColor,
                                  blurRadius: 36,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: _danger.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(11),
                                        border: Border.all(color: _danger.withOpacity(0.32)),
                                      ),
                                      child: Icon(Icons.warning_amber_rounded, color: _danger, size: 19),
                                    ),
                                    const SizedBox(width: 13),
                                    const Text(
                                      "Konfirmasi",
                                      style: TextStyle(
                                        color: _textLight,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Yakin ingin menghapus user '${user['username']}'?",
                                  style: const TextStyle(color: _textSub, fontSize: 14, height: 1.5),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: _bgSurface.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: _border),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(12),
                                            onTap: () => Navigator.pop(context, false),
                                            child: const Center(
                                              child: Text(
                                                "Batal",
                                                style: TextStyle(color: _textSub, fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        height: 46,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [_danger, _dangerSoft]),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _danger.withOpacity(0.32),
                                              blurRadius: 14,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(12),
                                            onTap: () => Navigator.pop(context, true),
                                            child: const Center(
                                              child: Text(
                                                "Hapus",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
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
                          ),
                        ),
                      ),
                    ),
                  );

                  if (confirm == true) {
                    deleteController.text = user['username'];
                    _deleteUser();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(totalPages, (index) {
        final page = index + 1;
        final bool isActive = currentPage == page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(colors: [_accentColor, _accentSecondary])
                : null,
            color: isActive ? null : _bgSurface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: isActive ? Colors.transparent : _border,
              width: 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.32),
                      blurRadius: 12,
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => currentPage = page),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(
                  "$page",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? _bgDeep : _textMuted,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _bgSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: _bgCard,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _accentColor, size: 20),
          style: const TextStyle(
            color: _textLight,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          items: items.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text(role.toUpperCase()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _bgSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color.withOpacity(0.85), size: 14),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: _textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      body: Stack(
        children: [
          // Lapisan latar belakang bertekstur halus (dekoratif murni, tidak mencolok)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _glowCtrl,
                builder: (context, _) => CustomPaint(
                  painter: _SubtleGridPainter(pulse: _glowCtrl.value),
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -100,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _glowCtrl,
                builder: (context, _) => Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _accentColor.withOpacity(0.05 + _glowCtrl.value * 0.02),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -110,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _accentSecondary.withOpacity(0.045),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _glowCtrl,
                            builder: (context, child) {
                              final glow = 0.10 + (_glowCtrl.value * 0.12);
                              return Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_accentColor.withOpacity(0.12), _accentSecondary.withOpacity(0.05)],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _accentColor.withOpacity(0.22), width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _shadowColor,
                                      blurRadius: 22,
                                      offset: const Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: _accentColor.withOpacity(glow),
                                      blurRadius: 34,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: child,
                              );
                            },
                            child: const Icon(
                              Icons.admin_panel_settings_outlined,
                              color: _accentColor,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [_textLight, _accentColor],
                            ).createShader(bounds),
                            child: const Text(
                              "ADMIN DASHBOARD",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _textLight,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _accentColor.withOpacity(0.22)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield_outlined, size: 11, color: _accentColor.withOpacity(0.9)),
                                const SizedBox(width: 6),
                                Text(
                                  "FULL ACCESS CONTROL",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // SECTION 1: DELETE USER
                  _buildSectionCard(
                    title: "DELETE USER",
                    subtitle: "Hapus akun secara permanen dari sistem",
                    icon: FontAwesomeIcons.userSlash,
                    animIndex: 0,
                    children: [
                      _buildInput(
                        label: "USERNAME TARGET",
                        controller: deleteController,
                        icon: FontAwesomeIcons.user,
                      ),
                      _buildActionBtn(
                        onPressed: isLoading ? null : _deleteUser,
                        text: "DELETE ACCOUNT",
                        icon: Icons.delete_forever_outlined,
                        isDestructive: true,
                      ),
                    ],
                  ),

                  // SECTION 2: CREATE ACCOUNT
                  _buildSectionCard(
                    title: "CREATE ACCOUNT",
                    subtitle: "Buat akun baru member atau reseller",
                    icon: FontAwesomeIcons.userPlus,
                    animIndex: 1,
                    children: [
                      _buildInput(
                        label: "USERNAME",
                        controller: createUsernameController,
                        icon: FontAwesomeIcons.user,
                      ),
                      _buildInput(
                        label: "PASSWORD",
                        controller: createPasswordController,
                        icon: FontAwesomeIcons.lock,
                      ),
                      _buildInput(
                        label: "DURASI (HARI)",
                        controller: createDayController,
                        icon: FontAwesomeIcons.calendarDay,
                        type: TextInputType.number,
                      ),
                      _buildDropdown(
                        value: newUserRole,
                        items: roleOptions,
                        onChanged: (val) => setState(() => newUserRole = val ?? 'member'),
                      ),
                      const SizedBox(height: 16),
                      _buildActionBtn(
                        onPressed: isLoading ? null : _createAccount,
                        text: isLoading ? "PROCESSING..." : "CREATE ACCOUNT",
                        icon: isLoading ? Icons.hourglass_empty_outlined : Icons.add_circle_outline,
                      ),
                    ],
                  ),

                  // SECTION 3: USER LIST
                  _buildSectionCard(
                    title: "USER MANAGEMENT",
                    subtitle: "Lihat dan kelola seluruh daftar pengguna aktif",
                    icon: FontAwesomeIcons.users,
                    animIndex: 2,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              value: selectedRole,
                              items: roleOptions,
                              onChanged: (val) {
                                if (val != null) {
                                  selectedRole = val;
                                  _filterAndPaginate();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildStatChip(Icons.people_alt_outlined, "${filteredList.length}", _accentColor),
                        ],
                      ),
                      const SizedBox(height: 16),
                      isLoading
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: AnimatedBuilder(
                                  animation: _shimmerCtrl,
                                  builder: (context, child) => SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: _accentColor,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                if (_getCurrentPageData().isEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 34),
                                    alignment: Alignment.center,
                                    child: Column(
                                      children: [
                                        Icon(Icons.inbox_outlined, color: _textMuted.withOpacity(0.5), size: 30),
                                        const SizedBox(height: 10),
                                        Text(
                                          "Tidak ada user pada kategori ini",
                                          style: TextStyle(color: _textMuted.withOpacity(0.7), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ..._getCurrentPageData()
                                      .asMap()
                                      .entries
                                      .map((e) => _buildUserItem(e.value, e.key))
                                      .toList(),
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: _bgSurface.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: _border),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildPagination(),
                                      const SizedBox(height: 10),
                                      Text(
                                        "Page $currentPage of $totalPages",
                                        style: const TextStyle(
                                          color: _textMuted,
                                          fontSize: 10,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                _border,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "VANTABLACK ADMIN",
                          style: TextStyle(
                            color: _textMuted.withOpacity(0.3),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter dekoratif: garis grid tipis yang berdenyut sangat halus, dipakai
// sebagai lapisan tekstur latar belakang agar tidak terlihat polos namun
// tetap tidak mencolok (opacity sangat rendah).
class _SubtleGridPainter extends CustomPainter {
  final double pulse;
  _SubtleGridPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = 0.015 + (pulse * 0.01);
    final paint = Paint()
      ..color = _accentColor.withOpacity(opacity)
      ..strokeWidth = 1;

    const step = 46.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SubtleGridPainter oldDelegate) => oldDelegate.pulse != pulse;
}

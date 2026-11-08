import 'dart:math' as math;
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

class PartnerPage extends StatefulWidget {
  final String sessionKey;
  final String username;

  const PartnerPage({
    super.key,
    required this.sessionKey,
    required this.username,
  });

  @override
  State<PartnerPage> createState() => _PartnerPageState();
}

class _PartnerPageState extends State<PartnerPage>
    with TickerProviderStateMixin {
  late String sessionKey;
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];

  // Role Options Partner: Admin, Reseller, VIP, Member
  final List<String> roleOptions = ['admin', 'reseller', 'vip', 'member'];
  String selectedRole = 'member';

  int currentPage = 1;
  int itemsPerPage = 25;

  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  final deleteController = TextEditingController();

  String newUserRole = 'member';
  bool isLoading = false;

  // --- Animation controllers (visual only) ---
  late final AnimationController _bgController;
  late final AnimationController _entryController;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _fetchUsers();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entryController.dispose();
    _glowController.dispose();
    createUsernameController.dispose();
    createPasswordController.dispose();
    createDayController.dispose();
    deleteController.dispose();
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
        _alert("Info", data['message'] ?? 'Gagal memuat user.');
      }
    } catch (_) {
      _alert("Error", "Gagal terhubung ke server.");
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
      _alert("Peringatan", "Masukkan username yang ingin dihapus.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/deleteUser?key=$sessionKey&username=$username'),
      );
      final data = jsonDecode(res.body);

      if (data['deleted'] == true) {
        _alert("Sukses", "User berhasil dihapus.");
        deleteController.clear();
        _fetchUsers();
      } else {
        _alert("Gagal", data['message'] ?? 'Gagal menghapus user.');
      }
    } catch (_) {
      _alert("Error", "Gagal menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  Future<void> _createAccount() async {
    final u = createUsernameController.text.trim();
    final p = createPasswordController.text.trim();
    final d = createDayController.text.trim();

    if (u.isEmpty || p.isEmpty || d.isEmpty) {
      _alert("Peringatan", "Semua field wajib diisi.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
        '$baseUrl/userAdd?key=$sessionKey&username=$u&password=$p&day=$d&role=$newUserRole',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['created'] == true) {
        _alert("Sukses", "Akun berhasil dibuat sebagai ${newUserRole.toUpperCase()}.");
        createUsernameController.clear();
        createPasswordController.clear();
        createDayController.clear();
        newUserRole = 'member';
        _fetchUsers();
      } else {
        _alert("Gagal", data['message'] ?? 'Gagal membuat akun.');
      }
    } catch (_) {
      _alert("Error", "Gagal menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  void _alert(String title, String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _borderAccent),
            boxShadow: [
              BoxShadow(
                color: _shadowColor,
                blurRadius: 30,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: _accentColor.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: -4,
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [_accentColor.withOpacity(0.2), _accentSecondary.withOpacity(0.1)],
                      ),
                      border: Border.all(
                        color: _accentColor.withOpacity(0.4),
                      ),
                    ),
                    child: Icon(Icons.info_outline, color: _accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: _textLight,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: _border),
              const SizedBox(height: 14),
              Text(
                message,
                style: const TextStyle(
                  color: _textSub,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_accentColor, _accentSecondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _accentColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(context),
                      child: Center(
                        child: const Text(
                          "OK",
                          style: TextStyle(
                            color: _bgDeep,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
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
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: _accentColor.withOpacity(0.55),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          keyboardType: type,
          cursorColor: _accentColor,
          style: const TextStyle(color: _textLight, fontSize: 15),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: _accentColor.withOpacity(0.7)),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _accentColor, size: 16),
            ),
            filled: true,
            fillColor: _bgSurface.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _accentColor.withOpacity(0.8), width: 1.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _bgSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: _accentColor.withOpacity(0.7)),
          dropdownColor: _bgCard,
          style: const TextStyle(
            color: _textLight,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          items: roleOptions.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Row(
                children: [
                  Icon(_roleIcon(role), size: 15, color: _accentColor.withOpacity(0.8)),
                  const SizedBox(width: 10),
                  Text(role.toUpperCase()),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return FontAwesomeIcons.crown;
      case 'reseller':
        return FontAwesomeIcons.store;
      case 'vip':
        return FontAwesomeIcons.gem;
      default:
        return FontAwesomeIcons.user;
    }
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    bool loading = false,
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
            color: btnColor.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 17, color: textColor),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    int index = 0,
  }) {
    final delay = (index * 0.15).clamp(0.0, 0.6);
    final animation = CurvedAnimation(
      parent: _entryController,
      curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = animation.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 30),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _shadowColor,
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _bgCard.withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (context, _) {
                      return Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _accentColor.withOpacity(_glowAnim.value * 0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _accentColor.withOpacity(_glowAnim.value * 0.18),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(icon, color: _accentColor, size: 19),
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: _textLight,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 11.5,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
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
              const SizedBox(height: 22),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserItem(Map user, int idx) {
    final role = (user['role'] ?? '').toString();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (idx * 40).clamp(0, 400)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset((1 - value) * 24, 0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _bgSurface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: _shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accentColor.withOpacity(0.3), _accentSecondary.withOpacity(0.1)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: _accentColor.withOpacity(0.25)),
              ),
              child: Icon(Icons.person, color: _accentColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['username'].toString(),
                    style: const TextStyle(
                      color: _textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _accentColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_roleIcon(role),
                                size: 10, color: _accentColor.withOpacity(0.8)),
                            const SizedBox(width: 4),
                            Text(
                              role.toUpperCase(),
                              style: TextStyle(
                                color: _accentColor.withOpacity(0.85),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.schedule, size: 11, color: _textMuted),
                      const SizedBox(width: 3),
                      Text(
                        "${user['expiredDate']}",
                        style: const TextStyle(
                          color: _textSub,
                          fontSize: 11.5,
                        ),
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
                border: Border.all(color: _danger.withOpacity(0.3)),
              ),
              child: IconButton(
                icon: Icon(Icons.delete_outline, color: _danger, size: 20),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    barrierColor: Colors.black.withOpacity(0.6),
                    builder: (_) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: _bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _danger.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: _shadowColor,
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: _danger),
                                const SizedBox(width: 10),
                                const Text("Konfirmasi",
                                    style: TextStyle(
                                        color: _textLight,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text("Hapus user ini?",
                                style: TextStyle(color: _textSub)),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: _bgSurface.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _border),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () => Navigator.pop(context, false),
                                        child: Center(
                                          child: const Text("Batal",
                                              style: TextStyle(color: _textSub)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [_danger, _dangerSoft],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () => Navigator.pop(context, true),
                                        child: const Center(
                                          child: Text("Hapus",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold)),
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
                  );
                  if (confirm == true) {
                    deleteController.text = user['username'].toString();
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
    if (totalPages <= 0) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: List.generate(totalPages, (index) {
        final page = index + 1;
        final active = currentPage == page;
        return GestureDetector(
          onTap: () => setState(() => currentPage = page),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: active
                  ? const LinearGradient(colors: [_accentColor, _accentSecondary])
                  : null,
              color: active ? null : _bgSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? Colors.transparent : _border,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: _accentColor.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ]
                  : [],
            ),
            child: Text(
              "$page",
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? _bgDeep : _textSub,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Icon(Icons.person_off_outlined, color: _textMuted, size: 38),
          const SizedBox(height: 10),
          Text(
            "Tidak ada user pada role ini",
            style: TextStyle(color: _textMuted, fontSize: 13),
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
          // Animated ambient background (grid + glow)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _AmbientBackgroundPainter(
                    progress: _bgController.value,
                    lineColor: _accentColor,
                    glowColor: _accentColor,
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _bgDeep,
                  _accentColor.withOpacity(0.06),
                  _bgDeep,
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header
                  AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (context, _) {
                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _accentColor.withOpacity(_glowAnim.value * 0.5),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _accentColor.withOpacity(_glowAnim.value * 0.2),
                              blurRadius: 22,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(Icons.handshake, color: _accentColor, size: 42),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [_textLight, _accentColor.withOpacity(0.7)],
                    ).createShader(bounds),
                    child: const Text(
                      "PARTNER DASHBOARD",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Kelola akun mitra dengan kendali penuh",
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 12.5,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 60,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, _accentColor, Colors.transparent],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 34),

                  // SECTION 1: DELETE USER
                  _buildGlassCard(
                    title: "DELETE USER",
                    subtitle: "Hapus akun mitra secara permanen",
                    icon: FontAwesomeIcons.userSlash,
                    index: 0,
                    children: [
                      _buildSectionLabel("USERNAME TARGET"),
                      _buildInput(
                        label: "Username Target",
                        controller: deleteController,
                        icon: FontAwesomeIcons.user,
                      ),
                      const SizedBox(height: 4),
                      _buildActionButton(
                        label: "DELETE ACCOUNT",
                        icon: Icons.delete_forever_rounded,
                        onTap: isLoading ? null : _deleteUser,
                        loading: isLoading,
                        isDestructive: true,
                      ),
                    ],
                  ),

                  // SECTION 2: CREATE ACCOUNT
                  _buildGlassCard(
                    title: "CREATE ACCOUNT",
                    subtitle: "Tambahkan akun baru beserta rolenya",
                    icon: FontAwesomeIcons.userPlus,
                    index: 1,
                    children: [
                      _buildSectionLabel("DATA AKUN"),
                      _buildInput(
                        label: "Username",
                        controller: createUsernameController,
                        icon: FontAwesomeIcons.user,
                      ),
                      _buildInput(
                        label: "Password",
                        controller: createPasswordController,
                        icon: FontAwesomeIcons.lock,
                      ),
                      _buildInput(
                        label: "Durasi (Hari)",
                        controller: createDayController,
                        icon: FontAwesomeIcons.calendarDay,
                        type: TextInputType.number,
                      ),
                      _buildSectionLabel("ROLE"),
                      _buildRoleDropdown(
                        value: newUserRole,
                        onChanged: (val) =>
                            setState(() => newUserRole = val ?? 'member'),
                      ),
                      const SizedBox(height: 20),
                      _buildActionButton(
                        label: "CREATE ACCOUNT",
                        icon: Icons.person_add_alt_1_rounded,
                        onTap: isLoading ? null : _createAccount,
                        loading: isLoading,
                      ),
                    ],
                  ),

                  // SECTION 3: USER LIST
                  _buildGlassCard(
                    title: "USER LIST",
                    subtitle: "Total ${filteredList.length} akun pada role terpilih",
                    icon: FontAwesomeIcons.users,
                    index: 2,
                    children: [
                      _buildSectionLabel("FILTER ROLE"),
                      _buildRoleDropdown(
                        value: selectedRole,
                        onChanged: (val) {
                          if (val != null) {
                            selectedRole = val;
                            _filterAndPaginate();
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      isLoading
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _accentColor,
                                ),
                              ),
                            )
                          : filteredList.isEmpty
                              ? _buildEmptyState()
                              : Column(
                                  children: [
                                    ..._getCurrentPageData()
                                        .asMap()
                                        .entries
                                        .map((e) => _buildUserItem(e.value, e.key))
                                        .toList(),
                                    const SizedBox(height: 16),
                                    _buildPagination(),
                                  ],
                                ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for a subtle animated grid + glow ambience.
class _AmbientBackgroundPainter extends CustomPainter {
  final double progress;
  final Color lineColor;
  final Color glowColor;

  _AmbientBackgroundPainter({
    required this.progress,
    required this.lineColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = lineColor.withOpacity(0.03)
      ..strokeWidth = 1;

    const spacing = 46.0;
    final offset = (progress * spacing) % spacing;

    for (double x = -spacing + offset; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = -spacing + offset; y < size.height + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withOpacity(0.12),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(
            size.width * (0.2 + 0.6 * (0.5 + 0.5 * math.sin(progress * 2 * math.pi))),
            size.height * 0.12,
          ),
          radius: size.width * 0.65,
        ),
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

    final glowPaint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withOpacity(0.05),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(
            size.width * (0.8 - 0.6 * (0.5 + 0.5 * math.cos(progress * 2 * math.pi))),
            size.height * 0.85,
          ),
          radius: size.width * 0.55,
        ),
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint2);
  }

  @override
  bool shouldRepaint(covariant _AmbientBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
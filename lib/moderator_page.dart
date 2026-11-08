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

// Warna tambahan
const Color _danger = Color(0xFFFF5C7A);
const Color _dangerSoft = Color(0xFFFF9BB0);
// =================================================

class ModeratorPage extends StatefulWidget {
  final String sessionKey;
  final String username;

  const ModeratorPage({
    super.key,
    required this.sessionKey,
    required this.username,
  });

  @override
  State<ModeratorPage> createState() => _ModeratorPageState();
}

class _ModeratorPageState extends State<ModeratorPage> {
  late String sessionKey;
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];

  final List<String> roleOptions = ['partner', 'admin', 'reseller', 'vip', 'member'];
  String selectedRole = 'member';

  int currentPage = 1;
  int itemsPerPage = 25;

  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  final deleteController = TextEditingController();

  String newUserRole = 'member';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    _fetchUsers();
  }

  @override
  void dispose() {
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

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'partner':
        return Icons.handshake_outlined;
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      case 'reseller':
        return Icons.storefront_outlined;
      case 'vip':
        return Icons.workspace_premium_outlined;
      default:
        return Icons.person_outline;
    }
  }

  void _alert(String title, String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _borderAccent),
            boxShadow: [
              BoxShadow(
                color: _shadowColor,
                blurRadius: 25,
                offset: const Offset(0, 10),
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
                      color: _accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: _accentColor.withOpacity(0.2)),
                    ),
                    child: Icon(Icons.info_outline, color: _accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: _textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
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
                style: const TextStyle(color: _textSub, fontSize: 14, height: 1.4),
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "MENGERTI",
                      style: TextStyle(
                        color: _bgDeep,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 13,
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

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: type,
        cursorColor: _accentColor,
        style: const TextStyle(color: _textLight, fontSize: 14.5, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _textMuted, fontSize: 13.5),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _accentColor, size: 16),
          ),
          filled: true,
          fillColor: _bgSurface.withOpacity(0.4),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
    );
  }

  Widget _buildRoleDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
    String? hint,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _bgSurface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(_roleIcon(value), color: _accentColor, size: 16),
          const SizedBox(width: 10),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(hint, style: const TextStyle(color: _textMuted, fontSize: 12)),
            ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: _bgCard,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: _accentColor),
                style: const TextStyle(
                  color: _textLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  letterSpacing: 0.6,
                ),
                items: roleOptions.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_roleIcon(role), size: 14, color: _textSub),
                        const SizedBox(width: 8),
                        Text(role.toUpperCase()),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({
    required String title,
    required IconData icon,
    String? subtitle,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _bgCard.withOpacity(0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _accentColor.withOpacity(0.2)),
                ),
                child: Icon(icon, color: _accentColor, size: 18),
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
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: _textMuted, fontSize: 11.5),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: _border),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
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
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
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
          onTap: onPressed,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: textColor,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 17, color: textColor),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
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

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: _bgSurface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            Icon(icon, color: _accentColor, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(color: _textLight, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textMuted, fontSize: 10.5, letterSpacing: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      decoration: BoxDecoration(
        color: _bgCard.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _border, width: 1.4),
                ),
              ),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_accentColor.withOpacity(0.2), _bgDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: _accentColor.withOpacity(0.3)),
                ),
                child: Icon(Icons.shield_moon_outlined, color: _accentColor, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [_textLight, _accentColor.withOpacity(0.7)],
            ).createShader(bounds),
            child: const Text(
              "MODERATOR DASHBOARD",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _bgSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_outlined, color: _accentColor, size: 13),
                const SizedBox(width: 6),
                Text(
                  "Masuk sebagai ${widget.username}",
                  style: const TextStyle(color: _textSub, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatChip("Total Akun", "${fullUserList.length}", Icons.groups_outlined),
              const SizedBox(width: 12),
              _buildStatChip("Role Aktif", selectedRole.toUpperCase(), _roleIcon(selectedRole)),
              const SizedBox(width: 12),
              _buildStatChip("Ditampilkan", "${filteredList.length}", Icons.filter_alt_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(Map user) {
    final username = (user['username'] ?? '-').toString();
    final role = (user['role'] ?? '-').toString();
    final expired = (user['expiredDate'] ?? '-').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _bgSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_accentColor.withOpacity(0.2), _bgDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: _accentColor.withOpacity(0.25)),
            ),
            child: Text(
              _initials(username),
              style: const TextStyle(color: _textLight, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textLight, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _accentColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_roleIcon(role), size: 11, color: _accentColor),
                          const SizedBox(width: 4),
                          Text(
                            role.toUpperCase(),
                            style: TextStyle(color: _accentColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule, size: 12, color: _textMuted),
                        const SizedBox(width: 4),
                        Text(
                          expired,
                          style: const TextStyle(color: _textSub, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _danger.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: _danger.withOpacity(0.3)),
            ),
            child: IconButton(
              tooltip: 'Hapus user',
              icon: Icon(Icons.delete_outline, color: _danger, size: 20),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.6),
                  builder: (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: _bgCard,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _danger.withOpacity(0.3)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: _danger),
                              const SizedBox(width: 10),
                              const Text(
                                "Konfirmasi Hapus",
                                style: TextStyle(color: _textLight, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            "Apakah kamu yakin ingin menghapus akun \"$username\"? Tindakan ini tidak dapat dibatalkan.",
                            style: const TextStyle(color: _textSub, fontSize: 13.5, height: 1.4),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: _bgSurface.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _border),
                                  ),
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text("Batal", style: TextStyle(color: _textSub)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [_danger, _dangerSoft],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text(
                                      "Hapus",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  deleteController.text = username;
                  _deleteUser();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, color: _textMuted, size: 40),
          const SizedBox(height: 12),
          Text(
            "Belum ada pengguna pada role ini",
            style: TextStyle(color: _textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    if (totalPages <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: currentPage > 1 ? () => setState(() => currentPage--) : null,
          icon: Icon(Icons.chevron_left, color: currentPage > 1 ? _accentColor : _textMuted.withOpacity(0.3)),
        ),
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: List.generate(totalPages, (index) {
              final page = index + 1;
              final active = currentPage == page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton(
                  onPressed: () => setState(() => currentPage = page),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: active ? _accentColor : Colors.transparent,
                    foregroundColor: active ? _bgDeep : _textSub,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: active ? Colors.transparent : _border),
                    ),
                  ),
                  child: Text(
                    "$page",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: active ? _bgDeep : _textSub,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        IconButton(
          onPressed: currentPage < totalPages ? () => setState(() => currentPage++) : null,
          icon: Icon(Icons.chevron_right, color: currentPage < totalPages ? _accentColor : _textMuted.withOpacity(0.3)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgDeep, _accentColor.withOpacity(0.06), _bgDeep],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 28),

                // SECTION 1: DELETE USER
                _buildGlassCard(
                  title: "DELETE USER",
                  icon: FontAwesomeIcons.userSlash,
                  subtitle: "Hapus akun pengguna berdasarkan username",
                  trailing: Icon(Icons.warning_amber_rounded, color: _textMuted, size: 18),
                  children: [
                    _buildInput(
                      label: "Username Target",
                      controller: deleteController,
                      icon: FontAwesomeIcons.user,
                    ),
                    const SizedBox(height: 4),
                    _buildActionButton(
                      label: "DELETE ACCOUNT",
                      icon: Icons.delete_forever_outlined,
                      onPressed: isLoading ? null : _deleteUser,
                      loading: false,
                      isDestructive: true,
                    ),
                  ],
                ),

                // SECTION 2: CREATE ACCOUNT
                _buildGlassCard(
                  title: "CREATE ACCOUNT",
                  icon: FontAwesomeIcons.userPlus,
                  subtitle: "Buat akun baru lengkap dengan role & durasi aktif",
                  trailing: Icon(_roleIcon(newUserRole), color: _textMuted, size: 18),
                  children: [
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
                    _buildRoleDropdown(
                      value: newUserRole,
                      hint: "Role",
                      onChanged: (val) => setState(() => newUserRole = val ?? 'member'),
                    ),
                    const SizedBox(height: 18),
                    _buildActionButton(
                      label: "CREATE ACCOUNT",
                      icon: Icons.person_add_alt_1_outlined,
                      onPressed: isLoading ? null : _createAccount,
                      loading: isLoading,
                    ),
                  ],
                ),

                // SECTION 3: USER LIST
                _buildGlassCard(
                  title: "USER LIST",
                  icon: FontAwesomeIcons.users,
                  subtitle: "Kelola seluruh akun berdasarkan role",
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _accentColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      "${filteredList.length}",
                      style: TextStyle(color: _accentColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  children: [
                    _buildRoleDropdown(
                      value: selectedRole,
                      hint: "Filter",
                      onChanged: (val) {
                        if (val != null) {
                          selectedRole = val;
                          _filterAndPaginate();
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    isLoading
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(color: _accentColor),
                            ),
                          )
                        : Column(
                            children: [
                              if (filteredList.isEmpty)
                                _buildEmptyState()
                              else
                                ..._getCurrentPageData().map((u) => _buildUserItem(u)).toList(),
                              const SizedBox(height: 8),
                              _buildPagination(),
                            ],
                          ),
                  ],
                ),

                const SizedBox(height: 8),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, color: _textMuted.withOpacity(0.4), size: 13),
                      const SizedBox(width: 6),
                      Text(
                        "Moderator Panel • Sesi Aktif",
                        style: TextStyle(color: _textMuted.withOpacity(0.4), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
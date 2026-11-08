import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TikTokBooster extends StatefulWidget {
  final String sessionKey;
  final String role;
  
  const TikTokBooster({
    super.key,
    required this.sessionKey,
    required this.role,
  });

  @override
  State<TikTokBooster> createState() => _TikTokBoosterState(); // ← FIXED
}

class _TikTokBoosterState extends State<TikTokBooster> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isValidating = true;
  bool _hasAccess = false;
  String _errorMessage = '';
  
  final List<Map<String, dynamic>> boosterMenus = [
    {
      'title': 'Suntik Pengikut',
      'subtitle': 'Tambah Followers TikTok',
      'icon': FontAwesomeIcons.userPlus,
      'color': 0xFF4CAF50,
      'url': 'https://zefoy.online/followers/',
    },
    {
      'title': 'Suntik Like',
      'subtitle': 'Tambah Likes Video',
      'icon': FontAwesomeIcons.heart,
      'color': 0xFFE91E63,
      'url': 'https://zefoy.online/likes/index.html',
    },
    {
      'title': 'Suntik Komen Like',
      'subtitle': 'Tambah likes komentar',
      'icon': FontAwesomeIcons.commentDots,
      'color': 0xFF2196F3,
      'url': 'https://zefoy.online/comments-likes/index.html',
    },
    {
      'title': 'Suntik Views',
      'subtitle': 'Tambah views video',
      'icon': FontAwesomeIcons.eye,
      'color': 0xFFFF9800,
      'url': 'https://zefoy.online/views/index.html',
    },
    {
      'title': 'Suntik Favorit',
      'subtitle': 'Tambah favorites',
      'icon': FontAwesomeIcons.star,
      'color': 0xFF9C27B0,
      'url': 'https://zefoy.online/favorites/index.html',
    },
  ];
  
  final List<String> allowedRoles = ['admin', 'partner', 'owner'];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
    _validateAccess();
  }
  
  Future<void> _validateAccess() async {
    setState(() => _isValidating = true);
    
    try {
      final response = await http.get(
        Uri.parse('http://projectsxteam.clouderz.my.id:2064/api/user/validate?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userRole = data['role']?.toString().toLowerCase() ?? widget.role.toLowerCase();
        setState(() {
          _hasAccess = allowedRoles.contains(userRole);
          _isValidating = false;
          if (!_hasAccess) _errorMessage = 'Akses Khusus untuk Role: ADMIN, PARTNER, OWNER';
        });
      } else {
        setState(() {
          _hasAccess = allowedRoles.contains(widget.role.toLowerCase());
          _isValidating = false;
          if (!_hasAccess) _errorMessage = 'Akses Khusus untuk Role: ADMIN, PARTNER, OWNER';
        });
      }
    } catch (e) {
      setState(() {
        _hasAccess = allowedRoles.contains(widget.role.toLowerCase());
        _isValidating = false;
        if (!_hasAccess) _errorMessage = 'Akses Khusus untuk Role: ADMIN, PARTNER, OWNER\n\nPeriksa koneksi internet Anda';
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0E27),
              const Color(0xFF1A1A4E),
              const Color(0xFF0F0F3A),
              const Color(0xFF1A1A5E),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _isValidating
                ? _buildLoadingState()
                : _hasAccess
                    ? _buildBoosterContent()
                    : _buildAccessDenied(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2196F3).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Verifikasi Akses...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Rangers • Tiktok Booster',
            style: TextStyle(
              color: Color(0xFF2196F3),
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAccessDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.red.shade800, Colors.red.shade900],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'AKSES DITOLAK',
              style: TextStyle(
                color: Colors.red.shade400,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A4E), Color(0xFF0A0E27)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RoleBadge(label: 'ADMIN', color: 0xFF2196F3),
                      SizedBox(width: 8),
                      RoleBadge(label: 'PARTNER', color: 0xFF9C27B0),
                      SizedBox(width: 8),
                      RoleBadge(label: 'OWNER', color: 0xFFE91E63),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBoosterContent() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          floating: true,
          pinned: true,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  '',
                  height: 30,
                  errorBuilder: (_, __, ___) => const Icon(Icons.flash_on, color: Color(0xFF2196F3), size: 24),
                ),
                const SizedBox(width: 8),
                const Text(
                  '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0A0E27),
                    const Color(0xFF1A1A4E),
                    const Color(0xFF2196F3).withOpacity(0.3),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          FontAwesomeIcons.tiktok,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Rangers Booster',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.role.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF2196F3),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1A1A4E).withOpacity(0.8), const Color(0xFF0A0E27).withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                InfoIcon(),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cara Penggunaan',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Klik menu booster, akan terbuka di Chrome, ikuti instruksi di web',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildBoosterCard(boosterMenus[index]),
              childCount: boosterMenus.length,
            ),
          ),
        ),
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Divider(color: const Color(0xFF2196F3).withOpacity(0.3)),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield, color: Color(0xFF2196F3), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Powered By Rangers',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBoosterCard(Map<String, dynamic> menu) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final Uri uri = Uri.parse(menu['url']);
          final bool berhasil = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!berhasil && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tidak bisa membuka link')),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1A4E),
                const Color(0xFF0A0E27),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(menu['color']).withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(menu['color']).withOpacity(0.2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(menu['color']).withOpacity(0.1),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(menu['color']),
                            Color(menu['color']).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        menu['icon'],
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      menu['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      menu['subtitle'],
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget tambahan
class RoleBadge extends StatelessWidget {
  final String label;
  final int color;
  
  const RoleBadge({super.key, required this.label, required this.color});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(color).withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Color(color).withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: Color(color), fontSize: 10),
      ),
    );
  }
}

class InfoIcon extends StatelessWidget {
  const InfoIcon({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF00BCD4)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.info, color: Colors.white),
    );
  }
}
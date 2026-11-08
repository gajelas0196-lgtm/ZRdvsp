import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ComicPage extends StatefulWidget {
  const ComicPage({super.key});

  @override
  State<ComicPage> createState() => _ComicPageState();
}

class _ComicPageState extends State<ComicPage> {
  // ── ICE BLUE THEME (seperti di foto) ──
  final Color bgDark        = const Color(0xFF0A1929);      // Background biru gelap
  final Color primaryBlue   = const Color(0xFF0288D1);      // Biru utama
  final Color accentBlue    = const Color(0xFF4FC3F7);      // Biru aksen terang
  final Color lightBlue     = const Color(0xFF81D4FA);      // Biru lebih terang
  final Color darkBlue      = const Color(0xFF01579B);      // Biru gelap
  final Color textLight     = const Color(0xFFE1F5FE);      // Teks biru sangat terang
  final Color textGrey      = const Color(0xFFB0BEC5);      // Teks abu-abu kebiruan
  final Color cardDark      = const Color(0x1A0288D1);      // Card dengan transparansi biru
  final Color borderBlue    = const Color(0x334FC3F7);      // Border biru transparan
  final Color glowBlue      = const Color(0xFF4FC3F7);      // Efek glow biru
  
  // Gradient Biru
  final LinearGradient blueGradient = const LinearGradient(
    colors: [Color(0xFF0288D1), Color(0xFF4FC3F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Controller pencarian
  final TextEditingController _searchController = TextEditingController();
  
  // Data List
  List<dynamic> _comicList = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _headingText = "Hot Comic";

  @override
  void initState() {
    super.initState();
    _fetchTopManga();
  }

  // --- API FUNCTIONS (Jikan API V4) ---
  
  Future<void> _fetchTopManga() async {
    setState(() { _isLoading = true; _isSearching = false; _headingText = "Hot Comic"; });
    try {
      final response = await http.get(Uri.parse('https://api.jikan.moe/v4/top/manga?limit=20'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _comicList = data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching manga: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchManga(String query) async {
    if (query.isEmpty) return;
    setState(() { _isLoading = true; _isSearching = true; _headingText = "Search Result"; });
    try {
      final response = await http.get(Uri.parse('https://api.jikan.moe/v4/manga?q=$query&limit=20'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _comicList = data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error searching manga: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (Rect bounds) {
            return blueGradient.createShader(bounds);
          },
          child: const Text(
            "COMIC ZONE",
            style: TextStyle(
              fontFamily: "Orbitron", 
              fontWeight: FontWeight.bold, 
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient Ice Blue
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgDark, darkBlue, Colors.black],
              ),
            ),
          ),
          
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100),

                // 1. HEADER CARD (Comic Area)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryBlue.withOpacity(0.15),
                        darkBlue.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: accentBlue.withOpacity(0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.3), 
                        blurRadius: 20, 
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(FontAwesomeIcons.bookOpenReader, color: glowBlue, size: 40),
                      const SizedBox(height: 12),
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return blueGradient.createShader(bounds);
                        },
                        child: Text(
                          "Comic Zone", 
                          style: TextStyle(
                            color: textLight, 
                            fontSize: 24, 
                            fontFamily: "Orbitron", 
                            fontWeight: FontWeight.bold,
                            shadows: [BoxShadow(color: glowBlue, blurRadius: 15)],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Read & Find Your Favorite Manga", 
                        style: TextStyle(color: textGrey, fontFamily: "ShareTechMono", fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // 2. SEARCH BAR
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderBlue),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontFamily: "ShareTechMono"),
                    decoration: InputDecoration(
                      hintText: "Search Manga / Comic...",
                      hintStyle: TextStyle(color: textGrey),
                      prefixIcon: Icon(Icons.search, color: accentBlue),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.send, color: accentBlue, size: 20),
                        onPressed: () => _searchManga(_searchController.text),
                      ),
                    ),
                    onSubmitted: (value) => _searchManga(value),
                  ),
                ),

                const SizedBox(height: 20),

                // 3. RECOMMENDATION CHIPS
                Text(
                  "Recommendation Search:", 
                  style: TextStyle(color: textGrey, fontSize: 11, fontFamily: "Orbitron", fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildRecChip("One Piece"),
                      _buildRecChip("Naruto"),
                      _buildRecChip("Solo Leveling"),
                      _buildRecChip("Berserk"),
                      _buildRecChip("Chainsaw Man"),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 4. TITLE SECTION (Hot Comic / Result)
                Row(
                  children: [
                    Container(
                      height: 24, 
                      width: 5,
                      decoration: BoxDecoration(
                        gradient: blueGradient,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [BoxShadow(color: glowBlue, blurRadius: 8)],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _headingText, 
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 20, 
                        fontFamily: "Orbitron", 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if(_isSearching)
                      GestureDetector(
                        onTap: _fetchTopManga,
                        child: Text("Reset", style: TextStyle(color: accentBlue, fontSize: 12, fontWeight: FontWeight.w500)),
                      )
                  ],
                ),

                const SizedBox(height: 15),

                // 5. GRID LIST COMIC
                _isLoading 
                  ? Container(
                      height: 300, 
                      alignment: Alignment.center, 
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: accentBlue, strokeWidth: 3),
                          const SizedBox(height: 16),
                          Text("Loading Comics...", style: TextStyle(color: textGrey)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: _comicList.length,
                      itemBuilder: (context, index) {
                        final manga = _comicList[index];
                        return _buildComicCard(manga);
                      },
                    ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildRecChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: InkWell(
        onTap: () {
          _searchController.text = text;
          _searchManga(text);
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue.withOpacity(0.2), darkBlue.withOpacity(0.3)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accentBlue.withOpacity(0.3)),
          ),
          child: Text(
            text, 
            style: TextStyle(color: textLight, fontSize: 12, fontFamily: "ShareTechMono", fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  Widget _buildComicCard(dynamic manga) {
    String imageUrl = manga['images']['jpg']['image_url'] ?? '';
    String title = manga['title'] ?? 'Unknown';
    String score = manga['score'] != null ? manga['score'].toString() : 'N/A';
    String type = manga['type'] ?? 'Manga';

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ComicDetailPage(mangaData: manga)));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.03),
            ],
          ),
          border: Border.all(color: borderBlue, width: 1),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.1), 
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: darkBlue.withOpacity(0.5),
                        child: Icon(Icons.broken_image, color: textGrey, size: 40),
                      ),
                    ),
                    // Badge Score
                    Positioned(
                      top: 8, 
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: accentBlue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              score, 
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Badge Type
                    Positioned(
                      top: 8, 
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: blueGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          type, 
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info Bawah
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis, 
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 13, 
                      fontWeight: FontWeight.bold, 
                      fontFamily: "Orbitron",
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.touch_app, color: accentBlue, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        "Tap to read", 
                        style: TextStyle(color: textGrey, fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- HALAMAN DETAIL KOMIK ---
class ComicDetailPage extends StatelessWidget {
  final Map<String, dynamic> mangaData;

  // Ice Blue Theme colors
  final Color primaryBlue = const Color(0xFF0288D1);
  final Color accentBlue = const Color(0xFF4FC3F7);
  final Color darkBlue = const Color(0xFF01579B);
  final Color bgDark = const Color(0xFF0A1929);
  
  final LinearGradient blueGradient = const LinearGradient(
    colors: [Color(0xFF0288D1), Color(0xFF4FC3F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  const ComicDetailPage({super.key, required this.mangaData});

  @override
  Widget build(BuildContext context) {
    String imageUrl = mangaData['images']['jpg']['large_image_url'] ?? mangaData['images']['jpg']['image_url'];
    String title = mangaData['title'] ?? 'Unknown';
    String synopsis = mangaData['synopsis'] ?? 'No synopsis available.';
    String status = mangaData['status'] ?? 'Unknown';
    String chapters = mangaData['chapters'] != null ? mangaData['chapters'].toString() : '?';
    String url = mangaData['url'] ?? '';

    return Scaffold(
      backgroundColor: bgDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar dengan Gambar Background Besar
          SliverAppBar(
            expandedHeight: 400.0,
            floating: false,
            pinned: true,
            backgroundColor: bgDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(imageUrl, fit: BoxFit.cover),
                  // Gradient Ice Blue agar teks terbaca
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, 
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, bgDark.withOpacity(0.9), bgDark],
                        stops: const [0.4, 0.7, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: accentBlue.withOpacity(0.3)),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          // Konten Detail
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul dengan gradient
                  ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return blueGradient.createShader(bounds);
                    },
                    child: Text(
                      title, 
                      style: const TextStyle(
                        fontFamily: "Orbitron", 
                        fontSize: 24, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Info Bar (Status, Chapter, Score)
                  Row(
                    children: [
                      _buildInfoBadge(Icons.timelapse, status, primaryBlue),
                      const SizedBox(width: 12),
                      _buildInfoBadge(Icons.book, "$chapters Ch", accentBlue),
                      const SizedBox(width: 12),
                      _buildInfoBadge(Icons.star, "${mangaData['score'] ?? 'N/A'}", Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Divider Biru
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: blueGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Synopsis Header
                  Row(
                    children: [
                      Icon(Icons.description, color: primaryBlue, size: 20),
                      const SizedBox(width: 10),
                      const Text(
                        "Story / Synopsis", 
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 18, 
                          fontFamily: "Orbitron", 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Synopsis Text
                  Text(
                    synopsis,
                    style: const TextStyle(
                      color: Colors.white70, 
                      fontSize: 14, 
                      height: 1.6, 
                      fontFamily: "ShareTechMono",
                    ),
                    textAlign: TextAlign.justify,
                  ),

                  const SizedBox(height: 40),

                  // Tombol Action (Buka Browser)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: blueGradient,
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Could not launch url")),
                            );
                          }
                        },
                        icon: const Icon(Icons.open_in_browser, color: Colors.white, size: 22),
                        label: const Text(
                          "Read More & Details on Web", 
                          style: TextStyle(
                            color: Colors.white, 
                            fontFamily: "Orbitron", 
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            text, 
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
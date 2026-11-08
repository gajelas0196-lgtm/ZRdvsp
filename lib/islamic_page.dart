import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class IslamicPage extends StatefulWidget {
  const IslamicPage({super.key});

  @override
  State<IslamicPage> createState() => _IslamicPageState();
}

class _IslamicPageState extends State<IslamicPage> with TickerProviderStateMixin {
  // === COLOR PALETTE ===
  static const Color bgVoid       = Color(0xFF060608);
  static const Color bgCard       = Color(0xFF0E0F14);
  static const Color bgCardAlt    = Color(0xFF12131A);
  static const Color accentRed    = Color(0xFFE63946);
  static const Color accentAmber  = Color(0xFFFFB703);
  static const Color accentGold   = Color(0xFFD4A017);
  static const Color accentGreen  = Color(0xFF2DC653);
  static const Color accentBlue   = Color(0xFF3A86FF);
  static const Color borderDim    = Color(0xFF1E1F2B);
  static const Color textPrimary  = Color(0xFFEEEEF0);
  static const Color textMuted    = Color(0xFF6B6D7E);
  static const Color textFaint    = Color(0xFF3A3C4E);

  // Real-Time Clock
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  // Prayer times
  Map<String, String> prayerTimes = {
    "Fajr": "04:30",
    "Dhuhr": "12:00",
    "Asr": "15:15",
    "Maghrib": "18:00",
    "Isha": "19:15",
  };
  bool isLoadingPrayer = true;
  String currentPrayer = "Fajr";
  String nextPrayer = "Dhuhr";
  bool isPrayerTimeNow = false;

  // Quotes
  final List<Map<String, String>> quotes = [
    {"arab": "مَنْ جَدَّ وَجَدَ", "text": "Barangsiapa bersungguh-sungguh, pasti ia akan berhasil."},
    {"arab": "الصَّبْرُ يُعِيْنُ عَلَى كُلِّ عَمَلٍ", "text": "Kesabaran itu menolong segala pekerjaan."},
    {"arab": "خَيْرُ النَّاسِ أَنْفَعُهُمْ لِلنَّاسِ", "text": "Sebaik-baik manusia adalah yang paling bermanfaat bagi orang lain."},
    {"arab": "الوَقْتُ كَالسَّيْفِ إِنْ لَمْ تَقْطَعْهُ قَطَعَكَ", "text": "Waktu itu seperti pedang. Jika kau tidak memotongnya, ia akan memotongmu."},
    {"arab": "العِلْمُ بِلَا عَمَلٍ كَالشَّجَرِ بِلَا ثَمَرٍ", "text": "Ilmu tanpa amal bagaikan pohon tanpa buah."},
    {"arab": "لَا تَحْتَقِرْ مَنْ دُوْنَكَ فَلِكُلِّ شَيْءٍ مَزِيَّةٌ", "text": "Jangan meremehkan orang yang di bawahmu, karena setiap sesuatu memiliki kelebihan."},
    {"arab": "مَنْ قَلَّ صِدْقُهُ قَلَّ صَدِيْقُهُ", "text": "Barangsiapa sedikit kejujurannya, sedikit pula temannya."},
    {"arab": "سَلَامَةُ الإِنْسَانِ فِي حِفْظِ اللِّسَانِ", "text": "Keselamatan manusia terletak pada penjagaan lisannya."},
    {"arab": "أَصْلِحْ نَفْسَكَ يَصْلُحْ لَكَ النَّاسُ", "text": "Perbaikilah dirimu, maka orang lain akan baik kepadamu."},
    {"arab": "مَنْ سَارَ عَلَى الدَّرْبِ وَصَلَ", "text": "Barangsiapa berjalan pada jalurnya, ia pasti akan sampai."},
  ];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _fetchPrayerTimes();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
        _updatePrayerStatus();
      });
    });
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  Future<void> _fetchPrayerTimes() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.aladhan.com/v1/timingsByCity?city=Jakarta&country=Indonesia&method=11'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timings = data['data']['timings'];
        setState(() {
          prayerTimes = {
            "Fajr": timings['Fajr'],
            "Dhuhr": timings['Dhuhr'],
            "Asr": timings['Asr'],
            "Maghrib": timings['Maghrib'],
            "Isha": timings['Isha'],
          };
          isLoadingPrayer = false;
        });
        _updatePrayerStatus();
      }
    } catch (e) {
      setState(() => isLoadingPrayer = false);
    }
  }

  void _updatePrayerStatus() {
    String timeNow = "${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}";
    List<Map<String, String>> prayerList = [
      {"name": "Fajr", "time": prayerTimes["Fajr"]!},
      {"name": "Dhuhr", "time": prayerTimes["Dhuhr"]!},
      {"name": "Asr", "time": prayerTimes["Asr"]!},
      {"name": "Maghrib", "time": prayerTimes["Maghrib"]!},
      {"name": "Isha", "time": prayerTimes["Isha"]!},
    ];
    bool isMatch = false;
    for (int i = 0; i < prayerList.length; i++) {
      if (timeNow == prayerList[i]["time"]) {
        currentPrayer = prayerList[i]["name"]!;
        isPrayerTimeNow = true;
        isMatch = true;
        break;
      }
    }
    if (!isMatch) {
      isPrayerTimeNow = false;
      for (int i = 0; i < prayerList.length; i++) {
        if (timeNow.compareTo(prayerList[i]["time"]!) < 0) {
          nextPrayer = prayerList[i]["name"]!;
          break;
        }
        if (i == prayerList.length - 1) nextPrayer = "Fajr";
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ===========================================================
  // BUILD
  // ===========================================================
  @override
  Widget build(BuildContext context) {
    String jam   = _currentTime.hour.toString().padLeft(2, '0');
    String menit = _currentTime.minute.toString().padLeft(2, '0');
    String detik = _currentTime.second.toString().padLeft(2, '0');

    final List<Map<String, dynamic>> prayerData = [
      {"label": "SHUBUH",  "icon": Icons.nights_stay_outlined, "key": "Fajr",    "fKey": "Fajr"},
      {"label": "DZUHUR",  "icon": Icons.wb_sunny_outlined,    "key": "Dhuhr",   "fKey": "Dhuhr",   "isPeci": true},
      {"label": "ASHAR",   "icon": Icons.cloud_outlined,       "key": "Asr",     "fKey": "Asr"},
      {"label": "MAGHRIB", "icon": Icons.wb_twilight,          "key": "Maghrib", "fKey": "Maghrib"},
      {"label": "ISYA",    "icon": Icons.auto_awesome,         "key": "Isha",    "fKey": "Isha"},
    ];

    return Scaffold(
      backgroundColor: bgVoid,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildSectionLabel(
                prefix: "Jadwal",
                highlight: "Sholat",
                sub: "Jakarta · Indonesia · Waktu Lokal",
              ),
              const SizedBox(height: 16),
              _buildPrayerBanner(jam, menit, detik, prayerData),
              const SizedBox(height: 36),
              _buildSectionLabel(
                prefix: "Quotes",
                highlight: "Islamic",
                sub: "Mutiara hikmah dari para ulama",
              ),
              const SizedBox(height: 16),
              _buildQuoteCarousel(),
              const SizedBox(height: 36),
              _buildSectionLabel(
                prefix: "Study",
                highlight: "Islamic",
                sub: "Belajar dan dekatkan diri pada Allah SWT",
              ),
              const SizedBox(height: 16),
              _buildStudyButtons(),
              const SizedBox(height: 32),
              _buildDisclaimer(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================
  // HEADER
  // ===========================================================
  Widget _buildHeader() {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _HeaderPatternPainter()),
        ),
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accentRed.withOpacity(0.10),
                bgVoid,
              ],
            ),
          ),
        ),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderDim),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 16),
                    ),
                  ),
                  Row(
                    children: [
                      _buildLantern(Colors.amber),
                      const SizedBox(width: 20),
                      _buildLantern(accentGold),
                      const SizedBox(width: 20),
                      _buildLantern(Colors.amber),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentRed.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accentRed.withOpacity(0.35)),
                    ),
                    child: const Text(
                      "VANTABLACK",
                      style: TextStyle(color: accentRed, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 48),
              decoration: BoxDecoration(
                color: accentAmber.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentAmber.withOpacity(0.2)),
              ),
              child: const Text(
                "✦  Assalamu'alaikum Warahmatullahi Wabarakatuh  ✦",
                style: TextStyle(color: accentAmber, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 14),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [textPrimary, accentAmber],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                "ISLAMIC  AREA",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 24, height: 1, color: textFaint),
                const SizedBox(width: 8),
                const Text(
                  "STAY HALAL  ·  DEKAT KAN DIRI PADA ALLAH SWT",
                  style: TextStyle(color: textMuted, fontSize: 9, letterSpacing: 2),
                ),
                const SizedBox(width: 8),
                Container(width: 24, height: 1, color: textFaint),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  i == 3 ? Icons.star : Icons.star_border,
                  color: i == 3 ? accentAmber : textFaint,
                  size: i == 3 ? 14 : 8,
                ),
              )),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================
  // LANTERN WIDGET
  // ===========================================================
  Widget _buildLantern(Color color) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Column(
        children: [
          Container(width: 1.5, height: 28, color: color.withOpacity(0.4)),
          Container(
            width: 22, height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.5), width: 1),
              boxShadow: [BoxShadow(color: color.withOpacity(_pulseAnim.value * 0.5), blurRadius: 14, spreadRadius: 1)],
            ),
            child: Center(child: Icon(FontAwesomeIcons.lightbulb, color: color, size: 12)),
          ),
          Container(width: 8, height: 4, decoration: BoxDecoration(color: color.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }

  // ===========================================================
  // SECTION LABEL
  // ===========================================================
  Widget _buildSectionLabel({required String prefix, required String highlight, required String sub}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 22, decoration: BoxDecoration(color: accentRed, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  children: [
                    TextSpan(text: "$prefix  ", style: const TextStyle(color: textPrimary)),
                    TextSpan(text: highlight, style: const TextStyle(color: accentRed)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 13),
            child: Text(sub, style: const TextStyle(color: textMuted, fontSize: 11, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // PRAYER BANNER
  // ===========================================================
  Widget _buildPrayerBanner(String jam, String menit, String detik, List<Map<String, dynamic>> prayerData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderDim),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 20, offset: const Offset(0, 8)),
          BoxShadow(color: accentRed.withOpacity(0.04), blurRadius: 40),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgCardAlt,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: borderDim)),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPrayerTimeNow ? accentGreen : accentAmber,
                      boxShadow: [BoxShadow(color: (isPrayerTimeNow ? accentGreen : accentAmber).withOpacity(_pulseAnim.value * 0.8), blurRadius: 8)],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPrayerTimeNow
                        ? "🕌  Waktu Sholat $currentPrayer — Segera tunaikan ibadah"
                        : "⏳  Menunggu waktu Sholat $nextPrayer",
                    style: TextStyle(
                      color: isPrayerTimeNow ? accentGreen : textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: accentRed.withOpacity(0.3)),
                  ),
                  child: const Text("LIVE", style: TextStyle(color: accentRed, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_outlined, color: textMuted, size: 12),
                    const SizedBox(width: 4),
                    const Text("Jakarta, Indonesia", style: TextStyle(color: textMuted, fontSize: 11)),
                    const SizedBox(width: 12),
                    Icon(Icons.mosque_outlined, color: textMuted, size: 12),
                    const SizedBox(width: 4),
                    const Text("Metode: Kemenag RI", style: TextStyle(color: textMuted, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: bgVoid,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderDim),
                    boxShadow: [BoxShadow(color: accentAmber.withOpacity(0.04), blurRadius: 20)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildClockGroup(jam, "JAM"),
                      _buildClockSep(),
                      _buildClockGroup(menit, "MENIT"),
                      _buildClockSep(),
                      _buildClockGroup(detik, "DETIK"),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Container(height: 1, color: borderDim)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text("WAKTU SHOLAT HARI INI", style: TextStyle(color: textFaint, fontSize: 10, letterSpacing: 2)),
                    ),
                    Expanded(child: Container(height: 1, color: borderDim)),
                  ],
                ),
                const SizedBox(height: 20),
                isLoadingPrayer
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(color: accentRed, strokeWidth: 2),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: prayerData.map((p) {
                            final bool active = nextPrayer == p["fKey"] || currentPrayer == p["fKey"];
                            return _buildPrayerCard(
                              p["label"],
                              p["icon"],
                              prayerTimes[p["key"]]!,
                              active,
                              isPeci: p["isPeci"] == true,
                            );
                          }).toList(),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockGroup(String value, String label) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(anim),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Text(
            value,
            key: ValueKey<String>(value),
            style: const TextStyle(color: textPrimary, fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: textMuted, fontSize: 9, letterSpacing: 3)),
      ],
    );
  }

  Widget _buildClockSep() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18, left: 6, right: 6),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, __) => Text(
          ":",
          style: TextStyle(
            color: accentAmber.withOpacity(_pulseAnim.value),
            fontSize: 38,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ===========================================================
  // PRAYER CARD
  // ===========================================================
  Widget _buildPrayerCard(String title, IconData icon, String time, bool isNextOrNow, {bool isPeci = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: isNextOrNow ? 88 : 76,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: isNextOrNow ? accentRed.withOpacity(0.10) : bgVoid,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isNextOrNow ? accentRed.withOpacity(0.5) : textFaint,
          width: isNextOrNow ? 1.5 : 1,
        ),
        boxShadow: isNextOrNow
            ? [BoxShadow(color: accentRed.withOpacity(0.15), blurRadius: 16)]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isNextOrNow ? textPrimary : textMuted,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          if (isPeci)
            Column(children: [
              Container(
                width: 14, height: 6,
                decoration: const BoxDecoration(
                  color: accentAmber,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
              ),
              Icon(Icons.person, color: isNextOrNow ? textPrimary : textMuted, size: 18),
            ])
          else
            Icon(icon, color: isNextOrNow ? accentAmber : textMuted, size: 22),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isNextOrNow ? accentRed.withOpacity(0.15) : textFaint.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              time,
              style: TextStyle(
                color: isNextOrNow ? textPrimary : textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (isNextOrNow) ...[
            const SizedBox(height: 6),
            Container(
              width: 30, height: 2,
              decoration: BoxDecoration(color: accentRed, borderRadius: BorderRadius.circular(1)),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================
  // QUOTE CAROUSEL
  // ===========================================================
  Widget _buildQuoteCarousel() {
    return SizedBox(
      height: 172,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.88),
        physics: const BouncingScrollPhysics(),
        itemCount: quotes.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderDim),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(colors: [accentAmber.withOpacity(0.08), Colors.transparent]),
                      borderRadius: const BorderRadius.only(topRight: Radius.circular(20)),
                    ),
                    child: const Center(child: Icon(FontAwesomeIcons.quoteRight, color: accentAmber, size: 18)),
                  ),
                ),
                Positioned(
                  bottom: 12, left: 14,
                  child: Text(
                    "${(index + 1).toString().padLeft(2, '0')} / ${quotes.length.toString().padLeft(2, '0')}",
                    style: const TextStyle(color: textFaint, fontSize: 10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 48, 38),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quotes[index]["arab"]!,
                        style: const TextStyle(color: accentAmber, fontSize: 19, fontWeight: FontWeight.bold, height: 1.3),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 10),
                      Container(width: 32, height: 1.5, color: textFaint),
                      const SizedBox(height: 10),
                      Text(
                        '"${quotes[index]["text"]!}"',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontStyle: FontStyle.italic, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================
  // STUDY BUTTONS
  // ===========================================================
  Widget _buildStudyButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStudyButton(
              icon: FontAwesomeIcons.bookQuran,
              title: "Baca Qur'an",
              subtitle: "30 Juz Lengkap",
              color: accentGreen,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranListPage())),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStudyButton(
              icon: FontAwesomeIcons.lightbulb,
              title: "AI ISLAMIC",
              subtitle: "Coming Soon",
              color: accentBlue,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Coming Soon!", style: TextStyle())),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.07), blurRadius: 16)],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0, right: 0,
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: RadialGradient(colors: [color.withOpacity(0.12), Colors.transparent]),
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(18)),
                ),
              ),
            ),
            Positioned(
              bottom: 0, left: 20, right: 20,
              child: Container(height: 2, decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, color, Colors.transparent]),
                borderRadius: BorderRadius.circular(1),
              )),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 26),
                  const SizedBox(height: 8),
                  Text(title, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // DISCLAIMER
  // ===========================================================
  Widget _buildDisclaimer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderDim),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgCardAlt,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: borderDim)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentRed.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.info_outline, color: accentRed, size: 14),
                ),
                const SizedBox(width: 10),
                const Text("INFORMASI APLIKASI", style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "Aplikasi ini dibuat murni untuk edukasi dan membantu ibadah. Jika terdapat kesalahan data, hubungi tim kami.",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12, height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.headset_mic, color: textPrimary, size: 16),
                    label: const Text(
                      "Hubungi Tim VANTABLACK",
                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bgVoid,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: borderDim),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => launchUrl(Uri.parse('+s://t.me/@karzKyzen'), mode: LaunchMode.externalApplication),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// HEADER PATTERN PAINTER
// ===========================================================
class _HeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE63946).withOpacity(0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (double x = -size.height; x < size.width + size.height; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// =====================================================================
// QURAN LIST PAGE
// =====================================================================
class QuranListPage extends StatelessWidget {
  const QuranListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060608),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0F14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2DC653).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2DC653).withOpacity(0.3)),
              ),
              child: const Icon(FontAwesomeIcons.bookQuran, color: Color(0xFF2DC653), size: 14),
            ),
            const SizedBox(width: 10),
            const Text(
              "Al-Qur'an · 30 Juz",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1E1F2B)),
        ),
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: 30,
        itemBuilder: (context, index) {
          final int juzNumber = index + 1;
          final bool isFive = juzNumber % 5 == 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0E0F14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isFive ? const Color(0xFF2DC653).withOpacity(0.3) : const Color(0xFF1E1F2B),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2DC653).withOpacity(0.08),
                  border: Border.all(color: const Color(0xFF2DC653).withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    "$juzNumber",
                    style: const TextStyle(color: Color(0xFF2DC653), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              title: Text(
                "Juz  $juzNumber",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              subtitle: Text(
                isFive ? "✦  Juz pilihan" : "Baca ayat-ayat suci",
                style: TextStyle(
                  color: isFive ? const Color(0xFF2DC653).withOpacity(0.7) : const Color(0xFF6B6D7E),
                  fontSize: 11,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1F2B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_forward_ios, color: Color(0xFF6B6D7E), size: 12),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QuranDetailPage(juzNumber: juzNumber)),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =====================================================================
// QURAN DETAIL PAGE
// =====================================================================
class QuranDetailPage extends StatefulWidget {
  final int juzNumber;
  const QuranDetailPage({super.key, required this.juzNumber});

  @override
  State<QuranDetailPage> createState() => _QuranDetailPageState();
}

class _QuranDetailPageState extends State<QuranDetailPage> {
  List<dynamic> ayahs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJuzData();
  }

  Future<void> _fetchJuzData() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.alquran.cloud/v1/juz/${widget.juzNumber}/quran-uthmani'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          ayahs = data['data']['ayahs'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060608),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0F14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 18),
            children: [
              const TextSpan(text: "Isi  ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              TextSpan(text: "Juz ${widget.juzNumber}", style: const TextStyle(color: Color(0xFF2DC653), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1E1F2B)),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2DC653), strokeWidth: 2))
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: ayahs.length,
              itemBuilder: (context, index) {
                final ayah = ayahs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E0F14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF1E1F2B)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12131A),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          border: const Border(bottom: BorderSide(color: Color(0xFF1E1F2B))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2DC653).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF2DC653).withOpacity(0.3)),
                              ),
                              child: Text(
                                ayah['surah']['englishName'],
                                style: const TextStyle(color: Color(0xFF2DC653), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFD4A017).withOpacity(0.1),
                                border: Border.all(color: const Color(0xFFD4A017).withOpacity(0.5)),
                              ),
                              child: Center(
                                child: Text(
                                  ayah['numberInSurah'].toString(),
                                  style: const TextStyle(color: Color(0xFFD4A017), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                        child: Text(
                          ayah['text'],
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            height: 2.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
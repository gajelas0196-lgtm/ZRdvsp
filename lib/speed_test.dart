import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});

  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage>
    with SingleTickerProviderStateMixin {
  bool _isTesting = false;
  double _ping = 0;
  double _downloadMbps = 0;
  double _uploadMbps = 0;
  String _status = 'Siap melakukan test';
  String _phase = '';
  double _progress = 0;

  late AnimationController _dialController;
  late Animation<double> _dialAnim;

  final Color primaryDark = const Color(0xFF0D0221);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFAA00FF);
  final Color lightPurple = const Color(0xFFE040FB);
  final Color cardDark = const Color(0xFF1A1A2E);
  final Color cyanBlue = const Color(0xFF00E5FF);

  @override
  void initState() {
    super.initState();
    _dialController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _dialAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _dialController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _dialController.dispose();
    super.dispose();
  }

  Future<void> _startTest() async {
    setState(() {
      _isTesting = true;
      _ping = 0; _downloadMbps = 0; _uploadMbps = 0;
      _progress = 0;
    });

    // === PING TEST ===
    setState(() { _phase = 'ping'; _status = 'Mengukur latency...'; });
    final pings = <double>[];
    for (int i = 0; i < 5; i++) {
      try {
        final sw = Stopwatch()..start();
        await http.get(Uri.parse('https://www.google.com')).timeout(const Duration(seconds: 5));
        sw.stop();
        pings.add(sw.elapsedMilliseconds.toDouble());
      } catch (_) { pings.add(999); }
      setState(() => _progress = (i + 1) / 5 * 0.2);
    }
    pings.sort();
    setState(() => _ping = pings[pings.length ~/ 2]);

    // === DOWNLOAD TEST ===
    setState(() { _phase = 'download'; _status = 'Mengukur download speed...'; });
    double totalDl = 0;
    final dlUrls = [
      'https://speed.cloudflare.com/__down?bytes=1000000',
      'https://httpbin.org/bytes/500000',
    ];
    for (int i = 0; i < dlUrls.length; i++) {
      try {
        final sw = Stopwatch()..start();
        final resp = await http.get(Uri.parse(dlUrls[i])).timeout(const Duration(seconds: 10));
        sw.stop();
        final bytes = resp.bodyBytes.length;
        final seconds = sw.elapsedMilliseconds / 1000;
        if (seconds > 0 && bytes > 1000) {
          totalDl += (bytes * 8) / (seconds * 1000000); // Mbps
        }
      } catch (_) {}
      setState(() => _progress = 0.2 + (i + 1) / dlUrls.length * 0.4);
    }
    setState(() => _downloadMbps = totalDl > 0 ? totalDl / 2 : 0);
    _dialController.forward(from: 0);

    // === UPLOAD TEST ===
    setState(() { _phase = 'upload'; _status = 'Mengukur upload speed...'; });
    double totalUl = 0;
    for (int i = 0; i < 2; i++) {
      try {
        final data = List.filled(250000, 0);
        final sw = Stopwatch()..start();
        await http.post(
          Uri.parse('https://httpbin.org/post'),
          body: data,
          headers: {'Content-Type': 'application/octet-stream'},
        ).timeout(const Duration(seconds: 10));
        sw.stop();
        final bytes = 250000;
        final seconds = sw.elapsedMilliseconds / 1000;
        if (seconds > 0) totalUl += (bytes * 8) / (seconds * 1000000);
      } catch (_) {}
      setState(() => _progress = 0.6 + (i + 1) / 2 * 0.4);
    }
    setState(() {
      _uploadMbps = totalUl > 0 ? totalUl / 2 : 0;
      _isTesting = false;
      _phase = 'done';
      _status = 'Test selesai!';
      _progress = 1.0;
    });
  }

  String _rating(double dl) {
    if (dl <= 0) return '-';
    if (dl < 1) return 'Sangat Lambat 🐌';
    if (dl < 5) return 'Lambat 🐢';
    if (dl < 25) return 'Cukup 🚶';
    if (dl < 100) return 'Cepat 🚗';
    if (dl < 500) return 'Sangat Cepat 🚀';
    return 'Luar Biasa ⚡';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("SPEED TEST",
            style: TextStyle(
              color: Colors.white, fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold, fontSize: 16,
              shadows: [Shadow(color: cyanBlue.withOpacity(0.8), blurRadius: 10)],
            )),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryPurple.withOpacity(0.4), Colors.transparent],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Speedometer visual
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardDark, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryPurple.withOpacity(0.4)),
                boxShadow: [BoxShadow(color: primaryPurple.withOpacity(0.2), blurRadius: 20)],
              ),
              child: Column(children: [
                // Main dial
                SizedBox(
                  width: 200, height: 200,
                  child: Stack(alignment: Alignment.center, children: [
                    SizedBox(
                      width: 180, height: 180,
                      child: CircularProgressIndicator(
                        value: _isTesting ? _progress : (_phase == 'done' ? 1.0 : 0),
                        backgroundColor: Colors.white10,
                        color: _phase == 'ping' ? Colors.yellow
                            : _phase == 'download' ? cyanBlue
                            : _phase == 'upload' ? lightPurple
                            : _phase == 'done' ? const Color(0xFF00E676)
                            : primaryPurple,
                        strokeWidth: 12,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      if (_phase == 'download' || _phase == 'done')
                        Text(
                          _downloadMbps > 0 ? _downloadMbps.toStringAsFixed(1) : '--',
                          style: TextStyle(color: cyanBlue, fontFamily: 'Orbitron', fontSize: 36, fontWeight: FontWeight.bold),
                        )
                      else if (_phase == 'ping')
                        Text(_ping > 0 ? '${_ping.round()}ms' : '--',
                            style: TextStyle(color: Colors.yellow, fontFamily: 'Orbitron', fontSize: 28, fontWeight: FontWeight.bold))
                      else
                        Text('--', style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Orbitron', fontSize: 36, fontWeight: FontWeight.bold)),
                      Text(
                        _phase == 'ping' ? 'PING' : 'Mbps',
                        style: TextStyle(color: Colors.grey.shade400, fontFamily: 'ShareTechMono', fontSize: 14),
                      ),
                    ]),
                  ]),
                ),
                const SizedBox(height: 16),
                Text(_status, style: TextStyle(color: Colors.grey.shade400, fontFamily: 'ShareTechMono', fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 20),

            // Stats row
            Row(children: [
              Expanded(child: _statCard("PING", _ping > 0 ? '${_ping.round()} ms' : '--', Icons.swap_horiz, Colors.yellow)),
              const SizedBox(width: 12),
              Expanded(child: _statCard("DOWNLOAD", _downloadMbps > 0 ? '${_downloadMbps.toStringAsFixed(1)} Mbps' : '--', Icons.download, cyanBlue)),
              const SizedBox(width: 12),
              Expanded(child: _statCard("UPLOAD", _uploadMbps > 0 ? '${_uploadMbps.toStringAsFixed(1)} Mbps' : '--', Icons.upload, lightPurple)),
            ]),
            const SizedBox(height: 20),

            if (_phase == 'done') ...[
              Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.speed, color: Color(0xFF00E676), size: 22),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("KUALITAS KONEKSI", style: TextStyle(color: Colors.grey.shade500, fontFamily: 'ShareTechMono', fontSize: 10, letterSpacing: 1)),
                    Text(_rating(_downloadMbps), style: const TextStyle(color: Colors.white, fontFamily: 'Orbitron', fontSize: 14, fontWeight: FontWeight.bold)),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _isTesting ? null : _startTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 8, shadowColor: primaryPurple.withOpacity(0.5),
                ),
                child: _isTesting
                    ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        const SizedBox(width: 12),
                        Text("TESTING...", style: TextStyle(fontFamily: 'Orbitron', color: Colors.white, letterSpacing: 1.5)),
                      ])
                    : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.play_circle_outline, color: Colors.white),
                        SizedBox(width: 10),
                        Text("MULAI TEST", style: TextStyle(
                            fontFamily: 'Orbitron', color: Colors.white,
                            letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                      ]),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: cardDark, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 6),
      Text(label, style: TextStyle(color: Colors.grey.shade500, fontFamily: 'ShareTechMono', fontSize: 9, letterSpacing: 1)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color, fontFamily: 'Orbitron', fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    ]),
  );
}

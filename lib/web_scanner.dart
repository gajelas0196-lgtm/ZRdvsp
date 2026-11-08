import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart'

class WebScannerPage extends StatefulWidget {
  const WebScannerPage({super.key});

  @override
  State<WebScannerPage> createState() => _WebScannerPageState();
}

class _WebScannerPageState extends State<WebScannerPage>
    with TickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _scanResult;

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnim;

  final Color primaryDark = const Color(0xFF0D0221);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFAA00FF);
  final Color lightPurple = const Color(0xFFE040FB);
  final Color cardDark = const Color(0xFF1A1A2E);
  final Color terminalGreen = const Color(0xFF00FF41);
  final Color warningYellow = const Color(0xFFFFD600);
  final Color dangerRed = const Color(0xFFFF1744);

  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(_scanLineController);
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _addLog(String msg) {
    setState(() => _logs.add("[${DateTime.now().toString().substring(11, 19)}] $msg"));
  }

  Future<void> _startScan() async {
    String url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = "Masukkan URL target.");
      return;
    }
    if (!url.startsWith('http')) url = 'https://$url';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _scanResult = null;
      _logs.clear();
    });

    _addLog("Memulai scan target: $url");

    final results = <String, dynamic>{
      'url': url,
      'headers': {},
      'security': {},
      'whois': {},
      'tech': [],
      'ports': {},
    };

    try {
      // === 1. HTTP Headers Analysis ===
      _addLog("Menganalisis HTTP headers...");
      try {
        final resp = await http.get(Uri.parse(url), headers: {
          'User-Agent': 'Mozilla/5.0 NexaScanner/2.0',
        }).timeout(const Duration(seconds: 8));

        results['statusCode'] = resp.statusCode;
        final headers = Map<String, String>.from(resp.headers);
        results['headers'] = headers;

        // Security headers check
        final secChecks = <String, dynamic>{};
        secChecks['X-Frame-Options'] = headers.containsKey('x-frame-options')
            ? {'status': 'OK', 'value': headers['x-frame-options']}
            : {'status': 'MISSING', 'value': null};
        secChecks['X-Content-Type-Options'] = headers.containsKey('x-content-type-options')
            ? {'status': 'OK', 'value': headers['x-content-type-options']}
            : {'status': 'MISSING', 'value': null};
        secChecks['Strict-Transport-Security'] = headers.containsKey('strict-transport-security')
            ? {'status': 'OK', 'value': headers['strict-transport-security']}
            : {'status': 'MISSING', 'value': null};
        secChecks['Content-Security-Policy'] = headers.containsKey('content-security-policy')
            ? {'status': 'OK', 'value': headers['content-security-policy']}
            : {'status': 'MISSING', 'value': null};
        secChecks['X-XSS-Protection'] = headers.containsKey('x-xss-protection')
            ? {'status': 'OK', 'value': headers['x-xss-protection']}
            : {'status': 'MISSING', 'value': null};
        secChecks['Referrer-Policy'] = headers.containsKey('referrer-policy')
            ? {'status': 'OK', 'value': headers['referrer-policy']}
            : {'status': 'MISSING', 'value': null};

        results['security'] = secChecks;
        _addLog("Headers ditemukan: ${headers.length} entri");

        // Tech stack detection
        final techList = <String>[];
        final server = headers['server'] ?? '';
        final xPowered = headers['x-powered-by'] ?? '';
        if (server.isNotEmpty) techList.add('Server: $server');
        if (xPowered.isNotEmpty) techList.add('Powered-By: $xPowered');
        if (headers.containsKey('x-wp-super-cache') ||
            headers.containsKey('x-pingback')) techList.add('WordPress');
        if (headers['server']?.toLowerCase().contains('nginx') == true)
          techList.add('NGINX');
        if (headers['server']?.toLowerCase().contains('apache') == true)
          techList.add('Apache');
        if (headers['server']?.toLowerCase().contains('cloudflare') == true)
          techList.add('Cloudflare');
        if (headers.containsKey('x-shopify-stage')) techList.add('Shopify');
        results['tech'] = techList;
        _addLog("Tech stack terdeteksi: ${techList.length} teknologi");

        // SSL check
        results['ssl'] = url.startsWith('https') ? 'AKTIF ✓' : 'TIDAK ADA ✗';
        _addLog("SSL: ${results['ssl']}");
      } catch (e) {
        results['headers_error'] = e.toString();
        _addLog("Headers scan gagal: $e");
      }

      // === 2. DNS / WHOIS via siputzx API ===
      _addLog("Mengambil info DNS...");
      try {
        final domain = Uri.parse(url).host;
        final dnsResp = await http.get(
          Uri.parse('$baseUrl/api/tools/dns?domain=$domain'),
        ).timeout(const Duration(seconds: 8));
        if (dnsResp.statusCode == 200) {
          final dnsData = jsonDecode(dnsResp.body);
          if (dnsData['status'] == true) {
            results['dns'] = dnsData['data'];
            _addLog("DNS info berhasil diambil.");
          }
        }
      } catch (e) {
        _addLog("DNS lookup gagal.");
      }

      // === 3. IP Geolocation ===
      _addLog("Resolving IP address...");
      try {
        final domain = Uri.parse(url).host;
        final ipResp = await http.get(
          Uri.parse('https://ipwho.is/$domain'),
        ).timeout(const Duration(seconds: 8));
        if (ipResp.statusCode == 200) {
          final ipData = jsonDecode(ipResp.body);
          results['ip_info'] = {
            'ip': ipData['ip'],
            'country': ipData['country'],
            'city': ipData['city'],
            'org': ipData['org'] ?? ipData['connection']?['org'],
            'isp': ipData['connection']?['isp'],
          };
          _addLog("IP: ${ipData['ip']} (${ipData['country']})");
        }
      } catch (e) {
        _addLog("IP lookup gagal.");
      }

      // === 4. Score ===
      final securityMap = results['security'] as Map<String, dynamic>;
      final okCount = securityMap.values
          .where((v) => v is Map && v['status'] == 'OK')
          .length;
      final totalChecks = securityMap.length;
      results['score'] = totalChecks > 0 ? (okCount / totalChecks * 100).round() : 0;
      _addLog("Security Score: ${results['score']}%");
      _addLog("Scan selesai!");

      setState(() => _scanResult = results);
    } catch (e) {
      setState(() => _errorMessage = "Scan gagal: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _scoreColor(int score) {
    if (score >= 70) return const Color(0xFF00E676);
    if (score >= 40) return const Color(0xFFFFD600);
    return const Color(0xFFFF1744);
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
        title: Text(
          "WEB SCANNER",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            shadows: [Shadow(color: terminalGreen.withOpacity(0.8), blurRadius: 10)],
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryPurple.withOpacity(0.4), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scanner animation header
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: terminalGreen.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    if (_isLoading)
                      AnimatedBuilder(
                        animation: _scanLineAnim,
                        builder: (_, __) => Positioned(
                          top: _scanLineAnim.value * 70,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  terminalGreen.withOpacity(0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.radar, color: terminalGreen, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            _isLoading ? "SCANNING TARGET..." : "READY TO SCAN",
                            style: TextStyle(
                              color: terminalGreen,
                              fontFamily: 'ShareTechMono',
                              fontSize: 14,
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
            const SizedBox(height: 20),

            // URL Input
            Container(
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: primaryPurple.withOpacity(0.5)),
              ),
              child: TextField(
                controller: _urlController,
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'ShareTechMono'),
                decoration: InputDecoration(
                  hintText: "https://target.com",
                  hintStyle: TextStyle(
                      color: Colors.grey.shade600, fontFamily: 'ShareTechMono'),
                  prefixIcon: Icon(Icons.language, color: lightPurple),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 8,
                  shadowColor: accentPurple.withOpacity(0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isLoading ? Icons.hourglass_top : Icons.search,
                        color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      _isLoading ? "SCANNING..." : "START SCAN",
                      style: const TextStyle(
                          fontFamily: 'Orbitron',
                          color: Colors.white,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Terminal Logs
            if (_logs.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: terminalGreen.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.terminal, color: terminalGreen, size: 16),
                        const SizedBox(width: 8),
                        Text("SCAN LOG",
                            style: TextStyle(
                                color: terminalGreen,
                                fontFamily: 'ShareTechMono',
                                fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._logs.map((log) => Text(
                          "> $log",
                          style: TextStyle(
                              color: terminalGreen.withOpacity(0.8),
                              fontFamily: 'ShareTechMono',
                              fontSize: 11),
                        )),
                  ],
                ),
              ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: dangerRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dangerRed.withOpacity(0.4)),
                ),
                child: Text(_errorMessage!,
                    style: TextStyle(
                        color: dangerRed, fontFamily: 'ShareTechMono')),
              ),
            ],

            // Results
            if (_scanResult != null) ...[
              const SizedBox(height: 24),

              // Score
              if (_scanResult!['score'] != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _scoreColor(_scanResult!['score']).withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text("SECURITY SCORE",
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontFamily: 'Orbitron',
                              fontSize: 12,
                              letterSpacing: 2)),
                      const SizedBox(height: 10),
                      Text(
                        "${_scanResult!['score']}%",
                        style: TextStyle(
                          color: _scoreColor(_scanResult!['score']),
                          fontFamily: 'Orbitron',
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _scanResult!['score'] / 100,
                        backgroundColor: Colors.white12,
                        color: _scoreColor(_scanResult!['score']),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // IP Info
              if (_scanResult!['ip_info'] != null)
                _buildResultCard("IP INFO", Icons.public, [
                  _buildRow("IP Address", _scanResult!['ip_info']['ip'] ?? '-'),
                  _buildRow("Country", _scanResult!['ip_info']['country'] ?? '-'),
                  _buildRow("City", _scanResult!['ip_info']['city'] ?? '-'),
                  _buildRow("ISP", _scanResult!['ip_info']['isp'] ?? _scanResult!['ip_info']['org'] ?? '-'),
                ]),

              const SizedBox(height: 16),

              // SSL & Status
              _buildResultCard("STATUS SERVER", Icons.dns, [
                _buildRow("HTTP Status", _scanResult!['statusCode']?.toString() ?? '-'),
                _buildRow("SSL/HTTPS", _scanResult!['ssl'] ?? '-'),
              ]),

              const SizedBox(height: 16),

              // Tech Stack
              if (_scanResult!['tech'] != null && (_scanResult!['tech'] as List).isNotEmpty)
                _buildResultCard("TECH STACK", Icons.layers, [
                  ...(_scanResult!['tech'] as List).map((t) => _buildRow("▸", t.toString())),
                ]),

              const SizedBox(height: 16),

              // Security Headers
              if (_scanResult!['security'] != null)
                _buildSecurityHeadersCard(_scanResult!['security'] as Map<String, dynamic>),

              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, IconData icon, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryPurple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: lightPurple, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      color: lightPurple,
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5)),
            ],
          ),
          const Divider(color: Colors.white12, height: 20),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontFamily: 'ShareTechMono',
                    fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'ShareTechMono',
                    fontSize: 12)),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.copy, size: 14, color: Colors.grey.shade600),
            onPressed: () => Clipboard.setData(ClipboardData(text: value)),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityHeadersCard(Map<String, dynamic> security) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryPurple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: lightPurple, size: 18),
              const SizedBox(width: 8),
              Text("SECURITY HEADERS",
                  style: TextStyle(
                      color: lightPurple,
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5)),
            ],
          ),
          const Divider(color: Colors.white12, height: 20),
          ...security.entries.map((entry) {
            final isOk = entry.value['status'] == 'OK';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (isOk ? const Color(0xFF00E676) : dangerRed).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (isOk ? const Color(0xFF00E676) : dangerRed).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isOk ? Icons.check_circle : Icons.cancel,
                    color: isOk ? const Color(0xFF00E676) : dangerRed,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(entry.key,
                        style: TextStyle(
                            color: isOk ? Colors.white : Colors.grey.shade400,
                            fontFamily: 'ShareTechMono',
                            fontSize: 11)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isOk ? const Color(0xFF00E676) : dangerRed).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isOk ? "OK" : "MISSING",
                      style: TextStyle(
                        color: isOk ? const Color(0xFF00E676) : dangerRed,
                        fontFamily: 'ShareTechMono',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

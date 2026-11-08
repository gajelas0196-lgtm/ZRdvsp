import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class IpGeoPage extends StatefulWidget {
  const IpGeoPage({super.key});

  @override
  State<IpGeoPage> createState() => _IpGeoPageState();
}

class _IpGeoPageState extends State<IpGeoPage> with SingleTickerProviderStateMixin {
  final TextEditingController _ipController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _ipData;
  String? _errorMessage;
  String? _myIp;
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  final Color primaryDark = const Color(0xFF0D0221);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFAA00FF);
  final Color lightPurple = const Color(0xFFE040FB);
  final Color cardDark = const Color(0xFF1A1A2E);
  final Color cyanBlue = const Color(0xFF00E5FF);

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _fetchMyIp();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyIp() async {
    try {
      final resp = await http.get(Uri.parse('https://api.ipify.org?format=json'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() => _myIp = data['ip']);
      }
    } catch (_) {}
  }

  Future<void> _checkIp([String? ipOverride]) async {
    final ip = (ipOverride ?? _ipController.text.trim());
    if (ip.isEmpty) {
      setState(() => _errorMessage = "Masukkan IP address.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _ipData = null;
    });

    try {
      // Primary: ipwho.is
      final resp = await http.get(Uri.parse('https://ipwho.is/$ip'))
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['success'] == true) {
          setState(() => _ipData = data);
        } else {
          // Fallback: ip-api
          await _fallbackCheck(ip);
        }
      } else {
        await _fallbackCheck(ip);
      }
    } catch (e) {
      setState(() => _errorMessage = "Gagal mengambil data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fallbackCheck(String ip) async {
    try {
      final resp = await http.get(
          Uri.parse('http://ip-api.com/json/$ip?fields=status,message,country,countryCode,region,regionName,city,zip,lat,lon,timezone,isp,org,as,query,proxy,hosting,mobile'))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['status'] == 'success') {
          setState(() => _ipData = {
            'ip': data['query'],
            'country': data['country'],
            'country_code': data['countryCode'],
            'region': data['regionName'],
            'city': data['city'],
            'postal': data['zip'],
            'latitude': data['lat'],
            'longitude': data['lon'],
            'timezone': {'id': data['timezone']},
            'connection': {
              'isp': data['isp'],
              'org': data['org'],
              'asn': data['as'],
            },
            'security': {
              'proxy': data['proxy'],
              'hosting': data['hosting'],
              'mobile': data['mobile'],
            }
          });
        } else {
          setState(() => _errorMessage = data['message'] ?? "IP tidak valid.");
        }
      }
    } catch (e) {
      setState(() => _errorMessage = "Gagal: $e");
    }
  }

  void _openMap() {
    if (_ipData == null) return;
    final lat = _ipData!['latitude'];
    final lon = _ipData!['longitude'];
    if (lat != null && lon != null) {
      launchUrl(Uri.parse('https://maps.google.com/?q=$lat,$lon'));
    }
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
          "IP GEOLOCATION",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            shadows: [Shadow(color: cyanBlue.withOpacity(0.8), blurRadius: 10)],
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
            // Globe animation
            Center(
              child: AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, __) => Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryPurple.withOpacity(0.1),
                    border: Border.all(
                        color: cyanBlue.withOpacity(_glowAnim.value), width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: cyanBlue.withOpacity(_glowAnim.value * 0.4),
                          blurRadius: 20,
                          spreadRadius: 5)
                    ],
                  ),
                  child: Icon(Icons.public, color: cyanBlue, size: 46),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // My IP Display
            if (_myIp != null)
              Center(
                child: GestureDetector(
                  onTap: () {
                    _ipController.text = _myIp!;
                    _checkIp(_myIp!);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: cyanBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cyanBlue.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.my_location, color: cyanBlue, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          "IP Saya: $_myIp",
                          style: TextStyle(
                              color: cyanBlue,
                              fontFamily: 'ShareTechMono',
                              fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.touch_app, color: cyanBlue.withOpacity(0.6), size: 14),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Input
            Container(
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: primaryPurple.withOpacity(0.5)),
              ),
              child: TextField(
                controller: _ipController,
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'ShareTechMono'),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Masukkan IP address (cth: 8.8.8.8)",
                  hintStyle: TextStyle(
                      color: Colors.grey.shade600, fontFamily: 'ShareTechMono'),
                  prefixIcon: Icon(Icons.dns, color: lightPurple),
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
                onPressed: _isLoading ? null : () => _checkIp(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 8,
                  shadowColor: primaryPurple.withOpacity(0.5),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: cyanBlue, strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text("TRACING...",
                              style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  color: Colors.white,
                                  letterSpacing: 1.5)),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_searching, color: Colors.white),
                          SizedBox(width: 10),
                          Text("TRACE IP",
                              style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.4)),
                ),
                child: Text(_errorMessage!,
                    style: TextStyle(
                        color: Colors.red.shade300,
                        fontFamily: 'ShareTechMono')),
              ),

            if (_ipData != null) ...[
              // Main Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryPurple.withOpacity(0.3),
                      cyanBlue.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cyanBlue.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                        color: cyanBlue.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5)
                  ],
                ),
                child: Column(
                  children: [
                    // Flag + IP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getFlag(_ipData!['country_code'] ?? ''),
                          style: const TextStyle(fontSize: 36),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _ipData!['ip'] ?? '-',
                              style: TextStyle(
                                color: cyanBlue,
                                fontFamily: 'ShareTechMono',
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              "${_ipData!['city'] ?? '-'}, ${_ipData!['country'] ?? '-'}",
                              style: TextStyle(
                                  color: Colors.grey.shade300,
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Koordinat
                    if (_ipData!['latitude'] != null && _ipData!['longitude'] != null)
                      GestureDetector(
                        onTap: _openMap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.pin_drop,
                                  color: Colors.blue, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                "${_ipData!['latitude']}, ${_ipData!['longitude']}",
                                style: const TextStyle(
                                    color: Colors.blue,
                                    fontFamily: 'ShareTechMono',
                                    fontSize: 12),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.open_in_new,
                                  color: Colors.blue, size: 14),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Detail Grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildInfoTile("NEGARA", _ipData!['country'] ?? '-', Icons.flag),
                  _buildInfoTile("REGION", _ipData!['region'] ?? '-', Icons.map),
                  _buildInfoTile("KOTA", _ipData!['city'] ?? '-', Icons.location_city),
                  _buildInfoTile("KODE POS", _ipData!['postal'] ?? '-', Icons.markunread_mailbox),
                  _buildInfoTile(
                    "TIMEZONE",
                    _ipData!['timezone']?['id'] ?? _ipData!['timezone'] ?? '-',
                    Icons.access_time,
                  ),
                  _buildInfoTile("ISP",
                    _ipData!['connection']?['isp'] ?? '-', Icons.business),
                ],
              ),

              const SizedBox(height: 16),

              // ASN & Org
              _buildDetailCard("NETWORK INFO", [
                {'label': 'ASN', 'value': _ipData!['connection']?['asn'] ?? _ipData!['asn'] ?? '-'},
                {'label': 'Organisasi', 'value': _ipData!['connection']?['org'] ?? _ipData!['org'] ?? '-'},
                {'label': 'ISP', 'value': _ipData!['connection']?['isp'] ?? _ipData!['isp'] ?? '-'},
              ]),

              if (_ipData!['security'] != null) ...[
                const SizedBox(height: 16),
                _buildSecurityFlags(_ipData!['security']),
              ],

              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryPurple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: lightPurple, size: 14),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontFamily: 'ShareTechMono',
                      fontSize: 10,
                      letterSpacing: 1)),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'ShareTechMono',
                fontSize: 13,
                fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Map<String, String>> rows) {
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
          Text(title,
              style: TextStyle(
                  color: lightPurple,
                  fontFamily: 'Orbitron',
                  fontSize: 11,
                  letterSpacing: 1.5)),
          const Divider(color: Colors.white12, height: 16),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(row['label']!,
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontFamily: 'ShareTechMono',
                              fontSize: 11)),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Clipboard.setData(
                            ClipboardData(text: row['value']!)),
                        child: Text(row['value']!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'ShareTechMono',
                                fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSecurityFlags(Map<String, dynamic> security) {
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
          Text("SECURITY FLAGS",
              style: TextStyle(
                  color: lightPurple,
                  fontFamily: 'Orbitron',
                  fontSize: 11,
                  letterSpacing: 1.5)),
          const Divider(color: Colors.white12, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFlag("PROXY", security['proxy'] == true, Icons.vpn_lock),
              _buildFlag("HOSTING", security['hosting'] == true, Icons.cloud),
              _buildFlag("MOBILE", security['mobile'] == true, Icons.smartphone),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlag(String label, bool active, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (active ? Colors.orange : const Color(0xFF00E676)).withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: (active ? Colors.orange : const Color(0xFF00E676)).withOpacity(0.4),
            ),
          ),
          child: Icon(icon,
              color: active ? Colors.orange : const Color(0xFF00E676), size: 22),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade400,
                fontFamily: 'ShareTechMono',
                fontSize: 10)),
        Text(
          active ? "YES" : "NO",
          style: TextStyle(
              color: active ? Colors.orange : const Color(0xFF00E676),
              fontFamily: 'Orbitron',
              fontSize: 10,
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _getFlag(String countryCode) {
    if (countryCode.length != 2) return '🌐';
    return String.fromCharCodes(
      countryCode.toUpperCase().codeUnits.map((c) => c + 127397),
    );
  }
}

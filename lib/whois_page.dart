import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart'

class WhoisPage extends StatefulWidget {
  const WhoisPage({super.key});

  @override
  State<WhoisPage> createState() => _WhoisPageState();
}

class _WhoisPageState extends State<WhoisPage> {
  final TextEditingController _domainCtrl = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  final Color primaryDark = const Color(0xFF0D0221);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple = const Color(0xFFAA00FF);
  final Color lightPurple = const Color(0xFFE040FB);
  final Color cardDark = const Color(0xFF1A1A2E);
  final Color terminalGreen = const Color(0xFF00FF41);

  Future<void> _lookup() async {
    String domain = _domainCtrl.text.trim().toLowerCase()
        .replaceAll('https://', '').replaceAll('http://', '').split('/').first;
    if (domain.isEmpty) {
      setState(() => _error = "Masukkan domain.");
      return;
    }

    setState(() { _isLoading = true; _error = null; _result = null; });

    try {
      // Try rdap.org (free, no key needed)
      final tld = domain.split('.').last;
      final rdapUrl = 'https://rdap.org/domain/$domain';
      final resp = await http.get(Uri.parse(rdapUrl),
          headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        _parseRdap(data, domain);
      } else {
        // Fallback: whois.freeaitools.net
        final resp2 = await http.get(
          Uri.parse('$baseUrl/api/tools/whois?domain=$domain'),
        ).timeout(const Duration(seconds: 10));
        if (resp2.statusCode == 200) {
          final data2 = jsonDecode(resp2.body);
          if (data2['status'] == true) {
            setState(() => _result = _flattenMap(data2['data'] ?? {}));
          } else {
            setState(() => _error = "Data WHOIS tidak tersedia untuk domain ini.");
          }
        } else {
          setState(() => _error = "Gagal mengambil data WHOIS.");
        }
      }
    } catch (e) {
      setState(() => _error = "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _parseRdap(Map<String, dynamic> data, String domain) {
    final result = <String, dynamic>{};
    result['Domain'] = domain.toUpperCase();

    // Status
    final statuses = (data['status'] as List?)?.join(', ') ?? '-';
    result['Status'] = statuses;

    // Dates
    for (final e in (data['events'] ?? []) as List) {
      final action = e['eventAction'] ?? '';
      final date = e['eventDate'] ?? '';
      if (action == 'registration') result['Terdaftar'] = date.toString().substring(0, 10);
      if (action == 'expiration') result['Kadaluarsa'] = date.toString().substring(0, 10);
      if (action == 'last changed') result['Terakhir Update'] = date.toString().substring(0, 10);
    }

    // Nameservers
    final ns = <String>[];
    for (final n in (data['nameservers'] ?? []) as List) {
      ns.add(n['ldhName'] ?? '');
    }
    if (ns.isNotEmpty) result['Nameservers'] = ns.join('\n');

    // Registrar
    for (final entity in (data['entities'] ?? []) as List) {
      final roles = (entity['roles'] as List?) ?? [];
      if (roles.contains('registrar')) {
        final vcardArray = entity['vcardArray'] as List?;
        if (vcardArray != null && vcardArray.length > 1) {
          for (final vcard in vcardArray[1] as List) {
            if ((vcard as List).isNotEmpty && vcard[0] == 'fn') {
              result['Registrar'] = vcard[3] ?? '-';
            }
          }
        }
      }
      if (roles.contains('registrant')) {
        final vcardArray = entity['vcardArray'] as List?;
        if (vcardArray != null && vcardArray.length > 1) {
          for (final vcard in vcardArray[1] as List) {
            if ((vcard as List).isNotEmpty && vcard[0] == 'org') {
              result['Pemilik'] = vcard[3] ?? '-';
            }
          }
        }
      }
    }

    // Handle
    result['Handle'] = data['handle'] ?? '-';

    setState(() => _result = result);
  }

  Map<String, dynamic> _flattenMap(Map<String, dynamic> map, [String prefix = '']) {
    final result = <String, dynamic>{};
    map.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result.addAll(_flattenMap(value, '$key.'));
      } else {
        result['$prefix$key'] = value?.toString() ?? '-';
      }
    });
    return result;
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
        title: Text("WHOIS LOOKUP",
            style: TextStyle(
              color: Colors.white, fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold, fontSize: 16,
              shadows: [Shadow(color: terminalGreen.withOpacity(0.8), blurRadius: 10)],
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
            Center(
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryPurple.withOpacity(0.15),
                  border: Border.all(color: terminalGreen.withOpacity(0.5), width: 2),
                ),
                child: Icon(Icons.manage_search, color: terminalGreen, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            Text("Cek informasi registrasi domain",
                style: TextStyle(color: Colors.grey.shade500, fontFamily: 'ShareTechMono', fontSize: 12)),
            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                color: cardDark, borderRadius: BorderRadius.circular(15),
                border: Border.all(color: primaryPurple.withOpacity(0.5)),
              ),
              child: TextField(
                controller: _domainCtrl,
                style: const TextStyle(color: Colors.white, fontFamily: 'ShareTechMono'),
                decoration: InputDecoration(
                  hintText: "google.com",
                  hintStyle: TextStyle(color: Colors.grey.shade600, fontFamily: 'ShareTechMono'),
                  prefixIcon: Icon(Icons.domain, color: terminalGreen),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _lookup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.search, color: Colors.white),
                        SizedBox(width: 10),
                        Text("WHOIS LOOKUP", style: TextStyle(
                            fontFamily: 'Orbitron', color: Colors.white,
                            letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                      ]),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontFamily: 'ShareTechMono')),
              ),
            ],

            if (_result != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardDark, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: terminalGreen.withOpacity(0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("WHOIS DATA", style: TextStyle(
                        color: terminalGreen, fontFamily: 'Orbitron', fontSize: 12, letterSpacing: 1.5)),
                    IconButton(
                      padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                      icon: Icon(Icons.copy_all, color: terminalGreen, size: 18),
                      onPressed: () {
                        final text = _result!.entries.map((e) => '${e.key}: ${e.value}').join('\n');
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text("Disalin!"), backgroundColor: primaryPurple,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        );
                      },
                    ),
                  ]),
                  const Divider(color: Colors.white12, height: 20),
                  ..._result!.entries.map((entry) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(width: 110, child: Text(entry.key,
                          style: TextStyle(color: Colors.grey.shade500, fontFamily: 'ShareTechMono', fontSize: 11))),
                      const Text(": ", style: TextStyle(color: Colors.white30, fontSize: 11)),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Clipboard.setData(ClipboardData(text: entry.value.toString())),
                          child: Text(entry.value.toString(),
                              style: const TextStyle(color: Colors.white, fontFamily: 'ShareTechMono', fontSize: 12)),
                        ),
                      ),
                    ]),
                  )),
                ]),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Ambil API key dari .env
final String groqApiKey = dotenv.env['GROQ_API_KEY'] ?? '';

// Ganti pemanggilan API di kodemu menggunakan variabel groqApiKey
// Contoh: headers: {'Authorization': 'Bearer $groqApiKey'}
// ── Model Groq (gratisan semua) ────────────────────────
const String _model = 'llama-3.3-70b-versatile'; 
// Alternatif: 'mixtral-8x7b-32768', 'llama-3.1-8b-instant', 'gemma2-9b-it'

class AIPage extends StatefulWidget {
  final String username;
  final String sessionKey;
  const AIPage({super.key, required this.username, required this.sessionKey});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  final Color bgDark        = const Color(0xFF0D0221);
  final Color primaryPurple = const Color(0xFF7B1FA2);
  final Color accentPurple  = const Color(0xFFEA80FC);
  final Color borderGlass   = const Color(0x1AFFFFFF);

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Kirim request ke Groq API ─────────────────────────
  Future<String?> _sendToGroq(List<Map<String, dynamic>> messages) async {
    try {
      final res = await http.post(
        Uri.parse(_groqBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.9,
          'max_tokens': 1024,
        }),
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['choices']?[0]?['message']?['content'] ?? 'Maaf, tidak ada respons.';
      } else if (res.statusCode == 429) {
        return '⚠️ Rate limit Groq tercapai. Tunggu sebentar dan coba lagi.\n\nFree tier: 14,400 req/hari, 7,000 req/menit.';
      } else if (res.statusCode == 401) {
        return '🔑 API Key Groq tidak valid. Cek lagi di console.groq.com/keys';
      } else {
        final error = jsonDecode(res.body);
        return '❌ Error ${res.statusCode}: ${error['error']?['message'] ?? 'Unknown error'}';
      }
    } catch (e) {
      return '🌐 Koneksi gagal: $e';
    }
  }

  // ── Kirim pesan ───────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _inputCtrl.clear();
    _scrollToBottom();

    // Build messages untuk Groq
    final groqMessages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': 'Kamu adalah RDVSPAI, asisten AI yang cerdas, ramah, dan cepat. '
            'Jawab dalam bahasa Indonesia jika user pakai bahasa Indonesia. '
            'Gaya bahasa santai tapi informatif.'
      }
    ];
    
    for (final msg in _messages) {
      groqMessages.add({
        'role': msg['role'] == 'user' ? 'user' : 'assistant',
        'content': msg['text'],
      });
    }

    final reply = await _sendToGroq(groqMessages);

    setState(() {
      if (reply != null) {
        _messages.add({'role': 'model', 'text': reply});
      } else {
        _messages.add({
          'role': 'model',
          'text': '⚠️ Gagal terhubung ke Groq. Periksa koneksi internetmu.',
        });
      }
      _isLoading = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: const Color(0xFF130530),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryPurple, accentPurple],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('RDVSP AI',
                style: TextStyle(
                  color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.bold, fontFamily: 'Orbitron',
                )),
            Text('⚡ Powered by Groq',
                style: TextStyle(color: accentPurple, fontSize: 10,
                    fontFamily: 'ShareTechMono')),
          ]),
        ]),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white54),
              tooltip: 'Hapus Chat',
              onPressed: () => setState(() => _messages.clear()),
            ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == _messages.length) return _buildTypingIndicator();
                    final msg = _messages[i];
                    return _buildBubble(
                        text: msg['text']!, isUser: msg['role'] == 'user');
                  },
                ),
        ),
        _buildInputBar(),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryPurple.withOpacity(0.3), accentPurple.withOpacity(0.15)],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.auto_awesome, color: accentPurple, size: 44),
        ),
        const SizedBox(height: 20),
        const Text('RDVSP SIAP MELAYANI!',
            style: TextStyle(color: Colors.white, fontSize: 18,
                fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
        const SizedBox(height: 10),
        Text('⚡ Ultra-fast responses with Groq LPU',
            style: TextStyle(color: Colors.white38, fontSize: 13,
                fontFamily: 'ShareTechMono')),
        const SizedBox(height: 30),
        Wrap(
          spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
          children: [
            '💡 Ide konten TikTok',
            '🔐 Tips keamanan siber',
            '📱 Cara coding Flutter',
            '🤖 Apa itu AI?',
          ].map((hint) => GestureDetector(
                onTap: () {
                  _inputCtrl.text = hint.substring(3);
                  _sendMessage();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentPurple.withOpacity(0.4)),
                  ),
                  child: Text(hint,
                      style: TextStyle(color: accentPurple, fontSize: 12)),
                ),
              ))
              .toList(),
        ),
      ]),
    );
  }

  Widget _buildBubble({required String text, required bool isUser}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
            bottom: 10, left: isUser ? 60 : 0, right: isUser ? 0 : 60),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isUser
              ? LinearGradient(
                  colors: [primaryPurple, accentPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)
              : null,
          color: isUser ? null : const Color(0xFF1E0B35),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser
              ? null
              : Border.all(color: accentPurple.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: (isUser ? accentPurple : primaryPurple).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Icon(Icons.auto_awesome, color: accentPurple, size: 14),
                const SizedBox(width: 6),
              ],
              Flexible(
                  child: Text(text,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : Colors.white.withOpacity(0.9),
                        fontSize: 13.5,
                        height: 1.5,
                      ))),
            ]),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E0B35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentPurple.withOpacity(0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.auto_awesome, color: accentPurple, size: 14),
          const SizedBox(width: 8),
          SizedBox(
              width: 40,
              height: 16,
              child: _DotsIndicator(color: accentPurple)),
        ]),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF130530),
        border: Border(top: BorderSide(color: borderGlass)),
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E0B35),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accentPurple.withOpacity(0.35)),
            ),
            child: TextField(
              controller: _inputCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Tulis pesan...',
                hintStyle:
                    TextStyle(color: Colors.white30, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _sendMessage,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isLoading
                    ? [Colors.grey.shade700, Colors.grey.shade600]
                    : [primaryPurple, accentPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentPurple.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════
//  DOTS TYPING INDICATOR
// ════════════════════════════════════════════════════════
class _DotsIndicator extends StatefulWidget {
  final Color color;
  const _DotsIndicator({required this.color});
  @override
  State<_DotsIndicator> createState() => _DotsIndicatorState();
}

class _DotsIndicatorState extends State<_DotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (i) {
          final delay = i / 3;
          final val = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
          final opacity = (val < 0.5 ? val * 2 : (1 - val) * 2).clamp(0.2, 1.0);
          return Opacity(
            opacity: opacity,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                  color: widget.color, shape: BoxShape.circle),
            ),
          );
        }),
      ),
    );
  }
}
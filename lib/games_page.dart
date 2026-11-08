import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// DESIGN TOKENS
// ============================================================
class _C {
  static const bg       = Color(0xFF080810);
  static const surface  = Color(0xFF0F0F1A);
  static const card     = Color(0xFF13131F);
  static const border   = Color(0xFF1E1E30);

  static const neonPink   = Color(0xFFFF0066);
  static const neonGreen  = Color(0xFF00FFAA);
  static const neonBlue   = Color(0xFF00B4FF);
  static const neonPurple = Color(0xFF9B5DE5);
  static const neonYellow = Color(0xFFFFD600);
  static const neonOrange = Color(0xFFFF6B00);
  static const neonCyan   = Color(0xFF00E5FF);
  static const neonRed    = Color(0xFFFF1744);

  static const white  = Colors.white;
  static const white60 = Color(0x99FFFFFF);
  static const white30 = Color(0x4DFFFFFF);
  static const white10 = Color(0x1AFFFFFF);
}

// ============================================================
// REUSABLE WIDGETS
// ============================================================

/// Neon glowing border card
class _NeonCard extends StatelessWidget {
  final Color neon;
  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? radius;

  const _NeonCard({
    required this.neon,
    required this.child,
    this.padding,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: radius ?? BorderRadius.circular(16),
        border: Border.all(color: neon.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(color: neon.withOpacity(0.15), blurRadius: 20, spreadRadius: -2),
          BoxShadow(color: neon.withOpacity(0.06), blurRadius: 40, spreadRadius: 4),
        ],
      ),
      child: child,
    );
  }
}

/// Animated pulsing neon button
class _NeonButton extends StatefulWidget {
  final String label;
  final Color neon;
  final VoidCallback onTap;
  final IconData? icon;
  final bool dark;

  const _NeonButton({
    required this.label,
    required this.neon,
    required this.onTap,
    this.icon,
    this.dark = false,
  });

  @override
  State<_NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<_NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _glow = Tween(begin: 0.3, end: 0.7).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _glow,
        builder: (_, __) => Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: widget.dark ? widget.neon.withOpacity(0.08) : widget.neon,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.neon.withOpacity(0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: widget.neon.withOpacity(_glow.value * 0.5),
                  blurRadius: 18,
                  spreadRadius: -2),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon,
                    color: widget.dark ? widget.neon : Colors.black, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.dark ? widget.neon : Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Score chip
class _ScoreChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScoreChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace')),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: _C.white30,
                fontSize: 9,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

// ============================================================
// BASE GAME SCAFFOLD
// ============================================================
class _BaseGame extends StatelessWidget {
  final String title;
  final Color neon;
  final Widget body;
  final List<Widget>? actions;

  const _BaseGame(
      {required this.title,
      required this.neon,
      required this.body,
      this.actions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: neon, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: neon,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 3,
          ),
        ),
        actions: actions,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.transparent, neon, Colors.transparent]),
            ),
          ),
        ),
      ),
      body: body,
    );
  }
}

// ============================================================
// ENTRY POINT - GAMES HUB
// ============================================================
class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final games = [
      _GameDef('Number Guess',    'Tebak angka 1–100',              Icons.casino_rounded,          _C.neonPurple, const NumberGuessGame()),
      _GameDef('Reaction Time',   'Uji kecepatan reaksimu',         Icons.flash_on_rounded,        _C.neonGreen,  const ReactionGame()),
      _GameDef('Memory Card',     'Cocokkan kartu yang sama',       Icons.grid_view_rounded,       _C.neonBlue,   const MemoryCardGame()),
      _GameDef('Rock Paper Sc.',  'Lawan komputer',                 Icons.back_hand_rounded,       _C.neonPink,   const RPSGame()),
      _GameDef('Tap Counter',     'Tap sebanyak mungkin 10 detik',  Icons.touch_app_rounded,       _C.neonOrange, const TapCounterGame()),
      _GameDef('Math Quiz',       'Jawab soal matematika cepat',    Icons.calculate_rounded,       _C.neonCyan,   const MathQuizGame()),
      _GameDef('Tic Tac Toe',     'Duel X vs O klasik',             Icons.close_rounded,           _C.neonYellow, const TicTacToeGame()),
      _GameDef('Word Scramble',   'Susun huruf acak jadi kata',     Icons.sort_by_alpha_rounded,   _C.neonGreen,  const WordScrambleGame()),
      _GameDef('Simon Says',      'Ikuti urutan warna',             Icons.palette_rounded,         _C.neonPurple, const SimonSaysGame()),
      _GameDef('Higher or Lower', 'Tebak lebih tinggi/rendah',      Icons.trending_up_rounded,     _C.neonPink,   const HigherLowerGame()),
      _GameDef('Color Match',     'Cocokkan nama & warna',          Icons.color_lens_rounded,      _C.neonCyan,   const ColorMatchGame()),
      _GameDef('Whack a Mole',    'Pukul si tikus cepat!',          Icons.sports_mma_rounded,      _C.neonOrange, const WhackAMoleGame()),
      _GameDef('Coin Flip Streak','Tebak koin beruntun',            Icons.monetization_on_rounded, _C.neonYellow, const CoinFlipGame()),
      _GameDef('Type Racer',      'Ketik kalimat secepat mungkin',  Icons.keyboard_rounded,        _C.neonBlue,   const TypeRacerGame()),
      _GameDef('Binary Quiz',     'Konversi angka ke biner',        Icons.memory_rounded,          _C.neonRed,    const BinaryQuizGame()),
    ];

    return Scaffold(
      backgroundColor: _C.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── HEADER ──
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _C.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: _HubHeader(totalGames: games.length),
            ),
          ),

          // ── GRID ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _GameCard(def: games[i], onTap: () {
                  Navigator.push(ctx, _slideRoute(games[i].page));
                }),
                childCount: games.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

PageRoute _slideRoute(Widget page) => PageRouteBuilder(
      pageBuilder: (_, a, __) => page,
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 300),
    );

class _GameDef {
  final String title, desc;
  final IconData icon;
  final Color neon;
  final Widget page;
  const _GameDef(this.title, this.desc, this.icon, this.neon, this.page);
}

// ── HUB HEADER ──
class _HubHeader extends StatefulWidget {
  final int totalGames;
  const _HubHeader({required this.totalGames});
  @override
  State<_HubHeader> createState() => _HubHeaderState();
}

class _HubHeaderState extends State<_HubHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF120025), Color(0xFF080810), Color(0xFF001A30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Animated scanline
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Positioned(
              top: _ctrl.value * 200,
              left: 0, right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    _C.neonPurple.withOpacity(0.3),
                    _C.neonCyan.withOpacity(0.3),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),
          // Decorative blobs
          Positioned(top: -40, right: -40,
            child: Container(width: 180, height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: _C.neonPurple.withOpacity(0.06)))),
          Positioned(bottom: -30, left: -20,
            child: Container(width: 120, height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: _C.neonBlue.withOpacity(0.05)))),
          // Content
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 24, top: 70),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _C.neonPurple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.neonPurple.withOpacity(0.4), width: 1.5),
                      boxShadow: [BoxShadow(color: _C.neonPurple.withOpacity(0.25), blurRadius: 12)],
                    ),
                    child: const Icon(Icons.sports_esports_rounded, color: _C.neonPurple, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [_C.neonPurple, _C.neonCyan, _C.neonPink],
                      ).createShader(b),
                      child: const Text('ARCADE HUB',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        )),
                    ),
                    const SizedBox(height: 4),
                    Text('${widget.totalGames} GAMES TERSEDIA',
                      style: const TextStyle(
                        color: _C.white30,
                        fontSize: 11,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.bold,
                      )),
                  ]),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── GAME CARD ──
class _GameCard extends StatefulWidget {
  final _GameDef def;
  final VoidCallback onTap;
  const _GameCard({required this.def, required this.onTap});
  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _border;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1800 + Random().nextInt(1000)))
      ..repeat(reverse: true);
    _border = Tween(begin: 0.2, end: 0.6)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final d = widget.def;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _border,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: d.neon.withOpacity(_border.value), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: d.neon.withOpacity(_border.value * 0.25),
                  blurRadius: 16,
                  spreadRadius: -2),
            ],
          ),
          child: Stack(
            children: [
              // Corner glow
              Positioned(top: -10, right: -10,
                child: Container(width: 70, height: 70,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: d.neon.withOpacity(0.05)))),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon box
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: d.neon.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: d.neon.withOpacity(0.3), width: 1),
                        boxShadow: [BoxShadow(color: d.neon.withOpacity(0.2), blurRadius: 10)],
                      ),
                      child: Icon(d.icon, color: d.neon, size: 24),
                    ),
                    const Spacer(),
                    Text(d.title,
                      style: const TextStyle(
                        color: _C.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(d.desc,
                      style: const TextStyle(
                          color: _C.white30, fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    // PLAY tag
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: d.neon.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: d.neon.withOpacity(0.5), width: 1),
                        ),
                        child: Text('▶  PLAY',
                          style: TextStyle(
                            color: d.neon,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          )),
                      ),
                    ]),
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

// ============================================================
// GAME 1 — NUMBER GUESS
// ============================================================
class NumberGuessGame extends StatefulWidget {
  const NumberGuessGame({super.key});
  @override
  State<NumberGuessGame> createState() => _NumberGuessGameState();
}

class _NumberGuessGameState extends State<NumberGuessGame> {
  final _ctrl = TextEditingController();
  int _secret = Random().nextInt(100) + 1;
  int _attempts = 0;
  String _msg = 'Tebak angka antara 1 – 100';
  Color _msgColor = _C.white60;
  bool _won = false;
  final List<String> _history = [];

  void _guess() {
    final val = int.tryParse(_ctrl.text);
    if (val == null || val < 1 || val > 100) {
      setState(() { _msg = 'Masukkan angka valid (1–100)'; _msgColor = _C.neonOrange; });
      return;
    }
    _attempts++;
    if (val == _secret) {
      setState(() { _msg = '🎉 BENAR! Dalam $_attempts percobaan'; _msgColor = _C.neonGreen; _won = true; });
    } else if (val < _secret) {
      _history.insert(0, '$val  ↑  Terlalu kecil');
      setState(() { _msg = 'Terlalu kecil! Coba lebih besar ↑'; _msgColor = _C.neonCyan; });
    } else {
      _history.insert(0, '$val  ↓  Terlalu besar');
      setState(() { _msg = 'Terlalu besar! Coba lebih kecil ↓'; _msgColor = _C.neonRed; });
    }
    _ctrl.clear();
  }

  void _reset() {
    setState(() {
      _secret = Random().nextInt(100) + 1;
      _attempts = 0; _msg = 'Tebak angka antara 1 – 100';
      _msgColor = _C.white60; _won = false; _history.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _BaseGame(
      title: 'Number Guess', neon: _C.neonPurple,
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          _NeonCard(
            neon: _C.neonPurple,
            child: Column(children: [
              const Icon(Icons.casino_rounded, color: _C.neonPurple, size: 36),
              const SizedBox(height: 12),
              Text(_msg, style: TextStyle(color: _msgColor, fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text('PERCOBAAN: $_attempts', style: const TextStyle(color: _C.white30, fontSize: 11, letterSpacing: 2)),
            ]),
          ),
          const SizedBox(height: 20),
          if (!_won) ...[
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: _C.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '???',
                hintStyle: const TextStyle(color: _C.white10),
                filled: true, fillColor: _C.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _C.neonPurple, width: 2)),
              ),
              onSubmitted: (_) => _guess(),
            ),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity,
              child: _NeonButton(label: 'TEBAK', neon: _C.neonPurple, onTap: _guess)),
          ] else
            SizedBox(width: double.infinity,
              child: _NeonButton(label: 'MAIN LAGI', neon: _C.neonGreen, icon: Icons.refresh_rounded, onTap: _reset)),
          const SizedBox(height: 20),
          if (_history.isNotEmpty) ...[
            const Align(alignment: Alignment.centerLeft,
              child: Text('RIWAYAT', style: TextStyle(color: _C.white30, fontSize: 9, letterSpacing: 2.5, fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            Expanded(child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _history.length,
              itemBuilder: (_, i) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.border)),
                child: Text(_history[i], style: const TextStyle(color: _C.white60, fontSize: 13, fontFamily: 'monospace')),
              ),
            )),
          ],
        ]),
      ),
    );
  }
}

// ============================================================
// GAME 2 — REACTION TIME
// ============================================================
class ReactionGame extends StatefulWidget {
  const ReactionGame({super.key});
  @override
  State<ReactionGame> createState() => _ReactionGameState();
}

class _ReactionGameState extends State<ReactionGame> {
  String _state = 'idle';
  DateTime? _startTime;
  int _reactionMs = 0;
  Timer? _timer;
  final List<int> _scores = [];

  void _start() {
    setState(() => _state = 'waiting');
    _timer = Timer(Duration(milliseconds: 1500 + Random().nextInt(3000)), () {
      if (mounted) setState(() { _state = 'ready'; _startTime = DateTime.now(); });
    });
  }

  void _tap() {
    if (_state == 'idle') { _start(); return; }
    if (_state == 'waiting') {
      _timer?.cancel();
      setState(() => _state = 'idle');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Terlalu cepat! Tunggu warna hijau'), backgroundColor: _C.neonRed.withOpacity(0.9)));
      return;
    }
    if (_state == 'ready') {
      final ms = DateTime.now().difference(_startTime!).inMilliseconds;
      _scores.insert(0, ms);
      setState(() { _reactionMs = ms; _state = 'result'; });
    } else if (_state == 'result') {
      setState(() => _state = 'idle');
    }
  }

  String get _rating {
    if (_reactionMs < 150) return '⚡ LEGENDARY';
    if (_reactionMs < 250) return '🔥 SANGAT CEPAT';
    if (_reactionMs < 400) return '👍 BAGUS';
    return '🐢 Latihan lagi...';
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor; String label; Color neon;
    if (_state == 'idle') { bgColor = _C.surface; label = 'TAP UNTUK\nMULAI'; neon = _C.neonGreen; }
    else if (_state == 'waiting') { bgColor = const Color(0xFF1A0000); label = 'TUNGGU...'; neon = _C.neonRed; }
    else if (_state == 'ready') { bgColor = const Color(0xFF001A08); label = 'TAP\nSEKARANG!'; neon = _C.neonGreen; }
    else { bgColor = const Color(0xFF001530); label = '$_reactionMs ms\n$_rating\n\nTap lanjut'; neon = _C.neonBlue; }

    return _BaseGame(
      title: 'Reaction Time', neon: _C.neonGreen,
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          GestureDetector(
            onTap: _tap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 260,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: neon.withOpacity(0.5), width: 2),
                boxShadow: [BoxShadow(color: neon.withOpacity(0.2), blurRadius: 30)],
              ),
              child: Center(child: Text(label,
                style: TextStyle(color: neon, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2),
                textAlign: TextAlign.center)),
            ),
          ),
          const SizedBox(height: 20),
          if (_scores.isNotEmpty) ...[
            _NeonCard(neon: _C.neonGreen, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.emoji_events_rounded, color: _C.neonYellow, size: 20),
              const SizedBox(width: 8),
              Text('BEST: ${_scores.reduce(min)} ms',
                style: const TextStyle(color: _C.neonGreen, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
            ])),
            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerLeft,
              child: Text('RIWAYAT', style: TextStyle(color: _C.white30, fontSize: 9, letterSpacing: 2.5, fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            Expanded(child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _scores.length,
              itemBuilder: (_, i) {
                final isBest = _scores[i] == _scores.reduce(min) && i == _scores.lastIndexOf(_scores.reduce(min));
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.border)),
                  child: Row(children: [
                    Text('#${i + 1}', style: const TextStyle(color: _C.white30, fontSize: 11, fontFamily: 'monospace')),
                    const SizedBox(width: 12),
                    Text('${_scores[i]} ms', style: const TextStyle(color: _C.white, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    const Spacer(),
                    if (isBest) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _C.neonGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                      child: const Text('BEST', style: TextStyle(color: _C.neonGreen, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    ),
                  ]),
                );
              },
            )),
          ],
        ]),
      ),
    );
  }
}

// ============================================================
// GAME 3 — MEMORY CARD
// ============================================================
class MemoryCardGame extends StatefulWidget {
  const MemoryCardGame({super.key});
  @override
  State<MemoryCardGame> createState() => _MemoryCardGameState();
}

class _MemoryCardGameState extends State<MemoryCardGame> {
  final _emojis = ['🎮', '🎯', '🎲', '🃏', '🎸', '🎺', '🎭', '🏆'];
  late List<String> _cards;
  late List<bool> _flipped;
  late List<bool> _matched;
  int? _first;
  bool _lock = false;
  int _moves = 0, _pairs = 0;

  @override
  void initState() { super.initState(); _init(); }

  void _init() {
    _cards = [..._emojis, ..._emojis]..shuffle();
    _flipped = List.filled(16, false);
    _matched = List.filled(16, false);
    _first = null; _lock = false; _moves = 0; _pairs = 0;
  }

  void _tap(int i) async {
    if (_lock || _flipped[i] || _matched[i]) return;
    setState(() => _flipped[i] = true);
    if (_first == null) { _first = i; return; }
    _moves++;
    if (_cards[_first!] == _cards[i]) {
      setState(() { _matched[_first!] = true; _matched[i] = true; _pairs++; _first = null; });
    } else {
      _lock = true;
      await Future.delayed(const Duration(milliseconds: 700));
      setState(() { _flipped[_first!] = false; _flipped[i] = false; _first = null; _lock = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BaseGame(
      title: 'Memory Card', neon: _C.neonBlue,
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _ScoreChip(label: 'MOVES', value: '$_moves', color: _C.neonBlue),
            _ScoreChip(label: 'PAIRS', value: '$_pairs/8', color: _C.neonBlue),
            GestureDetector(
              onTap: () => setState(_init),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _C.neonBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.neonBlue.withOpacity(0.4)),
                ),
                child: const Row(children: [
                  Icon(Icons.refresh_rounded, color: _C.neonBlue, size: 14),
                  SizedBox(width: 6),
                  Text('RESET', style: TextStyle(color: _C.neonBlue, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          if (_pairs == 8)
            _NeonCard(neon: _C.neonGreen, padding: const EdgeInsets.all(12),
              child: Text('🎉 SELESAI DALAM $_moves LANGKAH!',
                style: const TextStyle(color: _C.neonGreen, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                textAlign: TextAlign.center)),
          const SizedBox(height: 10),
          Expanded(child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: 16,
            itemBuilder: (_, i) {
              final isFlipped = _flipped[i] || _matched[i];
              return GestureDetector(
                onTap: () => _tap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: _matched[i] ? _C.neonBlue.withOpacity(0.12) : isFlipped ? _C.surface : _C.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _matched[i] ? _C.neonBlue.withOpacity(0.6) : isFlipped ? _C.neonBlue.withOpacity(0.3) : _C.border),
                    boxShadow: _matched[i] ? [BoxShadow(color: _C.neonBlue.withOpacity(0.2), blurRadius: 8)] : [],
                  ),
                  child: Center(child: Text(
                    isFlipped ? _cards[i] : '?',
                    style: TextStyle(fontSize: isFlipped ? 24 : 20,
                      color: isFlipped ? _C.white : _C.white10),
                  )),
                ),
              );
            },
          )),
        ]),
      ),
    );
  }
}

// ============================================================
// GAME 4 — ROCK PAPER SCISSORS
// ============================================================
class RPSGame extends StatefulWidget {
  const RPSGame({super.key});
  @override
  State<RPSGame> createState() => _RPSGameState();
}

class _RPSGameState extends State<RPSGame> {
  final _choices = ['✊', '✋', '✌️'];
  final _labels = ['BATU', 'KERTAS', 'GUNTING'];
  String _player = '', _cpu = '', _result = '';
  int _wins = 0, _losses = 0, _draws = 0;

  void _play(int i) {
    final cpu = Random().nextInt(3);
    String res;
    if (i == cpu) res = 'SERI';
    else if ((i == 0 && cpu == 2) || (i == 1 && cpu == 0) || (i == 2 && cpu == 1)) { res = 'MENANG'; _wins++; }
    else { res = 'KALAH'; _losses++; }
    if (res == 'SERI') _draws++;
    setState(() { _player = _choices[i]; _cpu = _choices[cpu]; _result = res; });
  }

  Color get _rc {
    if (_result == 'MENANG') return _C.neonGreen;
    if (_result == 'KALAH') return _C.neonRed;
    return _C.neonYellow;
  }

  @override
  Widget build(BuildContext context) {
    return _BaseGame(
      title: 'Rock Paper Scissors', neon: _C.neonPink,
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _ScoreChip(label: 'MENANG', value: '$_wins', color: _C.neonGreen),
            _ScoreChip(label: 'SERI', value: '$_draws', color: _C.neonYellow),
            _ScoreChip(label: 'KALAH', value: '$_losses', color: _C.neonRed),
          ]),
          const SizedBox(height: 28),
          _NeonCard(neon: _result.isEmpty ? _C.border : _rc, child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _buildDisplay(_player.isEmpty ? '❓' : _player, 'KAMU', _C.neonPink),
              Column(children: [
                Text('VS', style: TextStyle(color: _C.white30, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
                if (_result.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: _rc.withOpacity(0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: _rc.withOpacity(0.5))),
                    child: Text(_result, style: TextStyle(color: _rc, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
                  ),
                ]
              ]),
              _buildDisplay(_cpu.isEmpty ? '❓' : _cpu, 'CPU', _C.neonBlue),
            ]),
          ),
          const SizedBox(height: 30),
          const Text('PILIH SENJATAMU', style: TextStyle(color: _C.white30, fontSize: 10, letterSpacing: 3)),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (i) => GestureDetector(
              onTap: () => _play(i),
              child: Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.neonPink.withOpacity(0.3), width: 1.5),
                  boxShadow: [BoxShadow(color: _C.neonPink.withOpacity(0.1), blurRadius: 12)],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_choices[i], style: const TextStyle(fontSize: 34)),
                  const SizedBox(height: 4),
                  Text(_labels[i], style: const TextStyle(color: _C.white30, fontSize: 9, letterSpacing: 1)),
                ]),
              ),
            )),
          ),
        ]),
      ),
    );
  }

  Widget _buildDisplay(String emoji, String lbl, Color c) {
    return Column(children: [
      Container(width: 72, height: 72,
        decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle,
          border: Border.all(color: c.withOpacity(0.4), width: 2),
          boxShadow: [BoxShadow(color: c.withOpacity(0.15), blurRadius: 12)]),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 32)))),
      const SizedBox(height: 6),
      Text(lbl, style: const TextStyle(color: _C.white30, fontSize: 9, letterSpacing: 2)),
    ]);
  }
}

// ============================================================
// GAME 5 — TAP COUNTER
// ============================================================
class TapCounterGame extends StatefulWidget {
  const TapCounterGame({super.key});
  @override
  State<TapCounterGame> createState() => _TapCounterGameState();
}

class _TapCounterGameState extends State<TapCounterGame> {
  int _count = 0, _timeLeft = 10, _best = 0;
  bool _running = false, _done = false;
  Timer? _timer;

  void _start() {
    setState(() { _count = 0; _timeLeft = 10; _running = true; _done = false; });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() { _timeLeft--; });
      if (_timeLeft <= 0) {
        t.cancel();
        if (_count > _best) _best = _count;
        setState(() { _running = false; _done = true; });
      }
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _BaseGame(
      title: 'Tap Counter', neon: _C.neonOrange,
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _ScoreChip(label: 'WAKTU', value: '${_timeLeft}s', color: _timeLeft <= 3 ? _C.neonRed : _C.neonOrange),
            _ScoreChip(label: 'BEST', value: '$_best', color: _C.neonYellow),
          ]),
          const SizedBox(height: 20),
          Text('$_count', style: const TextStyle(color: _C.white, fontSize: 90, fontWeight: FontWeight.w900, fontFamily: 'monospace', height: 1)),
          const Text('TAPS', style: TextStyle(color: _C.white30, fontSize: 12, letterSpacing: 3)),
          const SizedBox(height: 20),
          if (_done) _NeonCard(neon: _C.neonOrange, child:
            Text(_count >= _best && _best > 0 ? '🏆 REKOR BARU! $_count taps!' : '✨ Kamu berhasil $_count taps!',
              style: const TextStyle(color: _C.white, fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          const SizedBox(height: 20),
          if (!_running)
            SizedBox(width: double.infinity,
              child: _NeonButton(label: _done ? 'MAIN LAGI' : 'MULAI', neon: _C.neonOrange, onTap: _start))
          else ...[
            const Spacer(),
            GestureDetector(
              onTap: () { if (_running) setState(() => _count++); },
              child: Container(
                width: 210, height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [_C.neonOrange.withOpacity(0.2), Colors.transparent]),
                  border: Border.all(color: _C.neonOrange, width: 3),
                  boxShadow: [BoxShadow(color: _C.neonOrange.withOpacity(0.3), blurRadius: 30)],
                ),
                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.touch_app_rounded, color: _C.neonOrange, size: 52),
                  SizedBox(height: 8),
                  Text('TAP!', style: TextStyle(color: _C.neonOrange, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3)),
                ]),
              ),
            ),
            const Spacer(),
          ],
        ]),
      ),
    );
  }
}

// ============================================================
// GAME 6 — MATH QUIZ
// ============================================================
class MathQuizGame extends StatefulWidget {
  const MathQuizGame({super.key});
  @override
  State<MathQuizGame> createState() => _MathQuizGameState();
}

class _MathQuizGameState extends State<MathQuizGame> {
  final _rng = Random();
  late int _a, _b, _correct;
  late String _op;
  late List<int> _options;
  int _score = 0, _timeLeft = 15, _streak = 0, _bestStreak = 0;
  Timer? _timer;
  bool _started = false, _answered = false;
  int? _chosen;

  @override
  void initState() { super.initState(); _newQ(); }

  void _newQ() {
    final ops = ['+', '-', '×'];
    _op = ops[_rng.nextInt(3)];
    _a = _rng.nextInt(20) + 1; _b = _rng.nextInt(20) + 1;
    if (_op == '+') _correct = _a + _b;
    else if (_op == '-') _correct = _a - _b;
    else _correct = _a * _b;
    final Set<int> opts = {_correct};
    while (opts.length < 4) opts.add(_correct + _rng.nextInt(21) - 10);
    _options = opts.toList()..shuffle();
    _answered = false; _chosen = null;
  }

  void _start() {
    _score = 0; _streak = 0; _timeLeft = 15;
    setState(() { _started = true; _newQ(); });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() { _timeLeft--; });
      if (_timeLeft <= 0) { t.cancel(); setState(() => _started = false); }
    });
  }

  void _answer(int val) {
    if (_answered || !_started) return;
    _answered = true; _chosen = val;
    if (val == _correct) { _score++; _streak++; if (_streak > _bestStreak) _bestStreak = _streak; }
    else _streak = 0;
    setState(() {});
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted && _started) setState(_newQ);
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _BaseGame(
      title: 'Math Quiz', neon: _C.neonCyan,
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _ScoreChip(label: 'SKOR', value: '$_score', color: _C.neonCyan),
            _ScoreChip(label: 'WAKTU', value: '${_timeLeft}s', color: _timeLeft <= 5 ? _C.neonRed : _C.neonCyan),
            _ScoreChip(label: 'STREAK', value: '🔥$_streak', color: _C.neonOrange),
          ]),
          const SizedBox(height: 24),
          if (!_started) Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_score > 0) ...[
              Text('SKOR: $_score', style: const TextStyle(color: _C.white, fontSize: 30, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
              Text('BEST STREAK: $_bestStreak 🔥', style: const TextStyle(color: _C.white30, fontSize: 14)),
              const SizedBox(height: 28),
            ] else
              const Icon(Icons.calculate_rounded, color: _C.neonCyan, size: 56),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity,
              child: _NeonButton(label: _score > 0 ? 'MAIN LAGI' : 'MULAI', neon: _C.neonCyan, onTap: _start)),
          ]))
          else ...[
            _NeonCard(neon: _C.neonCyan,
              child: Text('$_a  $_op  $_b  = ?',
                style: const TextStyle(color: _C.white, fontSize: 36, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                textAlign: TextAlign.center)),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true, crossAxisCount: 2,
              crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.2,
              children: _options.map((opt) {
                Color bc = _C.border, bg = _C.surface;
                if (_answered && _chosen == opt) {
                  bc = opt == _correct ? _C.neonGreen : _C.neonRed;
                  bg = (opt == _correct ? _C.neonGreen : _C.neonRed).withOpacity(0.12);
                } else if (_answered && opt == _correct) {
                  bc = _C.neonGreen; bg = _C.neonGreen.withOpacity(0.12);
                }
                return GestureDetector(
                  onTap: () => _answer(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: bc, width: 1.5)),
                    child: Center(child: Text('$opt',
                      style: const TextStyle(color: _C.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'monospace'))),
                  ),
                );
              }).toList(),
            ),
          ],
        ]),
      ),
    );
  }
}

// ============================================================
// GAME 7 — TIC TAC TOE
// ============================================================
class TicTacToeGame extends StatefulWidget {
  const TicTacToeGame({super.key});
  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  List<String> _board = List.filled(9, '');
  bool _xTurn = true;
  String _status = "GILIRAN X";
  bool _over = false;
  int _xWins = 0, _oWins = 0, _draws = 0;

  static const _wins = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];

  void _tap(int i) {
    if (_board[i].isNotEmpty || _over) return;
    _board[i] = _xTurn ? 'X' : 'O';
    final winner = _checkWinner();
    if (winner != null) {
      _status = '$winner MENANG! 🎉';
      _over = true;
      winner == 'X' ? _xWins++ : _oWins++;
    } else if (!_board.contains('')) {
      _status = 'SERI!';
      _over = true;
      _draws++;
    } else {
      _xTurn = !_xTurn;
      _status = 'GILIRAN ${_xTurn ? "X" : "O"}';
    }
    setState(() {});
  }

  String? _checkWinner() {
    for (final w in _wins) {
      if (_board[w[0]].isNotEmpty && _board[w[0]] == _board[w[1]] && _board[w[1]] == _board[w[2]]) {
        return _board[w[0]];
      }
    }
    return null;
  }

  void _reset() {
    setState(() { _board = List.filled(9, ''); _xTurn = true; _status = 'GILIRAN X'; _over = false; });
  }

  @override
  Widget build(BuildContext context) {
    return _BaseGame(
      title: 'Tic Tac Toe', neon: _C.neonYellow,
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _ScoreChip(label: 'X MENANG', value: '$_xWins', color: _C.neonCyan),
            _ScoreChip(label: 'SERI', value: '$_draws', color: _C.neonYellow),
            _ScoreChip(label: 'O MENANG', value: '$_oWins', color: _C.neonPink),
          ]),
          const SizedBox(height: 16),
          _NeonCard(neon: _C.neonYellow, padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Text(_status, style: const TextStyle(color: _C.neonYellow, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2),
              textAlign: TextAlign.center)),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: 9,
              itemBuilder: (_, i) {
                final cell = _board[i];
                final color = cell == 'X' ? _C.neonCyan : _C.neonPink;
                return GestureDetector(
                  onTap: () => _tap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: cell.isEmpty ? _C.surface : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cell.isEmpty ? _C.border : color.withOpacity(0.6), width: 1.5),
                      boxShadow: cell.isNotEmpty ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)] : [],
                    ),
                    child: Center(child: Text(cell,
                      style: TextStyle(color: color, fontSize: 40, fontWeight: FontWeight.w900))),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity,
            child: _NeonButton(label: 'RESET', neon: _C.neonYellow, icon: Icons.refresh_rounded, dark: true, onTap: _reset)),
        ]),
      ),
    );
  }
}

// ============================================================
// GAME 8 — WORD SCRAMBLE
// ============================================================
class WordScrambleGame extends StatefulWidget {
  const WordScrambleGame({super.key});
  @override
  State<WordScrambleGame> createState() => _WordScrambleGameState();
}

class _WordScrambleGameState extends State<WordScrambleGame> {
  final _words = ['FLUTTER', 'ANDROID', 'PYTHON', 'KOTLIN', 'DESIGN',
    'ARCADE', 'ROCKET', 'MATRIX', 'VECTOR', 'TURBO'];
  final _ctrl = TextEditingController();
  late String _word, _scrambled;
  int _score = 0, _hints = 3;
  String _msg = '';
  Color _msgColor = _C.white60;

  @override
  void initState() { super.initState(); _next(); }

  void _next() {
    _word = _words[Random().nextInt(_words.length)];
    final chars = _word.split('')..shuffle();
    _scrambled = chars.join();
    _ctrl.clear();
    _msg = '';
    setState(() {});
  }

  void _check() {
    if (_ctrl.text.toUpperCase() == _word) {
      _score++;
      setState(() { _msg = '✅ BENAR! +1'; _msgColor = _C.neonGreen; });
      Future.delayed(const Duration(milliseconds: 600), _next);
    } else {
      setState(() { _msg = '❌ SALAH! Coba lagi'; _msgColor = _C.neonRed; });
    }
    _ctrl.clear();
  }

  void _hint() {
    if (_hints <= 0) return;
    _hints--;
    setState(() { _msg = '💡 Huruf pertama: ${_word[0]}'; _msgColor = _C.neonYellow; });
  }

  @override
  Widget build(BuildContext context) {
    return _BaseGame(
      title: 'Word Scramble', neon: _C.neonGreen,
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _ScoreChip(label: 'SKOR', value: '$_score', color: _C.neonGreen),
            _ScoreChip(label: 'HINTS', value: '$_hints', color: _C.neonYellow),
          ]),
          const SizedBox(height: 28),
          _NeonCard(neon: _C.neonGreen,
            child: Column(children: [
              const Text('SUSUN HURUF INI:', style: TextStyle(color: _C.white30, fontSize: 10, letterSpacing: 2)),
              const SizedBox(height: 14),
              Text(_scrambled, style: const TextStyle(
                color: _C.neonGreen, fontSize: 34, fontWeight: FontWeight.w900,
                letterSpacing: 8, fontFamily: 'monospace')),
              if (_msg.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_msg, style: TextStyle(color: _msgColor, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ]),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: _C.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 4, fontFamily: 'monospace'),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Ketik jawaban...',
              hintStyle: const TextStyle(color: _C.white10),
              filled: true, fillColor: _C.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _C.neonGreen, width: 2)),
            ),
            onSubmitted: (_) => _check(),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _NeonButton(label: 'CEK', neon: _C.neonGreen, onTap: _check)),
            const SizedBox(width: 10),
            Expanded(child: _NeonButton(label: 'HINT', neon: _C.neonYellow, dark: true, icon: Icons.lightbulb_outline, onTap: _hint)),
            const SizedBox(width: 10),
            Expanded(child: _NeonButton(label: 'SKIP', neon: _C.neonRed, dark: true, onTap: _next)),
          ]),
        ]),
      ),
    );
  }
}

// ============================================================
// GAME 9 — SIMON SAYS
// ============================================================
class SimonSaysGame extends StatefulWidget {
  const SimonSaysGame({super.key});
  @override
  State<SimonSaysGame> createState() => _SimonSaysGameState();
}

class _SimonSaysGameState extends State<SimonSaysGame> {
  final _colors = [_C.neonRed, _C.neonBlue, _C.neonGreen, _C.neonYellow];
  final _icons = [Icons.arrow_upward_rounded, Icons.arrow_back_rounded, Icons.arrow_downward_rounded, Icons.arrow_forward_rounded];
  List<int> _seq = [];
  int _playerIdx = 0;
  bool _showing = false, _started = false, _over = false;
  int _lit = -1;
  int _best = 0;

  Future<void> _startSeq() async {
    _seq.add(Random().nextInt(4));
    setState(() { _showing = true; _lit = -1; });
    await Future.delayed(const Duration(milliseconds: 600));
    for (final s in _seq) {
      setState(() => _lit = s);
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _lit = -1);
      await Future.delayed(const Duration(milliseconds: 300));
    }
    setState(() { _showing = false; _playerIdx = 0; });
  }

  void _tap(int i) async {
    if (_showing || !_started || _over) return;
    if (i == _seq[_playerIdx]) {
      _playerIdx++;
      if (_playerIdx == _seq.length) {
        if (_seq.length > _best) _best = _seq.length;
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 500));
        _startSeq();
      }
    } else {
      setState(() { _over = true; _started = false; });
    }
  }

  void _start() {
    _seq = []; _playerIdx = 0; _over = false;
    setState(() => _started = true);
    _startSeq();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseGame(
      title: 'Simon Says', neon: _C.neonPurple,
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _ScoreChip(label: 'LEVEL', value: '${_seq.length}', color: _C.neonPurple),
            _ScoreChip(label: 'BEST', value: '$_best', color: _C.neonYellow),
          ]),
          const SizedBox(height: 16),
          _NeonCard(neon: _C.neonPurple, padding: const EdgeInsets.all(10),
            child: Text(
              _over ? '💀 GAME OVER! Level ${_seq.length}' :
              _showing ? '👀 PERHATIKAN...' :
              _started ? '🎮 GILIRANMU!' : 'IKUTI URUTAN WARNA',
              style: const TextStyle(color: _C.neonPurple, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5),
              textAlign: TextAlign.center)),
          const SizedBox(height: 28),
          GridView.count(
            shrinkWrap: true, crossAxisCount: 2,
            crossAxisSpacing: 12, mainAxisSpacing: 12,
            children: List.generate(4, (i) {
              final isLit = _lit == i;
              return GestureDetector(
                onTap: () => _tap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isLit ? _colors[i].withOpacity(0.4) : _colors[i].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _colors[i].withOpacity(isLit ? 0.9 : 0.3), width: 2),
                    boxShadow: isLit ? [BoxShadow(color: _colors[i].withOpacity(0.5), blurRadius: 24)] : [],
                  ),
                  child: Icon(_icons[i], color: _colors[i].withOpacity(isLit ? 1.0 : 0.5), size: 40),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          if (!_started)
            SizedBox(width: double.infinity,
              child: _NeonButton(label: _over ? 'MAIN LAGI' : 'MULAI', neon: _C.neonPurple, onTap: _start)),
        ]),
      ),
    );
  }
}

// ============================================================
// GAME 10 — HIGHER OR LOWER
// ============================================================
class HigherLowerGame extends StatefulWidget {
  const HigherLowerGame({super.key});
  @override
  State<HigherLowerGame> createState() => _HigherLowerGameState();
}

class _HigherLowerGameState extends State<HigherLowerGame> {
  final _rng = Random();
  int _current = 0, _next = 0, _score = 0, _best = 0;
  bool _started = false, _over = false;
  String _msg = '';
  Color _msgColor = _C.white60;

  void _start() {
    _current = _rng.nextInt(100) + 1;
    _next = _rng.nextInt(100) + 1;
    _score = 0; _over = false; _msg = '';
    setState(() => _started = true);
  }

  void _guess(bool higher) {
    final correct = higher ? _next > _current : _next <= _current;
    if (correct) {
      _score++;
      if (_score > _best) _best = _score;
      _current = _next;
      _next = _rng.nextInt(100) + 1;
      setState(() { _msg = '✅ BENAR! +1'; _msgColor = _C.neonGreen; });
    } else {
      setState(() { _over = true; _started = false; _msg = '❌ SALAH! Skor: $_score'; _msgColor = _C.neonRed; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BaseGame(
      title: 'Higher or Lower', neon: _C.neonPink,
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _ScoreChip(label: 'SKOR', value: '$_score', color: _C.neonPink),
            _ScoreChip(label: 'BEST', value: '$_best', color: _C.neonYellow),
          ]),
          const SizedBox(height: 28),
          if (!_started && !_over)
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.trending_up_rounded, color: _C.neonPink, size: 64),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity,
                child: _NeonButton(label: 'MULAI', neon: _C.neonPink, onTap: _start)),
            ]))
          else ...[
            _NeonCard(neon: _C.neonPink, child: Column(children: [
              const Text('ANGKA SEKARANG', style: TextStyle(color: _C.white30, fontSize: 10, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text('$_current', style: const TextStyle(color: _C.white, fontSize: 64, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
            ])),
            const SizedBox(height: 20),
            _NeonCard(neon: _C.border, child: Column(children: [
              const Text('ANGKA BERIKUTNYA', style: TextStyle(color: _C.white30, fontSize: 10, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text(_over ? '$_next' : '???',
                style: TextStyle(color: _over ? _C.neonRed : _C.white30, fontSize: 48, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
            ])),
            const SizedBox(height: 16),
            if (_msg.isNotEmpty)
              Text(_msg, style: TextStyle(color: _msgColor, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (!_over) Row(children: [
              Expanded(child: _NeonButton(label: '▲  HIGHER', neon: _C.neonGreen, onTap: () => _guess(true))),
              const SizedBox(width: 12),
              Expanded(child: _NeonButton(label: '▼  LOWER', neon: _C.neonRed, onTap: () => _guess(false))),
            ]) else
              SizedBox(width: double.infinity,
                child: _NeonButton(label: 'MAIN LAGI', neon: _C.neonPink, icon: Icons.refresh_rounded, onTap: _start)),
          ],
        ]),
      ),
    );
  }
}

// ============================================================
// GAME 11 — COLOR MATCH (nama warna vs warna teks)
// ============================================================
class ColorMatchGame extends StatefulWidget {
  const ColorMatchGame({super.key});
  @override
  State<ColorMatchGame> createState() => _ColorMatchGameState();
}

class _ColorMatchGameState extends State<ColorMatchGame> {
  final _rng = Random();
  final _colorDefs = {
    'MERAH':   _C.neonRed,
    'BIRU':    _C.neonBlue,
    'HIJAU':   _C.neonGreen,
    'KUNING':  _C.neonYellow,
    'UNGU':    _C.neonPurple,
    'CYAN':    _C.neonCyan,
  };
  late String _displayWord, _displayColor;
  late bool _isMatch;
  int _score = 0, _timeLeft = 30, _best = 0;
  Timer? _timer;
  bool _started = false;
  String _feedback = '';
  Color _feedbackColor = _C.white60;

  void _nextQ() {
    final keys = _colorDefs.keys.toList();
    _displayWord = keys[_rng.nextInt(keys.length)];
    final colorKey = keys[_rng.nextInt(keys.length)];
    _displayColor = colorKey;
    _isMatch = _displayWord == _displayColor;
    setState(() {});
  }

  void _start() {
    _score = 0; _timeLeft = 30; _feedback = '';
    setState(() => _started = true);
    _nextQ();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        t.cancel();
        if (_score > _best) _best = _score;
        setState(() => _started = false);
      }
    });
  }

  void _answer(bool match) {
    if (!_started) return;
    if (match == _isMatch) {
      _score++;
      setState(() { _feedback = '✅'; _feedbackColor = _C.neonGreen; });
    } else {
      setState(() { _feedback = '❌'; _feedbackColor = _C.neonRed; });
    }
    Future.delayed(const Duration(milliseconds: 300), _nextQ);
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _BaseGame(
      title: 'Color Match', neon: _C.neonCyan,
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _ScoreChip(label: 'SKOR', value: '$_score', color: _C.neonCyan),
            _ScoreChip(label: 'WAKTU', value: '${_timeLeft}s', color: _timeLeft <= 10 ? _C.neonRed : _C.neonCyan),
            _ScoreChip(label: 'BEST', value: '$_best', color: _C.neonYellow),
          ]),
          const SizedBox(height: 24),
          if (!_started)
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.color_lens_rounded, color: _C.neonCyan, size: 56),
              const SizedBox(height: 14),
              const Text('Apakah NAMA = WARNA teks?', style: TextStyle(color: _C.white60, fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity,
                child: _NeonButton(label: _score > 0 ? 'MAIN LAGI' : 'MULAI', neon: _C.neonCyan, onTap: _start)),
            ]))
          else ...[
            const Spacer(),
            _NeonCard(neon: _C.neonCyan, child: Column(children: [
              const Text('APAKAH NAMA = WARNA TEKS?', style: TextStyle(color: _C.white30, fontSize: 10, letterSpacing: 2)),
              const SizedBox(height: 20),
              Text(_displayWord,
                style: TextStyle(color: _colorDefs[_displayColor], fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 4)),
              const SizedBox(height: 16),
              if (_feedback.isNotEmpty)
                Text(_feedback, style: TextStyle(color: _feedbackColor, fontSize: 24)),
            ])),
            const Spacer(),
            Row(children: [
              Expanded(child: _NeonButton(label: '✓  YA', neon: _C.neonGreen, onTap: () => _answer(true))),
              const SizedBox(width: 12),
              Expanded(child: _NeonButton(label: '✕  TIDAK', neon: _C.neonRed, onTap: () => _answer(false))),
            ]),
          ],
        ]),
      ),
    );
  }
}

// ============================================================
// GAME 12 — WHACK A MOLE
// ============================================================
class WhackAMoleGame extends StatefulWidget {
  const WhackAMoleGame({super.key});
  @override
  State<WhackAMoleGame> createState() => _WhackAMoleGameState();
}

class _WhackAMoleGameState extends State<WhackAMoleGame> {
  int _active = -1, _score = 0, _miss = 0, _timeLeft = 30, _best = 0;
  Timer? _gameTimer, _moleTimer;
  bool _started = false;

  void _start() {
    _score = 0; _miss = 0; _timeLeft = 30; _active = -1;
    setState(() => _started = true);
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        t.cancel(); _moleTimer?.cancel();
        if (_score > _best) _best = _score;
        setState(() { _started = false; _active = -1; });
      }
    });
    _spawnMole();
  }

  void _spawnMole() {
    _moleTimer?.cancel();
    final delay = (600 + max(0, (15 - _score) * 30)).toInt();
    _moleTimer = Timer(Duration(milliseconds: delay), () {
      if (!_started) return;
      setState(() => _active = Random().nextInt(9));
      _moleTimer = Timer(const Duration(milliseconds: 900), () {
        if (_started && _active != -1) setState(() { _miss++; _active = -1; });
        if (_started) _spawnMole();
      });
    });
  }

  void _whack(int i) {
    if (!_started || _active != i) return;
    _moleTimer?.cancel();
    _score++;
    setState(() => _active = -1);
    HapticFeedback.mediumImpact();
    _spawnMole();
  }

  @override
  void dispose() { _gameTimer?.cancel(); _moleTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _BaseGame(
      title: 'Whack A Mole', neon: _C.neonOrange,
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _ScoreChip(label: 'SKOR', value: '$_score', color: _C.neonOrange),
            _ScoreChip(label: 'MISS', value: '$_miss', color: _C.neonRed),
            _ScoreChip(label: 'WAKTU', value: '${_timeLeft}s', color: _timeLeft <= 10 ? _C.neonRed : _C.neonOrange),
            _ScoreChip(label: 'BEST', value: '$_best', color: _C.neonYellow),
          ]),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: 9,
              itemBuilder: (_, i) {
                final isActive = _active == i;
                return GestureDetector(
                  onTap: () => _whack(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isActive ? _C.neonOrange.withOpacity(0.15) : _C.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isActive ? _C.neonOrange.withOpacity(0.8) : _C.border, width: isActive ? 2 : 1),
                      boxShadow: isActive ? [BoxShadow(color: _C.neonOrange.withOpacity(0.3), blurRadius: 16)] : [],
                    ),
                    child: Center(child: Text(isActive ? '🐭' : '⬛', style: const TextStyle(fontSize: 32))),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (!_started)
            SizedBox(width: double.infinity,
              child: _NeonButton(label: _score > 0 ? 'MAIN LAGI' : 'MULAI', neon: _C.neonOrange, onTap: _start)),
        ]),
      ),
    );
  }
}

// ============================================================
// GAME 13 — COIN FLIP STREAK
// ============================================================
class CoinFlipGame extends StatefulWidget {
  const CoinFlipGame({super.key});
  @override
  State<CoinFlipGame> createState() => _CoinFlipGameState();
}

class _CoinFlipGameState extends State<CoinFlipGame> {
  String _result = '';
  int _streak = 0, _best = 0;
  bool _flipping = false;

  void _flip(bool heads) async {
    setState(() => _flipping = true);
    await Future.delayed(const Duration(milliseconds: 600));
    final landed = Random().nextBool();
    final correct = heads == landed;
    if (correct) {
      _streak++;
      if (_streak > _best) _best = _streak;
    } else {
      _streak = 0;
    }
    setState(() {
      _result = '${landed ? "HEADS 🪙" : "TAILS 💿"}  •  ${correct ? "BENAR ✅" : "SALAH ❌"}';
      _flipping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _BaseGame(
      title: 'Coin Flip Streak', neon: _C.neonYellow,
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _ScoreChip(label: 'STREAK', value: '$_streak', color: _C.neonYellow),
            _ScoreChip(label: 'BEST', value: '$_best', color: _C.neonOrange),
          ]),
          const SizedBox(height: 32),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.surface,
              border: Border.all(color: _C.neonYellow.withOpacity(_flipping ? 0.8 : 0.3), width: 3),
              boxShadow: [BoxShadow(color: _C.neonYellow.withOpacity(_flipping ? 0.4 : 0.1), blurRadius: 30)],
            ),
            width: 180,
            child: Center(child: Text(_flipping ? '🌀' : (_result.isEmpty ? '🪙' : (_result.contains('HEADS') ? '🪙' : '💿')),
              style: const TextStyle(fontSize: 70))),
          ),
          const SizedBox(height: 24),
          if (_result.isNotEmpty)
            _NeonCard(neon: _C.neonYellow, padding: const EdgeInsets.all(12),
              child: Text(_result, style: const TextStyle(color: _C.neonYellow, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
          const Spacer(),
          const Text('TEBAK HASIL KOIN', style: TextStyle(color: _C.white30, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _NeonButton(label: '🪙  HEADS', neon: _C.neonYellow, onTap: () => _flipping ? null : _flip(true))),
            const SizedBox(width: 12),
            Expanded(child: _NeonButton(label: '💿  TAILS', neon: _C.neonOrange, onTap: () => _flipping ? null : _flip(false))),
          ]),
        ]),
      ),
    );
  }
}

// ============================================================
// GAME 14 — TYPE RACER
// ============================================================
class TypeRacerGame extends StatefulWidget {
  const TypeRacerGame({super.key});
  @override
  State<TypeRacerGame> createState() => _TypeRacerGameState();
}

class _TypeRacerGameState extends State<TypeRacerGame> {
  final _sentences = [
    'flutter is awesome for building apps',
    'type this sentence as fast as you can',
    'the quick brown fox jumps over the lazy dog',
    'programming is the art of problem solving',
    'speed and accuracy are key in type racing',
  ];
  final _ctrl = TextEditingController();
  late String _target;
  DateTime? _startTime;
  int _wpm = 0, _best = 0;
  bool _done = false, _started = false;
  int _score = 0;

  @override
  void initState() { super.initState(); _pick(); }

  void _pick() {
    _target = _sentences[Random().nextInt(_sentences.length)];
    _ctrl.clear(); _startTime = null; _done = false; _started = false;
    setState(() {});
  }

  void _onChange(String val) {
    if (!_started) { _startTime = DateTime.now(); _started = true; }
    if (val == _target) {
      final elapsed = DateTime.now().difference(_startTime!).inSeconds;
      final words = _target.split(' ').length;
      _wpm = elapsed > 0 ? ((words / elapsed) * 60).round() : 999;
      if (_wpm > _best) _best = _wpm;
      _score++;
      setState(() => _done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typed = _ctrl.text;
    return _BaseGame(
      title: 'Type Racer', neon: _C.neonBlue,
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _ScoreChip(label: 'WPM', value: _done ? '$_wpm' : '—', color: _C.neonBlue),
            _ScoreChip(label: 'BEST', value: '$_best wpm', color: _C.neonYellow),
            _ScoreChip(label: 'SELESAI', value: '$_score', color: _C.neonGreen),
          ]),
          const SizedBox(height: 24),
          _NeonCard(neon: _C.neonBlue, child: RichText(
            text: TextSpan(
              children: List.generate(_target.length, (i) {
                Color c;
                if (i < typed.length) {
                  c = typed[i] == _target[i] ? _C.neonGreen : _C.neonRed;
                } else if (i == typed.length) {
                  c = _C.neonBlue;
                } else {
                  c = _C.white30;
                }
                return TextSpan(
                  text: _target[i],
                  style: TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace', letterSpacing: 1.2),
                );
              }),
            ),
          )),
          const SizedBox(height: 20),
          if (!_done) TextField(
            controller: _ctrl,
            onChanged: _onChange,
            autofocus: true,
            style: const TextStyle(color: _C.white, fontFamily: 'monospace', fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Mulai mengetik...',
              hintStyle: const TextStyle(color: _C.white10),
              filled: true, fillColor: _C.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _C.neonBlue, width: 2)),
            ),
          ),
          const SizedBox(height: 16),
          if (_done) ...[
            _NeonCard(neon: _C.neonGreen, child:
              Text('🚀 SELESAI! $_wpm WPM', style: const TextStyle(color: _C.neonGreen, fontSize: 18, fontWeight: FontWeight.w900), textAlign: TextAlign.center)),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity,
              child: _NeonButton(label: 'LANJUT', neon: _C.neonBlue, icon: Icons.arrow_forward_rounded, onTap: _pick)),
          ],
        ]),
      ),
    );
  }
}

// ============================================================
// GAME 15 — BINARY QUIZ
// ============================================================
class BinaryQuizGame extends StatefulWidget {
  const BinaryQuizGame({super.key});
  @override
  State<BinaryQuizGame> createState() => _BinaryQuizGameState();
}

class _BinaryQuizGameState extends State<BinaryQuizGame> {
  final _rng = Random();
  final _ctrl = TextEditingController();
  late int _number;
  String _msg = '';
  Color _msgColor = _C.white60;
  int _score = 0, _streak = 0, _best = 0;
  bool _mode = true; // true = decimal->binary, false = binary->decimal

  @override
  void initState() { super.initState(); _next(); }

  void _next() {
    _number = _rng.nextInt(63) + 1;
    _ctrl.clear(); _msg = '';
    setState(() {});
  }

  void _check() {
    final ans = _ctrl.text.trim();
    final correct = _mode ? ans == _number.toRadixString(2) : ans == _number.toString();
    if (correct) {
      _score++; _streak++;
      if (_streak > _best) _best = _streak;
      setState(() { _msg = '✅ BENAR! Streak: $_streak 🔥'; _msgColor = _C.neonGreen; });
      Future.delayed(const Duration(milliseconds: 500), _next);
    } else {
      _streak = 0;
      final correctAns = _mode ? _number.toRadixString(2) : _number.toString();
      setState(() { _msg = '❌ Jawaban: $correctAns'; _msgColor = _C.neonRed; });
    }
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseGame(
      title: 'Binary Quiz', neon: _C.neonRed,
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _ScoreChip(label: 'SKOR', value: '$_score', color: _C.neonRed),
            _ScoreChip(label: 'STREAK', value: '🔥$_streak', color: _C.neonOrange),
            _ScoreChip(label: 'BEST', value: '$_best', color: _C.neonYellow),
          ]),
          const SizedBox(height: 16),
          // Mode toggle
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            GestureDetector(
              onTap: () => setState(() { _mode = true; _next(); }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _mode ? _C.neonRed.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _mode ? _C.neonRed : _C.border),
                ),
                child: Text('DEC→BIN', style: TextStyle(color: _mode ? _C.neonRed : _C.white30, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => setState(() { _mode = false; _next(); }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: !_mode ? _C.neonRed.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: !_mode ? _C.neonRed : _C.border),
                ),
                child: Text('BIN→DEC', style: TextStyle(color: !_mode ? _C.neonRed : _C.white30, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _NeonCard(neon: _C.neonRed, child: Column(children: [
            Text(_mode ? 'KONVERSI KE BINER:' : 'KONVERSI KE DESIMAL:',
              style: const TextStyle(color: _C.white30, fontSize: 10, letterSpacing: 2)),
            const SizedBox(height: 12),
            Text(_mode ? '$_number' : _number.toRadixString(2),
              style: const TextStyle(color: _C.neonRed, fontSize: 44, fontWeight: FontWeight.w900, fontFamily: 'monospace', letterSpacing: 4)),
            if (_msg.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(_msg, style: TextStyle(color: _msgColor, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ])),
          const SizedBox(height: 20),
          TextField(
            controller: _ctrl,
            keyboardType: _mode ? TextInputType.number : TextInputType.number,
            style: const TextStyle(color: _C.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'monospace', letterSpacing: 3),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: _mode ? '0 atau 1...' : 'Angka desimal...',
              hintStyle: const TextStyle(color: _C.white10),
              filled: true, fillColor: _C.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _C.neonRed, width: 2)),
            ),
            onSubmitted: (_) => _check(),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _NeonButton(label: 'CEK', neon: _C.neonRed, onTap: _check)),
            const SizedBox(width: 10),
            Expanded(child: _NeonButton(label: 'SKIP', neon: _C.neonRed, dark: true, icon: Icons.skip_next_rounded, onTap: _next)),
          ]),
        ]),
      ),
    );
  }
}

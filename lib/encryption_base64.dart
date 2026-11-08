import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class EncryptionRavenClawx extends StatefulWidget {
  const EncryptionRavenClawx({super.key});

  @override
  State<EncryptionRavenClawx> createState() => _EncryptionRavenClawxState();
}

class _EncryptionRavenClawxState extends State<EncryptionRavenClawx> {
  String fileType = 'js';
  String inputText = '';
  String outputText = '';

  // ===== COLORS (RED - BLACK THEME) =====
  final Color bloodRed = const Color(0xFFE53935);
  final Color darkRed = const Color(0xFFB71C1C);
  final Color deepBlack = const Color(0xFF0A0A0A);
  final Color glassBlack = Colors.black.withOpacity(0.7);

  // ===== BASE64 =====
  String encrypt(String text) => base64Encode(utf8.encode(text));
  String decrypt(String text) => utf8.decode(base64Decode(text));

  // ===== AUTO DOWNLOAD =====
  Future<void> autoDownload(String data) async {
    final dir = await getExternalStorageDirectory();
    final fileName =
        "RavenClawx_${DateTime.now().millisecondsSinceEpoch}.$fileType";
    final file = File("${dir!.path}/$fileName");
    await file.writeAsString(data);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: darkRed,
        content: Text("Saved: $fileName"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepBlack,
      appBar: AppBar(
        title: const Text("Encryption Prime Vision"),
        centerTitle: true,
        backgroundColor: Colors.black,
        leading: const Icon(
          Icons.enhanced_encryption,
          color: Colors.red,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // DROPDOWN
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: glassBlack,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: darkRed),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: deepBlack,
                  value: fileType,
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(
                      value: 'js',
                      child: Text("JavaScript (.js)"),
                    ),
                    DropdownMenuItem(
                      value: 'html',
                      child: Text("HTML (.html)"),
                    ),
                  ],
                  onChanged: (v) => setState(() => fileType = v!),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // INPUT
            Expanded(
              child: TextField(
                maxLines: null,
                expands: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Input Source",
                  labelStyle: TextStyle(color: bloodRed),
                  filled: true,
                  fillColor: glassBlack,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: darkRed),
                  ),
                ),
                onChanged: (v) => inputText = v,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bloodRed,
                    ),
                    icon: const Icon(Icons.enhanced_encryption),
                    label: const Text("Encrypt + Download"),
                    onPressed: () {
                      outputText = encrypt(inputText);
                      autoDownload(outputText);
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkRed,
                    ),
                    icon: const Icon(Icons.lock_open),
                    label: const Text("Decrypt"),
                    onPressed: () {
                      outputText = decrypt(inputText);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // OUTPUT
            Expanded(
              child: TextField(
                readOnly: true,
                maxLines: null,
                expands: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Output Result",
                  labelStyle: TextStyle(color: bloodRed),
                  filled: true,
                  fillColor: glassBlack,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: darkRed),
                  ),
                ),
                controller: TextEditingController(text: outputText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
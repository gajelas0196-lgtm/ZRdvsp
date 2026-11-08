import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

// ============================================================
//  FILE: iqc.dart
//  Widget: IQCScreen (bisa dipanggil dari tools_gateway.dart)
// ============================================================

class IQCScreen extends StatefulWidget {
  const IQCScreen({super.key});

  @override
  State<IQCScreen> createState() => _IQCScreenState();
}

class _IQCScreenState extends State<IQCScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _chatTimeController = TextEditingController();
  final TextEditingController _statusBarTimeController = TextEditingController();

  Uint8List? _generatedImage;
  bool _isGenerating = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final timeFormat = DateFormat('HH:mm');
    final now = DateTime.now();
    _chatTimeController.text = timeFormat.format(now);
    _statusBarTimeController.text = timeFormat.format(now);
    _textController.text = 'bizz ganteng';
  }

  @override
  void dispose() {
    _textController.dispose();
    _chatTimeController.dispose();
    _statusBarTimeController.dispose();
    super.dispose();
  }

  bool _isValidTime(String time) {
    final regex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    return regex.hasMatch(time);
  }

  Future<void> _generateIQCImage() async {
    if (_textController.text.isEmpty) {
      _showError('Masukkan teks chat terlebih dahulu');
      return;
    }
    if (_chatTimeController.text.isEmpty || _statusBarTimeController.text.isEmpty) {
      _showError('Masukkan waktu chat dan status bar');
      return;
    }
    if (!_isValidTime(_chatTimeController.text)) {
      _showError('Format waktu chat salah (gunakan HH:mm)');
      return;
    }
    if (!_isValidTime(_statusBarTimeController.text)) {
      _showError('Format waktu status bar salah (gunakan HH:mm)');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedImage = null;
    });

    try {
      final text = Uri.encodeComponent(_textController.text);
      final chatTime = Uri.encodeComponent(_chatTimeController.text);
      final statusBarTime = Uri.encodeComponent(_statusBarTimeController.text);
      final apiUrl =
          'https://api.deline.web.id/maker/iqc?text=$text&chatTime=$chatTime&statusBarTime=$statusBarTime';

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'User-Agent': 'IQC-Screenshot-Maker/1.0'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        setState(() {
          _generatedImage = response.bodyBytes;
        });
        _showSuccess('Gambar berhasil dihasilkan dari API');
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal menghubungi API: $e';
      });
      _showError(_errorMessage!);
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _saveImage() async {
    if (_generatedImage == null) {
      _showError('Tidak ada gambar untuk disimpan');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Izin penyimpanan dibutuhkan');
      }

      final directory = await getExternalStorageDirectory();
      final downloadPath = '${directory!.path}/Download';
      final downloadDir = Directory(downloadPath);
      if (!downloadDir.existsSync()) {
        downloadDir.createSync(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName =
          'iqc_${_textController.text.replaceAll(' ', '_')}_$timestamp.png';
      final filePath = '$downloadPath/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(_generatedImage!);

      _showSuccess('Gambar disimpan di: Download/$fileName');
      _showSaveSuccessDialog(filePath, fileName);
    } catch (e) {
      _showError('Gagal menyimpan gambar: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showSuccess('Disalin ke clipboard: $text');
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSaveSuccessDialog(String filePath, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Gambar Disimpan!',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gambar berhasil disimpan di:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Download/$fileName',
                style: const TextStyle(
                  color: Color(0xFF60A5FA),
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Anda dapat membagikan gambar melalui aplikasi galeri atau file manager.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _copyToClipboard(filePath);
              Navigator.pop(context);
            },
            child: const Text('SALIN PATH'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String hint = '',
    bool isTime = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF334155),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white54),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: isTime
                  ? IconButton(
                      onPressed: () {
                        final timeFormat = DateFormat('HH:mm');
                        final now = DateTime.now();
                        controller.text = timeFormat.format(now);
                      },
                      icon: const Icon(Icons.access_time, color: Color(0xFF60A5FA)),
                      tooltip: 'Gunakan waktu sekarang',
                    )
                  : null,
            ),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            maxLines: isTime ? 1 : 3,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('IQC Screenshot Maker'),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_generatedImage != null)
            IconButton(
              onPressed: _isSaving ? null : _saveImage,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download),
              tooltip: 'Simpan Gambar',
            ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E293B),
                  title: const Text(
                    'Tentang',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Screen Shot Whatsapp iPhone\n\nFitur share sementara dinonaktifkan karena masalah kompatibilitas.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('TUTUP'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.info_outline),
            tooltip: 'Tentang',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInputField(
                    label: 'Teks Chat',
                    controller: _textController,
                    hint: 'Masukkan teks chat...',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          label: 'Waktu Chat',
                          controller: _chatTimeController,
                          hint: 'HH:mm',
                          isTime: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInputField(
                          label: 'Waktu Status Bar',
                          controller: _statusBarTimeController,
                          hint: 'HH:mm',
                          isTime: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _copyToClipboard('22:11'),
                    child: Row(
                      children: [
                        const Icon(Icons.info, size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        const Text(
                          'Format waktu: HH:mm (contoh: 22:11)',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateIQCImage,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.generating_tokens),
                      label: Text(
                        _isGenerating ? 'SEDANG MEMBUAT...' : 'BUAT SCREENSHOT',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEF4444)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                final apiUrl =
                    'https://api.deline.web.id/maker/iqc?text=${Uri.encodeComponent(_textController.text)}&chatTime=${Uri.encodeComponent(_chatTimeController.text)}&statusBarTime=${Uri.encodeComponent(_statusBarTimeController.text)}';
                _copyToClipboard(apiUrl);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.api, color: Color(0xFF60A5FA)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'API Endpoint',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'https://api.deline.web.id/maker/iqc',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.content_copy, color: Color(0xFF94A3B8), size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.preview, color: Color(0xFF60A5FA)),
                      SizedBox(width: 8),
                      Text(
                        'Hasil Screenshot',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_generatedImage != null)
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 600),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _generatedImage!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 300,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 64,
                                    color: Color(0xFFEF4444),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Gagal memuat gambar',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF334155),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.screenshot_monitor,
                            size: 80,
                            color: const Color(0xFF475569).withOpacity(0.5),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Belum ada screenshot',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Masukkan teks dan waktu, lalu klik "Buat Screenshot"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_generatedImage != null) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ukuran: ${(_generatedImage!.lengthInBytes / 1024).toStringAsFixed(1)} KB',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Dibuat: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contoh Cepat:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildExampleChip('Malam minggu yuk', '20:00', '20:05'),
                      _buildExampleChip('Besok ketemuan dimana?', '15:30', '15:45'),
                      _buildExampleChip('Lagi apa?', '21:15', '21:20'),
                      _buildExampleChip('Udah makan belum?', '12:00', '12:10'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleChip(String text, String chatTime, String statusBarTime) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _textController.text = text;
          _chatTimeController.text = chatTime;
          _statusBarTimeController.text = statusBarTime;
        });
        _showSuccess('Contoh diterapkan');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF334155),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF475569)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text.length > 20 ? '${text.substring(0, 20)}...' : text,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              '$chatTime | $statusBarTime',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
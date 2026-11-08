import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
// HAPUS: import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class CatboxUploaderPage extends StatefulWidget {
  final String username;
  final String role;
  final int totalTools;

  const CatboxUploaderPage({
    super.key,
    required this.username,
    required this.role,
    this.totalTools = 11,
  });

  @override
  State<CatboxUploaderPage> createState() => _CatboxUploaderPageState();
}

class _CatboxUploaderPageState extends State<CatboxUploaderPage> {
  File? _selectedFile;
  String? _fileName;
  String? _fileSize;
  String? _fileType;
  String? _uploadedUrl;
  bool _isUploading = false;
  String _uploadStatus = "";
  double _uploadProgress = 0.0;
  
  final TextEditingController _urlController = TextEditingController();
  
  final Color _primaryBlue = const Color(0xFF2196F3);
  final Color _darkBlue = const Color(0xFF0D47A1);
  final Color _softBlue = const Color(0xFF64B5F6);
  final Color _bgDark = const Color(0xFF0A1929);
  final Color _cardBg = const Color(0xFF0F1D2F);
  
  static const int maxFileSizeMB = 50;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      await Permission.photos.request();
      await Permission.videos.request();
      await Permission.audio.request();
    }
  }

  // ============ METHOD _pickMedia PAKAI IMAGE_PICKER ============
  Future<void> _pickMedia() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // Tampilkan dialog pilihan
      final XFile? result = await showDialog<XFile>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _cardBg,
          title: const Text(
            "Pilih Media",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text("Gallery", style: TextStyle(color: Colors.white)),
                onTap: () async {
                  final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
                  Navigator.pop(context, picked);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.green),
                title: const Text("Camera", style: TextStyle(color: Colors.white)),
                onTap: () async {
                  final XFile? picked = await picker.pickImage(source: ImageSource.camera);
                  Navigator.pop(context, picked);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library, color: Colors.orange),
                title: const Text("Video", style: TextStyle(color: Colors.white)),
                onTap: () async {
                  final XFile? picked = await picker.pickVideo(source: ImageSource.gallery);
                  Navigator.pop(context, picked);
                },
              ),
            ],
          ),
        ),
      );

      if (result != null) {
        final file = File(result.path);
        final sizeInBytes = await file.length();
        final sizeInMB = sizeInBytes / (1024 * 1024);
        
        if (sizeInMB > maxFileSizeMB) {
          _showSnackbar("File terlalu besar! Maksimal $maxFileSizeMB MB", isError: true);
          return;
        }
        
        setState(() {
          _selectedFile = file;
          _fileName = result.name;
          _fileSize = "${sizeInMB.toStringAsFixed(2)} MB";
          _fileType = result.path.split('.').last.toUpperCase();
          _uploadedUrl = null;
          _uploadStatus = "";
          _uploadProgress = 0.0;
        });
      }
    } catch (e) {
      _showSnackbar("Gagal memilih file: $e", isError: true);
    }
  }
  // =============================================================

  Future<void> _uploadToCatbox() async {
    if (_selectedFile == null) {
      _showSnackbar("Pilih media terlebih dahulu!", isError: true);
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadStatus = "Mengupload file...";
      _uploadProgress = 0.2;
    });

    try {
      final uri = Uri.parse("https://catbox.moe/user/api.php");
      final request = http.MultipartRequest("POST", uri);
      
      request.fields['reqtype'] = 'fileupload';
      request.fields['userhash'] = '';
      
      final fileStream = http.ByteStream(_selectedFile!.openRead());
      final fileLength = await _selectedFile!.length();
      final multipartFile = http.MultipartFile(
        'fileToUpload',
        fileStream,
        fileLength,
        filename: _fileName,
      );
      
      request.files.add(multipartFile);
      
      setState(() => _uploadProgress = 0.5);
      
      final response = await request.send().timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw Exception("Upload timeout (maksimal 5 menit)");
        },
      );
      
      setState(() => _uploadProgress = 0.8);
      
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200 && responseBody.isNotEmpty) {
        final url = responseBody.trim();
        
        if (url.startsWith("http")) {
          setState(() {
            _uploadedUrl = url;
            _urlController.text = url;
            _uploadStatus = "Upload berhasil!";
            _uploadProgress = 1.0;
            _isUploading = false;
          });
          _showSnackbar("Upload berhasil! URL siap digunakan", isError: false);
        } else {
          throw Exception("API Error: $responseBody");
        }
      } else {
        throw Exception("Gagal upload: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _uploadStatus = "Error: ${e.toString()}";
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      _showSnackbar("Upload gagal: ${e.toString()}", isError: true);
    }
  }

  void _copyToClipboard() {
    if (_uploadedUrl == null || _uploadedUrl!.isEmpty) {
      _showSnackbar("Tidak ada URL untuk disalin", isError: true);
      return;
    }
    Clipboard.setData(ClipboardData(text: _uploadedUrl!));
    _showSnackbar("URL berhasil disalin!", isError: false);
  }

  void _shareUrl() {
    if (_uploadedUrl == null || _uploadedUrl!.isEmpty) {
      _showSnackbar("Tidak ada URL untuk dibagikan", isError: true);
      return;
    }
    Share.share(
      "📁 Upload Media ke URI\n\n"
      "URI: $_uploadedUrl\n\n"
      "Upload by: ${widget.username}\n"
      "Role: ${widget.role}\n"
      "Tools: ${widget.totalTools} Modules\n\n"
      "🔗 Upload via Prime Vision",
      subject: "Upload Media URI",
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _fileSize = null;
      _fileType = null;
      _uploadedUrl = null;
      _urlController.clear();
      _uploadStatus = "";
      _uploadProgress = 0.0;
    });
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : _primaryBlue,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getFileIcon() {
    if (_fileType == null) return '📁';
    final type = _fileType!.toLowerCase();
    if (type.contains('jpg') || type.contains('jpeg') || type.contains('png') || type.contains('gif')) return '🖼️';
    if (type.contains('mp4') || type.contains('mov') || type.contains('avi')) return '🎬';
    if (type.contains('mp3') || type.contains('wav') || type.contains('flac')) return '🎵';
    if (type.contains('pdf')) return '📄';
    if (type.contains('zip') || type.contains('rar') || type.contains('7z')) return '🗜️';
    if (type.contains('apk') || type.contains('exe')) return '📦';
    return '📎';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _darkBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "UPLOAD MEDIA KE URI",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 16),
            _buildCategorySection(),
            const SizedBox(height: 16),
            _buildFilePreviewSection(),
            const SizedBox(height: 16),
            _buildResultSection(),
            const SizedBox(height: 16),
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryBlue, _darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Upload Media ke URI",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${_fileSize ?? '311.17 KB'}",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "KATEGORI MENU",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Pilih kategori menu yang Anda butuhkan.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _primaryBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${widget.totalTools} Modules",
              style: TextStyle(
                color: _softBlue,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreviewSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.image_rounded, color: _primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                "Pratinjau Media",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _bgDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryBlue.withOpacity(0.2)),
            ),
            child: _selectedFile != null
                ? _buildMediaPreview()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported_rounded, size: 48, color: Colors.white.withOpacity(0.3)),
                      const SizedBox(height: 8),
                      Text(
                        "Belum ada file dipilih",
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          if (_selectedFile != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bgDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(_getFileIcon(), style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fileName ?? "Unknown",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "$_fileSize • $_fileType",
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearSelection,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickMedia,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryBlue, _darkBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "Pilih Media",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedFile != null)
            GestureDetector(
              onTap: _isUploading ? null : _uploadToCatbox,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _primaryBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryBlue),
                ),
                child: Center(
                  child: _isUploading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${(_uploadProgress * 100).toInt()}%",
                              style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : Text(
                          "UPLOAD KE CATBOX",
                          style: TextStyle(
                            color: _primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    final ext = _fileType?.toLowerCase() ?? '';
    final isImage = ext.contains('jpg') || ext.contains('jpeg') || ext.contains('png') || ext.contains('gif') || ext.contains('webp');
    final isVideo = ext.contains('mp4') || ext.contains('mov') || ext.contains('avi') || ext.contains('mkv');
    final isAudio = ext.contains('mp3') || ext.contains('wav') || ext.contains('flac') || ext.contains('ogg');
    
    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _selectedFile!,
          width: double.infinity,
          height: 150,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_rounded, size: 48, color: Colors.white.withOpacity(0.3)),
                const Text("Tidak bisa preview", style: TextStyle(color: Colors.white54)),
              ],
            ),
          ),
        ),
      );
    } else if (isVideo) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_file_rounded, size: 48, color: _primaryBlue),
            const SizedBox(height: 8),
            const Text("Video file ready", style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    } else if (isAudio) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.audiotrack_rounded, size: 48, color: _primaryBlue),
            const SizedBox(height: 8),
            const Text("Audio file ready", style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_drive_file_rounded, size: 48, color: _primaryBlue),
            const SizedBox(height: 8),
            Text(_fileType ?? "Document", style: const TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }
  }

  Widget _buildResultSection() {
    if (_uploadedUrl == null) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "URI Hasil Upload",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bgDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryBlue.withOpacity(0.2)),
            ),
            child: SelectableText(
              _uploadedUrl!,
              style: TextStyle(
                color: _softBlue,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _copyToClipboard,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryBlue, _darkBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "COPY",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _shareUrl,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primaryBlue),
                    ),
                    child: const Center(
                      child: Text(
                        "BAGIKAN",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
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

  Widget _buildInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: _softBlue, size: 18),
              const SizedBox(width: 8),
              const Text(
                "Informasi",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoBullet("Upload media ke Catbox.moe dan dapatkan URI langsung."),
          _buildInfoBullet("Batas file per upload: 50 MB (jika lebih akan di-zip)."),
          _buildInfoBullet("Format file apa pun didukung."),
          _buildInfoBullet("URI akan langsung bisa digunakan."),
        ],
      ),
    );
  }

  Widget _buildInfoBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ", style: TextStyle(color: _softBlue, fontSize: 12)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
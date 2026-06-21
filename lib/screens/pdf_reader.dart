// lib/screens/pdf_reader.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:bayt_alhikma/view_model/dark_mode.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart'; // تمت الإضافة للتحميل
import 'package:path_provider/path_provider.dart'; // تمت الإضافة لمسار التخزين
import 'package:permission_handler/permission_handler.dart'; // تمت الإضافة للصلاحيات
import 'package:bayt_alhikma/view_model/local_storage_services.dart';

class PdfReaderScreen extends StatefulWidget {
  final String filePath;
  final String bookId;

  const PdfReaderScreen({
    Key? key,
    required this.filePath,
    required this.bookId,
  }) : super(key: key);

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  late PdfViewerController _pdfController;
  late PdfTextSearchResult _searchResult;
  int _pagesCount = 0;
  bool _jumpedToSavedPage = false; 

  // متغيرات حالة التحميل
  bool _isDownloading = false;
  bool _isDownloaded = false;
  late String _activeFilePath; 

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _activeFilePath = widget.filePath;
    _checkIfFileExistsLocally(); // التحقق عند فتح الشاشة
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  // التحقق مما إذا كان الكتاب محملاً مسبقاً لفتحه من الهاتف بدلاً من الإنترنت
  Future<void> _checkIfFileExistsLocally() async {
    if (!widget.filePath.startsWith('http')) {
      // الملف محلي بالفعل
      setState(() => _isDownloaded = true);
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final localPath = "${dir.path}/pdfs/${widget.bookId}.pdf";
    final file = File(localPath);

    if (await file.exists()) {
      setState(() {
        _isDownloaded = true;
        _activeFilePath = localPath; // تغيير المسار للملف المحلي
      });
    }
  }

  // دالة تحميل ملف الـ PDF
  Future<void> _handleDownload() async {
    if (!widget.filePath.startsWith('http')) return; 

    var status = await Permission.storage.request();

    if (status.isGranted || await Permission.storage.isLimited || Platform.isAndroid) {
      setState(() => _isDownloading = true);

      try {
        final dir = await getApplicationDocumentsDirectory();
        final pdfFolder = Directory("${dir.path}/pdfs");
        if (!pdfFolder.existsSync()) {
          pdfFolder.createSync(recursive: true);
        }

        final localPath = "${pdfFolder.path}/${widget.bookId}.pdf";
        final dio = Dio();

        await dio.download(widget.filePath, localPath);

        if (mounted) {
          setState(() {
            _isDownloading = false;
            _isDownloaded = true;
            _activeFilePath = localPath; // التبديل للقراءة المحلية بعد انتهاء التحميل
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم حفظ الكتاب بنجاح للقراءة بدون إنترنت')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDownloading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل التحميل: $e')),
          );
        }
      }
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('صلاحية التخزين مطلوبة لتحميل الكتاب.')),
      );
    }
  }

  Future<void> _shareFile() async {
    final path = _activeFilePath; // استخدام المسار النشط (سواء نت أو محلي)
    try {
      if (path.startsWith('http')) {
        await Share.share(path);
        return;
      }
      final file = File(path);
      if (await file.exists()) {
        await Share.shareXFiles([XFile(path)], text: 'Shared PDF');
      }
    } catch (e) {
      // Handle error
    }
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) async {
    setState(() => _pagesCount = details.document?.pages.count ?? 0);

    if (!_jumpedToSavedPage) {
      final savedPage = await LocalStorageService.getPdfPage(widget.bookId);
      if (savedPage > 1 && savedPage <= _pagesCount) {
        _pdfController.jumpToPage(savedPage);
        _jumpedToSavedPage = true;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resumed from page $savedPage'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    LocalStorageService.savePdfPage(widget.bookId, details.newPageNumber);
  }

  @override
  Widget build(BuildContext context) {
    // تحديد نوع الملف بناءً على المتغير النشط 
    bool isDark = Provider.of<DarkModeProvider>(context).isDark;
    final isLocal = !_activeFilePath.startsWith('http');
    Widget viewer;

    // الحل هنا: إزالة FutureBuilder وتمرير الملف مباشرة
    if (isLocal) {
      viewer = SfPdfViewer.file(
        File(_activeFilePath),
        controller: _pdfController,
        onDocumentLoaded: _onDocumentLoaded,
        onPageChanged: _onPageChanged,
      );
    } else {
      viewer = SfPdfViewer.network(
        _activeFilePath,
        controller: _pdfController,
        onDocumentLoaded: _onDocumentLoaded,
        onPageChanged: _onPageChanged,
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text('PDF Reader'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_isDownloading)
             Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.white : Colors.black),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Download PDF',
              icon: Icon(
                _isDownloaded ? Icons.cloud_done : Icons.cloud_download_outlined,
                color: _isDownloaded ? Colors.green : isDark ? Colors.white : Colors.black,
              ),
              onPressed: _isDownloaded ? null : _handleDownload,
            ),
          
          IconButton(
            tooltip: 'Go to page',
            icon: const Icon(Icons.format_list_numbered),
            onPressed: () async {
              final input = await showDialog<String>(
                context: context,
                builder: (ctx) {
                  String val = '';
                  return AlertDialog(
                    title: const Text('Go to page'),
                    content: TextField(
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => val = v,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, val),
                        child: const Text('Go'),
                      ),
                    ],
                  );
                },
              );
              if (input != null && input.trim().isNotEmpty) {
                final p = int.tryParse(input.trim());
                if (p != null) _pdfController.jumpToPage(p);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              // Your existing search logic
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareFile,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: viewer),
          Container(
            color: isDark ? Colors.black : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _pdfController.previousPage(),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _pagesCount > 0
                          ? 'Page • ${_pdfController.pageNumber} / $_pagesCount'
                          : 'Page • ${_pdfController.pageNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _pdfController.nextPage(),
                  icon: const Icon(Icons.chevron_right),
                ),
                IconButton(
                  onPressed: () => _pdfController.zoomLevel += 0.25,
                  icon: const Icon(Icons.zoom_in),
                ),
                IconButton(
                  onPressed: () {
                    final z = _pdfController.zoomLevel - 0.25;
                    _pdfController.zoomLevel = z > 1.0 ? z : 1.0;
                  },
                  icon: const Icon(Icons.zoom_out),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
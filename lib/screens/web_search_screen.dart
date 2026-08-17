import 'package:bayt_alhikma/utils/styles.dart';
import 'package:bayt_alhikma/view_model/dark_mode.dart';
import 'package:bayt_alhikma/view_model/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WebSearchScreen extends StatefulWidget {
  final String query;
  const WebSearchScreen({Key? key, required this.query}) : super(key: key);

  @override
  State<WebSearchScreen> createState() => _WebSearchScreenState();
}

class _WebSearchScreenState extends State<WebSearchScreen> {
  // 1. Declare the WebViewController
  late final WebViewController _controller;
  late TextEditingController _wishBookNameController;
  late TextEditingController _wishAuthorNameController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _wishBookNameController = TextEditingController();
    _wishAuthorNameController = TextEditingController();
    // 2. Initialize the controller
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() => _loading = true);
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _loading = false);
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(_searchUrl));
  }

  String get _searchUrl {
    final q = widget.query.trim();
    if (q.isEmpty) return 'https://www.google.com'; // Fallback if empty
    final encoded = Uri.encodeComponent(q);
    return 'https://www.google.com/search?q=$encoded';
  }

  void _addToWishList () async {
    bool isArabicLocale() {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      return languageProvider.isArabic;
    }
    String bookName = _wishBookNameController.text.trim();
    String authorName = _wishAuthorNameController.text.trim();
    Timestamp timestamp = Timestamp.now(); 

    try{
      await FirebaseFirestore.instance.collection('wishs').add({'book':bookName,'author':authorName,'timestamp':timestamp});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabicLocale() ? 'تم إضافة الكتاب إلى قائمة الرغبات' : 'Book added to wish list')),
      );
    }catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabicLocale() ? 'حدث خطأ أثناء إضافة الكتاب إلى قائمة الرغبات' : 'Error adding book to wish list')),
      );
      debugPrint('Error adding to wish list: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.query.isEmpty ? 'Google' : widget.query,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      // 3. Use WebViewWidget instead of WebView
      body: Stack(
        children: [
          // 1. WebViewWidget
          WebViewWidget(controller: _controller),
          // 2. Positioned.fill with Material and InkWell
          Positioned(
            left: 10,
            bottom: MediaQuery.of(context).size.height * 0.01,
            child: InkWell(
              splashColor: AppStyles.primaryGold.withOpacity(0.5),
              onTap: () {
                _wishDialog();
              },

              child: Center(
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppStyles.primaryGold, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    color: AppStyles.primaryGold.withOpacity(0.95),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.new_releases),
                      SizedBox(height: 8),
                      Text('Add to wish list', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _wishDialog() {
    bool isArabic = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).isArabic;
    bool isDark = Provider.of<DarkModeProvider>(context, listen: false).isDark;
    showDialog(
      
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          title: Text(
            isArabic
                ? 'أضف كتاب ترغب أن تراه في مكتبتنا'
                : 'Add a book you wish to see in our library',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16,
              fontFamily: 'Arabic Typesetting'
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _wishBookNameController,
                decoration: InputDecoration(
                  hintText: isArabic ? 'أدخل اسم الكتاب' : 'Enter book name',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontFamily: 'Arabic Typesetting'
                  ),
                ),
                style: TextStyle(color: isDark ? Colors.white : Colors.black,fontSize: 16,fontFamily: 'Arabic Typesetting'),
              ),
              TextField(
                controller: _wishAuthorNameController,
                decoration: InputDecoration(
                  hintText: isArabic ? 'أدخل اسم المؤلف' : 'Enter author name',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontFamily: 'Arabic Typesetting'
                  ),
                ),
                style: TextStyle(color: isDark ? Colors.white : Colors.black,fontSize: 16,fontFamily: 'Arabic Typesetting'),
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: () async {
                _addToWishList();
                Navigator.of(ctx).pop();
              }, child: Text("Add"))
            ],
          ),
        );
      },
    );
  }
}

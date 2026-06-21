import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebSearchScreen extends StatefulWidget {
  final String query;
  const WebSearchScreen({Key? key, required this.query}) : super(key: key);

  @override
  State<WebSearchScreen> createState() => _WebSearchScreenState();
}

class _WebSearchScreenState extends State<WebSearchScreen> {
  // 1. Declare the WebViewController
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

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
          Container(color: Colors.white),
          WebViewWidget(controller: _controller),
        ],
      ),
    );
  }
}

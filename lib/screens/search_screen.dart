// lib/screens/search_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/styles.dart';
import 'book_details.dart';
import 'package:bayt_alhikma/view_model/language_provider.dart';
import 'package:provider/provider.dart';
import 'web_search_screen.dart'; // <--- add this import

class SearchScreen extends StatefulWidget {
  // optionally receive a selectedBook map
  // { 'img': 'assets/...', 'title': '...', 'author': '...'}
  final Map<String, String>? selectedBook;
  const SearchScreen({Key? key, this.selectedBook}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, String>? get book => widget.selectedBook;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // if we open the search with a preselected book, optionally populate text
    if (book != null) {
      _searchController.text = book!['title'] ?? '';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(q.trim());
    });
  }

  Future<void> _performSearch(String q) async {
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final snap = await _firestore.collection('books').get();
      final lower = q.toLowerCase();
      final List<Map<String, dynamic>> matches = [];
      for (var d in snap.docs) {
        final data = Map<String, dynamic>.from(d.data());
        final nameEn = (data['nameEN'] ?? data['title'] ?? '')
            .toString()
            .toLowerCase();
        final nameAr = (data['nameAR'] ?? '').toString().toLowerCase();
        if (nameEn.contains(lower) || nameAr.contains(lower)) {
          matches.add(data);
        }
      }
      setState(() {
        _results = matches;
      });
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() {
        _results = [];
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _imageFor(dynamic raw) {
    final img = (raw ?? '').toString();
    if (img.isEmpty)
      return Image.asset(
        'images/hero.png',
        width: 72,
        height: 96,
        fit: BoxFit.cover,
      );
    Uri? uri = Uri.tryParse(img);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return Image.network(
        img,
        width: 72,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'images/hero.png',
          width: 72,
          height: 96,
          fit: BoxFit.cover,
        ),
      );
    }
    if (img.startsWith('/')) {
      try {
        return Image.file(
          File(img),
          width: 72,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset(
            'images/hero.png',
            width: 72,
            height: 96,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {}
    }
    // treat as local asset name
    return Image.asset(
      img,
      width: 72,
      height: 96,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        'images/hero.png',
        width: 72,
        height: 96,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabicLocale = Provider.of<LanguageProvider>(context).isArabic;

    return Scaffold(
      backgroundColor: AppStyles.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // top row: back, input, close
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 10,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: const Border(
                          bottom: BorderSide(color: Colors.transparent),
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                        ),
                        decoration: InputDecoration(
                          hintText: isArabicLocale
                              ? 'ابحث عن كتاب'
                              : 'Search for a book',
                          border: InputBorder.none,
                          suffixIcon: _loading
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        onChanged: (v) {
                          _onQueryChanged(v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      _onQueryChanged('');
                    },
                  ),
                ],
              ),
            ),

            // thin divider
            Container(height: 1, color: Colors.black12),

            // results area
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.white,
                child: _results.isEmpty
                    ? Center(
                        child: Column(
                          children: [
                            Text(
                              _loading
                                  ? (isArabicLocale
                                        ? 'جارٍ البحث...'
                                        : 'Searching...')
                                  : (isArabicLocale
                                        ? 'لا توجد نتائج'
                                        : 'No results'),
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                            TextButton(
                              onPressed: () {
                                final q = _searchController.text.trim();
                                if (q.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isArabicLocale
                                            ? 'أدخل نص البحث'
                                            : 'Enter search text',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        WebSearchScreen(query: '$q book'),
                                  ),
                                );
                              },
                              child: Text(
                                isArabicLocale
                                    ? 'البحث على الويب'
                                    : 'Search the web',
                                style: TextStyle(color: Colors.blue[600]),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, idx) {
                          final data = _results[idx];
                          final title =
                              (isArabicLocale
                                      ? (data['nameAR'] ?? data['title'])
                                      : (data['nameEN'] ?? data['title']))
                                  .toString();
                          final author =
                              (isArabicLocale
                                      ? (data['authorAR'] ?? '')
                                      : (data['authorEN'] ??
                                            data['author'] ??
                                            ''))
                                  .toString();
                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BookDetails(book: data),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 10.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _imageFor(
                                      data['image'] ??
                                          data['img'] ??
                                          data['cover'],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          author,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

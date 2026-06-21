import 'package:bayt_alhikma/screens/book_details.dart';
import 'package:bayt_alhikma/utils/styles.dart';
import 'package:bayt_alhikma/view_model/language_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserShelvesScreen extends StatefulWidget {
  final String username;
  final List<String> bookIds;

  const UserShelvesScreen({
    super.key,
    required this.username,
    required this.bookIds,
  });

  @override
  State<UserShelvesScreen> createState() => _UserShelvesScreenState();
}

class _UserShelvesScreenState extends State<UserShelvesScreen> {
  Future<List<Map<String, dynamic>>> _fetchFavoriteBooks() async {
    if (widget.bookIds.isEmpty) return [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('books')
          .get();
      final allBooks = snapshot.docs.map((doc) => doc.data()).toList();

      final favoriteBooks = allBooks.where((book) {
        final rawId = book['ID'] ?? book['id']; // Check both casing cases
        if (rawId == null) return false;
        final String dbId = rawId.toString().trim();
        return widget.bookIds.any((favId) => favId.trim() == dbId);
      }).toList();

      return favoriteBooks;
    } catch (e) {
      debugPrint("Error fetching shelves: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;

    return Scaffold(
      backgroundColor: AppStyles.pageBackground,
      appBar: AppBar(
        title: Text(
          isArabic ? "رفوف ${widget.username}" : "${widget.username}'s Shelves",
          style: const TextStyle(
            fontFamily: 'Andalus',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppStyles.pageBackground,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Image.asset(
              'images/library.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppStyles.pageBackground),
            ),
          ),
          // 2. Opacity Overlay
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.65)),
          ),
          // 3. Content
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchFavoriteBooks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    isArabic ? "لا توجد كتب في الرفوف" : "No books in shelves",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }

              final books = snapshot.data!;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    // Generate Rows (2 items per row)
                    for (int row = 0; row < ((books.length + 1) ~/ 2); row++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: _shelfSlot(context, row * 2, books),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _shelfSlot(context, row * 2 + 1, books),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets matching SavedScreen style ---

  Widget _shelfSlot(
    BuildContext context,
    int index,
    List<Map<String, dynamic>> books,
  ) {
    final hasBook = index < books.length;
    return AspectRatio(
      aspectRatio: 0.60,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: hasBook
              ? _bookTile(context, books[index])
              : Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E9DF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _bookTile(BuildContext context, Map<String, dynamic> book) {
    final bool isArabic = Provider.of<LanguageProvider>(context).isArabic;
    final String? imgPath = book['image'];
    final String title = isArabic
        ? (book['nameAR'] ?? 'Untitled')
        : (book['nameEN'] ?? 'Untitled');
    final String author = isArabic
        ? (book['authorAR'] ?? '')
        : (book['authorEN'] ?? '');

    Widget cover;
    if (imgPath != null && imgPath.isNotEmpty) {
      cover = (imgPath.startsWith('http'))
          ? Image.network(
              imgPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset('images/hero.png'),
            )
          : Image.asset('images/hero.png', fit: BoxFit.cover);
    } else {
      cover = Image.asset('images/hero.png', fit: BoxFit.cover);
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookDetails(book: book)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            author,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

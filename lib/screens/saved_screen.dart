// lib/screens/saved_screen.dart
import 'package:bayt_alhikma/model/Book.dart';
import 'package:bayt_alhikma/view_model/favorites_provider.dart'; // Import Provider
import 'package:bayt_alhikma/view_model/language_provider.dart';
import 'package:bayt_alhikma/view_model/dark_mode.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/styles.dart';
import 'book_details.dart';

class SavedScreen extends StatelessWidget {
  

  static const routeName = '/saved';
  const SavedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDark = Provider.of<DarkModeProvider>(context).isDark;
    final bool isArabicLocale = Provider.of<LanguageProvider>(context).isArabic;

    // LISTEN to the provider
    final favProvider = Provider.of<FavoritesProvider>(context);
    final books = favProvider.favoriteBooks;
    final isLoading = favProvider.isLoading;

    return Scaffold(
      
      
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black : AppStyles.pageBackground,
            border: Border(
              bottom: BorderSide(color:isDark ? AppStyles.primaryGold : Colors.grey.shade400, width: 1,style: BorderStyle.solid),
              top: BorderSide(color: AppStyles.primaryGold , width: 1),
            ),
          ),
          child: AppBar(
            backgroundColor:isDark ? Colors.black : Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              isArabicLocale ? 'أرفف الكتب' : 'Bookshelves',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'images/library.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppStyles.pageBackground),
            ),
          ),
          Positioned.fill(
            child: Container(color: isDark ? Colors.black.withOpacity(0.65) : Colors.white.withOpacity(0.65)),
          ),
          Column(
            children: [
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: books.isEmpty
                          ? Center(
                              child: Text(
                                isArabicLocale
                                    ? 'لا يوجد كتب محفوظة'
                                    : 'No saved books',
                              ),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: [
                                  for (
                                    int row = 0;
                                    row < ((books.length + 1) ~/ 2);
                                    row++
                                  )
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _shelfSlot(
                                              context,
                                              row * 2,
                                              books,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _shelfSlot(
                                              context,
                                              row * 2 + 1,
                                              books,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  // _shelfSlot and _bookTile remain exactly the same as your code...
  // Just ensure _bookTile passes the ID correctly to BookDetails.

  Widget _shelfSlot(BuildContext context, int index, List<Book> books) {
    bool isDark = Provider.of<DarkModeProvider>(context).isDark;
    final hasBook = index < books.length;
    return AspectRatio(
      aspectRatio: 0.60,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withOpacity(0.75) : Colors.white,
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

  Widget _bookTile(BuildContext context, Book b) {
    bool isDark = Provider.of<DarkModeProvider>(context).isDark;
    final bool isArabicLocale = Provider.of<LanguageProvider>(context).isArabic;
    final String? imgPath = b.image;
    final String title = isArabicLocale
        ? b.nameAR ?? 'Untitled'
        : b.nameEN ?? 'Untitled';
    final String author = isArabicLocale ? b.authorAR ?? '' : b.authorEN ?? '';

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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookDetails(
              book: {
                'ID': b.id,
                'nameAR': b.nameAR,
                'nameEN': b.nameEN,
                'authorAR': b.authorAR,
                'authorEN': b.authorEN,
                'descriptionAR': b.descriptionAR,
                'descriptionEN': b.descriptionEN,
                'image': b.image,
                'audio': b.audio,
                'pdf': b.pdf,
                'price': b.price,
              },
            ),
          ),
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
            style: TextStyle(fontSize: 16,color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            author,
            style:  TextStyle(color:isDark ? Colors.white70 : Colors.black54, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

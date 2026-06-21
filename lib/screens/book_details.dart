// lib/screens/book_details.dart
import 'package:bayt_alhikma/screens/hardcopy_screen.dart';
import 'package:bayt_alhikma/screens/pdf_reader.dart';
import 'package:bayt_alhikma/screens/saved_screen.dart';
import 'package:bayt_alhikma/view_model/dark_mode.dart';
import 'package:bayt_alhikma/utils/styles.dart';
import 'package:bayt_alhikma/view_model/favorites_provider.dart';
import 'package:bayt_alhikma/view_model/local_storage_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // IMPORT FIRESTORE
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bayt_alhikma/view_model/language_provider.dart';
import 'now_playing_screen.dart';
import '../utils/responsive.dart';

class BookDetails extends StatefulWidget {
  final Map<String, dynamic> book;
  const BookDetails({super.key, required this.book});

  @override
  State<BookDetails> createState() => _BookDetailsState();
}

class _BookDetailsState extends State<BookDetails> {
  bool _isBookmarked = false;

  bool isArabicLocale([bool listen = true]) {
    return Provider.of<LanguageProvider>(context, listen: listen).isArabic;
  }

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  void _checkIfSaved() {
    final id = widget.book['ID'] ?? widget.book['id'];
    if (id != null) {
      final favorites = LocalStorageService.getFavoritesLocally();
      setState(() {
        _isBookmarked = favorites.contains(id.toString());
      });
    }
  }

  Future<void> _toggleBookmark() async {
    final id = widget.book['ID'] ?? widget.book['id'];
    if (id == null) return;

    final String bookId = id.toString();

    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    try {
      if (_isBookmarked) {
        await Provider.of<FavoritesProvider>(
          context,
          listen: false,
        ).addToFavorites(bookId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isArabicLocale(false) ? 'تم الحفظ' : 'Saved'),
            ),
          );
        }
      } else {
        await Provider.of<FavoritesProvider>(
          context,
          listen: false,
        ).removeFromFavorites(bookId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabicLocale(false) ? 'تم الإزالة' : 'Removed from saved',
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isBookmarked = !_isBookmarked);
      print("Error toggling bookmark: $e");
    }
  }

  // =========================================================
  // NEW: Function to add rating to Firestore
  // =========================================================
  Future<void> _rateBookInFirestore(String bookId, int rating) async {
    try {
      // 1. Find the document where the field 'ID' matches our bookId
      // Note: If your Firestore Document ID IS the bookID, you can skip the where() query
      // and just use .doc(bookId). Assuming 'ID' is a field here:
      final querySnapshot = await FirebaseFirestore.instance
          .collection('books')
          .where('ID', isEqualTo: int.tryParse(bookId) ?? bookId)
          // Note: Try parsing to int if your DB stores IDs as numbers
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docRef = querySnapshot.docs.first.reference;

        // 2. Add the rating to the 'rates' list
        // FieldValue.arrayUnion adds elements to an array but only if they don't exist.
        // If you want to allow duplicate ratings (e.g. for calculating average),
        // strictly speaking you can't push duplicates with arrayUnion easily.
        // However, standard "Add to list" implementation is this:
        await docRef.update({
          'rates': FieldValue.arrayUnion([rating]),
        });

        print("Rating $rating added to Firestore for book $bookId");
      } else {
        print("Book document with ID $bookId not found in Firestore.");
      }
    } catch (e) {
      print("Error updating rating in Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Provider.of<DarkModeProvider>(context).isDark;
    final book = widget.book;

    double coverHeight = Responsive.hp(context, 0.40);
    if (coverHeight > 480) coverHeight = 480;
    if (coverHeight < 220) coverHeight = 220;

    final titleFont = Responsive.fs(context, 20);
    final authorFont = Responsive.fs(context, 18);
    final descFont = Responsive.fs(context, 16);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabicLocale()
              ? (book['nameAR'] ?? 'تفاصيل الكتاب')
              : (book['nameEN'] ?? 'Book Details'),
          style: TextStyle(fontSize: Responsive.fs(context, 18),color: isDark ? Colors.white : Colors.black87),
        ),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HardCopyPage(
                        title: isArabicLocale()
                            ? '${book['nameAR']} ${book['authorAR']}'
                            : '${book['nameEN']} ${book['authorEN']}',
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.book, color:isDark ? Colors.white : Colors.black87),
                    Text(
                      isArabicLocale()
                          ? 'اطلب نسخة مطبوعة'
                          : 'Order Printed Copy',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        decoration: TextDecoration.underline,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 20),

              /// ---------- bookmark ----------
              IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_add_outlined,
                  color: _isBookmarked
                      ? AppStyles.primaryGold
                      : isDark ? Colors.white : Colors.black87,
                  size: 30,
                ),
                onPressed: _toggleBookmark,
              ),
            ],
          ),

          /// ---------- cover ----------
          Container(
            height: coverHeight * .7,
            margin: EdgeInsets.all(Responsive.wp(context, 0.03)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppStyles.fieldBorderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                (book['image'] ?? '').toString(),
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'images/hero.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ),

          Text(
            isArabicLocale() ? (book['nameAR'] ?? '') : (book['nameEN'] ?? ''),
            style: AppStyles.sectionTitle.copyWith(fontSize: titleFont,
                color: isDark ? Colors.white : Colors.black87),
            textAlign: TextAlign.center,
          ),

          Text(
            isArabicLocale()
                ? (book['authorAR'] ?? '')
                : (book['authorEN'] ?? ''),
            style: AppStyles.sectionTitle.copyWith(
              fontSize: authorFont,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),

          // Rating stars
          Builder(
            builder: (context) {
              final id = book['ID'] ?? book['id'];
              final String bookId = id != null ? id.toString() : '';

              if (bookId.isEmpty) return const SizedBox.shrink();

              return FutureBuilder<int?>(
                future: LocalStorageService.getRating(bookId),
                builder: (context, snapshot) {
                  final currentRating = snapshot.data ?? 0;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          isArabicLocale() ? 'قيّم الكتاب:' : 'Rate this book:',
                          style: AppStyles.sectionTitle.copyWith(fontSize: 20, color: isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starIndex = index + 1;
                          final isFilled = starIndex <= currentRating;
                          return IconButton(
                            onPressed: () async {
                              try {
                                // 1. Save locally
                                await LocalStorageService.saveRating(
                                  bookId,
                                  starIndex,
                                );

                                // 2. NEW: Save to Firestore
                                // Pass 'id' directly if it's an int, or bookId string
                                await _rateBookInFirestore(bookId, starIndex);

                                if (mounted) {
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isArabicLocale(false)
                                            ? 'تم التقييم: $starIndex'
                                            : 'Rated: $starIndex',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isArabicLocale(false)
                                          ? 'فشل حفظ التقييم'
                                          : 'Failed to save rating',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: Icon(
                              isFilled ? Icons.star : Icons.star_border,
                              color: AppStyles.primaryGold,
                              size: 30,
                            ),
                            tooltip: isArabicLocale()
                                ? 'تقييم $starIndex'
                                : 'Rate $starIndex',
                          );
                        }),
                      ),
                      if (currentRating > 0)
                        Text(
                          isArabicLocale()
                              ? 'تقييمك: $currentRating/5'
                              : 'Your rating: $currentRating/5',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),

          Divider(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: isArabicLocale()
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Text(
                isArabicLocale() ? 'الوصف:' : 'Description:',
                style: AppStyles.sectionTitle.copyWith(fontSize: 26, color: isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.wp(context, 0.03),
              ),
              child: SingleChildScrollView(
                child: Text(
                  isArabicLocale()
                      ? (book['descriptionAR'] ?? '')
                      : (book['descriptionEN'] ?? ''),
                  textAlign: isArabicLocale()
                      ? TextAlign.right
                      : TextAlign.left,
                  style: TextStyle(fontSize: descFont, height: 1.5, color: isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// ---------- Buttons ----------
          Padding(
            padding: EdgeInsets.all(Responsive.wp(context, 0.03)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.primaryGold,
                    fixedSize: Size(
                      Responsive.wp(context, 0.4),
                      Responsive.hp(context, 0.06),
                    ),
                  ),
                  onPressed: () {
                    final pdfPath = (book['pdf'] ?? '').toString();

                    // 1. Get the ID
                    final rawId = book['ID'] ?? book['id'];
                    final String bookId = rawId != null
                        ? rawId.toString()
                        : 'unknown_book';

                    if (pdfPath.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PdfReaderScreen(
                            filePath: pdfPath,
                            bookId: bookId, // 2. Pass ID here
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                            isArabicLocale(false)
                                ? 'ملف PDF غير متوفر'
                                : 'PDF not available',
                          ),
                        ),
                      );
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.book, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        isArabicLocale() ? 'قراءة' : 'Read',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.iconColor,
                    fixedSize: Size(
                      Responsive.wp(context, 0.4),
                      Responsive.hp(context, 0.06),
                    ),
                  ),
                  onPressed: () {
                    if (book['audio'] == null ||
                        (book['audio'] ?? '').toString().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isArabicLocale(false)
                                ? 'ملف الصوت غير متوفر'
                                : 'Audio not available',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NowPlayingScreen(book: book),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.headset, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        isArabicLocale() ? 'استماع' : 'Listen',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

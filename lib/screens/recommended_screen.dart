import 'package:bayt_alhikma/screens/book_details.dart';
import 'package:bayt_alhikma/screens/search_screen.dart';
import 'package:bayt_alhikma/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:bayt_alhikma/view_model/language_provider.dart';
import 'package:bayt_alhikma/view_model/dark_mode.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// new import to read saved user profile/categories
import 'package:bayt_alhikma/view_model/local_storage_services.dart';
import 'package:hive_flutter/hive_flutter.dart';

class RecommendedScreen extends StatefulWidget {
  static const routeName = '/recommended';
  const RecommendedScreen({super.key});

  @override
  State<RecommendedScreen> createState() => _RecommendedScreenState();
}

class _RecommendedScreenState extends State<RecommendedScreen> {
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> recommendedBooks = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getdata();
  }

  Future<void> getdata() async {
    setState(() => isLoading = true);
    try {
      final querySnapshot = await _firestore.collection('books').get();
      final List<Map<String, dynamic>> books = [];
      for (var doc in querySnapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        books.add(data);
      }
      setState(() {
        recommendedBooks = books;
      });
    } catch (e) {
      // handle error or log
      debugPrint('Error fetching books: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // returns the user's saved categories (lowercased), or empty list if not available
  List<String> _userCategories() {
    try {
      final profile = LocalStorageService.getUserLocally();
      final cats = profile?.categories;
      if (cats == null) return [];
      return cats.map((c) => c.toString().trim().toLowerCase()).toList();
    } catch (e) {
      return [];
    }
  }

  // parse book categories field into list of lowercased strings
  List<String> _bookCategoriesFrom(dynamic src) {
    if (src == null) return [];
    if (src is List) {
      return src.map((e) => e.toString().trim().toLowerCase()).toList();
    }
    final s = src.toString();
    if (s.contains(',')) {
      return s
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    // single category string
    return s.trim().isEmpty ? [] : [s.trim().toLowerCase()];
  }

  // Filter recommendedBooks by user categories.
  List<Map<String, dynamic>> _filteredRecommended() {
    final userCats = _userCategories();
    if (userCats.isEmpty) {
      // no user preferences -> return default slice (e.g. first 10)
      return recommendedBooks.take(10).toList();
    }

    final List<Map<String, dynamic>> filtered = [];
    for (final book in recommendedBooks) {
      final bookCats = _bookCategoriesFrom(book['category'] ?? book['tags']);
      if (bookCats.isEmpty) continue;
      final matches = bookCats.where((c) => userCats.contains(c)).toList();
      if (matches.isNotEmpty) {
        filtered.add(book);
      }
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabicLocale = Provider.of<LanguageProvider>(context).isArabic;
    final bool isDark = Provider.of<DarkModeProvider>(context).isDark;

    return ValueListenableBuilder<Box<UserProfile>>(
      valueListenable: Hive.box<UserProfile>(
        LocalStorageService.boxName,
      ).listenable(),
      builder: (context, profileBox, _) {
        return ValueListenableBuilder(
          valueListenable: Hive.box(
            LocalStorageService.settingsBoxName,
          ).listenable(),
          builder: (context, settingsBox, _) {
            // 1. Calculate Recommendations
            final filtered = _filteredRecommended();

        // 2. Get Last Played Book ID
        final String? lastBookId = settingsBox.get('lastPlayedId');
        Map<String, dynamic> lastRunBook = {};

        // 3. Find the Book Object
        if (lastBookId != null && recommendedBooks.isNotEmpty) {
          lastRunBook = recommendedBooks.firstWhere((book) {
            final title = book['nameEN'] ?? book['title'] ?? 'audiobook';
            final genId = title
                .toString()
                .replaceAll(RegExp(r'[^\w\s]+'), '')
                .replaceAll(' ', '_');

            return (book['id'] == lastBookId) || (genId == lastBookId);
          }, orElse: () => {});
        }

        return ModalProgressHUD(
          inAsyncCall: isLoading,
          child: Scaffold(
            backgroundColor: isDark ? Colors.black : AppStyles.pageBackground,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => SearchScreen()),
                        );
                      },
                      icon: Icon(Icons.search, color: AppStyles.iconColor),
                    ),

                    // ==================================================
                    // FIX: Check lastRunBook.isNotEmpty instead of filtered
                    // ==================================================
                    if (lastRunBook.isNotEmpty)
                      GestureDetector(
                        // Add navigation to open the book when clicked
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BookDetails(book: lastRunBook),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppStyles.fieldBorderColor,
                                    width: 1.4,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Stack(
                                  children: [
                                    Image.network(
                                      lastRunBook['image'] ?? '', // Removed [0]
                                      height: 300,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey[300],
                                        height: 300,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.only(
                                        top: 60,
                                        left: 16,
                                        right: 16,
                                      ),
                                      height: 300,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.9),
                                          ],
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 50.0,
                                                    horizontal: 8.0,
                                                  ),
                                              child: Text(
                                                isArabicLocale
                                                    ? lastRunBook['nameAR'] ??
                                                          ''
                                                    : lastRunBook['nameEN'] ??
                                                          '',
                                                style: AppStyles.sectionTitle
                                                    .copyWith(
                                                      color: Colors.white,
                                                    ),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                isArabicLocale
                                                    ? "ل${lastRunBook['authorAR'] ?? ''}"
                                                    : "by ${lastRunBook['authorEN'] ?? ''}",
                                                style: AppStyles.sectionTitle
                                                    .copyWith(
                                                      color: Colors.white,
                                                      fontSize: 22,
                                                    ),
                                              ),
                                              const SizedBox(height: 20),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 6,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.play_circle_fill,
                                                      color:
                                                          AppStyles.primaryGold,
                                                      size: 40,
                                                    ),
                                                    Text(
                                                      isArabicLocale
                                                          ? "تابع الاستماع"
                                                          : "Continue listening",
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
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
                      )
                    else
                      // Fallback Empty Container if no book has been played yet
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        // You can put a placeholder text or leave it empty
                        child: Center(
                          child: Text(
                            isArabicLocale
                                ? "ابدأ القراءة الآن"
                                : "Start reading now",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Recommended Section Title
                    Text(
                      isArabicLocale ? "موصى به لك" : "Recommended for you",
                      style: AppStyles.sectionTitle.copyWith(
                        fontSize: 26,
                        fontFamily: isArabicLocale
                            ? 'Arabic Typesetting'
                            : 'Andalus',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Recommended List
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                isArabicLocale
                                    ? 'لا توجد توصيات'
                                    : 'No recommendations',
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final book = filtered[index];
                                final List<dynamic> ratesList =
                                    (book['rates'] as List?) ?? [];

                                double averageRating = 0.0;
                                int numOfRates = 0;

                                if (ratesList.isNotEmpty) {
                                  numOfRates = ratesList.length;
                                  final sum = ratesList.fold(0.0, (prev, curr) {
                                    return prev + (curr as num).toDouble();
                                  });
                                  averageRating = sum / numOfRates;
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              BookDetails(book: book),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            book['image'] ?? '',
                                            width: 60,
                                            height: 90,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Image.asset(
                                                  'images/hero.png',
                                                  width: 60,
                                                  height: 90,
                                                  fit: BoxFit.cover,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isArabicLocale
                                                    ? book['nameAR'] ?? ''
                                                    : book['nameEN'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                isArabicLocale
                                                    ? "ل${book['authorAR'] ?? ''}"
                                                    : "By ${book['authorEN'] ?? ''}",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: isDark? Colors.white70 : Colors.black54,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  ...List.generate(5, (i) {
                                                    if (averageRating >=
                                                        i + 1) {
                                                      return Icon(
                                                        Icons.star,
                                                        color: AppStyles
                                                            .primaryGold,
                                                        size: 16,
                                                      );
                                                    } else if (averageRating >
                                                            i &&
                                                        averageRating < i + 1) {
                                                      return Icon(
                                                        Icons.star_half,
                                                        color: AppStyles
                                                            .primaryGold,
                                                        size: 16,
                                                      );
                                                    } else {
                                                      return Icon(
                                                        Icons.star_border,
                                                        color: AppStyles
                                                            .primaryGold,
                                                        size: 16,
                                                      );
                                                    }
                                                  }),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    averageRating
                                                        .toStringAsFixed(1),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '($numOfRates)',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    }  
  );
 }
 }
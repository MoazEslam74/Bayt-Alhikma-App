import 'package:bayt_alhikma/view_model/dark_mode.dart'; // Import Provider
import 'package:bayt_alhikma/view_model/language_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/styles.dart';
import '../utils/responsive.dart';
import 'search_screen.dart';
import 'book_details.dart';

class StoreScreen extends StatefulWidget {
  static const routeName = '/store';
  StoreScreen({Key? key}) : super(key: key);

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  List<Map<String, dynamic>> storeBooks = [];
  final _firestore = FirebaseFirestore.instance;
  bool isLoading = false;
  int _selectedIndex = 0;
  List<List<String>> _allCategories = [];

  bool isArabicLocale([bool listen = true]) {
    return Provider.of<LanguageProvider>(context, listen: listen).isArabic;
  }

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
        storeBooks = books;
      });
    } catch (e) {
      debugPrint('Error fetching books: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void setCategories() {
    _allCategories.clear();
    _allCategories.add(['الكل','All']) ;
    _allCategories.add(['📚 خيال','📚 Fiction']);
    _allCategories.add(['🔬 علم','🔬 Science']);
   
    _allCategories.add(['📜 تاريخ','📜 History']);
    _allCategories.add(['🧠 فلسفة','🧠 Philosophy']);
    _allCategories.add(['🤲 دين','🤲 Religion']);
    _allCategories.add(['📖 شعر','📖 Poetry']);
    _allCategories.add(['👶 أطفال','👶 Children']);
    _allCategories.add(['❤️ رومانسية','❤️ Romance']);
    _allCategories.add(['💼 أعمال','💼 Business']);
    _allCategories.add(['💻 تكنولوجيا','💻 Technology']);
  
    _allCategories.add(['🗳️ سياسية','🗳️ Political']);
    _allCategories.add(['🏥 طبية','🏥 Medical']);
  }

  @override
  Widget build(BuildContext context) {
    setCategories();
    // 1. Check Dark Mode
    final isDark = Provider.of<DarkModeProvider>(context).isDark;

    final bool isArabic = isArabicLocale();
    final gridCross = MediaQuery.of(context).size.width > 600 ? 3 : 2;
    final itemWidth =
        (MediaQuery.of(context).size.width - Responsive.wp(context, 0.12)) /
        gridCross;
    final itemImageHeight = itemWidth * 1.0;

    List<Map<String, dynamic>> displayedBooks;

    if (_selectedIndex == 0) {
      displayedBooks = storeBooks;
    } else {
      List<String> selectedCat = _allCategories[_selectedIndex];
      String keyword = selectedCat[1]
          .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '')
          .trim();
      displayedBooks = storeBooks.where((book) {
        String bookCategory = ( book['category'] ?? '').toString();
        return bookCategory.toLowerCase().contains(keyword.toLowerCase());
      }).toList();
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : AppStyles.pageBackground,
      body: SafeArea(
        child: Stack(
          children: [
            if (!isDark)
              Positioned.fill(
                child: Image.asset(
                  'images/Baghdad.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppStyles.pageBackground),
                ),
              ),
            Positioned.fill(
              child: Container(
                color: isDark ? Colors.black : Colors.white.withOpacity(0.003),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                Responsive.wp(context, 0.048),
                Responsive.hp(context, 0.02),
                Responsive.wp(context, 0.048),
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      // Dynamic Header
                      color: isDark
                          ? Colors.grey[900]
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isArabic ? 'المتجر' : 'Explore Market',
                            style: AppStyles.sectionTitle.copyWith(
                              fontSize: 26,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => SearchScreen()),
                            );
                          },
                          icon: Icon(
                            Icons.search,
                            color: isDark
                                ? Colors.white70
                                : AppStyles.iconColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Categories Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_allCategories.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                            child: _pill(
                              isArabic ? _allCategories[index][0] : _allCategories[index][1],
                              active: _selectedIndex == index,
                              isDark: isDark,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Expanded(
                    child: isLoading && storeBooks.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : displayedBooks.isEmpty
                        ? Center(
                            child: Text(
                              isArabic
                                  ? "لا توجد كتب في هذا القسم"
                                  : "No books in this category",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: EdgeInsets.only(
                              bottom: Responsive.hp(context, 0.06),
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: gridCross,
                                  mainAxisSpacing: Responsive.hp(context, 0.06),
                                  crossAxisSpacing: Responsive.wp(
                                    context,
                                    0.03,
                                  ),
                                  childAspectRatio:
                                      (itemWidth) /
                                      (itemImageHeight +
                                          Responsive.hp(context, 0.19)),
                                ),
                            itemCount: displayedBooks.length,
                            itemBuilder: (ctx, i) {
                              return _productCard(
                                context,
                                displayedBooks[i],
                                itemImageHeight,
                                isDark,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, {bool active = false, required bool isDark}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: active
            ? AppStyles.primaryGold
            : (isDark ? Colors.grey[800] : Colors.white.withOpacity(0.9)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? AppStyles.primaryGold
              : (isDark ? Colors.grey[700]! : Colors.grey.shade300),
          width: 1.4,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _productCard(
    BuildContext context,
    Map<String, dynamic> data,
    double imageHeight,
    bool isDark,
  ) {
    final String? img = (data['img'] ?? data['image'] ?? data['cover'])
        ?.toString();
    final String title =
        (isArabicLocale() ? data['nameAR'] : data['nameEN'] ?? '').toString();
    final String author =
        (isArabicLocale() ? data['authorAR'] : data['authorEN'] ?? '')
            .toString();
    final String price = data['price'] == 0
        ? 'Free'
        : (data['price']?.toString() ?? '');
    final List<dynamic> ratesList = (data['rates'] as List?) ?? [];

    double averageRating = 0.0;
    int numOfRates = 0;

    if (ratesList.isNotEmpty) {
      numOfRates = ratesList.length;
      final sum = ratesList.fold(0.0, (prev, curr) {
        return prev + (curr as num).toDouble();
      });
      averageRating = sum / numOfRates;
    }
    Widget imageWidget = (img != null && img.isNotEmpty)
        ? (img.startsWith('http')
              ? Image.network(
                  img,
                  width: double.infinity,
                  height: imageHeight,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Image.asset('images/hero.png', fit: BoxFit.cover),
                )
              : Image.asset(
                  img,
                  width: double.infinity,
                  height: imageHeight,
                  fit: BoxFit.cover,
                ))
        : Image.asset(
            'images/hero.png',
            width: double.infinity,
            height: imageHeight,
            fit: BoxFit.cover,
          );

    return InkWell(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => BookDetails(book: data)));
      },
      child: Container(
        decoration: BoxDecoration(
          // DYNAMIC CARD BACKGROUND
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : AppStyles.veryLightPink,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageWidget,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              author,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.black54,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                ...List.generate(5, (i) {
                  if (averageRating >= i + 1) {
                    return Icon(
                      Icons.star,
                      color: AppStyles.primaryGold,
                      size: 16,
                    );
                  } else if (averageRating > i && averageRating < i + 1) {
                    return Icon(
                      Icons.star_half,
                      color: AppStyles.primaryGold,
                      size: 16,
                    );
                  } else {
                    return Icon(
                      Icons.star_border,
                      color: AppStyles.primaryGold,
                      size: 16,
                    );
                  }
                }),
                const SizedBox(width: 8),
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '($numOfRates)',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                // ElevatedButton(
                //   onPressed: () {},
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: isDark ? Colors.grey[800] : Colors.black87,
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 14,
                //       vertical: 10,
                //     ),
                //   ),
                //   child: const Text(
                //     'Buy',
                //     style: TextStyle(color: Colors.white),
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

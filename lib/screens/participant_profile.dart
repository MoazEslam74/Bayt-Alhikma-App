// lib/screens/participant_profile.dart
import 'package:bayt_alhikma/screens/user_shelves_screen.dart';
import 'package:bayt_alhikma/utils/styles.dart';
import 'package:bayt_alhikma/view_model/language_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ParticipantProfile extends StatefulWidget {
  final String username;

  const ParticipantProfile({super.key, required this.username});

  @override
  State<ParticipantProfile> createState() => _ParticipantProfileState();
}

class _ParticipantProfileState extends State<ParticipantProfile> {
  // Copy of the avatar list to ensure images match correctly
  final List<Map<String, String?>> avatars = [
    {
      'name': '1.png',
      "character_AR": 'نظام الملك',
      "character_EN": 'Nizam Al-Mulk',
      'link': 'https://archive.org/download/3_20251215_20251215_1250/1.png',
    },
    {
      'name': '2.png',
      "character_AR": 'فاطمة الفهرية',
      "character_EN": 'Fatima Al-Fihri',
      'link': 'https://archive.org/download/3_20251215_20251215_1250/2.png',
    },
    {
      'name': '3.png',
      "character_AR": 'ابن المقفع',
      "character_EN": 'Ibn Al-Muqaffa',
      'link': 'https://archive.org/download/3_20251215_20251215_1250/3.png',
    },
    {
      'name': '4.png',
      "character_AR": 'عباس بن فرناس',
      "character_EN": 'Abbas Ibn Al-Farnas',
      'link': 'https://archive.org/download/3_20251215_20251215_1250/4.png',
    },
    {
      'name': '5.png',
      "character_AR": 'الجزري',
      "character_EN": 'Al-Jazari',
      'link': 'https://archive.org/download/3_20251215_20251215_1250/5.png',
    },
    {
      'name': '6.png',
      "character_AR": 'مريم الاسطرلابية',
      "character_EN": 'Maryam Al-Astrulabiya',
      'link': 'https://archive.org/download/3_20251215_20251215_1250/6.png',
    },
    {
      'name': '7.png',
      "character_AR": 'الشفاء بنت عبد الله',
      "character_EN": 'Al-Shifa Bint Abdullah',
      'link': 'https://archive.org/download/3_20251215_20251215_1250/7.png',
    },
    {
      'name': '8.png',
      "character_AR": 'الحسن بن الهيثم',
      "character_EN": 'Hassan Ibn Al-Haytham',
      'link': 'https://archive.org/download/3_20251215_20251215_1250/8.png',
    },
    {
      'name': '9.png',
      "character_AR": 'الخوارزمي',
      "character_EN": 'Al-Khwarizmi',
      'link': 'https://archive.org/download/3_20251215_20251215_1250/9.png',
    },
    {
      'name': '10.png',
      "character_AR": 'هارون الرشيد',
      "character_EN": 'Harun Al-Rashid',
      'link': 'https://archive.org/download/3_20251215_20251215_1250/10.png',
    },
    {
      'name': '11.png',
      "character_AR": 'زينب الشَّعرية',
      "character_EN": 'Zainab Al-Shairiya',
      'link': 'https://archive.org/download/3_20251215_20251215_1250/11.png',
    },
    {
      'name': '12.png',
      "character_AR": 'فاطمة بنت العباس',
      "character_EN": 'Fatima Bint Al-Abbas',
      'link': 'https://archive.org/download/3_20251215_20251215_1250/12.png',
    },
    {
      'name': '13.png',
      "character_AR": 'الإمام الشافعي',
      "character_EN": 'Al-Shafi\'imam\'',
      'link': 'https://archive.org/download/3_20251215_20251215_1250/13.png',
    },
    {
      'name': '14.png',
      "character_AR": 'البيروني',
      "character_EN": 'Al-Biruni',
      'link': 'https://archive.org/download/3_20251215_20251215_1250/14.png',
    },
    {
      'name': '15.png',
      "character_AR": 'ابن سينا',
      "character_EN": 'Ibn Sina',
      'link': 'https://archive.org/download/3_20251215_20251215_1250/15.png',
    },
  ];

  Future<Map<String, dynamic>?> _fetchUserProfile() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('profils')
          .where('username', isEqualTo: widget.username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    bool isArabicLocale = Provider.of<LanguageProvider>(context).isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username),
        backgroundColor: AppStyles.primaryGold,
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'images/astrolab.png',
              alignment: Alignment.bottomCenter,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppStyles.pageBackground),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.06)),
          ),

          // Content
          FutureBuilder<Map<String, dynamic>?>(
            future: _fetchUserProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return Center(
                  child: Text(
                    isArabicLocale ? 'مستخدم غير موجود' : 'User not found',
                  ),
                );
              }

              final data = snapshot.data!;

              // ==========================================
              // NEW: Check for Security Status
              // ==========================================
              final bool isSecure = data['secure'] ?? false;

              if (!isSecure) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    height: MediaQuery.of(context).size.height * 0.5,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 80,
                          color: AppStyles.primaryGold,
                        ),

                        const SizedBox(height: 16),
                        Text(
                          isArabicLocale
                              ? "هذا الحساب محمي"
                              : "The account is secured",
                          style: TextStyle(
                            fontSize: 22,
                            color: AppStyles.primaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              // ==========================================

              final firstname = data['firstname'] ?? '';
              final lastname = data['lastname'] ?? '';
              final email = data['email'] ?? '';
              final List<dynamic> cats = data['categories'] ?? [];
              final categories = cats.join(", ");
              final String avatarName = data['avatar'] ?? '1.png';
              final List<String> bookIDs = List<String>.from(
                data['favorites'] ?? [],
              );
              print('Book IDs for ${widget.username}: $bookIDs');
              // Resolve Avatar URL
              final String? avatarUrl = avatars.firstWhere(
                (a) => a['name'] == avatarName,
                orElse: () => {},
              )['link'];

              final String finalAvatarUrl =
                  avatarUrl ??
                  'https://archive.org/download/3_20251215_20251215_1250/$avatarName';

              return SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  width: double.infinity,
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppStyles.primaryGold,
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.transparent,
                          backgroundImage: NetworkImage(finalAvatarUrl),
                          onBackgroundImageError: (_, __) {},
                        ),
                      ),

                      // Info Box
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: AppStyles.primaryGold,
                            width: 2.0,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow(
                                isArabicLocale ? 'اسم المستخدم:' : 'Username:',
                                widget.username,
                              ),
                              const SizedBox(height: 12),
                              _infoRow(
                                isArabicLocale ? 'الاسم الكامل:' : 'Name:',
                                '$firstname $lastname',
                              ),
                              const SizedBox(height: 12),
                              _infoRow(
                                isArabicLocale ? 'البريد:' : 'Email:',
                                email,
                              ),
                              const SizedBox(height: 12),
                              _infoRow(
                                isArabicLocale ? 'الفئات:' : 'Categories:',
                                categories.isEmpty ? '-' : categories,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      UserShelves(widget.username, bookIDs),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.normal,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget UserShelves(String username, List<String> books) {
    isArabicLocale() {
      return Provider.of<LanguageProvider>(context, listen: false).isArabic;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserShelvesScreen(
              username: username,
              bookIds: books, // Pass the list of favorites IDs
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: Colors.yellowAccent,
            style: BorderStyle.solid,
          ),
        ),
        width: MediaQuery.of(context).size.width * 0.7,
        child: Stack(
          children: [
            Image.asset(
              'images/library.png',
              alignment: Alignment.bottomCenter,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppStyles.pageBackground),
            ),
            Positioned(
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                color: Colors.transparent,
                child: Center(
                  child: Text(
                    isArabicLocale()
                        ? 'رفوف الكتب لـ $username'
                        : '$username book Shelves',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

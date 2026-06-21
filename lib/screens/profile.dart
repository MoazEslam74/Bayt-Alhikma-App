// lib/screens/profile.dart
import 'package:bayt_alhikma/main.dart';
import 'package:bayt_alhikma/screens/edit_profile.dart';
import 'package:bayt_alhikma/view_model/language_provider.dart';
import 'package:bayt_alhikma/view_model/local_storage_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bayt_alhikma/view_model/dark_mode.dart';
import '../utils/styles.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  AppStyles appStyles = AppStyles();
  bool isSecure = false;

  String firstname = '';
  String lastname = '';
  String username = '';
  String email = '';
  List<String> categories = [];

  // Default avatar
  String currentAvatar = '1.png';

  // Avatar Data List
  List<Map<String, String?>> avatars = [
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = LocalStorageService.getUserLocally();
    if (user != null) {
      setState(() {
        firstname = user.firstname;
        lastname = user.lastname;
        username = user.username;
        email = user.email;
        categories = user.categories;
        currentAvatar = user.avatar;
        // Load secure status locally
        isSecure = user.isSecure;
      });
      _fetchSecureStatus();
    }
  }

  Future<void> _fetchSecureStatus() async {
    if (username.isEmpty) return;
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('profils')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        if (mounted) {
          setState(() {
            bool cloudSecure = data['secure'] ?? false;
            if (isSecure != cloudSecure) {
              isSecure = cloudSecure;
              LocalStorageService.updateSecureStatusLocally(isSecure);
            }
            if (data['avatar'] != null) {
              currentAvatar = data['avatar'];
              LocalStorageService.updateAvatarLocally(currentAvatar);
            }
          });
        }
      }
    } catch (e) {
      print("Error fetching secure status: $e");
    }
  }

  Future<void> _toggleSecureStatus() async {
    setState(() {
      isSecure = !isSecure;
    });
    await LocalStorageService.updateSecureStatusLocally(isSecure);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('profils')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await FirebaseFirestore.instance
            .collection('profils')
            .doc(docId)
            .update({'secure': isSecure});
      }
    } catch (e) {
      print("Error updating secure status: $e");
    }
  }

  Future<void> _changeAvatar(String newAvatarName) async {
    setState(() {
      currentAvatar = newAvatarName;
    });

    await LocalStorageService.updateAvatarLocally(newAvatarName);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('profils')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docRef = querySnapshot.docs.first.reference;
        await docRef.update({'avatar': newAvatarName});
      }
    } catch (e) {
      print("Error updating avatar in Firestore: $e");
    }
  }

  void _showAvatarPickerDialog(bool isArabic) {
    final int numberOfAvatars = 15;
    final isDark = Provider.of<DarkModeProvider>(context, listen: false).isDark;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          title: Text(
            isArabic ? 'اختر شخصية' : 'Choose Avatar',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: GridView.builder(
              itemCount: numberOfAvatars,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final String fileName = '${index + 1}.png';
                final String? avatarUrl = avatars.firstWhere(
                  (a) => a['name'] == fileName,
                  orElse: () => {},
                )['link'];

                final String finalUrl =
                    avatarUrl ??
                    'https://archive.org/download/3_20251215_20251215_1250/$fileName';

                return InkWell(
                  onTap: () {
                    _changeAvatar(fileName);
                    Navigator.pop(ctx);
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: currentAvatar == fileName
                                  ? AppStyles.primaryGold
                                  : Colors.transparent,
                              width: 3,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.transparent,
                            backgroundImage: NetworkImage(finalUrl),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // Shows "1", "2" etc.
                        (() {
                          final map = avatars.firstWhere(
                            (a) => a['name'] == fileName,
                            orElse: () => <String, String>{
                              'name': fileName,
                              'character_AR': '',
                              'character_EN': '',
                            },
                          );
                          final ar = map['character_AR'] ?? '';
                          final en = map['character_EN'] ?? '';
                          if (isArabic)
                            return ar.isNotEmpty
                                ? ar
                                : (en.isNotEmpty
                                      ? en
                                      : map['character_EN'] ?? fileName);
                          return en.isNotEmpty
                              ? en
                              : (ar.isNotEmpty
                                    ? ar
                                    : map['character_AR'] ?? fileName);
                        })(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isArabicLocale = Provider.of<LanguageProvider>(context).isArabic;
    // 1. GET THEME STATE
    bool isDark = Provider.of<DarkModeProvider>(context).isDark;

    final String? currentAvatarUrl = avatars.firstWhere(
      (a) => a['name'] == currentAvatar,
      orElse: () => {},
    )['link'];

    final String finalMainAvatarUrl =
        currentAvatarUrl ??
        'https://archive.org/download/3_20251215_20251215_1250/$currentAvatar';

    return Scaffold(
      backgroundColor: isDark
          ? Colors.black
          : AppStyles.pageBackground, // Main BG
      body: Stack(
        children: [
          // Hide the background image in dark mode if it conflicts, or dim it
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
            child: Container(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.white.withOpacity(0.06),
            ),
          ),
          SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.transparent,
              child: Column(
                children: [
                  // Circle Avatar Container
                  InkWell(
                    onTap: () => _showAvatarPickerDialog(isArabicLocale),
                    child: Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(vertical: 20.0),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        // 2. DYNAMIC CONTAINER COLOR
                        color: isDark ? Colors.grey[900] : Colors.white,
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
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 80,
                            backgroundImage: NetworkImage(finalMainAvatarUrl),
                            backgroundColor: Colors.transparent,
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppStyles.primaryGold,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.black : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Info Box
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      // 3. DYNAMIC BACKGROUND
                      color: isDark
                          ? Colors.grey[850]
                          : Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: AppStyles.primaryGold,
                        width: 2.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[600]!
                                  : Colors.black.withOpacity(0.8),
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black26
                                    : Colors.white.withOpacity(0.8),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            // 4. INNER CONTAINER COLOR
                            color: isDark ? Colors.grey[900] : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isArabicLocale
                                          ? 'اسم المستخدم: $username'
                                          : 'Username: $username',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isArabicLocale
                                          ? 'الاسم الكامل: $firstname $lastname'
                                          : 'Name: $firstname $lastname',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isArabicLocale
                                          ? 'البريد: $email'
                                          : 'Email: $email',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isArabicLocale
                                          ? 'الفئات: ${categories.join(", ")}'
                                          : 'Categories: ${categories.join(", ")}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditProfile(
                                        username: username,
                                        email: email,
                                        firstname: firstname,
                                        lastname: lastname,
                                        categories: categories,
                                      ),
                                    ),
                                  ).then((_) => _loadUserData());
                                },
                                icon: const Icon(Icons.edit),
                              ),
                            ],
                          ),
                        ),

                        // Dark Mode Toggle
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: InkWell(
                            onTap: () {},
                            child: Row(
                              children: [
                                Consumer<DarkModeProvider>(
                                  builder: (context, dm, _) {
                                    return GestureDetector(
                                      onTap: () => dm.toggle(),
                                      child: Row(
                                        children: [
                                          Icon(
                                            dm.isDark
                                                ? Icons.nights_stay
                                                : Icons.wb_sunny,
                                            color: dm.isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                          const SizedBox(width: 8.0),
                                          Text(
                                            isArabicLocale
                                                ? (dm.isDark
                                                      ? 'الوضع الليلي'
                                                      : 'الوضع النهاري')
                                                : (dm.isDark
                                                      ? 'Dark Mode'
                                                      : 'Light Mode'),
                                                      style: TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        // SECURITY SECTION
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return StatefulBuilder(
                                    builder: (context, setDialogState) {
                                      return AlertDialog(
                                        // Dynamic dialog background
                                        backgroundColor: isDark
                                            ? Colors.grey[900]
                                            : Colors.white,
                                        title: Text(
                                          isArabicLocale
                                              ? 'الأمان'
                                              : 'Security',
                                          style: TextStyle(
                                            fontFamily: 'Al-Tarhouny',
                                            fontSize: 20,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                        content: Text(
                                          isArabicLocale
                                              ? 'لضمان أمان حسابك، لا تشارك كلمة مرورك مع أي شخص.'
                                              : 'To ensure the security of your account, Do not share your password with anyone.',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black87,
                                          ),
                                        ),
                                        actions: [
                                          Column(
                                            children: [
                                              const Divider(height: 15),
                                              InkWell(
                                                onTap: () async {
                                                  await _toggleSecureStatus();
                                                  setDialogState(() {});
                                                },
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      isSecure
                                                          ? Icons.visibility
                                                          : Icons
                                                                .visibility_off,
                                                      color: isSecure
                                                          ? Colors.green
                                                          : Colors.grey,
                                                    ),
                                                    const SizedBox(width: 8.0),
                                                    Flexible(
                                                      child: Text(
                                                        isArabicLocale
                                                            ? 'معلومات حسابي مرئية.'
                                                            : 'My account info is visible.',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color: isSecure
                                                              ? Colors.green
                                                              : (isDark
                                                                    ? Colors
                                                                          .white70
                                                                    : Colors
                                                                          .black54),
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text(
                                              isArabicLocale ? 'حسناً' : 'OK',
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.security),
                                const SizedBox(width: 4.0),
                                Text(isArabicLocale ? 'الأمان' : 'Security',style: TextStyle( fontSize: 16),),
                              ],
                            ),
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
    );
  }
}

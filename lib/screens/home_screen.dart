// lib/screens/home_screen.dart
import 'package:bayt_alhikma/screens/coffe_shop_screen.dart';
import 'package:bayt_alhikma/screens/profile.dart';
import 'package:bayt_alhikma/screens/recommended_screen.dart';
import 'package:bayt_alhikma/view_model/language_provider.dart';
import 'package:bayt_alhikma/view_model/dark_mode.dart';
import 'package:bayt_alhikma/view_model/local_storage_services.dart'; // IMPORTANT: Added to clear local data
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'store_screen.dart';
import 'search_screen.dart';
import 'saved_screen.dart';
import 'now_playing_screen.dart';
import '../utils/styles.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  late User? loggedInUser;
  int _currentIndex = 0;

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('User is signed in: ${user.email}');
        loggedInUser = user;
      } else {
        print('No user is signed in.');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  final List<Widget> _pages = [
    const RecommendedScreen(),
    StoreScreen(),
    const SavedScreen(),
    const CoffeeScreen(),
    const Profile(),
  ];

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    bool isDark = Provider.of<DarkModeProvider>(context).isDark;
    bool isArabicLocale = Provider.of<LanguageProvider>(context).isArabic;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
      
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black : AppStyles.pageBackground,
            border: Border(
              bottom: BorderSide(color:isDark ? AppStyles.primaryGold : Colors.grey.shade400, width: 2,style: BorderStyle.solid),
              top: BorderSide(color: AppStyles.primaryGold , width: 1),
            ),
          ),
          child: AppBar(
            title: Text(
              isArabicLocale ? 'بيت الحكمة' : 'Bayt Al-Hikma',
              style: TextStyle(
                color: AppStyles.primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor:  isDark ? Colors.black : Colors.white,
            elevation: 0,
            actions: [
              InkWell(
                
                onTap: () {
                  isArabicLocale
                      ? Provider.of<LanguageProvider>(context, listen: false)
                          .changeLanguage(Locale('en', 'US'))
                      : Provider.of<LanguageProvider>(context, listen: false)
                          .changeLanguage(Locale('ar', 'SA'));
                },
                child: Column(
                  children: [
                    const Icon(Icons.language, size: 25),
                    Text(
                      isArabicLocale ? 'EN' : 'عربي',
                      style: TextStyle(
                        color: AppStyles.primaryGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              ),
              
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.logout, size: 25),
                onPressed: () async {
                  // 1. Sign out of Firebase
                  await _auth.signOut();
          
                  // 2. Wipe the encrypted local profile data so the next login is clean
                  await LocalStorageService.clearUserData();
          
                  // 3. Navigate back to login screen
                  if (!mounted) return;
                  Navigator.of(context).pushReplacementNamed('/login');
                },
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppStyles.primaryGold,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.recommend),
            label: isArabicLocale ? 'أكتشف' : 'Discover',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.store),
            label: isArabicLocale ? 'المتجر' : 'Store',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bookmarks),
            label: isArabicLocale ? 'المحفوظات' : 'Saved',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.coffee),
            label: isArabicLocale ? 'المقهى' : 'The Coffee Shop',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline_outlined),
            label: isArabicLocale ? 'الملف الشخصي' : 'Profile',
          ),
        ],
      ),
    );
  }
}
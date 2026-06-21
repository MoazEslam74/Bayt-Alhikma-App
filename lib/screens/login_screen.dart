// lib/screens/login_screen.dart
import 'package:bayt_alhikma/view_model/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/styles.dart';
import 'signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bayt_alhikma/view_model/local_storage_services.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';

  LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  late String _email = '';
  late String _password = '';

  Widget _buildInputField({
    required String hint,
    required TextEditingController controller,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppStyles.fieldBorderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            offset: const Offset(6, 8),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        onChanged: (observed) {
          if (controller == _emailController) {
            _email = observed;
          } else if (controller == _passwordController) {
            _password = observed;
          }
        },
        obscureText: obscure,
        decoration: InputDecoration(hintText: hint, border: InputBorder.none),
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_email.isEmpty || _password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _email.trim(),
        password: _password,
      );

      // ==========================================
      // التحقق: هل المستخدم قام بتفعيل الإيميل؟
      // ==========================================
      if (!userCredential.user!.emailVerified) {
        // لو مفعلش الإيميل، بنعمله تسجيل خروج ونظهرله رسالة
        await _auth.signOut();
        setState(() => _isLoading = false);
        
        final isArabic = Provider.of<LanguageProvider>(context, listen: false).isArabic;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic 
              ? 'برجاء تفعيل بريدك الإلكتروني أولاً لتتمكن من الدخول' 
              : 'Please verify your email address first to log in.'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: isArabic ? 'إعادة الإرسال' : 'Resend',
              onPressed: () async {
                // ميزة إضافية: لو نسي بيبعتله اللينك تاني
                try {
                  await userCredential.user!.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isArabic ? 'تم إرسال الرابط مرة أخرى' : 'Link resent successfully')),
                  );
                } catch (e) {
                  print(e);
                }
              },
            ),
          ),
        );
        return; // بنوقف الدالة هنا ومابيدخلش التطبيق
      }

      final uid = userCredential.user!.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('profils')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        throw Exception("User profile not found in database");
      }

      final data = userDoc.data() as Map<String, dynamic>;

      final userProfile = UserProfile(
        uid: uid,
        firstname: data['firstname'] ?? '',
        lastname: data['lastname'] ?? '',
        username: data['username'] ?? '',
        email: _email.trim(),
        categories: List<String>.from(data['categories'] ?? []),
      );

      await LocalStorageService.saveUserLocally(userProfile);

      if (!mounted) return;

      setState(() => _isLoading = false);

      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      print('Login failed: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isArabicLocale = languageProvider.isArabic;

    final media = MediaQuery.of(context);
    final width = media.size.width;

    return ModalProgressHUD(
      inAsyncCall: _isLoading,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      if (isArabicLocale) {
                        languageProvider.changeLanguage(const Locale('en'));
                      } else {
                        languageProvider.changeLanguage(const Locale('ar'));
                      }
                    },
                    child: Column(
                      children: [
                        const Icon(Icons.language),
                        const SizedBox(height: 6),
                        Text(
                          isArabicLocale ? 'English' : 'العربية',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 160,
                    child: Center(
                      child: Column(
                        children: [
                          Image.asset(
                            'images/logo_placeholder.png',
                            height: 110,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isArabicLocale ? 'بَيْت الْحِكْمَة' : 'BAYT AL-HIKMA',
                            style: AppStyles.logoTextStyle,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  _buildInputField(
                    hint: isArabicLocale ? 'البريد الإلكتروني' : 'Email',
                    controller: _emailController,
                  ),
                  const SizedBox(height: 18),

                  _buildInputField(
                    hint: isArabicLocale ? 'كلمة المرور' : 'Password',
                    controller: _passwordController,
                    obscure: true,
                  ),
                  const SizedBox(height: 26),

                  SizedBox(
                    width: width * 0.45,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.primaryGold,
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.login, color: Colors.white),
                      label: Text(
                        isArabicLocale ? 'تسجيل الدخول' : 'Sign in',
                        style: const TextStyle(fontSize: 16),
                      ),
                      onPressed: _handleLogin,
                    ),
                  ),

                  const SizedBox(height: 26),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          offset: const Offset(0, 6),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(SignUpScreen.routeName);
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppStyles.lightBeige,
                        ),
                        child: Icon(
                          Icons.star,
                          size: 16,
                          color: AppStyles.primaryGold,
                        ),
                      ),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 12,
                        ),
                        child: Text(
                          isArabicLocale ? 'إنشاء حساب' : 'Sign up',
                          style: TextStyle(
                            color: AppStyles.primaryGold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.transparent),
                        backgroundColor: AppStyles.veryLightPink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
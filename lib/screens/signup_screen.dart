// lib/screens/signup_screen.dart
import 'package:bayt_alhikma/view_model/language_provider.dart';
import 'package:bayt_alhikma/view_model/local_storage_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  static const routeName = '/signup';
  SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(); // حقل الموبايل للحفظ فقط

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  late String _username;
  late String _email;
  late String _password;
  late String _confirmPassword;
  late String _firstname;
  late String _lastname;
  late String _phone;

  // category data
  final List<String> _allCategories = [
    'Fiction', 'Science', 'History', 'Philosophy', 'Religion',
    'Poetry', 'Children', 'Romance', 'Business', 'Technology',
    'Political', 'Medical',
  ];
  List<String> _filteredCategories = [];
  List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _filteredCategories = List.from(_allCategories);
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _categoryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  isArabicLocale() {
    return Provider.of<LanguageProvider>(context, listen: false).isArabic;
  }

  Widget _buildInputField({
    required String hint,
    required TextEditingController controller,
    bool obscure = false,
    String? Function(String?)? validator,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppStyles.fieldBorderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            offset: Offset(6, 8),
            blurRadius: 8,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        onChanged: (observed) {
          if (controller == _usernameController) _username = observed;
          else if (controller == _emailController) _email = observed;
          else if (controller == _passwordController) _password = observed;
          else if (controller == _confirmController) _confirmPassword = observed;
          else if (controller == _firstnameController) _firstname = observed;
          else if (controller == _lastnameController) _lastname = observed;
          else if (controller == _phoneController) _phone = observed;
        },
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          suffixIcon: suffix,
        ),
        style: TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return isArabicLocale() ? 'الرجاء إدخال البريد الإلكتروني' : 'Please enter email';
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(v.trim())) return isArabicLocale() ? 'أدخل بريدًا إلكترونيًا صالحًا' : 'Enter a valid email';
    return null;
  }

  String? _requiredValidator(String? v) {
    if (v == null || v.trim().isEmpty) return isArabicLocale() ? 'هذا الحقل مطلوب' : 'This field is required';
    return null;
  }

  void _submit() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabicLocale() ? 'كلمات المرور غير متطابقة' : 'Passwords do not match')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final snapshot = await FirebaseFirestore.instance.collection('profils').where('email', isEqualTo: _emailController.text.trim()).get();
      final snapshot_username = await FirebaseFirestore.instance.collection('profils').where('username', isEqualTo: _usernameController.text.trim()).get();
          
      if (snapshot.docs.isNotEmpty || snapshot_username.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isArabicLocale() ? 'البريد الإلكتروني أو اسم المستخدم موجود بالفعل' : 'Email or Username already exists')),
          );
          setState(() => _isSubmitting = false);
        }
        return;
      }

      // 1) إنشاء الحساب
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      // 2) إرسال رابط تفعيل الإيميل
      await userCredential.user!.sendEmailVerification();

      // 3) حفظ البيانات في Firestore 
      await FirebaseFirestore.instance.collection('profils').doc(uid).set({
        'firstname': _firstnameController.text.trim(),
        'lastname': _lastnameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(), 
        'categories': _selectedCategories,
      });

      // تسجيل خروج عشان ميخشش التطبيق إلا لما يفعل الإيميل
      await _auth.signOut();

      if (mounted) {
        setState(() => _isSubmitting = false);
        // رسالة تنبيه للمستخدم إنه يروح يفتح إيميله
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(isArabicLocale() ? 'تم إنشاء الحساب' : 'Account Created'),
            content: Text(isArabicLocale() 
              ? 'تم إرسال رابط تفعيل إلى بريدك الإلكتروني. يرجى مراجعة صندوق الوارد (أو مجلد Spam) والضغط على الرابط لتفعيل حسابك قبل تسجيل الدخول.' 
              : 'A verification link has been sent to your email. Please check your inbox (or Spam folder) and click the link to activate your account.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // قفل الدايالوج
                  Navigator.of(context).pushReplacementNamed('/login'); // توجيه لشاشة الدخول
                },
                child: Text(isArabicLocale() ? 'حسناً' : 'OK'),
              )
            ],
          ),
        );
      }

    } catch (e) {
      if (mounted) setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;

    return ModalProgressHUD(
      inAsyncCall: _isSubmitting,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 22, vertical: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: 6),
                    SizedBox(
                      height: 160,
                      child: Center(
                        child: Column(
                          children: [
                            Image.asset('images/logo_placeholder.png', height: 110, fit: BoxFit.contain),
                            SizedBox(height: 10),
                            Text(isArabicLocale() ? 'بَيْت الْحِكْمَة' : 'BAYT AL-HIKMA', style: AppStyles.logoTextStyle),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 28),
                    _buildInputField(hint: isArabicLocale() ? 'الاسم الأول' : 'first name', controller: _firstnameController, validator: _requiredValidator),
                    SizedBox(height: 18),
                    _buildInputField(hint: isArabicLocale() ? 'الاسم الأخير' : 'last name', controller: _lastnameController, validator: _requiredValidator),
                    SizedBox(height: 18),
                    _buildInputField(hint: isArabicLocale() ? 'اسم المستخدم' : 'username', controller: _usernameController, validator: _requiredValidator),
                    
                    // Categories... (مختصرة في العرض هنا بس إنت هتسيبها زي ما هي)
                    const SizedBox(height: 18),
                    Align(
                      alignment: isArabicLocale() ? Alignment.centerRight : Alignment.centerLeft,
                      child: Text(isArabicLocale() ? 'الفئات' : 'Categories', style: TextStyle(fontSize: 14, color: Colors.black54)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _categoryController,
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: isArabicLocale() ? 'اكتب لتصفية أو إضافة فئة' : 'Type to filter or add category',
                        filled: true, fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppStyles.fieldBorderColor, width: 1.4)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            final txt = _categoryController.text.trim();
                            if (txt.isEmpty) return;
                            if (!_selectedCategories.contains(txt)) setState(() => _selectedCategories.add(txt));
                            _categoryController.clear();
                            setState(() => _filteredCategories = List.from(_allCategories));
                          },
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          final q = val.trim().toLowerCase();
                          if (q.isEmpty) _filteredCategories = List.from(_allCategories);
                          else _filteredCategories = _allCategories.where((c) => c.toLowerCase().contains(q)).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filteredCategories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) {
                          final c = _filteredCategories[i];
                          return GestureDetector(
                            onTap: () {
                              if (!_selectedCategories.contains(c)) setState(() => _selectedCategories.add(c));
                              _categoryController.clear();
                              setState(() => _filteredCategories = List.from(_allCategories));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppStyles.veryLightPink)),
                              child: Text(c, style: const TextStyle(fontSize: 14)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedCategories.isNotEmpty)
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _selectedCategories.map((c) {
                          return Chip(
                            label: Text(c), deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => setState(() => _selectedCategories.remove(c)),
                            backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 18),
                    _buildInputField(hint: isArabicLocale() ? 'البريد الإلكتروني' : 'email', controller: _emailController, keyboardType: TextInputType.emailAddress, validator: _emailValidator),
                    SizedBox(height: 18),
                    _buildInputField(hint: isArabicLocale() ? 'رقم الموبايل (اختياري)' : 'Phone (optional)', controller: _phoneController, keyboardType: TextInputType.phone),
                    SizedBox(height: 18),
                    _buildInputField(
                      hint: isArabicLocale() ? 'كلمة المرور' : 'password', controller: _passwordController, obscure: _obscurePassword,
                      validator: (v) {
                        if (v == null || v.isEmpty) return isArabicLocale() ? 'الرجاء إدخال كلمة المرور' : 'Please enter password';
                        if (v.length < 6) return isArabicLocale() ? 'يجب أن تكون كلمة المرور 6 أحرف على الأقل' : 'Password must be at least 6 chars';
                        return null;
                      },
                      suffix: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                    ),
                    SizedBox(height: 18),
                    _buildInputField(
                      hint: isArabicLocale() ? 'تأكيد كلمة المرور' : 'confirm password', controller: _confirmController, obscure: _obscureConfirm, validator: _requiredValidator,
                      suffix: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)),
                    ),
                    SizedBox(height: 26),

                    SizedBox(
                      width: width * 0.45,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.primaryGold, elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: Icon(Icons.login, color: Colors.white),
                        label: _isSubmitting ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isArabicLocale() ? 'إنشاء حساب' : 'Sign up', style: TextStyle(fontSize: 16)),
                        onPressed: _isSubmitting ? null : _submit,
                      ),
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
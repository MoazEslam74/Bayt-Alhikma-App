import 'package:bayt_alhikma/utils/styles.dart';
import 'package:bayt_alhikma/view_model/language_provider.dart';
import 'package:bayt_alhikma/view_model/dark_mode.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bayt_alhikma/view_model/local_storage_services.dart';
import 'package:provider/provider.dart';

class EditProfile extends StatefulWidget {
  EditProfile({
    super.key,
    this.username,
    this.email,
    this.firstname,
    this.lastname,
    required this.categories,
  });
  final String? username;
  final String? email;
  final String? firstname;
  final String? lastname;
  final List<String> categories;
  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final routeName = '/edit_profile';
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _firstnameController;
  late TextEditingController _lastnameController;
  final TextEditingController _categoryController = TextEditingController();

  final List<List<String>> _allCategories = [
    ['Fiction', 'خيال'],
    ['Science', 'علم'],
    ['History', 'تاريخ'],
    ['Philosophy', 'فلسفة'],
    ['Religion', 'دين'],
    ['Poetry', 'شعر'],
    ['Children', 'أطفال'],
    ['Romance', 'رومانسية'],
    ['Business', 'أعمال'],
    ['Technology', 'تكنولوجيا'],
    ['Political', 'سياسة'],
    ['Medical', 'طبية'],
  ];
  late List<String> _filteredCategories;
  late List<String> _selectedCategories;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // initialize controllers with existing values
    _usernameController = TextEditingController(text: widget.username ?? '');
    _emailController = TextEditingController(text: widget.email ?? '');
    _firstnameController = TextEditingController(text: widget.firstname ?? '');
    _lastnameController = TextEditingController(text: widget.lastname ?? '');
    _selectedCategories = List<String>.from(widget.categories);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the current locale safely
    final isArabic = Provider.of<LanguageProvider>(context).isArabic;

    // Initialize the list with the correct index (1 for Arabic, 0 for English)
    setState(() {
      _filteredCategories = List.from(
        _allCategories.map((c) => isArabic ? c[1] : c[0]),
      );
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstnameController.dispose();
    _lastnameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    // pick uid from local storage fallback to firebase auth
    final local = LocalStorageService.getUserLocally();
    String? uid = local?.uid;
    uid ??= FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to determine user id')),
      );
      setState(() => _isSaving = false);
      return;
    }

    // keep old values if controller text is empty
    final String username = _usernameController.text.trim().isNotEmpty
        ? _usernameController.text.trim()
        : (widget.username ?? '');
    final String email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : (widget.email ?? '');
    final String firstname = _firstnameController.text.trim().isNotEmpty
        ? _firstnameController.text.trim()
        : (widget.firstname ?? '');
    final String lastname = _lastnameController.text.trim().isNotEmpty
        ? _lastnameController.text.trim()
        : (widget.lastname ?? '');
    final List<String> categories = _selectedCategories.map((selected) {
      // Find the category pair that matches the selection (English or Arabic)
      final pair = _allCategories.firstWhere(
        (p) => p[0] == selected || p[1] == selected,
        orElse: () => [selected, selected],
      );
      return pair[0]; // Always return the English Key (Index 0)
    }).toList();

    final Map<String, dynamic> updateData = {
      'username': username,
      'email': email,
      'firstname': firstname,
      'lastname': lastname,
      'categories': categories,
    };

    try {
      final docRef = FirebaseFirestore.instance.collection('profils').doc(uid);
      await docRef.set(updateData, SetOptions(merge: true));

      // update local storage
      final newProfile = UserProfile(
        uid: uid,
        firstname: firstname,
        lastname: lastname,
        username: username,
        email: email,
        categories: categories,
      );
      await LocalStorageService.saveUserLocally(newProfile);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));

      Navigator.of(context).pop(newProfile);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _normalizeCategory(String text) {
    final match = _allCategories.firstWhere(
      (pair) => pair[0] == text || pair[1] == text,
      orElse: () => [text, text],
    );
    return match[0];
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Provider.of<DarkModeProvider>(context).isDark;
    final isArabicLocale = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).isArabic;
    return Scaffold(
      appBar: AppBar(
        title: Text(isArabicLocale ? "تعديل الملف الشخصي" : "Edit Profile"),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    isArabicLocale ? 'حفظ' : 'Save',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 18),
                  ),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelStyle: TextStyle(fontSize: 18),
                  labelText: isArabicLocale ? "اسم المستخدم" : "Username",
                ),
                style:  TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14),
              ),
               SizedBox(height: 15),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelStyle: TextStyle(fontSize: 18),
                  labelText: isArabicLocale ? "البريد الإلكتروني" : "Email",
                ),
                style:  TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _firstnameController,
                decoration: InputDecoration(
                  labelStyle: TextStyle(fontSize: 18),
                  labelText: isArabicLocale ? "الاسم الأول" : "First Name",
                ),
                style:  TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _lastnameController,
                decoration: InputDecoration(
                  labelStyle: TextStyle(fontSize: 18),
                  labelText: isArabicLocale ? "الاسم الأخير" : "Last Name",
                ),
                style:  TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 15),
              Align(
                alignment: isArabicLocale
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Text(
                  isArabicLocale ? 'الفئات' : 'Categories',
                  style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _categoryController,
                style:  TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 16),
                decoration: InputDecoration(
                  hintText: isArabicLocale
                      ? 'اكتب لتصفية أو إضافة فئة'
                      : 'Type to filter or add category',
                  filled: true,
                  fillColor: Colors.white,
                  hintStyle: const TextStyle(
                    color: Colors.black45,
                    fontSize: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppStyles.fieldBorderColor,
                      width: 1.4,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final txt = _categoryController.text.trim();
                      if (txt.isEmpty) return;
                      final normalized = _normalizeCategory(txt);
                      if (!_selectedCategories.contains(normalized)) {
                        setState(() {
                          _selectedCategories.add(normalized);
                        });
                      }
                      _categoryController.clear();
                      setState(
                        () => _filteredCategories = List.from(
                          _allCategories.map((c) => isArabicLocale ? c[1] : c[0]),
                        ),
                      );
                    },
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    final isArabic = Provider.of<LanguageProvider>(
                      context,
                      listen: false,
                    ).isArabic;
                    final q = val.trim().toLowerCase();

                    if (q.isEmpty) {
                      // Reset list to all categories in the correct language
                      _filteredCategories = List.from(
                        _allCategories.map((c) => isArabic ? c[1] : c[0]),
                      );
                    } else {
                      _filteredCategories.clear(); // Clear before filtering
                      for (var c in _allCategories) {
                        // Check if either English or Arabic matches the search query
                        if (c[0].toLowerCase().contains(q) ||
                            c[1].toLowerCase().contains(q)) {
                          // ADD THE CORRECT LANGUAGE TO THE LIST (Fixing the bug here)
                          _filteredCategories.add(isArabic ? c[1] : c[0]);
                        }
                      }
                    }
                  });
                },
                onSubmitted: (val) {
                  final txt = val.trim();
                  if (txt.isEmpty) return;
                  if (!_selectedCategories.contains(txt)) {
                    setState(() => _selectedCategories.add(txt));
                  }
                  _categoryController.clear();
                  setState(
                    () => _filteredCategories = List.from(
                      _allCategories.map((c) => c[0]),
                    ),
                  );
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
                        final normalized = _normalizeCategory(c);
                        if (!_selectedCategories.contains(normalized)) {
                          setState(() => _selectedCategories.add(normalized));
                        }
                        _categoryController.clear();
                        setState(
                          () => _filteredCategories = List.from(
                            _allCategories.map((c) => isArabicLocale ? c[1] : c[0]),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppStyles.veryLightPink),
                        ),
                        child: Text(c, style:  TextStyle(fontSize: 14, color: isDark ? Colors.black87 : Colors.black54)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (_selectedCategories.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedCategories.map((c) {
                    final displayText = isArabicLocale
                        ? _allCategories.firstWhere(
                            (pair) => pair[0] == c || pair[1] == c,
                            orElse: () => [c, c],
                          )[1]
                        : _allCategories.firstWhere(
                            (pair) => pair[0] == c || pair[1] == c,
                            orElse: () => [c, c],
                          )[0];
                    return Chip(
                      label: Text(
                        displayText,
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.black87 : Colors.black54),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() => _selectedCategories.remove(c));
                      },
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

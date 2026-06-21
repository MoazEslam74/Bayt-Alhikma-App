import 'package:bayt_alhikma/utils/styles.dart';
import 'package:bayt_alhikma/view_model/local_storage_services.dart'; // Import Hive Service
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/material.dart';

class CreateChatScreen extends StatefulWidget {
  const CreateChatScreen({super.key});

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  final TextEditingController _chatNameController = TextEditingController();
  final TextEditingController _chatDescriptionController =
      TextEditingController();
  final TextEditingController _participantsController = TextEditingController(
    text: '2',
  );

  isArabicLocale(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar';
  }

  bool _isCreating = false;

  @override
  void dispose() {
    _chatNameController.dispose();
    _chatDescriptionController.dispose();
    _participantsController.dispose();
    super.dispose();
  }

  Future<void> _createChat() async {
    final name = _chatNameController.text.trim();
    final description = _chatDescriptionController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabicLocale(context)
                ? 'يرجى إدخال اسم الدردشة'
                : 'Please enter a chat name',
          ),
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      // 1. Get current username from Local Storage
      final currentUser = LocalStorageService.getUserLocally();
      final String creatorName = currentUser?.username ?? 'Anonymous';

      // 2. Prepare Data
      final participantsCount =
          int.tryParse(_participantsController.text.trim()) ?? 2;
      final chatID = DateTime.now().millisecondsSinceEpoch;

      // 3. Define the exact structure from the image
      final chatData = {
        'chatName': name,
        'chatDescription': description,
        'chatID': chatID,
        'numOfParticipants': participantsCount,
        'participants': [creatorName], // Start with creator only
        'messages': {}, // Empty Map<String, String> as requested
      };

      // 4. Save to Firestore (using chatID as document ID for easy access)
      await FirebaseFirestore.instance
          .collection('Chats')
          .doc(chatID.toString())
          .set(chatData);

      if (!mounted) return;

      // Close screen
      Navigator.pop(context);
    } catch (e) {
      print("Error creating chat: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabicLocale(context)
                ? 'فشل إنشاء الدردشة: $e'
                : 'Failed to create chat: $e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabicLocale(context) ? 'إنشاء دردشة جديدة' : 'Create New Chat',
        ),
        backgroundColor: AppStyles.primaryGold,
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _chatNameController,
              decoration: InputDecoration(
                labelStyle: TextStyle(fontSize: 18),
                labelText: isArabicLocale(context)
                    ? 'اسم الدردشة'
                    : 'Chat Name',
                border: OutlineInputBorder(),
              ),
              style: TextStyle(color: AppStyles.darkGray, fontSize: 18),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _chatDescriptionController,
              decoration: InputDecoration(
                labelStyle: TextStyle(fontSize: 18),
                labelText: isArabicLocale(context)
                    ? 'وصف الدردشة'
                    : 'Chat Description',
                border: OutlineInputBorder(),
              ),
              style: TextStyle(color: AppStyles.darkGray, fontSize: 18),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _participantsController,
              decoration: InputDecoration(
                labelStyle: TextStyle(fontSize: 18),
                labelText: isArabicLocale(context)
                    ? 'عدد المشاركين'
                    : 'Number of Participants',
                border: OutlineInputBorder(),
              ),
              style: TextStyle(color: AppStyles.darkGray, fontSize: 18),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24.0),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primaryGold,
                ),
                onPressed: _isCreating ? null : _createChat,
                child: _isCreating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isArabicLocale(context) ? 'إنشاء دردشة' : 'Create Chat',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

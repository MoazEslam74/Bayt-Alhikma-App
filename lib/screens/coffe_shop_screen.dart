import 'package:bayt_alhikma/screens/create_chat_screen.dart';
import 'package:bayt_alhikma/screens/participant_profile.dart';
import 'package:bayt_alhikma/utils/styles.dart';
import 'package:bayt_alhikma/view_model/dark_mode.dart';
import 'package:bayt_alhikma/view_model/language_provider.dart';
import 'package:bayt_alhikma/view_model/local_storage_services.dart'; // Import Hive
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CoffeeScreen extends StatefulWidget {
  const CoffeeScreen({super.key});

  @override
  State<CoffeeScreen> createState() => _CoffeeScreenState();
}

class _CoffeeScreenState extends State<CoffeeScreen> {
  bool isArabicLocale([bool listen = true]) {
    return Provider.of<LanguageProvider>(context, listen: listen).isArabic;
  }

  

  void _openCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateChatScreen()),
    );
  }

  Future<void> _joinAndOpenRoom(QueryDocumentSnapshot chatDoc) async {
    final chatID = chatDoc['chatID'].toString();
    final participants = List<String>.from(chatDoc['participants'] ?? []);

    // Get current user from Hive
    final currentUserProfile = LocalStorageService.getUserLocally();
    final String currentUsername = currentUserProfile?.username ?? 'Guest';

    // Add user to participants if not already there
    if (!participants.contains(currentUsername)) {
      await FirebaseFirestore.instance.collection('Chats').doc(chatID).update({
        'participants': FieldValue.arrayUnion([currentUsername]),
      });
    }

    // Navigate to Chat Screen
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatID: chatID,
          chatName: chatDoc['chatName'],
          currentUsername: currentUsername,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Provider.of<DarkModeProvider>(context).isDark;
    final titleText = isArabicLocale()
        ? "مقهى المكتبة"
        : "The Library's Coffee Shop";

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black : AppStyles.primaryGold,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppStyles.primaryGold : Colors.grey.shade400,
                width: 1,
                style: BorderStyle.solid,
              ),
              top: BorderSide(color: AppStyles.primaryGold, width: 1),
            ),
          ),
          child: AppBar(
            title: Text(titleText),
            backgroundColor:isDark ? Colors.black : AppStyles.primaryGold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Image.asset(
            'images/chat_background.png',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          Opacity(opacity: 0.1, child: Container(color: Colors.white)),
          Column(
            children: [
              // STREAM BUILDER for Lists
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Chats')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          isArabicLocale() ? 'لا توجد محادثات' : 'No chats yet',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final chat = docs[index];
                        final data = chat.data() as Map<String, dynamic>;
                        final participants =
                            data['participants'] as List? ?? [];

                        return InkWell(
                          onTap: () => _joinAndOpenRoom(chat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['chatName'] ?? 'Chat',
                                        style:  TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color:isDark? Colors.white70 : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data['chatDescription'] ?? '',
                                        style: TextStyle(
                                          color: isDark ? Colors.white70 : Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.people,
                                            size: 16,
                                            color: AppStyles.primaryGold,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${participants.length} / ${data['numOfParticipants'] ?? 0}',
                                            style:  TextStyle(
                                              color: isDark ? Colors.white70 : Colors.black54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                 Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: isDark ? Colors.white70 : Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Add Button
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FloatingActionButton(
                        splashColor: AppStyles.primaryGold,
                        backgroundColor:isDark ? Colors.black : AppStyles.primaryGold,
                        onPressed: _openCreate,
                        child:  Icon(Icons.add, color:isDark ?  AppStyles.primaryGold: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// CHAT SCREEN (Using Document Stream)
// ==========================================

class ChatScreen extends StatefulWidget {
  final String chatID;
  final String chatName;
  final String currentUsername;

  const ChatScreen({
    Key? key,
    required this.chatID,
    required this.chatName,
    required this.currentUsername,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String uniqueKey = "${widget.currentUsername}/$timestamp";

    try {
      // USE SET + MERGE instead of UPDATE
      await FirebaseFirestore.instance
          .collection('Chats')
          .doc(widget.chatID)
          .set({
            'messages': {
              uniqueKey: text, // This handles keys with dots/slashes safely
            },
          }, SetOptions(merge: true));
    } catch (e) {
      // Print the error if it fails again so you know why
      print("Error sending message: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    }
  }

  void _showParticipantsDialog() {
    
    bool isArabicLocale([bool listen = true]) {
      return Provider.of<LanguageProvider>(context, listen: listen).isArabic;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            isArabicLocale()
                ? ' أعضاء محادثة ${widget.chatName}'
                : '${widget.chatName} Participants',
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Chats')
                  .doc(widget.chatID)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 50,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Text("Chat not found");
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final List<dynamic> participantsList =
                    data['participants'] ?? [];

                if (participantsList.isEmpty) {
                  return const Text("No participants.");
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: participantsList.length,
                  itemBuilder: (context, index) {
                    final String name = participantsList[index].toString();
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        // ---------------------------------------------
                        // UPDATED: Navigate to ParticipantProfile
                        // ---------------------------------------------
                        onTap: () {
                          // Close dialog first (optional, but usually better UX)
                          // Navigator.pop(ctx);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ParticipantProfile(username: name),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 8.0,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: AppStyles.primaryGold,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Provider.of<DarkModeProvider>(context).isDark;
    bool isArabicLocale([bool listen = true]) {
      return Provider.of<LanguageProvider>(context, listen: listen).isArabic;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName,style: TextStyle(color:isDark ? Colors.black : Colors.white),),
        backgroundColor: AppStyles.primaryGold,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: isDark ? Colors.black : Colors.white),
            onPressed: _showParticipantsDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Chats')
                    .doc(widget.chatID)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data == null) return const SizedBox();

                  // Retrieve Messages Map
                  final Map<String, dynamic> messagesMap =
                      data['messages'] ?? {};

                  if (messagesMap.isEmpty) {
                    return Center(
                      child: Text(
                        "Start the chat",
                        style: TextStyle(fontSize: 18, color: isDark ? Colors.white : Colors.black),
                      ),
                    );
                  }

                  // 1. Convert Map to List
                  final messageEntries = messagesMap.entries.toList();

                  // 2. Sort messages by timestamp (the part after '/')
                  messageEntries.sort((a, b) {
                    final timeA = int.tryParse(a.key.split('/').last) ?? 0;
                    final timeB = int.tryParse(b.key.split('/').last) ?? 0;
                    return timeA.compareTo(timeB);
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messageEntries.length,
                    itemBuilder: (context, index) {
                      final entry = messageEntries[index];
                      final rawKey = entry.key;
                      final msgText = entry.value.toString();

                      // 3. Extract clean username (before the '/')
                      final displayUsername = rawKey.contains('/')
                          ? rawKey.split('/')[0]
                          : rawKey;

                      final isMe = displayUsername == widget.currentUsername;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              // Username Label
                              Text(
                                displayUsername,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Message Bubble
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.blue[100]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(12),
                                    topRight: const Radius.circular(12),
                                    bottomLeft: isMe
                                        ? const Radius.circular(12)
                                        : Radius.zero,
                                    bottomRight: isMe
                                        ? Radius.zero
                                        : const Radius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  msgText,
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.blue[900]
                                        : Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Input Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                    color: Colors.black.withOpacity(0.05),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: isArabicLocale()
                            ? 'اكتب رسالتك...'
                            : 'Type your message...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor:isDark ? Colors.grey[600] : Colors.grey[100],
                      ),
                      style: TextStyle(color: AppStyles.iconColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppStyles.primaryGold,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _sendMessage,
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
}

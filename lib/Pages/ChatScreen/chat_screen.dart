import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  final String reciverId;
  final String chatId;

  const ChatScreen({
    Key? key,
    required this.reciverId,
    required this.chatId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User? loggedInUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? userName;
  String? userProfileImage;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    fetchReceiverData();
  }

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      debugPrint('Error getting current user: $e');
    }
  }

  Future<void> fetchReceiverData() async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('user')
          .doc(widget.reciverId)
          .get();

      setState(() {
        userName = userDoc['name'];
        userProfileImage = userDoc['imageUrl'];
      });
    } catch (e) {
      debugPrint('Error fetching receiver data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: userProfileImage != null
                  ? NetworkImage(userProfileImage!)
                  : AssetImage('aaa.jpg') as ImageProvider,
            ),
            const SizedBox(width: 10),
            Text(userName ?? 'Chat'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MessageStream(
              chatId: widget.chatId,
              currentUserId: loggedInUser?.uid ?? '',
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 20.0,
                        ),
                        hintText: 'Type your message here...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (_messageController.text.trim().isEmpty) return;

                      try {
                        final chatProvider = Provider.of<ChatProvider>(
                          context,
                          listen: false,
                        );

                        await chatProvider.sendMessage(
                          widget.chatId,
                          widget.reciverId,
                          _messageController.text,
                        );

                        _messageController.clear();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error sending message: $e')),
                        );
                      }
                    },
                    child: const Text(
                      'Send',
                      style: TextStyle(
                        color: Colors.lightBlueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
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

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

class MessageStream extends StatelessWidget {
  final String chatId;
  final String currentUserId;

  const MessageStream({
    Key? key,
    required this.chatId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('message')
            .orderBy('timeStamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No messages yet'));
          }

          List<MessageBubble> messageBubbles = [];

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;

            // Safely access the data with null checks
            final messageText = data['messageBody'] as String? ?? '';
            final senderId = data['senderID'] as String? ?? '';
            final timestamp = (data['timeStamp'] as Timestamp?)?.toDate();

            final messageBubble = MessageBubble(
              sender: senderId,
              text: messageText,
              isMe: currentUserId == senderId,
              time: timestamp,
            );

            messageBubbles.add(messageBubble);
          }

          return ListView(
            reverse: true,
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 20.0,
            ),
            children: messageBubbles,
          );
        },
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String sender;
  final String text;
  final bool isMe;
  final DateTime? time;

  const MessageBubble({
    Key? key,
    required this.sender,
    required this.text,
    required this.isMe,
    this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Material(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(30.0),
              topRight: const Radius.circular(30.0),
              bottomLeft: isMe
                  ? const Radius.circular(30.0)
                  : const Radius.circular(0.0),
              bottomRight: isMe
                  ? const Radius.circular(0.0)
                  : const Radius.circular(30.0),
            ),
            elevation: 5.0,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 20.0,
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black54,
                  fontSize: 15.0,
                ),
              ),
            ),
          ),
          if (time != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '${time!.hour}:${time!.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 10.0,
                  color: Colors.black54,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

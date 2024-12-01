import 'package:chat_app/Pages/AuthenticationPages/login_page.dart';
import 'package:chat_app/providers/chat_provider.dart';
import 'package:chat_app/widgets/chat_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../SearchScreen/search_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = FirebaseAuth.instance;
  User? loggedInUser;


  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        loggedInUser = user;
      });
    }
  }

  Future<Map<String, dynamic>> _fetchChatData(String chatId) async {
    final chatDoc =
    await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
    final chatData = chatDoc.data();
    if (chatData != null) {
      final users = chatData['user'] as List<dynamic>;
      final receiverId = users.firstWhere((id) => id != loggedInUser!.uid);
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(receiverId)
          .get();
      final userData = userDoc.data()!;
      return {
        'chatId': chatId,
        'lastMessage': chatData['lastMessage'] ?? '',
        'timeStamp': chatData['timeStamp']!.toDate() ?? DateTime.now(),
        'userData': userData,
      };
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    if (loggedInUser == null) {
     print('no users available');
      return Scaffold(
        appBar: AppBar(
          title: const Text("Chats"),
          centerTitle: true,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          foregroundColor: CupertinoColors.white,
          backgroundColor: CupertinoColors.activeBlue,
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (ontext) => SearchScreen()));
          },
          child: Icon(Icons.search),
        ),
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Chats"),
          actions: [

            IconButton(
                onPressed: () {
                  _auth.signOut();
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => LoginScreen()));
                },
                icon: Icon(Icons.logout)),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                  stream: chatProvider.getChats(loggedInUser!.uid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      print('no user available');
                      return Center(child: CircularProgressIndicator());
                    }
                    final chatsDocs = snapshot.data!.docs;
                    return FutureBuilder<List<Map<String, dynamic>>>(
                        future: Future.wait(
                            chatsDocs.map((chatDoc) => _fetchChatData(chatDoc.id))),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }
                          final chatDataList = snapshot.data!;
                          return ListView.builder(
                              itemCount: chatDataList.length,

                              itemBuilder: (context, index) {
                                final chatData = chatDataList[index];
                                return ChatTile(
                                  chatId: chatData['chatId'],
                                  lastMessage: chatData['lastMessage'],
                                  timeStamp: chatData['timeStamp'],
                                  reciverData: chatData['userData'],
                                );
                              });
                        });
                  }),
            ),
          ],
        ),
      ),
    );
  }
}

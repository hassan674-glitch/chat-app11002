import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';
import '../ChatScreen/chat_screen.dart';

// class SearchScreen extends StatefulWidget {
//   const SearchScreen({super.key});
//
//   @override
//   State<SearchScreen> createState() => _SearchScreenState();
// }
//
// class _SearchScreenState extends State<SearchScreen> {
//   final _auth= FirebaseAuth.instance;
//   User? loggedInUser;
//   String searchQuery='';
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     getCurrentUser();
//   }
//   void getCurrentUser()async{
//     final user=await _auth.currentUser;
//     if(user!=null){
//       setState(() {
//         loggedInUser=user;
//       });
//     }
//   }
//
//   void handleSerachQuery(String query){
//     setState(() {
//       searchQuery=query;
//     });
//   }
//   @override
//   Widget build(BuildContext context) {
//     final chatProvider= Provider.of<ChatProvider>(context);
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Search Screen"),
//         centerTitle: true,
//       ),
//       body:Column(
//         children: [
//          Padding(
//            padding: const EdgeInsets.all(8.0),
//            child: TextField(
//                decoration: InputDecoration(
//                  hintText: "Search User...",
//                  border: OutlineInputBorder(
//                    borderRadius: BorderRadius.circular(16),
//                  ),
//                ),
//              onChanged: handleSerachQuery,
//            ),
//          ),
//           Expanded(child: StreamBuilder<QuerySnapshot>(
//               stream:searchQuery.isEmpty ? Stream.empty()
//                   :chatProvider.searchUsers(searchQuery),
//               builder: (context,snapshot){
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }
//                 if(!snapshot.hasData){
//                   return Center(child: CircularProgressIndicator());
//                 }
//                 final users=snapshot.data!.docs;
//                 if (users.isEmpty) {
//                   return const Center(child: Text('No users found'));
//                 }
//                 List<UserTile> userWidgets=[];
//                 for(var user in users){
//                   final userData=user.data() as Map<String,dynamic>;
//                   if(userData['uid']!=loggedInUser!.uid){
//                     final userWidget=UserTile(
//                         userId: userData['uid'],
//                         name: userData['name'],
//                         userEmail: userData['email'],
//                         imageUrl: userData['imageUrl']);
//                     userWidgets.add(userWidget);
//                   }
//                 }
//                 return ListView(
//                   children: userWidgets,
//                 );
//               })),
//
//                  ],
//       ),
//     );
//   }
// }


//gpt code

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _auth = FirebaseAuth.instance;
  User? loggedInUser;
  String searchQuery = '';

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

  void handleSearchQuery(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Screen"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search User...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onChanged: handleSearchQuery,
            ),
          ),
          Expanded(
            child: searchQuery.isEmpty
                ? const Center(child: Text("Enter a search term"))
                : StreamBuilder<QuerySnapshot>(
              stream: chatProvider.searchUsers(searchQuery),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final usersDocs = snapshot.data!.docs;

                if (usersDocs.isEmpty) {
                  return const Center(child: Text("No users found"));
                }

                return ListView.builder(
                  itemCount: usersDocs.length,
                  itemBuilder: (context, index) {
                    final userDoc = usersDocs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(userDoc['name'] ?? 'Unknown'),
                      subtitle: Text(userDoc['email'] ?? 'No email'),
                      onTap: () async {
                        // Fetch chat room or create one and navigate to chat screen
                        String receiverId = usersDocs[index].id;
                        String? chatRoomId = await chatProvider.getChatsRoom(receiverId);
                        if (chatRoomId == null) {
                          chatRoomId = await chatProvider.createChatRoom(receiverId);
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              chatId: chatRoomId!,
                               reciverId: receiverId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class UserTile extends StatelessWidget {
final String userId;
final String name;
final String userEmail;
final String imageUrl;
UserTile({ required this.userId,
  required this.name,
  required this.userEmail,
  required this.imageUrl});
  @override
  Widget build(BuildContext context) {
    final chatProvider=Provider.of<ChatProvider>(context,listen: false);
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(imageUrl),
      ),
      title: Text(name),
      subtitle: Text(userEmail),
      onTap: ()async{
        final currantUser = FirebaseAuth.instance.currentUser;
        if (currantUser == null) {
          // Handle null user by showing a message or redirecting to login screen
          print("No user is currently logged in");
          return;
        }

        final chatId = await chatProvider.getChatsRoom(userId) ??
            await chatProvider.createChatRoom(userId);

        if (chatId != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return ChatScreen(reciverId: userId, chatId: chatId);
          }));
        } else {
          print("Failed to create or retrieve chat room");
        }
      },
    );
  }
}

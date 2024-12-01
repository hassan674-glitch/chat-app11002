// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/cupertino.dart';
//
// class ChatProvider with ChangeNotifier {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
//
//   Stream<QuerySnapshot> getChats(String userId) {
//     return _firebaseFirestore
//         .collection("chats")
//         .where("user", arrayContains: userId)
//         .snapshots();
//   }
//
//   // Add this method for debugging
//   Stream<QuerySnapshot> searchUsers(String query) {
//     print("Search query: $query");
//     String searchLower = query.trim().toLowerCase();
//     print("Formatted search query: $searchLower");
//
//     return _firebaseFirestore
//         .collection('user')  // Changed from 'users' to 'user'
//         .where('email', isEqualTo: searchLower)
//         .snapshots();
//   }
//
//   Future<void> debugPrintAllUsers() async {
//     try {
//       final snapshot = await _firebaseFirestore.collection('user').get();
//       print('Total users in database: ${snapshot.docs.length}');
//       for (var doc in snapshot.docs) {
//         print('User document: ${doc.data()}');
//       }
//     } catch (e) {
//       print('Error fetching users: $e');
//     }
//   }
//
//   Future<void> sendMessage(String chatId, String reciverId, String message) async {
//     final currantUser = _auth.currentUser;
//     if (currantUser != null) {
//       await _firebaseFirestore.collection('chats').doc(chatId).collection('message').add({
//         'senderID': currantUser.uid,
//         'reciverId': reciverId,
//         'messageBody': message,
//         'timeStamp': FieldValue.serverTimestamp()
//       });
//
//       await _firebaseFirestore.collection('chats').doc(chatId).set({
//         'user': {currantUser.uid, reciverId},
//         'lastMessage': message,
//         'timeStamp': FieldValue.serverTimestamp()
//       }, SetOptions(merge: true));
//     }
//   }
//
//   Future<String?> getChatsRoom(String reciverId) async {
//     final currantUser = _auth.currentUser;
//     if (currantUser != null) {
//       final chatQuery = await _firebaseFirestore
//           .collection('chats')
//           .where('user', arrayContains: currantUser.uid)
//           .get();
//       final chats = chatQuery.docs.where((chat) => chat['user'].contains(reciverId)).toList();
//       if (chats.isNotEmpty) {
//         return chats.first.id;
//       }
//     }
//     return null;
//   }
//
//   Future<String> createChatRoom(String reciverId) async {
//     final currantUser = _auth.currentUser;
//     if (currantUser != null) {
//       final chatRoom = await _firebaseFirestore.collection('chats').add({
//         'user': {currantUser.uid, reciverId},
//         'lastMessage': '',
//         'timeStamp': FieldValue.serverTimestamp()
//       });
//       return chatRoom.id;
//     }
//     throw Exception("Current User is Null");
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getChats(String userId) {
    return _firebaseFirestore
        .collection('chats')
        .where('user', arrayContains: userId)
        .orderBy('timeStamp', descending: true)  // This requires an index
        .snapshots();
  }

  Stream<QuerySnapshot> searchUsers(String searchQuery) {
    return _firebaseFirestore
        .collection('user')
        .where('name', isGreaterThanOrEqualTo: searchQuery)
        .where('name', isLessThanOrEqualTo: searchQuery + '\uf8ff')
        .snapshots();
  }

  Future<void> debugPrintAllUsers() async {
    try {
      final snapshot = await _firebaseFirestore.collection('user').get();
      debugPrint('Total users in database: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        debugPrint('User document: ${doc.data()}');
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
    }
  }

  Future<void> sendMessage(String chatId, String receiverId, String message) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not authenticated");

    final batch = _firebaseFirestore.batch();

    // Add message to subcollection
    final messageRef = _firebaseFirestore
        .collection('chats')
        .doc(chatId)
        .collection('message')
        .doc();

    batch.set(messageRef, {
      'senderID': currentUser.uid,
      'reciverId': receiverId,
      'messageBody': message,
      'timeStamp': FieldValue.serverTimestamp()
    });

    // Update chat document
    final chatRef = _firebaseFirestore.collection('chats').doc(chatId);
    batch.set(chatRef, {
      'user': [currentUser.uid, receiverId],
      'lastMessage': message,
      'timeStamp': FieldValue.serverTimestamp()
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<String?> getChatsRoom(String receiverId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    try {
      final chatQuery = await _firebaseFirestore
          .collection('chats')
          .where('user', arrayContains: currentUser.uid)
          .get();

      for (var doc in chatQuery.docs) {
        List<dynamic> users = List.from(doc['user']);
        if (users.contains(receiverId)) {
          return doc.id;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting chat room: $e');
      return null;
    }
  }

  Future<String> createChatRoom(String receiverId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not authenticated");

    try {
      final chatRoom = await _firebaseFirestore.collection('chats').add({
        'user': [currentUser.uid, receiverId],
        'lastMessage': '',
        'timeStamp': FieldValue.serverTimestamp()
      });
      return chatRoom.id;
    } catch (e) {
      throw Exception("Failed to create chat room: $e");
    }
  }
}
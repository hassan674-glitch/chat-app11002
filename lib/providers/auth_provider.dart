import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/cupertino.dart';

class AuthProvider with ChangeNotifier{
 final FirebaseAuth _auth=FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore=FirebaseFirestore.instance;

  User? get currentUser=>_auth.currentUser;
  bool get isSignedIn=> currentUser != null;


Future<void>  SignIn(String email,String password)async{
  await _auth.signInWithEmailAndPassword(email: email, password: password);
  notifyListeners();
}

 // Future<void>  SignUp(String email,String password,String name ,String imageUrl)async{
 //  UserCredential userCrediential=await _auth.createUserWithEmailAndPassword(
 //      email: email,
 //      password: password);
 //  final imageUrl= await _uploadImage(_image!);
 //  await _firebaseFirestore.collection("user").doc(userCrediential.user!.uid).set(
 //      {
 //        'email':email,
 //        'uid':userCrediential.user!.uid,
 //        'name':name,
 //        'imageUrl':imageUrl,
 //      });
 //  notifyListeners();
 // }

Future<void> signOut()async {
  await _auth.signOut();
  notifyListeners();
}
}
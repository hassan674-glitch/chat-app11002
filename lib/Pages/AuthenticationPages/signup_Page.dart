import 'dart:io';
import 'package:chat_app/Pages/AuthenticationPages/login_page.dart';
import 'package:chat_app/Pages/Home/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreen();
}

class _SignUpScreen extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  File? image;
  final _auth = FirebaseAuth.instance;
  final _fireStore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        image = File(pickedFile.path);
      }
    });
  }

  Future<String> uploadFile(File image) async {
    final ref = _storage.ref().child('user_images').child("${_auth.currentUser!.uid}.jpg");
    await ref.putFile(image);
    return ref.getDownloadURL();
  }

  Future<void> SignUp() async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text, password: _passwordController.text);

    final imageUrl = await uploadFile(image!);
    await _fireStore.collection("user").doc(userCredential.user!.uid).set({
      'uid': userCredential.user!.uid,
      'email': _emailController.text,
      'name': _nameController.text,
      'imageUrl': imageUrl,
    });

    Fluttertoast.showToast(msg: "SignUp Success");
   Navigator.push(context, MaterialPageRoute(builder:(context) =>HomePage()));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Create Account"),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: pickImage,
                      child: Container(
                          height: 200,
                          width: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black
                            )
                          ),
                          child: image == null
                              ? const Center(
                            child: Icon(
                              CupertinoIcons.person,
                              size: 50,
                            ),
                          )
                              : ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.file(
                              image!,
                              fit: BoxFit.cover,
                            ),
                          )),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      decoration: const InputDecoration(
                        labelText: "Name",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your name";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your password";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 50),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 1.5,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: SignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CupertinoColors.activeBlue,
                          foregroundColor: CupertinoColors.white,
                        ),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Or", style: TextStyle(fontSize: 20)),
                    TextButton(
                      onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) =>LoginScreen()),  // Navigate to LoginScreen
                      );
                      },
                      child: const Text(
                        "Sign In",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.activeBlue,
                            fontSize: 25),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

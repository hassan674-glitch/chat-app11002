import 'package:chat_app/Pages/AuthenticationPages/signup_Page.dart';
import 'package:chat_app/Pages/Home/home_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text("LoginPage"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
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
              SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
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
              SizedBox(height: 50),
              SizedBox(
                width: MediaQuery.of(context).size.width / 1.5,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
          
                    try {
                      await authProvider.SignIn(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                      );
                      Fluttertoast.showToast(msg: "Login Success");
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => HomePage()),
                      );
                    } catch (e) {
                     GetSnackBar(
                       title: "Login Error $e",
                     );
                     print(e);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CupertinoColors.activeBlue,
                    foregroundColor: CupertinoColors.white,
                  ),
                  child: Text(
                    "Log In",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
              SizedBox(height: 20,),
              Text("Or", style: TextStyle(fontSize: 20),),
            SizedBox(height: 20,),
          
            TextButton(onPressed: (){
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SignUpScreen()),  // Navigate to LoginScreen
              );
              }, child: Text("Create Account",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                    color: CupertinoColors.activeBlue,
                    fontSize: 25),
              )
              ),
          
            ],
          ),
        ),
      ),
    );
  }
}

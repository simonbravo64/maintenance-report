import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dm_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  String errorMessage = "";
  Future<String?> getUserRole(String uid) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userDoc.exists) {
      return userDoc['role']; // Return the role of the user
    } else {
      return null;
    }
  }
  Future<void> addUserToFirestore(String uid, String email) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'email': email, 'role': 'maintenance'});
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Handle login logic here
      final email = _emailController.text;
      final password = _passwordController.text;
      try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      // Navigate to the next screen after login

      debugPrint('======= ##### USER CREDENTIAL ###### $userCredential');
      final user = userCredential.user;
      String? role = await getUserRole(user!.uid);

       // Navigate to the corresponding page based on the user's role
        if (role == 'dorm_manager'||role == 'SSD'||role == 'SAO'||role=='maintenance_supervisor'||role=='FAD'||role=='supply_officer') {
          
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ReportViewingPage()));
        } else {
          // Handle unexpected roles, or if the role doesn't exist

          addUserToFirestore(user.uid, email);
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ReportViewingPage()));

        }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message!;
      });
    }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log In'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Log In',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  // Simple email validation
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login
                ,child: const Text('Log In'),
               )
              ,if (errorMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),]
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:dorm_maintenance_reporter/launch_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        .set({'email': email, 'role': 'user'});
  }

  void _showForgotPasswordDialog() {
  final TextEditingController _resetEmailController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Reset Password"),
      content: TextField(
        controller: _resetEmailController,
        decoration: const InputDecoration(
          labelText: "Enter your email",
        ),
        keyboardType: TextInputType.emailAddress,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () async {
            final email = _resetEmailController.text.trim();
            if (email.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please enter an email")),
              );
              return;
            }
            try {
              await _auth.sendPasswordResetEmail(email: email);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Password reset email sent! Check your inbox."),
                ),
              );
            } catch (e) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error: ${e.toString()}")),
              );
            }
          },
          child: const Text("Send"),
        ),
      ],
    ),
  );
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
        if (role == 'user'||role == 'admin'||role == 'superadmin') {
          
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LaunchPage()));
        } else {
          // Handle unexpected roles, or if the role doesn't exist

          addUserToFirestore(user.uid, email);
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LaunchPage()));

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
              TextButton(
                onPressed: _showForgotPasswordDialog,
                child: const Text(
                'Forgot Password?',
                style: TextStyle(color: Colors.blueAccent),
                ),
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
import 'package:dorm_maintenance_reporter/launch_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dm_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  String _userName = 'Loading...';
  String _userEmail = 'Loading...';
  String? _userRole;
  int _selectedIndex = 2; // Default to Profile Page

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        setState(() {
          _userName = userDoc['name'] ?? 'Unknown';
          _userEmail = currentUser.email ?? 'No email';
          _userRole = userDoc['role'] ?? 'user';
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _updateName() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'name': _nameController.text,
        });

        setState(() {
          _userName = _nameController.text;
        });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated successfully')));
      }
    } catch (e) {
      print('Error updating name: $e');
    }
  }

  Future<void> _updateEmail(String newEmail) async {
  try {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      // Send verification email to the new email
      await currentUser.verifyBeforeUpdateEmail(newEmail);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'A verification email has been sent to $newEmail. Please verify it before updating. Log out and log back in to update the profile.',
          ),
        ),
      );

      // Show a confirmation dialog for users
      _showVerificationReminder(newEmail);
    }
  } catch (e) {
    print('Error updating email: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }

  FirebaseAuth.instance.userChanges().listen((User? user) async {
      if (user != null && user.email == newEmail && user.emailVerified) {
        // Update Firestore once email is verified
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'email': newEmail});

        setState(() {
          _userEmail = newEmail;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email updated in Firestore.")),
        );
      }
    });
  } 

  void _showVerificationReminder(String newEmail) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Verify Your Email"),
      content: Text(
          "A verification email has been sent to $newEmail. Please check your inbox and click the verification link before continuing."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}


  Future<void> _sendPasswordResetEmail() async {
    try {
      await _auth.sendPasswordResetEmail(email: _userEmail);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent. Check your inbox.')),
      );
    } catch (e) {
      print('Error sending password reset email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (Route<dynamic> route) => false,
                ); // Clear all previous routes
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(String title, TextEditingController controller, Function(String) onSave) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: title),
          keyboardType: title == 'Email' ? TextInputType.emailAddress : TextInputType.text,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => onSave(controller.text), child: const Text('Save')),
        ],
      ),
    );
  }

  // Show password prompt before updating email
  void _showPasswordPromptForEmailChange(String newEmail) {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _verifyPasswordAndUpdateEmail(passwordController.text, newEmail);
              Navigator.pop(context); // Close the dialog
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPasswordAndUpdateEmail(String password, String newEmail) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Re-authenticate the user using the provided password
        AuthCredential credential = EmailAuthProvider.credential(
          email: currentUser.email!,
          password: password,
        );

        await currentUser.reauthenticateWithCredential(credential);

        // Proceed to update the email
        await _updateEmail(newEmail);
      }
    } catch (e) {
      print('Error re-authenticating: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return; // Avoid unnecessary rebuilds

    

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const LaunchPage()));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportViewingPage()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
        break;
      
      }
  }

  @override
  Widget build(BuildContext context) {
    if (_userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()), // Show loading spinner
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutConfirmation(context);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: $_userName', style: const TextStyle(fontSize: 18)),
            TextButton(
              onPressed: () {
                _nameController.text = _userName;
                _showEditDialog('Name', _nameController, (value) => _updateName());
              },
              child: const Text('Change Name'),
            ),
            const SizedBox(height: 10),
            Text('Email: $_userEmail', style: const TextStyle(fontSize: 18)),
            TextButton(
              onPressed: () {
                _emailController.text = _userEmail;
                 _showEditDialog('Email', _emailController, (newEmail) {
                  _showPasswordPromptForEmailChange(newEmail);
                });
              },
              child: const Text('Change Email'),
            ),
            const SizedBox(height: 10),
            
            const SizedBox(height: 10),
            Text('Role: $_userRole', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendPasswordResetEmail,
              child: const Text('Reset Password'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          
        ],
      ),
    );
  }
}

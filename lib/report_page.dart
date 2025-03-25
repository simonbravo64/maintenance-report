import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class ReportSubmissionPage extends StatefulWidget {
  const ReportSubmissionPage({super.key});

  @override
  ReportSubmissionPageState createState() => ReportSubmissionPageState();
}

class ReportSubmissionPageState extends State<ReportSubmissionPage> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  
  String _name = '';
  File? _imageFile; // Store selected image
  final ImagePicker _picker = ImagePicker();

  // Fetch user details
  Future<void> _fetchUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        setState(() {
          _name = userDoc['name'] ?? 'Anonymous';
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _sendEmail(String senderName, String reportTitle) async {
    String username = "spbravo@brc.pshs.edu.ph"; 
    String password = "wkzsrtmdttpabrwp"; // App password 

    // Fetch all admin user emails from Firestore
    List<String> adminEmails = await _getAdminEmails();

    if (adminEmails.isEmpty) {
      print("❌ No maintenance emails found.");
      return;
    }

    final smtpServer = gmail(username, password); // Gmail SMTP settings

    final message = Message()
      ..from = Address(username, 'Dorm Maintenance Report Hub') // Sender info
      ..recipients.addAll(adminEmails) // Add all maintenance emails
      ..subject = 'New Maintenance Report Submitted'
      ..text = 'A new report has been submitted by $senderName.\n\nTitle: $reportTitle';

    try {
      final sendReport = await send(message, smtpServer);
      print('✅ Email sent to admin: ${sendReport.toString()}');
    } catch (e) {
      print('❌ Failed to send email: $e');
    }
  }

  Future<List<String>> _getAdminEmails() async {
  List<String> emails = [];

  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'admin') // Filter by role
        .get();

    for (var doc in querySnapshot.docs) {
      String email = doc['email']; 
      emails.add(email);
    }

    print("📧 Admin Emails: $emails"); // Debugging
  } catch (e) {
    print("❌ Error fetching maintenance emails: $e");
  }

  return emails;
}


  // Submit the report
  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      DateTime now = DateTime.now();
      String date = DateFormat('yyyy-MM-dd').format(now);
      String time = DateFormat('HH:mm').format(now);

      try {
        await FirebaseFirestore.instance.collection('reports').add({
          'name': _name,
          'title': _titleController.text,
          'date': now,
          'time': time,
          'details': _detailsController.text,
          'status': 'New',
          'imagePath': _imageFile?.path ?? '', // Store image path (optional)
        });

        // Send email notification
        await _sendEmail(_name, _titleController.text);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report Submitted Successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting report: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit a Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter title';
                  }
                  return null;
                },
              ),
              
              TextFormField(
                controller: _detailsController,
                decoration: const InputDecoration(labelText: 'Details'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter details';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),
              const Text("Send Attachment"),

              // Image Picker Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.image),
                    label: const Text('Gallery'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera),
                    label: const Text('Camera'),
                  ),
                ],
              ),

              // Show selected image preview
              if (_imageFile != null) ...[
                const SizedBox(height: 10),
                Image.file(_imageFile!, height: 200),
              ],

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitReport,
                child: const Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

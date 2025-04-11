import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  
  
  final String _imgurClientId = "37130fc40b866b5"; 

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

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

  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Upload image to Imgur and return the image URL
  Future<String?> _uploadImageToImgur(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgur.com/3/image'),
      );
      request.headers['Authorization'] = 'Client-ID $_imgurClientId';
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return jsonData['data']['link']; 
      } else {
        print('❌ Failed to upload image: ${jsonData['data']['error']}');
        return null;
      }
    } catch (e) {
      print('❌ Image upload error: $e');
      return null;
    }
  }

  Future<void> _sendEmail(String senderName, String reportTitle, String reportDetails) async {
    String username = "dormmaintenancereporthub@gmail.com"; 
    String password = "qplwtaaptzornudb"; 

    List<String> adminEmails = await _getAdminEmails();

    if (adminEmails.isEmpty) {
      print("❌ No admin emails found.");
      return;
    }

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Dorm Maintenance Report Hub')
      ..recipients.addAll(adminEmails)
      ..subject = 'New Maintenance Report Submitted'
      ..text = 'A new report has been submitted by $senderName.\n\nTitle: $reportTitle\n\nDetails: $reportDetails';
;

    try {
      await send(message, smtpServer);
      print('✅ Email sent to admins.');
    } catch (e) {
      print('❌ Failed to send email: $e');
    }
  }

  Future<List<String>> _getAdminEmails() async {
    List<String> emails = [];
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      for (var doc in querySnapshot.docs) {
        String email = doc['email'];
        emails.add(email);
      }

      print("📧 Admin Emails: $emails");
    } catch (e) {
      print("❌ Error fetching admin emails: $e");
    }
    return emails;
  }

  Future<void> _submitReport() async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true); // Show spinner
    DateTime now = DateTime.now();
    String time = DateFormat('HH:mm').format(now);

    String? imageUrl;
    String? email;

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      email = currentUser.email;
    }

    if (_imageFile != null) {
      imageUrl = await _uploadImageToImgur(_imageFile!);
    }

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'name': _name,
        'title': _titleController.text,
        'date': now,
        'time': time,
        'details': _detailsController.text,
        'status': 'New',
        'imageUrl': imageUrl ?? '',
        'user_email': email ?? '', // Save reporter's email
      });

      await _sendEmail(_name, _titleController.text, _detailsController.text);

      if (mounted) {
        setState(() => _isLoading = false); // Hide spinner
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report Submitted Successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting report: $e')),
        );
      }
    }
  }
}


  void _removeImage() {
    setState(() {
      _imageFile = null;
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Submit a Report'),
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Report Title',
                      counterText: ''),
                    maxLength: 50,
                    inputFormatters: [LengthLimitingTextInputFormatter(50)],
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter title'
                        : null,
                  ),
                  TextFormField(
                    controller: _detailsController,
                    decoration: const InputDecoration(
                      labelText: 'Details',
                      counterText: ''),
                    maxLength: 250,
                    inputFormatters: [LengthLimitingTextInputFormatter(250)],
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter details'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  const Text("Attach an Image"),
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
                  if (_imageFile != null) ...[
                    const SizedBox(height: 10),
                    Image.file(_imageFile!, height: 200),
                    TextButton(
                      onPressed: _removeImage,
                      child: const Text(
                        'Remove Image',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
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
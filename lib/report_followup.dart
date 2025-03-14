import 'package:dorm_maintenance_reporter/dm_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FollowUpReportPage extends StatefulWidget {
  final String reportId;

  const FollowUpReportPage({super.key, required this.reportId});

  @override
  FollowUpReportPageState createState() => FollowUpReportPageState();
}

class FollowUpReportPageState extends State<FollowUpReportPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';

  final TextEditingController _remarksController = TextEditingController();



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
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Follow Up on Remarks')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              
               TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(labelText: 'Remarks'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter remarks';
                  }
                  return null;
                },
              ),
            
              
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    String name = _name;
                    _replyToReport(name, _remarksController.text);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ReportViewingPage()));
                  }
                },
                child: const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _replyToReport(String _name, String remarks) async {
    await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).update({
      'dm': _name,
      'dm_remarks': remarks,
      'status': 'Followed-Up by DM',
    });
  }
}

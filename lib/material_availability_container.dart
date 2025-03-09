// lib/material_request_container.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MaterialAvailabilityContainer extends StatefulWidget {
  final String materials;
  final String reportId;
  final String role;
  const MaterialAvailabilityContainer({
    Key? key,
    required this.materials,
    required this.reportId,
    required this.role,
  }) : super(key: key);

  @override
  _MaterialAvailabilityContainerState createState() =>
      _MaterialAvailabilityContainerState(this.role);
}

class _MaterialAvailabilityContainerState
    extends State<MaterialAvailabilityContainer> {
  bool isExpanded = false;
  bool existing = false;
  String remarks = '';
  bool requestForPurchase = false;

  _MaterialAvailabilityContainerState(String role) {
    isExpanded = role == 'supply_officer';
  }

  void onSetRemarks(String remarks) {
    setState(() {
      this.remarks = remarks;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchMaterialsData();
  }

  Future<void> _fetchMaterialsData() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('materials')
          .doc(widget.materials)
          .get();
      if (snapshot.exists) {
        var materials = snapshot.data() as Map<String, dynamic>;
        onSetRemarks(materials['so_remarks'] ?? '');
        setState(() {
          existing = true;
        }); // Update the UI after data is fetched
      }
    } catch (e) {
      print("Error fetching materials data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var remarksController = TextEditingController(text: remarks);
    return Column(
      children: !existing
          ? []
          : [
              ExpansionTile(
                initiallyExpanded: isExpanded,
                title: const Text('Materials/Supply Availability'),
                trailing: Icon(
                    isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                onExpansionChanged: (bool expanded) {
                  setState(() {
                    isExpanded = expanded;
                  });
                },
                children: isExpanded
                    ? [
                        CheckboxListTile(
                          enabled: widget.role == 'supply_officer',
                          title: const Text("Request for Purchase"),
                          value: requestForPurchase,
                          onChanged: (newValue) {
                            setState(() {
                              requestForPurchase = newValue ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity
                              .leading, //  <-- leading Checkbox
                        ),
                        TextField(
                          enabled: widget.role == 'supply_officer',
                          controller: remarksController,
                          maxLines: null,
                          decoration: const InputDecoration(
                            labelText: 'Supply Officer Remarks',
                            border: OutlineInputBorder(),
                          ),
                        )
                      ]
                    : [],
              ),
              if (widget.role == 'supply_officer')
                ElevatedButton(
                  onPressed: () async {
                    if (requestForPurchase) {
                      await FirebaseFirestore.instance
                      .collection('materials')
                      .doc(widget.reportId)
                      .update({
                        'status': 'Requesting Purchase of Materials',
                      });
                    } else {
                      await FirebaseFirestore.instance
                      .collection('materials')
                      .doc(widget.reportId)
                      .update({
                        'status': 'Available',
                      });
                    }
                  },
                  child: Text(requestForPurchase
                      ? 'Request Purchase'
                      : 'Supply is available'),
                ),
            ],
    );
  }
}

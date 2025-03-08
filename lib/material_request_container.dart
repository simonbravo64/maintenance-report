// lib/material_request_container.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dorm_maintenance_reporter/material_entry_form.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MaterialRequestContainer extends StatefulWidget {
  final String materials;
  final String reportId;
  const MaterialRequestContainer({
    Key? key,
    required this.materials,
    required this.reportId,
  }) : super(key: key);

  @override
  _MaterialRequestContainerState createState() =>
      _MaterialRequestContainerState();
}

class _MaterialRequestContainerState extends State<MaterialRequestContainer> {
  bool isExpanded = false;
  bool existing = false;
  String remarks = '';

  final List<DataRow> _rows = [];
  final List<String> _rowstr = [];

  void onAddEntry(String unit, String description, int quantity) {
    setState(() {
      _rowstr.add('$unit$description$quantity');
      _rows.add(DataRow(cells: [
        DataCell(Text(unit)),
        DataCell(Text(description)),
        DataCell(Text(quantity.toString())),
        DataCell(IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () =>
              onDeleteEntry(_rowstr.indexOf('$unit$description$quantity')),
        )),
      ]));
    });
  }

  void onDeleteEntry(int index) {
    setState(() {
      _rows.removeAt(index);
      _rowstr.removeAt(index);
    });
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
        onSetRemarks(materials['remarks'] ?? '');
        var list = materials['list'] as List<dynamic>;

        for (var item in list) {
          String unit = item['unit'];
          String description = item['item'];
          int quantity = item['qty'];
          onAddEntry(unit, description, quantity);
        }

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
      children: [
        ExpansionTile(
          title: const Text('Request Material/Supply'),
          trailing:
              Icon(isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down),
          onExpansionChanged: (bool expanded) {
            setState(() {
              isExpanded = expanded;
            });
          },
          children: [
            if (isExpanded)
              DataTable(
                columns: const <DataColumn>[
                  DataColumn(
                    label: Expanded(
                      child: Text('Unit',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                    ),
                  ),
                  DataColumn(
                    label: Expanded(
                      child: Text('Item',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                    ),
                  ),
                  DataColumn(
                    label: Expanded(
                      child: Text('Qty',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                    ),
                  ),
                  DataColumn(
                    label: Expanded(
                      child: Text('X',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                    ),
                  ),
                ],
                rows: _rows,
              ),
            MaterialEntryForm(onAddEntry: onAddEntry),
          ],
        ),
        TextField(
          controller: remarksController,
          maxLines: null,
          decoration: const InputDecoration(
            labelText: 'Enter Remarks',
            border: OutlineInputBorder(),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            var materials = FirebaseFirestore.instance.collection('materials');
            var payload = {
              'remarks': remarksController.text,
              'list': _rows.map((dataRow) {
                var map = <String, dynamic>{};
                map['unit'] = (dataRow.cells[0].child as Text).data.toString();
                map['item'] = (dataRow.cells[1].child as Text).data.toString();
                map['qty'] = int.parse(
                  (dataRow.cells[2].child as Text).data.toString(),
                );

                return map;
              }).toList(), // Convert to list
            };
            
            await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).update({
                'status': 'Inspected by Maintenance Supervisor',
                'date_inspected': Timestamp.now(),
                'time_inspected': DateFormat('HH:mm').format(DateTime.now()),
              });

            if (existing) {
              await materials.doc(widget.materials).update(payload);
              Navigator.pop(context, widget.reportId);
              print('Success');
            } else {
              var docRef = await materials.add(payload);
              await FirebaseFirestore.instance
                  .collection('reports')
                  .doc(widget.reportId)
                  .update({'materials': docRef.id});
              
              Navigator.pop(context, docRef.id);
              print('Success: ${docRef.id}');
            };
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

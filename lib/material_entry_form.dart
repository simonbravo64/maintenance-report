import 'package:flutter/material.dart';

class MaterialEntryForm extends StatefulWidget {
  final Function(String unit, String description, int quantity) onAddEntry;

  MaterialEntryForm({required this.onAddEntry});

  @override
  _MaterialEntryFormState createState() => _MaterialEntryFormState();
}

class _MaterialEntryFormState extends State<MaterialEntryForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _unitController;
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _unitController = TextEditingController();
    _descriptionController = TextEditingController();
    _quantityController = TextEditingController();
  }

  @override
  void dispose() {
    _unitController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final unit = _unitController.text;
      final description = _descriptionController.text;
      final quantity = int.parse(_quantityController.text);
      widget.onAddEntry(unit, description, quantity);

      // Clear the form after submission
      _unitController.clear();
      _descriptionController.clear();
      _quantityController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _unitController,
            decoration: InputDecoration(labelText: 'Unit'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a unit';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: 'Description'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _quantityController,
            decoration: InputDecoration(labelText: 'Quantity'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a quantity';
              }
              if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          ElevatedButton(
            onPressed: _submitForm,
            child: Text('Add Entry'),
          ),
        ],
      ),
    );
  }
}

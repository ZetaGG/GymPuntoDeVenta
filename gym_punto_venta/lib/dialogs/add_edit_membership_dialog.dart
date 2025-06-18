import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddEditMembershipDialog extends StatefulWidget {
  final Map<String, dynamic>? membership;
  final Function(Map<String, dynamic> data) onSave;
  final bool mode; // For dark/light mode theming


  const AddEditMembershipDialog({
    Key? key,
    this.membership,
    required this.onSave,
    this.mode = false, // Default to light mode
  }) : super(key: key);

  @override
  _AddEditMembershipDialogState createState() => _AddEditMembershipDialogState();
}

class _AddEditMembershipDialogState extends State<AddEditMembershipDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.membership?['name']?.toString() ?? '');
    _priceController = TextEditingController(text: widget.membership?['price']?.toString() ?? '');
    _durationController = TextEditingController(text: widget.membership?['duration_days']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      labelStyle: TextStyle(color: widget.mode ? Colors.white70 : Colors.black54),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: widget.mode ? Colors.white54 : Colors.black38),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: widget.mode ? Colors.tealAccent : Colors.blue),
      ),
    );
    final textStyle = TextStyle(color: widget.mode ? Colors.white : Colors.black);

    return AlertDialog(
      backgroundColor: widget.mode ? Colors.grey[850] : Colors.white,
      title: DefaultTextStyle( // Prominent title
        style: Theme.of(context).textTheme.titleLarge!.copyWith(color: widget.mode ? Colors.white : Colors.blue),
        child: Text(widget.membership == null ? 'Add Membership Type' : 'Edit Membership Type'),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0), // Consistent padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                style: textStyle,
                decoration: inputDecoration.copyWith(labelText: 'Membership Name'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _priceController,
                style: textStyle,
                decoration: inputDecoration.copyWith(labelText: 'Price'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a price';
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) return 'Price must be a positive number';
                  return null;
                },
              ),
              TextFormField(
                controller: _durationController,
                style: textStyle,
                decoration: inputDecoration.copyWith(labelText: 'Duration (days)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a duration';
                  final duration = int.tryParse(value);
                  if (duration == null || duration <= 0) return 'Duration must be a positive integer';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancel', style: TextStyle(color: widget.mode ? Colors.redAccent[100] : Colors.red)),
          onPressed: () => Navigator.of(context).pop()
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: widget.mode ? Colors.teal : Colors.blue),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final data = {
                'id': widget.membership?['id'],
                'name': _nameController.text,
                'price': double.parse(_priceController.text),
                'duration_days': int.parse(_durationController.text),
              };
              widget.onSave(data);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}

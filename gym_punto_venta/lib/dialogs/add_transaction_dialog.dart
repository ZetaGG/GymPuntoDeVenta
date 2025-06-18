import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

enum TransactionType { income, expense }

class AddTransactionDialog extends StatefulWidget {
  final Function(Map<String, dynamic> data, TransactionType type) onSave;
  final bool mode; // For dark/light mode theming

  const AddTransactionDialog({
    Key? key,
    required this.onSave,
    this.mode = false, // Default to light mode
  }) : super(key: key);

  @override
  _AddTransactionDialogState createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  TransactionType _selectedType = TransactionType.income;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) { // Theme the date picker
        return Theme(
          data: widget.mode ? ThemeData.dark().copyWith(
             colorScheme: const ColorScheme.dark(
                primary: Colors.teal, // header background color
                onPrimary: Colors.white, // header text color
                onSurface: Colors.white, // body text color
             ),
             dialogBackgroundColor:Colors.grey[800],
          ) : ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
            ),
          ),
          child: child!,
        );
      }
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
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
    final dropdownColor = widget.mode ? Colors.grey[700] : Colors.white;
    final iconColor = widget.mode ? Colors.white70 : Colors.grey[700];

    return AlertDialog(
      backgroundColor: widget.mode ? Colors.grey[850] : Colors.white,
      title: DefaultTextStyle( // Prominent title
        style: Theme.of(context).textTheme.titleLarge!.copyWith(color: widget.mode ? Colors.white : Colors.blue),
        child: Text(_selectedType == TransactionType.income ? 'Add Income' : 'Add Expense'),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0), // Consistent padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<TransactionType>(
                value: _selectedType,
                dropdownColor: dropdownColor,
                style: textStyle,
                items: const [
                  DropdownMenuItem(value: TransactionType.income, child: Text("Income")),
                  DropdownMenuItem(value: TransactionType.expense, child: Text("Expense")),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() { _selectedType = value; });
                  }
                },
                decoration: inputDecoration.copyWith(labelText: 'Transaction Type'),
              ),
              TextFormField(
                controller: _descriptionController,
                style: textStyle,
                decoration: inputDecoration.copyWith(labelText: 'Description'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
              ),
              TextFormField(
                controller: _amountController,
                style: textStyle,
                decoration: inputDecoration.copyWith(labelText: 'Amount'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter an amount';
                  if (double.tryParse(value) == null) return 'Invalid amount';
                  if (double.parse(value) <= 0) return 'Amount must be positive';
                  return null;
                },
              ),
              TextFormField(
                controller: _categoryController,
                style: textStyle,
                decoration: inputDecoration.copyWith(
                  labelText: _selectedType == TransactionType.income ? 'Income Type (e.g., Product Sale)' : 'Expense Category (e.g., Rent)'
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a type/category' : null,
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text("Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}", style: textStyle),
                trailing: Icon(Icons.calendar_today, color: iconColor),
                onTap: () => _pickDate(context),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancel', style: TextStyle(color: widget.mode ? Colors.redAccent[100] : Colors.red)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: widget.mode ? Colors.teal : Colors.blue),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final data = {
                'description': _descriptionController.text,
                'amount': double.parse(_amountController.text),
                'date': _selectedDate.toIso8601String(),
              };
              if (_selectedType == TransactionType.income) {
                data['type'] = _categoryController.text; // This is the 'type' for Income table
              } else {
                data['category'] = _categoryController.text; // This is the 'category' for Expenses table
              }
              widget.onSave(data, _selectedType);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}

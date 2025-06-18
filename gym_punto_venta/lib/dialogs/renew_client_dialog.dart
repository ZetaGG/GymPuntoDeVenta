import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:gym_punto_venta/models/clients.dart';

class RenewClientDialog extends StatefulWidget {
  final Client client;
  final Function(Client client, String newMembershipType) onRenew;
  final bool mode;
  final Future<List<Map<String, dynamic>>> membershipTypesFuture;

  const RenewClientDialog({
    Key? key,
    required this.mode,
    required this.client,
    required this.onRenew,
    required this.membershipTypesFuture,
  }) : super(key: key);

  @override
  _RenewClientDialogState createState() => _RenewClientDialogState();
}

class _RenewClientDialogState extends State<RenewClientDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedMembershipType;
  List<Map<String, dynamic>> _membershipTypes = [];
  DateTime _newStartDate = DateTime.now();
  DateTime? _newEndDate;
  double? _renewalPrice;
  bool _isLoadingTypes = true;

  @override
  void initState() {
    super.initState();
    widget.membershipTypesFuture.then((types) {
      if (mounted) {
        setState(() {
          _membershipTypes = types;
          if (_membershipTypes.isNotEmpty) {
            // Try to pre-select the client's current membership type or the first one
            _selectedMembershipType = _membershipTypes
                .firstWhere((type) => type['name'] == widget.client.membershipType, orElse: () => _membershipTypes.first)['name'] as String?;
          }
          _calculateEndDateAndPrice();
          _isLoadingTypes = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
         setState(() {
          _isLoadingTypes = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando tipos de membresía: $error')),
        );
      }
    });
  }

  void _calculateEndDateAndPrice() {
    if (_selectedMembershipType == null || _membershipTypes.isEmpty) {
      _newEndDate = null;
      _renewalPrice = null;
      return;
    }
    final selectedTypeDetails = _membershipTypes.firstWhere(
      (type) => type['name'] == _selectedMembershipType,
      orElse: () => {}, // Should not happen if _selectedMembershipType is from _membershipTypes
    );

    if (selectedTypeDetails.isNotEmpty) {
      final duration = selectedTypeDetails['duration_days'] as int? ?? 0;
      final price = selectedTypeDetails['price'] as double? ?? 0.0;
      _newEndDate = _newStartDate.add(Duration(days: duration));
      _renewalPrice = price;
    } else {
      _newEndDate = null;
      _renewalPrice = null;
    }
    // No need to call setState here if _calculateEndDateAndPrice is called within another setState or initState.
    // If called from onChanged, the Dropdown's setState will handle UI update.
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatPrice(double? price) {
    if (price == null) return 'N/A';
    return '\$${price.toStringAsFixed(2)}';
  }


  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      labelStyle: TextStyle(color: widget.mode ? Colors.white70 : Colors.black54),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: widget.mode ? Colors.white54 : Colors.black38),
      ),
    );
    final textStyle = TextStyle(color: widget.mode ? Colors.white : Colors.black);
    final infoTextStyle = TextStyle(color: widget.mode ? Colors.white70 : Colors.black87, fontSize: 16);
    final dropdownColor = widget.mode ? const Color.fromARGB(255, 59, 59, 59) : Colors.white;

    return AlertDialog(
      backgroundColor: widget.mode ? Colors.grey[850] : Colors.white, // Consistent background
      title: DefaultTextStyle( // Prominent title
        style: Theme.of(context).textTheme.titleLarge!.copyWith(color: widget.mode ? Colors.white : Colors.blue),
        child: const Text('Renovar Membresía'),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0), // Consistent padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cliente: ${widget.client.name}', style: infoTextStyle.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _isLoadingTypes
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      dropdownColor: dropdownColor,
                      decoration: inputDecoration.copyWith(labelText: 'Nuevo Tipo de Membresía'),
                      value: _selectedMembershipType,
                      items: _membershipTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type['name'] as String,
                          child: Text(type['name'] as String, style: textStyle),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMembershipType = value;
                          _calculateEndDateAndPrice();
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Seleccione un tipo de membresía';
                        }
                        return null;
                      },
                    ),
              const SizedBox(height: 20),
              Text('Fecha de Inicio: ${_formatDate(_newStartDate)}', style: infoTextStyle),
              const SizedBox(height: 10),
              Text('Nueva Fecha de Vencimiento: ${_formatDate(_newEndDate)}', style: infoTextStyle),
              const SizedBox(height: 10),
              Text('Precio de Renovación: ${_formatPrice(_renewalPrice)}', style: infoTextStyle),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: TextStyle(color: widget.mode ? Colors.redAccent[100] : Colors.red)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.mode ? Colors.teal : Colors.blue, // Standardized button color
          ),
          onPressed: (_selectedMembershipType == null || _isLoadingTypes) ? null : () {
            if (_formKey.currentState!.validate()) {
              widget.onRenew(widget.client, _selectedMembershipType!);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Renovar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
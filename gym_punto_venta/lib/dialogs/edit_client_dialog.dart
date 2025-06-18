import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gym_punto_venta/models/clients.dart';
import 'package:image_picker/image_picker.dart';

class EditClientDialog extends StatefulWidget {
  final Client client;
  final Function(Client) onSave;
  final bool mode;
  final Future<List<Map<String, dynamic>>> membershipTypesFuture;

  const EditClientDialog({
    Key? key,
    required this.mode,
    required this.client,
    required this.onSave,
    required this.membershipTypesFuture,
  }) : super(key: key);

  @override
  _EditClientDialogState createState() => _EditClientDialogState();
}

class _EditClientDialogState extends State<EditClientDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  // late TextEditingController _photoController; // Placeholder removed

  String? _selectedMembershipType;
  late String _selectedPaymentStatus;
  String? _currentPhotoPath; // Added for actual photo path
  List<Map<String, dynamic>> _membershipTypes = [];
  bool _isLoadingTypes = true;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (mounted) {
        setState(() {
          _currentPhotoPath = image.path; // Update this path
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client.name);
    _emailController = TextEditingController(text: widget.client.email);
    _phoneController = TextEditingController(text: widget.client.phone);
    // _photoController = TextEditingController(text: widget.client.photo ?? 'Photo path (later)'); // Removed
    _currentPhotoPath = widget.client.photo; // Initialize with current photo

    _selectedMembershipType = widget.client.membershipType;
    _selectedPaymentStatus = widget.client.paymentStatus;

    widget.membershipTypesFuture.then((types) {
      if (mounted) {
        setState(() {
          _membershipTypes = types;
          // Ensure the current client's membership type is valid and selected
          if (!_membershipTypes.any((type) => type['name'] == _selectedMembershipType) && _membershipTypes.isNotEmpty) {
            // If current type is not in the list (e.g. old/invalid), select the first available
             _selectedMembershipType = _membershipTypes.first['name'] as String?;
          } else if (_membershipTypes.isEmpty) {
            _selectedMembershipType = null; // No types available
          }
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

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      labelStyle: TextStyle(color: widget.mode ? Colors.white70 : Colors.black54),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: widget.mode ? Colors.white54 : Colors.black38),
      ),
    );
    final textStyle = TextStyle(color: widget.mode ? Colors.white : Colors.black);
    final dropdownColor = widget.mode ? const Color.fromARGB(255, 59, 59, 59) : Colors.white;

    return AlertDialog(
      backgroundColor: widget.mode ? Colors.grey[850] : Colors.white, // Consistent with other dialogs
      title: DefaultTextStyle( // Prominent title
        style: Theme.of(context).textTheme.titleLarge!.copyWith(color: widget.mode ? Colors.white : Colors.blue),
        child: const Text('Editar Cliente'),
      ),
      content: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0), // Consistent padding
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: inputDecoration.copyWith(labelText: 'Nombre'),
                style: textStyle,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un nombre';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: inputDecoration.copyWith(labelText: 'Email'),
                style: textStyle,
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: inputDecoration.copyWith(labelText: 'Teléfono'),
                style: textStyle,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _isLoadingTypes
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<String>(
                      dropdownColor: dropdownColor,
                      decoration: inputDecoration.copyWith(labelText: 'Tipo de Membresía'),
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
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Seleccione un tipo de membresía';
                        }
                        return null;
                      },
                    ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                dropdownColor: dropdownColor,
                decoration: inputDecoration.copyWith(labelText: 'Estado de Pago'),
                value: _selectedPaymentStatus,
                items: ['Paid', 'Pending', 'Overdue'].map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status, style: textStyle),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  if (_currentPhotoPath != null && _currentPhotoPath!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.file(
                        File(_currentPhotoPath!),
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error, color: Colors.red, size: 50);
                        },
                      ),
                    )
                  else
                    Icon(Icons.person, size: 100, color: widget.mode ? Colors.white54 : Colors.black54),
                  TextButton.icon(
                    icon: Icon(Icons.photo_camera, color: widget.mode ? Colors.white70 : Colors.blue),
                    label: Text(
                      _currentPhotoPath == null || _currentPhotoPath!.isEmpty ? "Seleccionar Foto" : "Cambiar Foto",
                      style: TextStyle(color: widget.mode ? Colors.white70 : Colors.blue),
                    ),
                    onPressed: _pickImage,
                  ),
                ],
              ),
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final updatedClient = widget.client;
              updatedClient.name = _nameController.text;
              updatedClient.email = _emailController.text;
              updatedClient.phone = _phoneController.text;
              updatedClient.membershipType = _selectedMembershipType!;
              updatedClient.paymentStatus = _selectedPaymentStatus;
              updatedClient.photo = _currentPhotoPath; // Use actual selected path
              // Other fields like startDate, endDate, isActive, currentMembershipPrice
              // are typically handled by renewal process or specific status update functions.
              // If editing membership type here should change price/dates, that logic would be in GymManagementFunctions.
              widget.onSave(updatedClient);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Guardar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
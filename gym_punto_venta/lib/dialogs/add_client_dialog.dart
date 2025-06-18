import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gym_punto_venta/models/clients.dart';
import 'package:image_picker/image_picker.dart';

class AddClientDialog extends StatefulWidget {
  final Function(Client) onSave;
  final bool mode;
  final Future<List<Map<String, dynamic>>> membershipTypesFuture;

  const AddClientDialog({
    Key? key,
    required this.mode,
    required this.onSave,
    required this.membershipTypesFuture,
  }) : super(key: key);

  @override
  _AddClientDialogState createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<AddClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  // final _photoController = TextEditingController(text: 'Photo path (later)'); // Placeholder removed

  String? _selectedMembershipType;
  String _selectedPaymentStatus = 'Paid';
  String? _selectedPhotoPath; // Added for actual photo path
  List<Map<String, dynamic>> _membershipTypes = [];
  bool _isLoadingTypes = true;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (mounted) {
        setState(() {
          _selectedPhotoPath = image.path;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    widget.membershipTypesFuture.then((types) {
      if (mounted) {
        setState(() {
          _membershipTypes = types;
          if (_membershipTypes.isNotEmpty) {
            _selectedMembershipType = _membershipTypes.first['name'] as String?;
          }
          _isLoadingTypes = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoadingTypes = false;
        });
        // Optionally show an error message to the user
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
        child: const Text('Nuevo Cliente'),
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
                  if (_selectedPhotoPath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50), // For circular preview
                      child: Image.file(
                        File(_selectedPhotoPath!),
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error, color: Colors.red, size: 50);
                        },
                      ),
                    ),
                  TextButton.icon(
                    icon: Icon(Icons.photo_camera, color: widget.mode ? Colors.white70 : Colors.blue),
                    label: Text(
                      _selectedPhotoPath == null ? "Seleccionar Foto" : "Cambiar Foto",
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
              final clientDataFromDialog = Client(
                id: "TEMPORARY_ID_WILL_BE_REPLACED", // This will be replaced
                name: _nameController.text,
                email: _emailController.text,
                phone: _phoneController.text,
                membershipType: _selectedMembershipType!,
                paymentStatus: _selectedPaymentStatus,
                photo: _selectedPhotoPath,
                startDate: DateTime.now(), // Placeholder, GMF will set final
                endDate: DateTime.now(),   // Placeholder, GMF will set final
                isActive: true,            // Placeholder, GMF will set final
              );
              widget.onSave(clientDataFromDialog);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Guardar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:gym_punto_venta/models/clients.dart';

class EditClientDialog extends StatefulWidget {
  final Client client;
  final Function(Client) onSave;
  bool mode;

  EditClientDialog({Key? key, required this.mode, required this.client, required this.onSave}) : super(key: key);

  @override
  _EditClientDialogState createState() => _EditClientDialogState();
}

class _EditClientDialogState extends State<EditClientDialog> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController.text = widget.client.name;
    emailController.text = widget.client.email;
    phoneController.text = widget.client.phone;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.mode ? const Color.fromARGB(255, 49, 49, 49) : Colors.white,
      title: Text('Editar Cliente', style: TextStyle(color: widget.mode ? Colors.white : Colors.blue)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Nombre', labelStyle: TextStyle(color: widget.mode ? Colors.white : Colors.black)),
              style: TextStyle(color: widget.mode ? Colors.white : Colors.black),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: widget.mode ? Colors.white : Colors.black)),
              style: TextStyle(color: widget.mode ? Colors.white : Colors.black),
            ),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'Teléfono', labelStyle: TextStyle(color: widget.mode ? Colors.white : Colors.black)),
              style: TextStyle(color: widget.mode ? Colors.white : Colors.black),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.mode ? Colors.grey[800] : Colors.blue,
          ),
          onPressed: () {
            final updatedClient = Client(
              id: widget.client.id,
              name: nameController.text,
              email: emailController.text,
              phone: phoneController.text,
              startDate: widget.client.startDate,
              endDate: widget.client.endDate,
              isActive: widget.client.isActive,
            );
            widget.onSave(updatedClient);
            Navigator.of(context).pop();
          },
          child: const Text('Guardar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
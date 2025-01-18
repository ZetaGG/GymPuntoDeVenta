import 'package:flutter/material.dart';
import 'package:gym_punto_venta/models/clients.dart';

class AddClientDialog extends StatefulWidget {
  final Function(Client) onSave;

  const AddClientDialog({Key? key, required this.onSave}) : super(key: key);

  @override
  _AddClientDialogState createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<AddClientDialog> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  String membershipType = 'Mensual';
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 30));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo Cliente'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Tipo de Membresía: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: membershipType,
                  items: const [
                    DropdownMenuItem(
                      value: 'Mensual',
                      child: Text('Mensual (30 días)'),
                    ),
                    DropdownMenuItem(
                      value: 'Semanal',
                      child: Text('Semanal (7 días)'),
                    ),
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      membershipType = value!;
                      endDate = startDate.add(Duration(days: value == 'Mensual' ? 30 : 7));
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final newClient = Client(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: nameController.text,
              email: emailController.text,
              phone: phoneController.text,
              startDate: startDate,
              endDate: endDate,
              isActive: true,
            );
            widget.onSave(newClient);
            Navigator.of(context).pop();
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}


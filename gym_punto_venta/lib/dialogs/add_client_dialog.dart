import 'package:flutter/material.dart';
import 'package:gym_punto_venta/models/clients.dart';

class AddClientDialog extends StatefulWidget {
  final Function(Client) onSave;
  bool mode;

   AddClientDialog({Key? key, required this.mode, required this.onSave}) : super(key: key);

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
      backgroundColor: widget.mode ? const Color.fromARGB(255, 49, 49, 49) :Colors.white,
      title: const Text('Nuevo Cliente', style: TextStyle(color: Colors.blue)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre', hintStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email' , hintStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Teléfono' , hintStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Tipo de Membresía: ' , style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  dropdownColor: widget.mode ? const Color.fromARGB(255, 49, 49, 49) :Colors.white,
                  value: membershipType,
                  items: const [
                    DropdownMenuItem(
                      value: 'Mensual',
                      child: Text('Mensual (30 días)', style: TextStyle(color: Colors.grey)),
                    ),
                    DropdownMenuItem(
                      value: 'Semanal',
                      child: Text('Semanal (7 días)', style: TextStyle(color: Colors.grey)),
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
          child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.mode ? Colors.grey[800]:Colors.white,
          ),
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
          child: const Text('Guardar', style: TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }
}


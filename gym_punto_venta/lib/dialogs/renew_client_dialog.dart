import 'package:flutter/material.dart';
import 'package:gym_punto_venta/models/clients.dart';

class RenewClientDialog extends StatefulWidget {
  final Client client;
  final Function(Client, String) onRenew;
  bool mode;

  RenewClientDialog({Key? key,required this.mode, required this.client, required this.onRenew}) : super(key: key);

  @override
  _RenewClientDialogState createState() => _RenewClientDialogState();
}

class _RenewClientDialogState extends State<RenewClientDialog> {
  String membershipType = 'Mensual';
  late DateTime newEndDate;

  @override
  void initState() {
    super.initState();
    newEndDate = DateTime.now().add(const Duration(days: 30));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.mode ? const Color.fromARGB(255, 49, 49, 49) :Colors.white,
      title: const Text('Renovar Membresía', style: TextStyle(color: Colors.blue),),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Cliente: ${widget.client.name}', style: TextStyle(color: Colors.grey),),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Tipo de Renovación: ', style: TextStyle(color: Colors.blue),),
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
                    child: Text('Semanal (7 días)',  style: TextStyle(color: Colors.grey)),
                  ),
                ],
                onChanged: (String? value) {
                  setState(() {
                    membershipType = value!;
                    newEndDate = DateTime.now().add(
                      Duration(days: value == 'Mensual' ? 30 : 7),
                    );
                  });
                },
              ),
            ],
          ),
        ],
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
              name: widget.client.name,
              email: widget.client.email,
              phone: widget.client.phone,
              startDate: DateTime.now(),
              endDate: newEndDate,
              isActive: true,
            );
            widget.onRenew(updatedClient, membershipType);
            Navigator.of(context).pop();
          },
          child: const Text('Renovar', style: TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }
}


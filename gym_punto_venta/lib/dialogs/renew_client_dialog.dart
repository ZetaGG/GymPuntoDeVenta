import 'package:flutter/material.dart';
import 'package:gym_punto_venta/models/clients.dart';

class RenewClientDialog extends StatefulWidget {
  final Client client;
  final Function(Client, String) onRenew;

  const RenewClientDialog({Key? key, required this.client, required this.onRenew}) : super(key: key);

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
      title: const Text('Renovar Membresía'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Cliente: ${widget.client.name}'),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Tipo de Renovación: '),
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
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
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
          child: const Text('Renovar'),
        ),
      ],
    );
  }
}


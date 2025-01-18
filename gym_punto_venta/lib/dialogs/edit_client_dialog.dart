import 'package:flutter/material.dart';
import 'package:gym_punto_venta/models/clients.dart';

class EditClientDialog extends StatefulWidget {
  final Client client;
  final Function(Client) onSave;

  const EditClientDialog({Key? key, required this.client, required this.onSave}) : super(key: key);

  @override
  _EditClientDialogState createState() => _EditClientDialogState();
}

class _EditClientDialogState extends State<EditClientDialog> {
  late DateTime newEndDate;

  @override
  void initState() {
    super.initState();
    newEndDate = widget.client.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar fecha de vencimiento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Cliente: ${widget.client.name}'),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: widget.client.endDate.isBefore(DateTime.now())
                    ? DateTime.now()
                    : widget.client.endDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() {
                  newEndDate = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                    23,
                    59,
                    59,
                  );
                });
              }
            },
            child: Text('Seleccionar nueva fecha'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedClient = Client(
              id: widget.client.id,
              name: widget.client.name,
              email: widget.client.email,
              phone: widget.client.phone,
              startDate: widget.client.startDate,
              endDate: newEndDate,
              isActive: true,
            );
            widget.onSave(updatedClient);
            Navigator.of(context).pop();
          },
          child: Text('Guardar'),
        ),
      ],
    );
  }
}


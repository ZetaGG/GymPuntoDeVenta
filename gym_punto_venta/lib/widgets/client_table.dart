import 'package:flutter/material.dart';
import 'package:gym_punto_venta/models/clients.dart';

class ClientTable extends StatelessWidget {
  final List<Client> clients;
  final Function(Client) onEdit;
  final Function(Client) onRenew;
  final Function(Client) onDelete;
  bool mode;

   ClientTable({
    Key? key,
    required this.mode,
    required this.clients,
    required this.onEdit,
    required this.onRenew,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Nombre', style: TextStyle(color: Colors.grey),)),
          DataColumn(label: Text('Email' , style: TextStyle(color: Colors.grey),)),
          DataColumn(label: Text('Teléfono' , style: TextStyle(color: Colors.grey),)),
          DataColumn(label: Text('Fecha Inicio' , style: TextStyle(color: Colors.grey),)),
          DataColumn(label: Text('Fecha Vencimiento' , style: TextStyle(color: Colors.grey),)),
          DataColumn(label: Text('Estado' , style: TextStyle(color: Colors.grey),)),
          DataColumn(label: Text('Acciones' , style: TextStyle(color: Colors.grey),)),
        ],
        rows: clients.map((client) {
          return DataRow(
            cells: [
              DataCell(Text(client.name, style: TextStyle(color: Colors.grey),)),
              DataCell(Text(client.email, style: TextStyle(color: Colors.grey),)),
              DataCell(Text(client.phone, style: TextStyle(color: Colors.grey),)),
              DataCell(Text(client.startDate.toString().split(' ')[0], style: TextStyle(color: Colors.grey),)),
              DataCell(Text(client.endDate.toString().split(' ')[0], style: TextStyle(color: Colors.grey),)),
              _buildStatusCell(client),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => onEdit(client),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('Editar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => onRenew(client),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('Renovar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => onDelete(client),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  DataCell _buildStatusCell(Client client) {
    final daysRemaining = _calculateRemainingDays(client.endDate);
    final isExpired = daysRemaining <= 0;
    final isNearExpiration = daysRemaining <= 7 && daysRemaining > 0;

    Color backgroundColor;
    Color textColor;
    String statusText;

    if (isExpired || !client.isActive) {
      backgroundColor = Colors.red.withOpacity(0.2);
      textColor = Colors.red.shade700;
      statusText = 'Inactivo';
    } else if (isNearExpiration) {
      backgroundColor = Colors.orange.withOpacity(0.2);
      textColor = Colors.orange.shade700;
      statusText = 'Activo - $daysRemaining días restantes';
    } else {
      backgroundColor = Colors.green.withOpacity(0.2);
      textColor = Colors.green.shade700;
      statusText = 'Activo - $daysRemaining días restantes';
    }

    return DataCell(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          statusText,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  int _calculateRemainingDays(DateTime endDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(today).inDays;
  }
}


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gym_punto_venta/models/clients.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class ClientTable extends StatelessWidget {
  final List<Client> clients;
  final Function(Client) onEdit;
  final Function(Client) onRenew;
  final Function(Client) onDelete;
  final Function(Client) onRegisterVisit; // New callback
  final bool mode;

   const ClientTable({ // Changed to const constructor
    Key? key,
    required this.mode,
    required this.clients,
    required this.onEdit,
    required this.onRenew,
    required this.onDelete,
    required this.onRegisterVisit, // New callback added
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Photo', style: TextStyle(color: mode ? Colors.white70 : Colors.black54))),
          DataColumn(label: Text('Nombre', style: TextStyle(color: mode ? Colors.white70 : Colors.black54))),
          DataColumn(label: Text('Email' , style: TextStyle(color: mode ? Colors.white70 : Colors.black54))),
          DataColumn(label: Text('Teléfono' , style: TextStyle(color: mode ? Colors.white70 : Colors.black54))),
          DataColumn(label: Text('Membership', style: TextStyle(color: mode ? Colors.white70 : Colors.black54))),
          DataColumn(label: Text('Payment', style: TextStyle(color: mode ? Colors.white70 : Colors.black54))),
          DataColumn(label: Text('Fecha Inicio' , style: TextStyle(color: mode ? Colors.white70 : Colors.black54))),
          DataColumn(label: Text('Fecha Vencimiento' , style: TextStyle(color: mode ? Colors.white70 : Colors.black54))),
          DataColumn(label: Text('Last Visit', style: TextStyle(color: mode ? Colors.white70 : Colors.black54))), // New Column
          DataColumn(label: Text('Estado' , style: TextStyle(color: mode ? Colors.white70 : Colors.black54))),
          DataColumn(label: Text('Acciones' , style: TextStyle(color: mode ? Colors.white70 : Colors.black54))),
        ],
        rows: clients.map((client) {
          final cellTextStyle = TextStyle(color: mode ? Colors.white : Colors.black87);
          return DataRow(
            cells: [
              DataCell(
                client.photo != null && client.photo!.isNotEmpty
                    ? CircleAvatar(
                        radius: 20,
                        backgroundImage: FileImage(File(client.photo!)),
                        onBackgroundImageError: (exception, stackTrace) {
                          print('Error loading image from path: ${client.photo}, Error: $exception');
                        },
                      )
                    : Icon(Icons.person, color: mode ? Colors.white54 : Colors.black54, size: 24),
              ),
              DataCell(Text(client.name, style: cellTextStyle)),
              DataCell(Text(client.email ?? '', style: cellTextStyle)),
              DataCell(Text(client.phone ?? '', style: cellTextStyle)),
              DataCell(Text(client.membershipType, style: cellTextStyle)),
              DataCell(Text(client.paymentStatus, style: cellTextStyle)),
              DataCell(Text(client.startDate.toString().split(' ')[0], style: cellTextStyle)),
              DataCell(Text(client.endDate.toString().split(' ')[0], style: cellTextStyle)),
              DataCell( // New Cell for Last Visit
                Text(
                  client.lastVisitDate != null
                      ? DateFormat('yyyy-MM-dd HH:mm').format(client.lastVisitDate!)
                      : 'N/A',
                  style: cellTextStyle,
                ),
              ),
              _buildStatusCell(client),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton( // New "Register Visit" button
                      icon: Icon(Icons.check_circle_outline, color: mode ? Colors.greenAccent[400] : Colors.green),
                      tooltip: 'Registrar Visita',
                      onPressed: () => onRegisterVisit(client),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: mode ? Colors.orangeAccent : Colors.orange),
                      tooltip: 'Editar Cliente',
                      onPressed: () => onEdit(client),
                    ),
                    IconButton(
                      icon: Icon(Icons.autorenew, color: mode ? Colors.blueAccent : Colors.blue),
                      tooltip: 'Renovar Membresía',
                      onPressed: () => onRenew(client),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: mode ? Colors.redAccent : Colors.red),
                      tooltip: 'Eliminar Cliente',
                      onPressed: () => onDelete(client),
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


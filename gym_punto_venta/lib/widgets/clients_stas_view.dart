import 'package:flutter/material.dart';
import '../models/clients.dart';
import 'statscard.dart';

class ClientStatsView extends StatelessWidget {
  final bool darkMode;
  final List<Client> clients;
  final int Function(DateTime) calculateRemainingDays;

  const ClientStatsView({
    Key? key,
    required this.darkMode,
    required this.clients,
    required this.calculateRemainingDays,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(mode: darkMode, title: 'Total Clientes', value: clients.length.toString()),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            mode: darkMode,
            title: 'Clientes Activos',
            value: clients.where((c) => c.isActive && calculateRemainingDays(c.endDate) > 0).length.toString(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            mode: darkMode,
            title: 'Clientes Inactivos',
            value: clients.where((c) => !c.isActive || calculateRemainingDays(c.endDate) <= 0).length.toString(),
          ),
        ),
      ],
    );
  }
}
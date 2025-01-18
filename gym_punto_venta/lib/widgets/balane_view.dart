import 'package:flutter/material.dart';
import 'statscard.dart';
import '../functions/funtions.dart';

class BalanceView extends StatelessWidget {
  final bool darkMode;
  final double balance;
  final GymManagementFunctions functions;

  const BalanceView({
    Key? key,
    required this.darkMode,
    required this.balance,
    required this.functions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(mode: darkMode, title: 'Balance Anual', value: balance.toStringAsFixed(2)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(mode: darkMode, title: 'Balance Mensual', value: (balance / 12).toStringAsFixed(2)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: darkMode ? Colors.grey[800] : Colors.white),
            onPressed: functions.editPrices,
            child: const Text('Editar Precios', style: TextStyle(color: Colors.blue)),
          ),
        ),
      ],
    );
  }
}
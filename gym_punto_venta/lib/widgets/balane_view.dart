import 'package:flutter/material.dart';
import 'statscard.dart';
import '../functions/funtions.dart';
import '../screens/manage_membership_types_screen.dart'; // Adjust path if necessary

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
            style: ElevatedButton.styleFrom(
              backgroundColor: darkMode ? Colors.grey[800] : Colors.white,
              disabledBackgroundColor: darkMode ? Colors.grey[700] : Colors.grey[300], // Style for disabled state
            ),
            onPressed: functions.areFeaturesUnlocked() // Check license status
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageMembershipTypesScreen(functions: functions),
                      ),
                    );
                  }
                : () { // Action when features are locked
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Managing membership types is a premium feature. Please activate your license."),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
            child: Text(
              'Tipos de Membresía', // Changed text to reflect new screen
              style: TextStyle(
                color: functions.areFeaturesUnlocked()
                         ? (darkMode ? Colors.tealAccent[400] : Colors.blue) // Normal color
                         : (darkMode ? Colors.white54 : Colors.black54), // Dimmed color when disabled
              ),
            ),
          ),
        ),
      ],
    );
  }
}
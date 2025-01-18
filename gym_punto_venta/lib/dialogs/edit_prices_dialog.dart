import 'package:flutter/material.dart';

class EditPricesDialog extends StatelessWidget {
  final double monthlyFee;
  final double weeklyFee;
  final double visitFee;
  final Function(double, double, double) onSave;

  EditPricesDialog({
    Key? key,
    required this.monthlyFee,
    required this.weeklyFee,
    required this.visitFee,
    required this.onSave,
  }) : super(key: key);

  final monthlyController = TextEditingController();
  final weeklyController = TextEditingController();
  final visitController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    monthlyController.text = monthlyFee.toString();
    weeklyController.text = weeklyFee.toString();
    visitController.text = visitFee.toString();

    return AlertDialog(
      title: const Text('Editar Precios'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: monthlyController,
            decoration: const InputDecoration(labelText: 'Precio Mensual'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: weeklyController,
            decoration: const InputDecoration(labelText: 'Precio Semanal'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: visitController,
            decoration: const InputDecoration(labelText: 'Precio de Visita'),
            keyboardType: TextInputType.number,
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
            onSave(
              double.parse(monthlyController.text),
              double.parse(weeklyController.text),
              double.parse(visitController.text),
            );
            Navigator.of(context).pop();
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';

class EditPricesDialog extends StatelessWidget {
  final double monthlyFee;
  final double weeklyFee;
  final double visitFee;
  final Function(double, double, double) onSave;
  bool mode;

  EditPricesDialog({
    Key? key,
    required this.mode,
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
      backgroundColor: mode ? const Color.fromARGB(255, 49, 49, 49)  : Colors.white,
      title: const Text('Editar Precios', style: TextStyle(color: Colors.blue)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            style:  TextStyle(color: mode ? Colors.white : Colors.black),
            controller: monthlyController,
            decoration: const InputDecoration(labelText: 'Precio Mensual', helperStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
            keyboardType: TextInputType.number,
          ),
          TextField(
            style:  TextStyle(color: mode ? Colors.white : Colors.black),
            controller: weeklyController,
            decoration: const InputDecoration(labelText: 'Precio Semanal' , helperStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
            keyboardType: TextInputType.number,
          ),
          TextField(
            style:  TextStyle(color: mode ? Colors.white : Colors.black),
            controller: visitController,
            keyboardType: TextInputType.number,
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
            backgroundColor: mode ? Colors.grey[800] : Colors.blue,
          ),
          onPressed: () {
            onSave(
              double.parse(monthlyController.text),
              double.parse(weeklyController.text),
              double.parse(visitController.text),
            );
            Navigator.of(context).pop();
          },
          child: const Text('Guardar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_punto_venta/models/product.dart'; // Asegúrate que la ruta es correcta

class EditStockDialog extends StatefulWidget {
  final Product product;
  final bool darkMode;

  const EditStockDialog({
    Key? key,
    required this.product,
    required this.darkMode,
  }) : super(key: key);

  @override
  _EditStockDialogState createState() => _EditStockDialogState();
}

class _EditStockDialogState extends State<EditStockDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _stockController;

  @override
  void initState() {
    super.initState();
    // Inicializa el controlador con el stock actual del producto
    _stockController = TextEditingController(text: widget.product.stock.toString());
  }

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }

  void _saveStock() {
    if (_formKey.currentState!.validate()) {
      final newStock = int.tryParse(_stockController.text);
      if (newStock != null) {
        Navigator.of(context).pop(newStock); // Devuelve el nuevo valor de stock
      } else {
        // Esto no debería ocurrir si la validación es correcta
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      labelStyle: TextStyle(color: widget.darkMode ? Colors.white70 : Colors.black54),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: widget.darkMode ? Colors.white54 : Colors.black38),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: widget.darkMode ? Colors.blueAccent : Colors.blue),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: widget.darkMode ? Colors.redAccent : Colors.red),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: widget.darkMode ? Colors.redAccent : Colors.red, width: 2.0),
      ),
    );
    final textStyle = TextStyle(color: widget.darkMode ? Colors.white : Colors.black);

    return AlertDialog(
      backgroundColor: widget.darkMode ? Colors.grey[850] : Colors.white,
      title: Text(
        'Editar Stock de ${widget.product.name}',
        style: TextStyle(color: widget.darkMode ? Colors.white : Colors.blue[700], fontSize: 18),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _stockController,
          decoration: inputDecoration.copyWith(labelText: 'Nueva Cantidad de Stock'),
          style: textStyle,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese una cantidad';
            }
            final n = int.tryParse(value);
            if (n == null) {
              return 'Por favor ingrese un número válido';
            }
            if (n < 0) {
              return 'El stock no puede ser negativo';
            }
            return null;
          },
          autofocus: true,
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancelar', style: TextStyle(color: widget.darkMode ? Colors.redAccent[100] : Colors.red)),
          onPressed: () {
            Navigator.of(context).pop(); // Devuelve null
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.darkMode ? Colors.teal : Colors.blue,
            foregroundColor: Colors.white,
          ),
          onPressed: _saveStock,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

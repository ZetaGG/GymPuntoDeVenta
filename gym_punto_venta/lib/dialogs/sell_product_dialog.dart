import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_punto_venta/models/product.dart';

class SellProductDialog extends StatefulWidget {
  final Product product;
  final bool darkMode;
  final Function(Product product, int quantity) onConfirmSale;
  // TODO: Considerar añadir una función para obtener el historial de ventas si se implementa esa mejora.

  const SellProductDialog({
    Key? key,
    required this.product,
    required this.darkMode,
    required this.onConfirmSale,
  }) : super(key: key);

  @override
  _SellProductDialogState createState() => _SellProductDialogState();
}

class _SellProductDialogState extends State<SellProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1'); // Default quantity to 1
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_validateQuantityRealTime);
  }

  @override
  void dispose() {
    _quantityController.removeListener(_validateQuantityRealTime);
    _quantityController.dispose();
    super.dispose();
  }

  void _validateQuantityRealTime() {
    final String value = _quantityController.text;
    if (value.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ingrese una cantidad';
        });
      }
      return;
    }
    final int? quantity = int.tryParse(value);
    if (quantity == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ingrese un número válido';
        });
      }
      return;
    }
    if (quantity <= 0) {
      if (mounted) {
        setState(() {
          _errorMessage = 'La cantidad debe ser mayor a 0';
        });
      }
      return;
    }
    if (quantity > widget.product.stock) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Stock insuficiente (Disp: ${widget.product.stock})';
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _errorMessage = null; // No error
      });
    }
  }

  String? _validateQuantityOnSubmit(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese una cantidad';
    }
    final quantity = int.tryParse(value);
    if (quantity == null) {
      return 'Ingrese un número válido';
    }
    if (quantity <= 0) {
      return 'La cantidad debe ser mayor a 0';
    }
    if (quantity > widget.product.stock) {
      return 'Stock insuficiente (Disponible: ${widget.product.stock})';
    }
    return null;
  }

  void _confirmSale() {
    if (_formKey.currentState!.validate()) {
      final int quantity = int.parse(_quantityController.text);
      widget.onConfirmSale(widget.product, quantity);
      Navigator.of(context).pop();
    } else {
      // Ensure real-time validation message is also shown if submit is pressed early
      _validateQuantityRealTime();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(color: widget.darkMode ? Colors.white : Colors.black);
    final labelStyle = TextStyle(color: widget.darkMode ? Colors.white70 : Colors.black54);
    final inputBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: widget.darkMode ? Colors.white54 : Colors.black38),
    );
    final focusedInputBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: widget.darkMode ? Colors.blueAccent : Colors.blue),
    );
    final errorInputBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: widget.darkMode ? Colors.redAccent : Colors.red),
    );
    final focusedErrorInputBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: widget.darkMode ? Colors.redAccent : Colors.red, width: 2.0),
    );

    return AlertDialog(
      backgroundColor: widget.darkMode ? Colors.grey[850] : Colors.white,
      title: Text(
        'Vender Producto',
        style: TextStyle(color: widget.darkMode ? Colors.white : Colors.blue[700]),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Producto: ${widget.product.name}', style: textStyle),
            Text('Precio: \$${widget.product.price.toStringAsFixed(2)}', style: textStyle),
            Text('Stock Disponible: ${widget.product.stock}', style: textStyle),
            SizedBox(height: 20),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Cantidad a Vender',
                labelStyle: labelStyle,
                enabledBorder: inputBorder,
                focusedBorder: focusedInputBorder,
                errorBorder: errorInputBorder,
                focusedErrorBorder: focusedErrorInputBorder,
                errorText: _errorMessage, // Real-time error message
                hintText: 'Ej. 1',
                hintStyle: TextStyle(color: widget.darkMode ? Colors.grey[600] : Colors.grey[400]),
              ),
              style: textStyle,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _validateQuantityOnSubmit, // Validation on submit
              autofocus: true,
            ),
            // SizedBox(height: 10),
            // TODO: Aquí se podría agregar el historial de ventas recientes
            // if (historialDeVentas.isNotEmpty) ...[
            //   Text('Ventas Recientes:', style: textStyle.copyWith(fontWeight: FontWeight.bold)),
            //   ...historialDeVentas.map((venta) => Text('${venta.fecha}: ${venta.cantidad}', style: textStyle)),
            // ]
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancelar', style: TextStyle(color: widget.darkMode ? Colors.redAccent[100] : Colors.red)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.darkMode ? Colors.teal : Colors.blue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: widget.darkMode ? Colors.grey[700] : Colors.grey[400],
          ),
          onPressed: _errorMessage == null && _quantityController.text.isNotEmpty ? _confirmSale : null, // Disable if error or empty
          child: const Text('Confirmar Venta'),
        ),
      ],
    );
  }
}

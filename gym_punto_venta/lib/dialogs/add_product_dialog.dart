import 'package:flutter/material.dart';
import 'package:gym_punto_venta/models/product.dart';
import 'package:gym_punto_venta/widgets/custom_form_field.dart';

class AddProductDialog extends StatefulWidget {
  final bool darkMode;
  final Function(Product) onProductSaved;
  final Product? initialProduct; // Para futura edición si se decide unificar

  const AddProductDialog({
    Key? key,
    required this.darkMode,
    required this.onProductSaved,
    this.initialProduct,
  }) : super(key: key);

  @override
  _AddProductDialogState createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialProduct != null) {
      _nameController.text = widget.initialProduct!.name;
      _categoryController.text = widget.initialProduct!.category;
      _priceController.text = widget.initialProduct!.price.toString();
      _stockController.text = widget.initialProduct!.stock.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      String name = _nameController.text;
      String category = _categoryController.text;
      double price = double.tryParse(_priceController.text) ?? 0.0;
      int stock = int.tryParse(_stockController.text) ?? 0;

      final product = Product(
        // id se asignará en la base de datos o por la función que guarda
        name: name,
        category: category,
        price: price,
        stock: stock,
      );

      widget.onProductSaved(product);
      Navigator.pop(context); // Cerrar el diálogo después de guardar
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.darkMode ? Colors.grey[850] : Colors.white,
      title: Text(
        widget.initialProduct == null ? 'Agregar Producto' : 'Editar Producto',
        style: TextStyle(color: widget.darkMode ? Colors.white : Colors.blue[700]),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CustomFormField(
                controller: _nameController,
                labelText: 'Nombre del Producto',
                darkMode: widget.darkMode,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre del producto';
                  }
                  return null;
                },
              ),
              CustomFormField(
                controller: _categoryController,
                labelText: 'Categoría',
                hintText: 'Ej. Proteína, Pre-entreno',
                darkMode: widget.darkMode,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la categoría';
                  }
                  return null;
                },
              ),
              CustomFormField(
                controller: _priceController,
                labelText: 'Precio (MXN)',
                darkMode: widget.darkMode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el precio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor ingrese un número válido';
                  }
                  if (double.parse(value) <= 0) {
                    return 'El precio debe ser mayor que cero';
                  }
                  return null;
                },
              ),
              CustomFormField(
                controller: _stockController,
                labelText: 'Cantidad Disponible (Stock)',
                darkMode: widget.darkMode,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la cantidad disponible';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Por favor ingrese un número entero válido';
                  }
                  if (int.parse(value) < 0) {
                    return 'La cantidad no puede ser negativa';
                  }
                  return null;
                },
              ),
            ],
          ),
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
          ),
          onPressed: _saveProduct,
          child: Text(widget.initialProduct == null ? 'Guardar Producto' : 'Actualizar Producto'),
        ),
      ],
    );
  }
}

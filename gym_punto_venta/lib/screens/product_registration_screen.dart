import 'package:flutter/material.dart';
import 'package:gym_punto_venta/widgets/custom_form_field.dart'; // Importar el widget reutilizable
import 'package:gym_punto_venta/models/product.dart'; // Importar el modelo Product

class ProductRegistrationScreen extends StatefulWidget {
  final bool darkMode;
  final Function(Product) onProductSaved; // Callback para guardar el producto

  const ProductRegistrationScreen({
    Key? key,
    required this.darkMode,
    required this.onProductSaved,
  }) : super(key: key);

  @override
  _ProductRegistrationScreenState createState() => _ProductRegistrationScreenState();
}

class _ProductRegistrationScreenState extends State<ProductRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

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

      final newProduct = Product(
        name: name,
        category: category,
        price: price,
        stock: stock,
      );

      widget.onProductSaved(newProduct); // Llamar al callback

      // Imprimir en consola por ahora (se puede remover si el SnackBar de PrincipalScreen es suficiente)
      // print('Producto Guardado y enviado al callback:');
      // print('Nombre: $name');
      // print('Categoría: $category');
      // print('Precio: $price MXN');
      // print('Stock: $stock');

      // Mostrar un SnackBar localmente también puede ser útil
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Producto "$name" registrado.')),
      );

      // Limpiar campos después de guardar
      _formKey.currentState!.reset();
      _nameController.clear();
      _categoryController.clear();
      _priceController.clear();
      _stockController.clear();

      // Regresar a la pantalla anterior
      Navigator.pop(context);
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
    // final inputDecoration = InputDecoration(...); // Ya no es necesario aquí
    // final textStyle = TextStyle(color: widget.darkMode ? Colors.white : Colors.black); // Ya no es necesario aquí

    return Scaffold(
      backgroundColor: widget.darkMode ? const Color.fromARGB(255, 49, 49, 49) : Colors.white,
      appBar: AppBar(
        title: const Text('Registrar Producto', style: TextStyle(color: Colors.white)),
        backgroundColor: widget.darkMode ? Colors.grey[850] : Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
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
              // const SizedBox(height: 16), // El CustomFormField ya tiene padding vertical
              CustomFormField(
                controller: _categoryController,
                labelText: 'Categoría',
                hintText: 'Ej. Proteína, Pre-entreno, Creatina',
                darkMode: widget.darkMode,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la categoría';
                  }
                  return null;
                },
              ),
              // const SizedBox(height: 16),
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
              // const SizedBox(height: 16),
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
              const SizedBox(height: 24), // Ajustar el espaciado antes del botón
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.darkMode ? Colors.teal : Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, color: Colors.white),
                ).copyWith(
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                ),
                onPressed: _saveProduct,
                child: const Text('Guardar Producto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

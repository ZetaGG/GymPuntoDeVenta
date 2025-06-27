import 'package:flutter/material.dart';
import 'package:gym_punto_venta/models/product.dart';
import 'package:gym_punto_venta/widgets/custom_form_field.dart';

class AddProductDialog extends StatefulWidget {
  final bool darkMode;
  final Function(Product) onProductSaved;
  final Product? initialProduct;
  final List<String> availableCategories; // Lista de categorías existentes

  const AddProductDialog({
    Key? key,
    required this.darkMode,
    required this.onProductSaved,
    this.initialProduct,
    required this.availableCategories,
  }) : super(key: key);

  @override
  _AddProductDialogState createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  // State for categories
  String? _selectedCategory;
  bool _showNewCategoryField = false;
  final _newCategoryController = TextEditingController();
  List<String> _allCategories = [];
  static const String _addNewCategoryValue = 'ADD_NEW_CATEGORY_VALUE';

  @override
  void initState() {
    super.initState();
    _allCategories = List.from(widget.availableCategories);

    if (widget.initialProduct != null) {
      _nameController.text = widget.initialProduct!.name;
      _priceController.text = widget.initialProduct!.price.toString();
      _stockController.text = widget.initialProduct!.stock.toString();
      // Set initial category for editing
      if (_allCategories.contains(widget.initialProduct!.category)) {
        _selectedCategory = widget.initialProduct!.category;
      } else if (widget.initialProduct!.category.isNotEmpty) {
        // If the product's category is not in the list (e.g. was added manually before this feature)
        // Treat it as a new category entry for editing purposes.
        _allCategories.add(widget.initialProduct!.category); // Temporarily add to list for display
         _allCategories.sort(); // Keep sorted
        _selectedCategory = widget.initialProduct!.category;
        // Or, could opt to show it in the "new category" field:
        // _showNewCategoryField = true;
        // _newCategoryController.text = widget.initialProduct!.category;
      }
    } else {
      // For new product, if categories exist, select the first one by default.
      // if (_allCategories.isNotEmpty) {
      // _selectedCategory = _allCategories.first;
      // }
      // Or leave null to force user selection
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      String name = _nameController.text;
      double price = double.tryParse(_priceController.text) ?? 0.0;
      int stock = int.tryParse(_stockController.text) ?? 0;
      String category = '';

      if (_showNewCategoryField) {
        category = _newCategoryController.text.trim();
        if (category.isEmpty) {
          // This should be caught by validator, but as a safeguard
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El nombre de la nueva categoría no puede estar vacío.')),
          );
          return;
        }
      } else {
        if (_selectedCategory == null || _selectedCategory!.isEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor seleccione o agregue una categoría.')),
          );
          return;
        }
        category = _selectedCategory!;
      }

      final product = Product(
        id: widget.initialProduct?.id, // Preserve ID if editing
        name: name,
        category: category, // Use determined category
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
              // Category Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  labelStyle: TextStyle(color: widget.darkMode ? Colors.white70 : Colors.black54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: widget.darkMode ? Colors.white54 : Colors.black38),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: widget.darkMode ? Colors.blueAccent : Colors.blue),
                  ),
                ),
                dropdownColor: widget.darkMode ? Colors.grey[700] : Colors.white,
                value: _selectedCategory,
                hint: Text('Seleccione una categoría', style: TextStyle(color: widget.darkMode ? Colors.white54 : Colors.black38)),
                isExpanded: true,
                items: [
                  ..._allCategories.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(color: widget.darkMode ? Colors.white : Colors.black)),
                    );
                  }).toList(),
                  DropdownMenuItem<String>(
                    value: _addNewCategoryValue,
                    child: Text('Agregar nueva categoría...', style: TextStyle(fontStyle: FontStyle.italic, color: widget.darkMode ? Colors.tealAccent : Colors.blue)),
                  ),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    if (newValue == _addNewCategoryValue) {
                      _showNewCategoryField = true;
                      _selectedCategory = null; // Clear selection when adding new
                    } else {
                      _showNewCategoryField = false;
                      _selectedCategory = newValue;
                    }
                  });
                },
                validator: (value) {
                  if (!_showNewCategoryField && value == null) {
                    return 'Por favor seleccione una categoría';
                  }
                  return null;
                },
              ),
              if (_showNewCategoryField)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: CustomFormField(
                    controller: _newCategoryController,
                    labelText: 'Nombre de Nueva Categoría',
                    darkMode: widget.darkMode,
                    autofocus: true,
                    validator: (value) {
                      if (_showNewCategoryField && (value == null || value.isEmpty)) {
                        return 'Ingrese el nombre de la nueva categoría';
                      }
                      if (_showNewCategoryField && _allCategories.map((c) => c.toLowerCase()).contains(value?.toLowerCase())) {
                        return 'Esta categoría ya existe';
                      }
                      return null;
                    },
                  ),
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

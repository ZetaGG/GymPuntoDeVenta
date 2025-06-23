import 'package:flutter/material.dart';
import 'package:gym_punto_venta/models/product.dart'; // Asegúrate que la ruta es correcta
import 'package:gym_punto_venta/widgets/product_card.dart'; // Asegúrate que la ruta es correcta

class ProductList extends StatelessWidget {
  final List<Product> products;
  final bool darkMode;
  final Function(Product) onSellProduct; // Callback para vender un producto específico
  final Function(Product) onEditStockProduct; // Callback para editar stock de un producto específico

  const ProductList({
    Key? key,
    required this.products,
    required this.darkMode,
    required this.onSellProduct,
    required this.onEditStockProduct, // Añadir el nuevo callback
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No hay productos registrados todavía.\n¡Agrega algunos usando el botón de arriba!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18.0,
              color: darkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: products.length,
      padding: const EdgeInsets.all(8.0), // Padding alrededor de la lista
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          darkMode: darkMode,
          onSell: () => onSellProduct(product),
          onEditStock: () => onEditStockProduct(product), // Pasa el producto específico al nuevo callback
        );
      },
    );
  }
}

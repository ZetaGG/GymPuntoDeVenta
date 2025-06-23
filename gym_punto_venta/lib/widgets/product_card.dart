import 'package:flutter/material.dart';
import 'package:gym_punto_venta/models/product.dart'; // Asegúrate que la ruta sea correcta

class ProductCard extends StatelessWidget {
  final Product product;
  final bool darkMode;
  final VoidCallback onSell; // Callback para cuando se presiona el botón de vender

  const ProductCard({
    Key? key,
    required this.product,
    required this.darkMode,
    required this.onSell,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color textColor = darkMode ? Colors.white : Colors.black87;
    final Color subtextColor = darkMode ? Colors.white70 : Colors.black54;
    final Color cardBackgroundColor = darkMode ? Colors.grey[800]! : Colors.white;
    final Color disabledButtonColor = darkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final Color enabledButtonColor = darkMode ? Colors.tealAccent[700]! : Colors.blue;
     final Color enabledButtonTextColor = darkMode ? Colors.black : Colors.white;


    return Card(
      elevation: darkMode ? 2.0 : 3.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4.0),
            Text(
              'Categoría: ${product.category}',
              style: TextStyle(
                fontSize: 14.0,
                color: subtextColor,
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Precio: \$${product.price.toStringAsFixed(2)} MXN',
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Text(
                  'Stock: ${product.stock}',
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                    color: product.stock > 0 ? (darkMode ? Colors.greenAccent : Colors.green) : (darkMode? Colors.redAccent[100] : Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: Icon(product.stock > 0 ? Icons.shopping_cart_checkout : Icons.remove_shopping_cart_outlined, size: 18),
                label: Text(product.stock > 0 ? 'Vender Unidad' : 'Sin Stock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: product.stock > 0 ? enabledButtonColor : disabledButtonColor,
                  foregroundColor: product.stock > 0 ? enabledButtonTextColor : subtextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                ),
                onPressed: product.stock > 0 ? onSell : null, // Deshabilita si no hay stock
              ),
            ),
          ],
        ),
      ),
    );
  }
}

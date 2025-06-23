import 'package:flutter/material.dart';
import 'package:gym_punto_venta/models/product.dart'; // Asegúrate que la ruta es correcta

class SalesSummary extends StatelessWidget {
  final List<Product> products;
  final bool darkMode;

  const SalesSummary({
    Key? key,
    required this.products,
    required this.darkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color textColor = darkMode ? Colors.white : Colors.black87;
    final Color cardBackgroundColor = darkMode ? Colors.grey[850]! : Colors.blue[600]!;
    final Color valueColor = darkMode ? Colors.tealAccent[100]! : Colors.white;

    int totalProductTypes = products.length;
    int totalStock = products.fold(0, (sum, product) => sum + product.stock);

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.all(12.0),
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('Tipos de Producto', totalProductTypes.toString(), textColor, valueColor),
            _buildSummaryItem('Stock Total Unidades', totalStock.toString(), textColor, valueColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color titleColor, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            color: titleColor.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

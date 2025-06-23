import 'package:flutter/material.dart';
import 'package:gym_punto_venta/functions/funtions.dart'; // Assuming GymManagementFunctions is here

class BalanceDashboardWidget extends StatefulWidget {
  final GymManagementFunctions functions;
  final bool darkMode;

  const BalanceDashboardWidget({
    Key? key,
    required this.functions,
    required this.darkMode,
  }) : super(key: key);

  @override
  _BalanceDashboardWidgetState createState() => _BalanceDashboardWidgetState();
}

class _BalanceDashboardWidgetState extends State<BalanceDashboardWidget> {
  // Placeholder for financial data
  Map<String, double>? _financialSummary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFinancialData();
  }

  Future<void> _fetchFinancialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final summary = await widget.functions.getCurrentMonthFinancialSummary();
      if (!mounted) return;
      setState(() {
        _financialSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching financial data: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.darkMode ? Colors.white : Colors.black;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Balance Financiero (Mes Actual)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: textColor),
                onPressed: _fetchFinancialData,
                tooltip: 'Actualizar',
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_financialSummary == null && !_isLoading)
            Center(child: Text('No hay datos financieros para mostrar.', style: TextStyle(color: textColor.withOpacity(0.7)))),
          if (_financialSummary != null)
          Card(
            color: widget.darkMode ? Colors.grey[800] : Colors.white,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Ventas Productos: \$${_financialSummary?['productSales']?.toStringAsFixed(2) ?? '0.00'}', style: TextStyle(color: textColor, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Ingresos Membresías: \$${_financialSummary?['membershipRevenue']?.toStringAsFixed(2) ?? '0.00'}', style: TextStyle(color: textColor, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Divider(),
                  Text('Ingresos Totales: \$${_financialSummary?['totalRevenue']?.toStringAsFixed(2) ?? '0.00'}', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Gráfico de Distribución (Próximamente)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
          ),
          Container(
            height: 200,
            alignment: Alignment.center,
            child: Text('Pie Chart Placeholder', style: TextStyle(color: textColor.withOpacity(0.7))),
            decoration: BoxDecoration(
              border: Border.all(color: textColor.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 20),
          // Placeholder for refresh button
          // ElevatedButton.icon(
          //   icon: const Icon(Icons.refresh),
          //   label: const Text('Actualizar'),
          //   onPressed: _fetchFinancialData,
          // ),
        ],
      ),
    );
  }
}

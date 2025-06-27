import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart
import 'package:gym_punto_venta/functions/funtions.dart'; // Assuming GymManagementFunctions is here
import 'package:intl/intl.dart'; // For date formatting
import 'package:gym_punto_venta/database/database_helper.dart'; // Import TimePeriod from here
import 'dart:math' show max; // Import max function

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
  TimePeriod _selectedPeriod = TimePeriod.lastMonth; // Default period
  // Data for charts
  List<FlSpot> _salesData = []; // For overall sales (Line/Bar)
  List<PieChartSectionData> _customerCategoryData = []; // For customer distribution (Pie)
  List<BarChartGroupData> _productSalesData = []; // For product sales (Bar)
  List<FlSpot> _clientTrafficData = []; // For client traffic (Line/Bar)

  @override
  void initState() {
    super.initState();
    _fetchDataForSelectedPeriod();
  }

  Future<void> _fetchDataForSelectedPeriod() async {
    if (!mounted) return;
    setState(() => _isLoading = true);    try {
      DateTime endDate = DateTime.now();
      DateTime startDate;

      switch (_selectedPeriod) {
        case TimePeriod.lastMonth:
          startDate = DateTime(endDate.year, endDate.month - 1, endDate.day);
          break;
        case TimePeriod.last6Months:
          startDate = DateTime(endDate.year, endDate.month - 6, endDate.day);
          break;
        case TimePeriod.lastYear:
          startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
          break;
      }

      final dateRange = DateTimeRange(start: startDate, end: endDate);

      // Fetching raw data from GymManagementFunctions
      final rawSalesDetails = await widget.functions.getSalesDataForChart(dateRange, _selectedPeriod);
      final rawCustomerData = await widget.functions.getCustomerDistributionForChart(dateRange);
      final rawProductSalesDetails = await widget.functions.getProductSalesDataForChart(dateRange, _selectedPeriod);
      final rawTrafficData = await widget.functions.getClientTrafficDataForChart(dateRange, _selectedPeriod);
      final summary = await widget.functions.getFinancialSummaryForDateRange(dateRange);

      // Processing raw data into chart-specific data structures
      final processedSalesData = _processSalesDataToFlSpot(rawSalesDetails, _selectedPeriod);
      final processedCustomerData = _processCustomerDataToPieChartData(rawCustomerData);
      final processedProductSalesData = _processProductSalesToBarData(rawProductSalesDetails, _selectedPeriod);
      final processedTrafficData = _processTrafficDataToFlSpot(rawTrafficData, _selectedPeriod);      if (!mounted) return;
      setState(() {
        _salesData = processedSalesData;
        _customerCategoryData = processedCustomerData;
        _productSalesData = processedProductSalesData;
        _clientTrafficData = processedTrafficData;

        _financialSummary = summary;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching chart data: ${e.toString()}')),
      );
    }
  }
  String _getPeriodLabel(TimePeriod period) {
    switch (period) {
      case TimePeriod.lastMonth:
        return 'Último Mes';
      case TimePeriod.last6Months:
        return 'Últimos 6 Meses';
      case TimePeriod.lastYear:
        return 'Último Año';
    }
  }

  // --- Data Processing Methods for Charts ---
  // These methods will convert raw data from GymManagementFunctions
  // into data structures suitable for FL Chart.

  List<FlSpot> _processSalesDataToFlSpot(List<dynamic> rawData, TimePeriod period) {
    // TODO: Implement actual data transformation.
    // rawData is expected to be List<Map<String, dynamic>> where each map is like:
    // {'time_group': 'YYYY-MM-DD' or 'YYYY-MM', 'total_sales': double}
    // This needs to be converted to FlSpot(x, y) where x is a numerical representation of time_group.
    print("Processing sales data: $rawData");
    List<FlSpot> spots = [];
    if (rawData.isEmpty) return spots;

    for (int i = 0; i < rawData.length; i++) {
      var entry = rawData[i] as Map<String, dynamic>;
      // Using index 'i' for x-axis. For more accurate date representation on axis,
      // 'time_group' (String) would need to be parsed to DateTime and then to double (e.g., millisecondsSinceEpoch)
      // and axis labels would need custom formatting.
      double xValue = i.toDouble();
      double yValue = (entry['total_sales'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(xValue, yValue));
    }
    print("Processed sales spots: $spots");
    return spots;
  }
  List<PieChartSectionData> _processCustomerDataToPieChartData(List<dynamic> rawData) {
    // TODO: Implement actual data transformation.
    // rawData is expected to be List<Map<String, dynamic>>:
    // {'membership_name': String, 'client_count': int}
    // Convert to PieChartSectionData.
    print("Processing customer data: $rawData");
    List<PieChartSectionData> sections = [];
    if (rawData.isEmpty) return sections;

    final List<Color> colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.pink,
      Colors.teal, Colors.cyan, Colors.amber, Colors.brown, Colors.indigo, Colors.lime,
    ];

    double totalClients = 0;
    for (var item in rawData) {
      totalClients += (item['client_count'] as num?)?.toDouble() ?? 0.0;
    }

    // Sort data by client_count descending to assign more prominent colors to larger sections
    List<dynamic> sortedData = List.from(rawData);
    sortedData.sort((a, b) => (b['client_count'] as num).compareTo(a['client_count'] as num));

    for (int i = 0; i < sortedData.length; i++) {
      var entry = sortedData[i] as Map<String, dynamic>;
      final double clientCount = (entry['client_count'] as num?)?.toDouble() ?? 0.0;
      final double percentage = totalClients > 0 ? (clientCount / totalClients) * 100 : 0;

      sections.add(PieChartSectionData(
        color: colors[i % colors.length],
        value: clientCount,
        title: '${entry['membership_name']}\n${percentage.toStringAsFixed(1)}%',
        radius: 80, // Adjust radius as needed
        titleStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: widget.darkMode ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8),
          shadows: widget.darkMode ? null : [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 2)],
        ),
        titlePositionPercentageOffset: 0.55, // Adjust to position title inside/outside
      ));
    }
    print("Processed customer sections: $sections");
    return sections;
  }

  List<BarChartGroupData> _processProductSalesToBarData(List<dynamic> rawData, TimePeriod period) {
    // TODO: Implement actual data transformation.
    // rawData is expected to be List<Map<String, dynamic>>:
    // {'time_group': 'YYYY-MM-DD' or 'YYYY-MM' (or product_name if grouped by product), 'total_product_sales': double}
    // Convert to BarChartGroupData.
    print("Processing product sales data: $rawData");
    List<BarChartGroupData> groups = [];
    if (rawData.isEmpty) return groups;

    for (int i = 0; i < rawData.length; i++) {
      var entry = rawData[i] as Map<String, dynamic>;
      double xValue = i.toDouble();
      double yValue = (entry['total_product_sales'] as num?)?.toDouble() ?? 0.0;

      groups.add(
        BarChartGroupData(
          x: xValue.toInt(),
          barRods: [
            BarChartRodData(
              toY: yValue,
              gradient: LinearGradient( // Using gradient for bars
                colors: [Theme.of(context).colorScheme.secondary.withOpacity(0.7), Theme.of(context).colorScheme.secondary],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 16, // Adjust bar width
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            ),
          ],
          // showingTooltipIndicators: [0], // Example to show tooltip for the first bar rod
        ),
      );
    }
    print("Processed product sales groups: $groups");
    return groups;
  }

  List<FlSpot> _processTrafficDataToFlSpot(List<dynamic> rawData, TimePeriod period) {
    // TODO: Implement actual data transformation.
    // rawData is expected to be List<Map<String, dynamic>>:
    // {'time_group': 'YYYY-MM-DD' or 'YYYY-MM', 'active_clients': int}
    // Convert to FlSpot(x, y).
    print("Processing client traffic data: $rawData");
    List<FlSpot> spots = [];
    if (rawData.isEmpty) return spots;

    for (int i = 0; i < rawData.length; i++) {
      var entry = rawData[i] as Map<String, dynamic>;
      double xValue = i.toDouble(); // Using index for x-axis
      double yValue = (entry['active_clients'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(xValue, yValue));
    }
    print("Processed client traffic spots: $spots");
    return spots;
  }
  @override
  Widget build(BuildContext context) {
    final textColor = widget.darkMode ? Colors.white : Colors.black;
    final screenSize = MediaQuery.of(context).size;
    final chartWidth = screenSize.width * 0.42; // 42% de ancho para cada gráfica
    final chartHeight = screenSize.height * 0.35; // 35% de altura para cada gráfica

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }    return Scaffold(
      backgroundColor: widget.darkMode ? Colors.grey[850] : Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header con título y controles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Dashboard Financiero',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: textColor),
                  onPressed: _fetchDataForSelectedPeriod,
                  tooltip: 'Actualizar',
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Selector de período
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TimePeriod.values.map((period) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(_getPeriodLabel(period), style: const TextStyle(fontSize: 12)),
                      selected: _selectedPeriod == period,
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() {
                            _selectedPeriod = period;
                            _fetchDataForSelectedPeriod();
                          });
                        }
                      },
                      selectedColor: Theme.of(context).primaryColor,
                      labelStyle: TextStyle(
                        color: _selectedPeriod == period
                            ? (widget.darkMode ? Colors.black : Colors.white)
                            : textColor,
                      ),
                      backgroundColor: widget.darkMode ? Colors.grey[700] : Colors.grey[300],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Resumen financiero compacto
            if (_financialSummary != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),                decoration: BoxDecoration(
                  color: widget.darkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.darkMode ? Colors.grey[600]! : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Productos', _financialSummary?['productSales'] ?? 0, textColor),
                    _buildSummaryItem('Membresías', _financialSummary?['membershipRevenue'] ?? 0, textColor),
                    _buildSummaryItem('Total', _financialSummary?['totalRevenue'] ?? 0, textColor),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Grid de gráficas 2x2
            Expanded(
              child: Row(
                children: [
                  // Columna izquierda
                  Expanded(
                    child: Column(
                      children: [
                        // Gráfica 1: Esquina superior izquierda - Ventas Totales
                        Expanded(
                          child: _buildChartContainer(
                            title: 'Ventas',
                            child: _buildSalesChart(chartWidth, chartHeight * 0.8),
                            textColor: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Gráfica 3: Esquina inferior izquierda - Ventas de Productos
                        Expanded(
                          child: _buildChartContainer(
                            title: 'Productos',
                            child: _buildProductSalesChart(chartWidth, chartHeight * 0.8),
                            textColor: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Columna derecha
                  Expanded(
                    child: Column(
                      children: [
                        // Gráfica 2: Esquina superior derecha - Distribución de Clientes
                        Expanded(
                          child: _buildChartContainer(
                            title: 'Clientes',
                            child: _buildCustomerChart(chartWidth, chartHeight * 0.8),
                            textColor: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Gráfica 4: Esquina inferior derecha - Tráfico de Clientes
                        Expanded(
                          child: _buildChartContainer(
                            title: 'Tráfico',
                            child: _buildClientTrafficChart(chartWidth, chartHeight * 0.8),
                            textColor: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color textColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7)),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${value.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
        ),
      ],
    );
  }

  Widget _buildChartContainer({
    required String title,
    required Widget child,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: () {
        // Funcionalidad para ampliar la gráfica (opcional)
        _showExpandedChart(title, child);
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),        decoration: BoxDecoration(
          color: widget.darkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.darkMode ? Colors.grey[600]! : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: widget.darkMode ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
  void _showExpandedChart(String title, Widget chart) {
    showDialog(
      context: context,      builder: (context) => Dialog(
        backgroundColor: widget.darkMode ? Colors.grey[850] : Colors.white,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.darkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.darkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: widget.darkMode ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: chart),
            ],
          ),        ),
      ),
    );
  }

  // Métodos para construir cada gráfica con tamaño optimizado
  Widget _buildSalesChart(double width, double height) {
    if (_salesData.isEmpty) {
      return Center(
        child: Text(
          'Sin datos',
          style: TextStyle(
            color: widget.darkMode ? Colors.white70 : Colors.black54,
            fontSize: 12,
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _salesData.map((e) => e.y).reduce(max) / 3,
          getDrawingHorizontalLine: (value) => FlLine(
            color: widget.darkMode ? Colors.grey[700]! : Colors.grey[300]!,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              interval: _salesData.map((e) => e.y).reduce(max) / 2,
              getTitlesWidget: (value, meta) => Text(
                NumberFormat.compact().format(value),
                style: TextStyle(
                  fontSize: 8,
                  color: widget.darkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: _salesData.length.toDouble() - 1,
        minY: 0,
        maxY: _salesData.map((e) => e.y).reduce(max) * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: _salesData,
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.3),
                  Theme.of(context).primaryColor.withOpacity(0.0)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => widget.darkMode ? Colors.grey[800]! : Colors.white,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                return LineTooltipItem(
                  NumberFormat.currency(symbol: '\$').format(barSpot.y),
                  TextStyle(
                    color: widget.darkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerChart(double width, double height) {
    if (_customerCategoryData.isEmpty) {
      return Center(
        child: Text(
          'Sin datos',
          style: TextStyle(
            color: widget.darkMode ? Colors.white70 : Colors.black54,
            fontSize: 12,
          ),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections: _customerCategoryData.map((section) {
          return PieChartSectionData(
            color: section.color,
            value: section.value,
            title: '${(section.value / _customerCategoryData.map((s) => s.value).reduce((a, b) => a + b) * 100).toStringAsFixed(0)}%',
            radius: 40,
            titleStyle: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        centerSpaceRadius: 20,
        sectionsSpace: 1,
      ),
    );
  }

  Widget _buildProductSalesChart(double width, double height) {
    if (_productSalesData.isEmpty) {
      return Center(
        child: Text(
          'Sin datos',
          style: TextStyle(
            color: widget.darkMode ? Colors.white70 : Colors.black54,
            fontSize: 12,
          ),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _productSalesData.map((group) => group.barRods.map((rod) => rod.toY).reduce(max)).reduce(max) * 1.2,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _productSalesData.map((group) => group.barRods.map((rod) => rod.toY).reduce(max)).reduce(max) / 3,
          getDrawingHorizontalLine: (value) => FlLine(
            color: widget.darkMode ? Colors.grey[700]! : Colors.grey[300]!,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              getTitlesWidget: (value, meta) => Text(
                NumberFormat.compact().format(value),
                style: TextStyle(
                  fontSize: 8,
                  color: widget.darkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _productSalesData.map((group) {
          return BarChartGroupData(
            x: group.x,
            barRods: group.barRods.map((rod) {
              return BarChartRodData(
                toY: rod.toY,
                color: Theme.of(context).colorScheme.secondary,
                width: 8,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2),
                  topRight: Radius.circular(2),
                ),
              );
            }).toList(),
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => widget.darkMode ? Colors.grey[800]! : Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                NumberFormat.currency(symbol: '\$').format(rod.toY),
                TextStyle(
                  color: widget.darkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildClientTrafficChart(double width, double height) {
    if (_clientTrafficData.isEmpty) {
      return Center(
        child: Text(
          'Sin datos',
          style: TextStyle(
            color: widget.darkMode ? Colors.white70 : Colors.black54,
            fontSize: 12,
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _clientTrafficData.map((e) => e.y).reduce(max) / 3,
          getDrawingHorizontalLine: (value) => FlLine(
            color: widget.darkMode ? Colors.grey[700]! : Colors.grey[300]!,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              interval: _clientTrafficData.map((e) => e.y).reduce(max) / 2,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontSize: 8,
                  color: widget.darkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: _clientTrafficData.length.toDouble() - 1,
        minY: 0,
        maxY: _clientTrafficData.map((e) => e.y).reduce(max) * 1.2,        lineBarsData: [
          LineChartBarData(
            spots: _clientTrafficData,
            isCurved: true,
            color: Colors.teal.shade600,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.teal.shade600.withOpacity(0.3),
                  Colors.teal.shade600.withOpacity(0.0)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => widget.darkMode ? Colors.grey[800]! : Colors.white,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                return LineTooltipItem(
                  '${barSpot.y.toInt()} clientes',
                  TextStyle(
                    color: widget.darkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),    );  }
}

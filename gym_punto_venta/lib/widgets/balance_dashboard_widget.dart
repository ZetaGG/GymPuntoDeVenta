import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart
import 'package:gym_punto_venta/functions/funtions.dart'; // Assuming GymManagementFunctions is here
import 'package:intl/intl.dart'; // For date formatting
import 'package:gym_punto_venta/database/database_helper.dart' show TimePeriod; // Ensure this import is present
import 'dart:math' show max; // Import max function

// Removed local TimePeriod enum definition

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
  List<dynamic> _rawSalesDetailsForTitles = []; // Store raw data for x-axis title formatting
  List<PieChartSectionData> _customerCategoryData = []; // For customer distribution (Pie)
  List<BarChartGroupData> _productSalesData = []; // For product sales (Bar)
  List<dynamic> _rawProductSalesDetailsForTitles = []; // Store raw data for product sales chart x-axis
  List<FlSpot> _clientTrafficData = []; // For client traffic (Line/Bar)
  List<dynamic> _rawClientTrafficDetailsForTitles = []; // Store raw data for client traffic chart x-axis

  // Titles for charts (dynamic based on period)
  String _salesChartTitle = '';
  String _customerChartTitle = '';
  String _productSalesChartTitle = '';
  String _clientTrafficChartTitle = '';

  @override
  void initState() {
    super.initState();
    _fetchDataForSelectedPeriod();
  }

  Future<void> _fetchDataForSelectedPeriod() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate;
      String periodString = '';

      switch (_selectedPeriod) {
        case TimePeriod.lastMonth:
          startDate = DateTime(endDate.year, endDate.month - 1, endDate.day);
          periodString = 'Último Mes';
          break;
        case TimePeriod.last6Months:
          startDate = DateTime(endDate.year, endDate.month - 6, endDate.day);
          periodString = 'Últimos 6 Meses';
          break;
        case TimePeriod.lastYear:
          startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
          periodString = 'Último Año';
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
      final processedTrafficData = _processTrafficDataToFlSpot(rawTrafficData, _selectedPeriod);

      if (!mounted) return;
      setState(() {
        _rawSalesDetailsForTitles = rawSalesDetails;
        _rawProductSalesDetailsForTitles = rawProductSalesDetails;
        _rawClientTrafficDetailsForTitles = rawTrafficData; // Store raw data for client traffic titles
        _salesData = processedSalesData;
        _customerCategoryData = processedCustomerData;
        _productSalesData = processedProductSalesData;
        _clientTrafficData = processedTrafficData;

        _financialSummary = summary;

        _salesChartTitle = 'Ventas Totales ($periodString)';
        _customerChartTitle = 'Distribución de Clientes ($periodString)';
        _productSalesChartTitle = 'Ventas de Productos ($periodString)';
        _clientTrafficChartTitle = 'Tráfico de Clientes ($periodString)';

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
      default: // Should not happen
        return '';
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

  String _getTooltipDate(int index, List<dynamic> rawData, TimePeriod period) {
    if (index >= 0 && index < rawData.length) {
      var entry = rawData[index] as Map<String, dynamic>;
      String timeGroup = entry['time_group']; // 'YYYY-MM-DD' or 'YYYY-MM'
      try {
        if (period == TimePeriod.lastMonth) { // Daily
          DateTime date = DateFormat('yyyy-MM-dd').parse(timeGroup);
          return DateFormat('dd MMM yyyy').format(date);
        } else { // Monthly
          DateTime date = DateFormat('yyyy-MM').parse(timeGroup);
          return DateFormat('MMM yyyy').format(date);
        }
      } catch (e) {
        return timeGroup; // Fallback to raw time_group string
      }
    }
    return '';
  }

  // Helper function to format bottom titles (dates) - can be enhanced
  Widget bottomTitleWidgets(double value, TitleMeta meta, List<dynamic> rawData, TimePeriod period) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    String text = '';
    int index = value.toInt();

    if (index >= 0 && index < rawData.length) {
      var entry = rawData[index] as Map<String, dynamic>;
      String timeGroup = entry['time_group']; // 'YYYY-MM-DD' or 'YYYY-MM'
      try {
        if (period == TimePeriod.lastMonth) { // Daily
          DateTime date = DateFormat('yyyy-MM-dd').parse(timeGroup);
          text = DateFormat('dd').format(date); // Show day number
        } else { // Monthly
          DateTime date = DateFormat('yyyy-MM').parse(timeGroup);
          text = DateFormat('MMM').format(date); // Show month abbreviation
        }
      } catch (e) {
        text = ''; // Fallback if parsing fails
      }
    }
    return SideTitleWidget(axisSide: meta.axisSide, space: 4, child: Text(text, style: style));
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
                'Balance Financiero', // Title can be more generic now
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: textColor),
                onPressed: _fetchDataForSelectedPeriod, // Updated to new method
                tooltip: 'Actualizar',
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Time Period Selector Chips
          Wrap(
            spacing: 8.0,
            children: TimePeriod.values.map((period) {
              return ChoiceChip(
                label: Text(_getPeriodLabel(period)),
                selected: _selectedPeriod == period,
                onSelected: (bool selected) {
                  if (selected) {
                    setState(() {
                      _selectedPeriod = period;
                      _fetchDataForSelectedPeriod(); // Refetch data for the new period
                    });
                  }
                },
                selectedColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(
                  color: _selectedPeriod == period
                      ? (widget.darkMode ? Colors.black : Colors.white) // Ensure contrast for selected chip
                      : textColor,
                ),
                backgroundColor: widget.darkMode ? Colors.grey[700] : Colors.grey[300],
                checkmarkColor: widget.darkMode ? Colors.black : Colors.white,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Existing financial summary (can be kept or integrated into charts)
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
          const SizedBox(height: 30),

          // --- Sales Chart ---
          Text(
            _salesChartTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 1.7, // Adjust as needed
            child: Card(
              elevation: widget.darkMode ? 1 : 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              color: widget.darkMode ? Colors.grey[850] : Colors.white,
              child: Padding(
                padding: const EdgeInsets.only(right: 20, top: 20, bottom: 10, left: 10),
                child: _salesData.isEmpty
                    ? Center(child: Text('No hay datos de ventas para mostrar.', style: TextStyle(color: textColor.withOpacity(0.7))))
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: _salesData.map((e) => e.y).reduce(max) / 5 > 0 ? _salesData.map((e) => e.y).reduce(max) / 5 : 1, // Adjust interval
                            verticalInterval: 1, // Adjust interval
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: widget.darkMode ? Colors.grey[700] : Colors.grey[300],
                                strokeWidth: 1,
                              );
                            },
                            getDrawingVerticalLine: (value) {
                              return FlLine(
                                color: widget.darkMode ? Colors.grey[700] : Colors.grey[300],
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 22,
                                interval: 1, // Show label for each spot
                                getTitlesWidget: (value, meta) => bottomTitleWidgets(value, meta, _rawSalesDetailsForTitles, _selectedPeriod),
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40, // Adjust space for labels
                                getTitlesWidget: (value, meta) {
                                  return Text(NumberFormat.compact().format(value), style: TextStyle(fontSize: 10, color: textColor), textAlign: TextAlign.left);
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: widget.darkMode ? Colors.grey[700]! : Colors.grey[400]!),
                          ),
                          minX: 0,
                          maxX: _salesData.length.toDouble() -1, // Based on index
                          minY: 0,
                          // maxY: Calculate max Y based on data for better scaling
                          maxY: _salesData.isEmpty ? 10 : _salesData.map((e) => e.y).reduce(max) * 1.2, // Add some padding
                          lineBarsData: [
                            LineChartBarData(
                              spots: _salesData,
                              isCurved: true,
                              gradient: LinearGradient(
                                colors: [Theme.of(context).primaryColor.withOpacity(0.5), Theme.of(context).primaryColor],
                              ),
                              barWidth: 3,
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
                          ],                          lineTouchData: LineTouchData( // Basic tooltip
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (touchedSpot) => widget.darkMode ? Colors.blueGrey : Colors.white,
                              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                                return touchedBarSpots.map((barSpot) {
                                  final flSpot = barSpot;
                                  return LineTooltipItem(
                                    '${NumberFormat.currency(symbol: '\$').format(flSpot.y)}\n',
                                    TextStyle(color: widget.darkMode ? Colors.white : Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                                    children: [
                                      TextSpan(
                                        text: _getTooltipDate(flSpot.x.toInt(), _rawSalesDetailsForTitles, _selectedPeriod),
                                        style: TextStyle(
                                          color: widget.darkMode ? Colors.grey[400] : Colors.grey[700],
                                          fontWeight: FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ]
                                  );
                                }).toList();
                              }
                            )
                          ),
                          extraLinesData: ExtraLinesData(horizontalLines: [ // Example: average line
                            // if (_salesData.isNotEmpty)
                            //   HorizontalLine(
                            //     y: _salesData.map((e) => e.y).reduce((a, b) => a + b) / _salesData.length,
                            //     color: Colors.red.withOpacity(0.8),
                            //     strokeWidth: 2,
                            //     dashArray: [5, 5],
                            //     label: HorizontalLineLabel(
                            //       show: true,
                            //       labelResolver: (line) => 'Avg: ${NumberFormat.compactCurrency(symbol: '\$').format(line.y)}',
                            //       style: TextStyle(color: Colors.white, backgroundColor: Colors.red.withOpacity(0.8)),
                            //     )
                            //   ),
                          ]),
                        ),
                        duration: const Duration(milliseconds: 250), // Animation duration
                      ),
              ),
            ),
          ),

          const SizedBox(height: 30),
          Text(
            _customerChartTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 1.5, // Adjust as needed, Pie charts can be more square
            child: Card(
              elevation: widget.darkMode ? 1 : 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              color: widget.darkMode ? Colors.grey[850] : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _customerCategoryData.isEmpty
                    ? Center(child: Text('No hay datos de clientes para mostrar.', style: TextStyle(color: textColor.withOpacity(0.7))))
                    : PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              // TODO: Handle touch events for interactivity if needed
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2, // Space between sections
                          centerSpaceRadius: 40, // Radius of the center hole
                          sections: _customerCategoryData,
                          startDegreeOffset: -90, // Start sections from the top
                        ),
                        swapAnimationDuration: const Duration(milliseconds: 250), // Optional
                        swapAnimationCurve: Curves.easeInOut, // Optional
                      ),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Placeholder for Product Sales Chart
          Text(
            _productSalesChartTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 1.7, // Adjust as needed
            child: Card(
              elevation: widget.darkMode ? 1 : 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              color: widget.darkMode ? Colors.grey[850] : Colors.white,
              child: Padding(
                padding: const EdgeInsets.only(right: 20, top: 20, bottom: 10, left: 10),
                child: _productSalesData.isEmpty
                    ? Center(child: Text('No hay datos de ventas de productos.', style: TextStyle(color: textColor.withOpacity(0.7))))
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _productSalesData.isEmpty ? 10 : _productSalesData.map((group) => group.barRods.map((rod) => rod.toY).reduce(max)).reduce(max) * 1.2, // Calculate max Y
                          minY: 0,                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => widget.darkMode ? Colors.blueGrey : Colors.white,                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                // Assuming bottomTitleWidgets can be adapted or a similar one created for product chart
                                // For now, just show groupIndex or find a way to get 'time_group'
                                // weekDay = 'Day ${group.x.toInt() + 1}';
                                return BarTooltipItem(
                                  '${NumberFormat.currency(symbol: '\$').format(rod.toY)}\n',
                                  TextStyle(color: widget.darkMode ? Colors.white : Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold),
                                  // children: <TextSpan>[
                                  //   TextSpan(
                                  //     text: weekDay, // TODO: Get actual date string
                                  //     style: TextStyle(
                                  //       color: Colors.grey[600],
                                  //       fontSize: 14,
                                  //       fontWeight: FontWeight.w500,
                                  //     ),
                                  //   ),
                                  // ],
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 22,
                                interval: 1,
                                getTitlesWidget: (value, meta) => bottomTitleWidgets(value, meta, _rawProductSalesDetailsForTitles, _selectedPeriod),
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                return Text(NumberFormat.compact().format(value), style: TextStyle(fontSize: 10, color: textColor), textAlign: TextAlign.left);
                                },
                              ),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false, // Cleaner look for bar chart
                            horizontalInterval: _productSalesData.isEmpty ? 1 : _productSalesData.map((group) => group.barRods.map((rod) => rod.toY).reduce(max)).reduce(max) / 5 > 0
                                                ? _productSalesData.map((group) => group.barRods.map((rod) => rod.toY).reduce(max)).reduce(max) / 5
                                                : 1,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: widget.darkMode ? Colors.grey[700] : Colors.grey[300],
                                strokeWidth: 1,
                              );
                            },
                          ),
                          borderData: FlBorderData(
                             show: true,
                             border: Border.all(color: widget.darkMode ? Colors.grey[700]! : Colors.grey[400]!),
                          ),
                          barGroups: _productSalesData,
                        ),
                        swapAnimationDuration: const Duration(milliseconds: 250),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Placeholder for Client Traffic Chart
          Text(
            _clientTrafficChartTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 1.7, // Adjust as needed
            child: Card(
              elevation: widget.darkMode ? 1 : 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              color: widget.darkMode ? Colors.grey[850] : Colors.white,
              child: Padding(
                padding: const EdgeInsets.only(right: 20, top: 20, bottom: 10, left: 10),
                child: _clientTrafficData.isEmpty
                    ? Center(child: Text('No hay datos de tráfico de clientes.', style: TextStyle(color: textColor.withOpacity(0.7))))
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: _clientTrafficData.map((e) => e.y).reduce(max) / 5 > 0 ? _clientTrafficData.map((e) => e.y).reduce(max) / 5 : 1,
                            verticalInterval: 1,
                            getDrawingHorizontalLine: (value) => FlLine(color: widget.darkMode ? Colors.grey[700] : Colors.grey[300], strokeWidth: 1),
                            getDrawingVerticalLine: (value) => FlLine(color: widget.darkMode ? Colors.grey[700] : Colors.grey[300], strokeWidth: 1),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 22,
                                interval: 1,
                                getTitlesWidget: (value, meta) => bottomTitleWidgets(value, meta, _rawClientTrafficDetailsForTitles, _selectedPeriod),
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30, // Adjusted for potentially smaller numbers
                                getTitlesWidget: (value, meta) {
                                  return Text(value.toInt().toString(), style: TextStyle(fontSize: 10, color: textColor), textAlign: TextAlign.left);
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: true, border: Border.all(color: widget.darkMode ? Colors.grey[700]! : Colors.grey[400]!)),
                          minX: 0,
                          maxX: _clientTrafficData.length.toDouble() -1,
                          minY: 0,
                          maxY: _clientTrafficData.isEmpty ? 10 : _clientTrafficData.map((e) => e.y).reduce(max) * 1.2,
                          lineBarsData: [
                            LineChartBarData(
                              spots: _clientTrafficData,
                              isCurved: true,
                              gradient: LinearGradient(colors: [Colors.green.shade700.withOpacity(0.5), Colors.green.shade700]),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [Colors.green.shade700.withOpacity(0.3), Colors.green.shade700.withOpacity(0.0)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (touchedSpot) => widget.darkMode ? Colors.blueGrey : Colors.white,
                              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                                return touchedBarSpots.map((barSpot) {
                                  return LineTooltipItem(
                                    '${barSpot.y.toInt()} clientes\n', // Assuming y is count
                                    TextStyle(color: widget.darkMode ? Colors.white : Colors.green.shade900, fontWeight: FontWeight.bold),
                                  );
                                }).toList();
                              }
                            )
                          ),
                        ),
                        duration: const Duration(milliseconds: 250),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
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

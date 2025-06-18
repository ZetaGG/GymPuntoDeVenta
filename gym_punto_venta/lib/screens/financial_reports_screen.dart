import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../functions/funtions.dart';

class FinancialReportsScreen extends StatefulWidget {
  final GymManagementFunctions functions;
  const FinancialReportsScreen({Key? key, required this.functions}) : super(key: key);

  @override
  _FinancialReportsScreenState createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _financialOverview = {};
  DateTimeRange? _selectedDateRange;

  final NumberFormat _currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _selectedDateRange = DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now());
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _financialOverview = await widget.functions.getFinancialOverview(dateRange: _selectedDateRange);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime.now().add(const Duration(days: 365)), // Allow future dates up to a year for forecasting if needed
        initialDateRange: _selectedDateRange ?? DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now()),
         builder: (context, child) { // Theme the date picker
            return Theme(
            data: widget.functions.darkMode ? ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(
                    primary: Colors.teal,
                    onPrimary: Colors.white,
                    surface: Colors.grey[800]!,
                    onSurface: Colors.white,
                ),
                dialogBackgroundColor:Colors.grey[850],
                buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            ) : ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                    primary: Colors.blue,
                ),
            ),
            child: child!,
            );
        }
    );
    if (picked != null && picked != _selectedDateRange) {
        setState(() {
            _selectedDateRange = picked;
        });
        _loadFinancialData();
    }
  }

  Widget _buildSummaryCard(String title, double amount, Color color, {bool isNetProfit = false}) {
    final bool isNegative = amount < 0;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      color: widget.functions.darkMode ? colorScheme.surfaceContainerHighest : colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text(
              isNetProfit && isNegative
                ? "-${_currencyFormatter.format(amount.abs())}"
                : _currencyFormatter.format(amount),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isNetProfit ? (isNegative ? Colors.orange.shade400 : Colors.blue.shade400) : color
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context) {
    final totalIncome = _financialOverview['totalIncome'] as double? ?? 0.0;
    final totalExpenses = _financialOverview['totalExpenses'] as double? ?? 0.0;
    final bool isDarkMode = widget.functions.darkMode;
    final colorScheme = Theme.of(context).colorScheme;

    if (totalIncome == 0.0 && totalExpenses == 0.0 &&
        (_financialOverview['allIncomeTransactions']?.isEmpty ?? true) &&
        (_financialOverview['allExpenseTransactions']?.isEmpty ?? true) ) {
          return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("No financial data for the selected period.", style: TextStyle(color: colorScheme.onSurfaceVariant))));
    }
    // The second 'if' block is redundant because the first 'if' block already covers the case where all data is empty for the period.
    // If the first condition is false, it means there's *some* data (even if totals are zero but transactions exist, or vice-versa),
    // so the chart should attempt to render.

    return AspectRatio(
        aspectRatio: 1.6,
        child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            color: isDarkMode ? colorScheme.surfaceContainerHighest.withOpacity(0.8) : colorScheme.surfaceContainerHigh,
            child: Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 12, left: 8, right: 20),
                child: BarChart(
                    BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (totalIncome > totalExpenses ? totalIncome : totalExpenses) * 1.2 + 1,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: _bottomTitles)),
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 60, getTitlesWidget: _leftTitles)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                            BarChartGroupData(x: 0, barRods: [
                                BarChartRodData(toY: totalIncome, color: Colors.greenAccent.shade400, width: 25, borderRadius: BorderRadius.circular(4))
                            ]),
                            BarChartGroupData(x: 1, barRods: [
                                BarChartRodData(toY: totalExpenses, color: Colors.redAccent.shade400, width: 25, borderRadius: BorderRadius.circular(4))
                            ]),
                        ],
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: ((totalIncome > totalExpenses ? totalIncome : totalExpenses) * 1.2 + 1) > 0
                                            ? ((totalIncome > totalExpenses ? totalIncome : totalExpenses) * 1.2 + 1) / 5
                                            : 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(color: colorScheme.onSurfaceVariant.withOpacity(0.1), strokeWidth: 0.8);
                          }
                        ),
                    ),
                ),
            ),
        ),
    );
  }

  Widget _bottomTitles(double value, TitleMeta meta) {
      final style = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 12);
      String text;
      switch (value.toInt()) {
          case 0: text = 'Income'; break;
          case 1: text = 'Expenses'; break;
          default: text = ''; break;
      }
      return SideTitleWidget(axisSide: meta.axisSide, space: 4, child: Text(text, style: style));
  }

  Widget _leftTitles(double value, TitleMeta meta) {
    final style = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10);
    // Show labels only at reasonable intervals
    if (value == 0 || value == meta.max || (value % (meta.max / 5).clamp(1.0, meta.max) == 0 && meta.max > 0) ) {
         return SideTitleWidget(axisSide: meta.axisSide, space: 4, child: Text(_currencyFormatter.format(value), style: style)); // Removed .replaceAll(".00", "")
    }
    return const SizedBox.shrink();
  }

  Widget _buildTransactionList(String title, List<Map<String, dynamic>> transactions) {
    final bool isDarkMode = widget.functions.darkMode;
    final colorScheme = Theme.of(context).colorScheme;

    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: Text("No $title transactions for the selected period.", style: TextStyle(color: colorScheme.onSurfaceVariant)))
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final item = transactions[index];
            final date = DateFormat('yyyy-MM-dd').format(DateTime.parse(item['date']));
            final amount = _currencyFormatter.format(item['amount']);
            return Card(
              elevation: 1,
              color: isDarkMode ? colorScheme.surfaceContainerHighest : colorScheme.surface,
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                title: Text(item['description'] ?? 'No description', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.onSurface)),
                subtitle: Text("$date - ${item['type'] ?? item['category'] ?? 'N/A'}", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                trailing: Text(amount, style: TextStyle(color: title.contains("Income") ? Colors.green.shade400 : Colors.red.shade400, fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize)),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = widget.functions.darkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Financial Reports'),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFinancialData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                              Expanded(
                                child: Text(
                                    _selectedDateRange == null
                                        ? "Displaying: All Time"
                                        : "Range: ${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}",
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: isDarkMode ? Colors.white70 : Colors.black87),
                                ),
                              ),
                              TextButton.icon(
                                  icon: Icon(Icons.calendar_today, color: isDarkMode ? Colors.tealAccent[400] : Colors.blue),
                                  label: Text("Change Range", style: TextStyle(color: isDarkMode ? Colors.tealAccent[400] : Colors.blue)),
                                  onPressed: () => _pickDateRange(context),
                              ),
                          ],
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryCard("Total Income", _financialOverview['totalIncome'] as double? ?? 0.0, Colors.green.shade400),
                      const SizedBox(height: 12),
                      _buildSummaryCard("Total Expenses", _financialOverview['totalExpenses'] as double? ?? 0.0, Colors.red.shade400),
                      const SizedBox(height: 12),
                      _buildSummaryCard("Net Profit", _financialOverview['netProfit'] as double? ?? 0.0,
                                         (_financialOverview['netProfit'] as double? ?? 0.0) >= 0 ? Colors.blue.shade400 : Colors.orange.shade400, isNetProfit: true),
                      const SizedBox(height: 24),
                      Text("Income vs Expenses Chart", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: isDarkMode ? Colors.white : Colors.black)),
                      const SizedBox(height: 8),
                      _buildBarChart(context),
                      const SizedBox(height: 24),
                      _buildTransactionList("Income Transactions", _financialOverview['allIncomeTransactions']?.cast<Map<String, dynamic>>() ?? []),
                      const SizedBox(height: 24),
                      _buildTransactionList("Expense Transactions", _financialOverview['allExpenseTransactions']?.cast<Map<String, dynamic>>() ?? []),
                  ],
                ),
              ),
            ),
    );
  }
}

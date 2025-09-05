import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Variáveis de estado
  bool _isLoading = true;
  String _activePeriod = '30d'; // Período ativo por defeito
  List<dynamic> _historyData = [];
  double _kwhCost = 0.0;
  String? _errorMessage;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        _apiService.getConsumptionHistory(period: _activePeriod),
        _apiService.getResidenceData(),
      ]);

      final history = results[0] as List<dynamic>;
      final residence = results[1] as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _historyData = history;
          _kwhCost = double.tryParse(residence['kwh_cost'].toString()) ?? 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Não foi possível carregar o histórico.';
          _isLoading = false;
        });
      }
      print('Erro ao buscar histórico: $e');
    }
  }

  void _changePeriod(String newPeriod) {
    setState(() {
      _activePeriod = newPeriod;
      _fetchHistory();
    });
  }

  // Widgets de construção da UI
  Widget _buildPeriodSelector() {
    final theme = Theme.of(context);
    final periods = {
      '7d': '7 Dias',
      '30d': '30 Dias',
      'this_month': 'Este Mês',
    };
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: periods.entries.map((entry) {
          final isSelected = _activePeriod == entry.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => _changePeriod(entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? theme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final double totalKwh = _historyData.fold(
      0.0,
      (sum, item) => sum + (double.tryParse(item['kwh'].toString()) ?? 0.0),
    );
    final double totalCost = totalKwh * _kwhCost;
    final double dailyAverage = _historyData.isNotEmpty
        ? totalKwh / _historyData.length
        : 0.0;

    return Column(
      children: [
        Row(
          children: [
            _buildSummaryCard(
              'Consumo Total',
              '${totalKwh.toStringAsFixed(2)} kWh',
            ),
            const SizedBox(width: 15),
            _buildSummaryCard(
              'Custo Total',
              'R\$ ${totalCost.toStringAsFixed(2)}',
            ),
          ],
        ),
        const SizedBox(height: 15),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              children: [
                Text(
                  'Média Diária',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${dailyAverage.toStringAsFixed(2)} kWh',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    final theme = Theme.of(context);
    final spots = _historyData.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        double.tryParse(entry.value['kwh'].toString()) ?? 0.0,
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Consumo Diário (kWh)",
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: theme.dividerColor, strokeWidth: 0.5),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 5, // Define o intervalo para 5
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _historyData.length > 7
                            ? (_historyData.length / 5).roundToDouble()
                            : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _historyData.length) {
                            final date = DateTime.parse(
                              _historyData[index]['date'],
                            );
                            return Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                DateFormat('dd/MM').format(date),
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: theme.primaryColor,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 16,
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Histórico',
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 20),
                    _buildPeriodSelector(),
                    const SizedBox(height: 20),
                    _buildSummaryCards(),
                    const SizedBox(height: 20),
                    if (_historyData.isNotEmpty) _buildLineChart(),
                  ],
                ),
              ),
      ),
    );
  }
}

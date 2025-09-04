import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String _userName = '';
  String _currentMonthConsumption = '0.00';
  String _estimatedCost = '0.00';
  String? _errorMessage;
  List<dynamic> _historyData = [];
  bool _isGoalMet = true;
  String _monthlyGoal = '0';
  Map<String, dynamic> _randomTip = {};
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    // ... (lógica de fetch de dados, sem alterações)
    try {
      final results = await Future.wait([
        _apiService.getUserData(),
        _apiService.getConsumptionSummary(),
        _apiService.getResidenceData(),
        _apiService.getConsumptionHistory(period: '7d'),
        _apiService.getRandomTip(),
      ]);
      final userData = results[0] as Map<String, dynamic>;
      final summaryData = results[1] as Map<String, dynamic>;
      final residenceData = results[2] as Map<String, dynamic>;
      final historyData = results[3] as List<dynamic>;
      final tipData = results[4] as Map<String, dynamic>;
      final double kwh =
          double.tryParse(summaryData['current_month_kwh'].toString()) ?? 0.0;
      final double kwhCost =
          double.tryParse(residenceData['kwh_cost'].toString()) ?? 0.0;
      final double monthlyGoal =
          double.tryParse(residenceData['monthly_goal_kwh'].toString()) ?? 0.0;
      final cost = kwh * kwhCost;
      if (mounted) {
        setState(() {
          _userName = userData['name']?.split(' ')[0] ?? 'Usuário';
          _currentMonthConsumption = kwh.toStringAsFixed(2);
          _estimatedCost = cost.toStringAsFixed(2);
          _monthlyGoal = monthlyGoal.toStringAsFixed(0);
          _isGoalMet = kwh <= monthlyGoal;
          _historyData = historyData;
          _randomTip = tipData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Não foi possível carregar os dados.';
          _isLoading = false;
        });
      }
      print('Erro ao buscar dados do dashboard: $e');
    }
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

  Widget _buildBarChart() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Consumo dos últimos 7 Dias",
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: _historyData.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY:
                              double.tryParse(entry.value['kwh'].toString()) ??
                              0.0,
                          color: theme.colorScheme.primary,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                          BarTooltipItem(
                            '${rod.toY.toStringAsFixed(1)} kWh',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
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
                        getTitlesWidget: (double value, TitleMeta meta) {
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
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: theme.dividerColor, strokeWidth: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalMessageCard() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _isGoalMet ? AppTheme.successColor : theme.colorScheme.error,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _isGoalMet ? Icons.lightbulb_outline : Icons.warning,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isGoalMet
                  ? 'Dentro da meta de $_monthlyGoal kWh!'
                  : 'Consumo acima da meta!',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard() {
    if (_randomTip.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _randomTip['title'] ?? 'Dica do Dia',
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              _randomTip['description'] ?? '',
              style: theme.textTheme.bodyMedium,
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
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, $_userName!',
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildSummaryCard(
                          'Consumo Mês',
                          '$_currentMonthConsumption kWh',
                        ),
                        const SizedBox(width: 15),
                        _buildSummaryCard(
                          'Custo Estimado',
                          'R\$ $_estimatedCost',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildBarChart(),
                    const SizedBox(height: 20),
                    _buildGoalMessageCard(),
                    const SizedBox(height: 20),
                    _buildTipCard(),
                  ],
                ),
              ),
      ),
    );
  }
}

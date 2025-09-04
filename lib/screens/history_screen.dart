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

  // Função para buscar os dados com base no período selecionado
  Future<void> _fetchHistory() async {
    // Garante que o estado de loading é ativado no início
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

  // Função para mudar o período e recarregar os dados
  void _changePeriod(String newPeriod) {
    setState(() {
      _activePeriod = newPeriod;
      _fetchHistory(); // Busca os dados novamente com o novo período
    });
  }

  // Widgets de construção da UI
  Widget _buildPeriodSelector() {
    // ... (código do seletor de período)
    final periods = {
      '7d': '7 Dias',
      '30d': '30 Dias',
      'this_month': 'Este Mês',
    };
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDEE2E6)),
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
                  color: isSelected
                      ? const Color(0xFF3B82F6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF212529),
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
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFDEE2E6)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              children: [
                const Text(
                  'Média Diária',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
                ),
                const SizedBox(height: 8),
                Text(
                  '${dailyAverage.toStringAsFixed(2)} kWh',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFDEE2E6)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212529),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    // Cria os pontos (FlSpot) para o gráfico a partir dos dados do histórico
    final spots = _historyData.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        double.tryParse(entry.value['kwh'].toString()) ?? 0.0,
      );
    }).toList();

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFDEE2E6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Consumo Diário (kWh)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _historyData.length > 7
                            ? (_historyData.length / 5).roundToDouble()
                            : 1, // Ajusta o intervalo dos rótulos
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
                                style: const TextStyle(
                                  color: Color(0xFF6C757D),
                                  fontSize: 12,
                                ),
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
                      color: const Color(0xFF3B82F6),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
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
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Histórico',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
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

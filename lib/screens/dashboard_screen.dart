import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // Pacote para formatação de datas

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Variáveis de estado
  bool _isLoading = true;
  String _userName = '';
  String _currentMonthConsumption = '0.00';
  String _estimatedCost = '0.00';
  String? _errorMessage;

  // Variáveis de estado para os novos componentes
  List<dynamic> _historyData = []; // Armazena os dados brutos do histórico
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

      // Processamento dos dados
      final double kwh =
          double.tryParse(summaryData['current_month_kwh'].toString()) ?? 0.0;
      final double kwhCost =
          double.tryParse(residenceData['kwh_cost'].toString()) ?? 0.0;
      final double monthlyGoal =
          double.tryParse(residenceData['monthly_goal_kwh'].toString()) ?? 0.0;
      final cost = kwh * kwhCost;

      // Atualiza o estado com todos os dados
      if (mounted) {
        setState(() {
          _userName = userData['name']?.split(' ')[0] ?? 'Usuário';
          _currentMonthConsumption = kwh.toStringAsFixed(2);
          _estimatedCost = cost.toStringAsFixed(2);
          _monthlyGoal = monthlyGoal.toStringAsFixed(0);
          _isGoalMet = kwh <= monthlyGoal;
          _historyData = historyData; // Armazena os dados para o gráfico
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

  // Widgets de construção da UI
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

  // GRÁFICO ATUALIZADO
  Widget _buildBarChart() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFDEE2E6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Consumo dos últimos 7 Dias",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  // Gera os dados das barras a partir do nosso estado _historyData
                  barGroups: _historyData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: double.tryParse(data['kwh'].toString()) ?? 0.0,
                          color: const Color(0xFF3B82F6),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  // Configuração do tooltip que aparece ao tocar
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipColor: Colors.blueGrey, // <-- CORREÇÃO AQUI
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toStringAsFixed(1)} kWh',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  // Configuração dos títulos (eixos X e Y)
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    // Títulos do eixo esquerdo (Y)
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    // Títulos do eixo inferior (X)
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          // Pega a data correspondente e formata para "dd/MM"
                          final index = value.toInt();
                          if (index >= 0 && index < _historyData.length) {
                            final date = DateTime.parse(
                              _historyData[index]['date'],
                            );
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 4,
                              child: Text(DateFormat('dd/MM').format(date)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  // Adiciona as linhas de grade horizontais
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false, // Sem linhas verticais
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
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _isGoalMet ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
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

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFDEE2E6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _randomTip['title'] ?? 'Dica do Dia',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              _randomTip['description'] ?? '',
              style: const TextStyle(color: Color(0xFF6C757D)),
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
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
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
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212529),
                      ),
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

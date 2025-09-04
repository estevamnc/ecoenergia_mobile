import 'package:flutter/material.dart';
import '../services/api_service.dart';

// 1. Transformado em StatefulWidget para poder buscar dados e gerenciar o estado de loading.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 2. Variáveis de estado
  bool _isLoading = true; // Começa carregando
  String _userName = '';
  String _currentMonthConsumption = '0.00';
  String _estimatedCost = '0.00';
  String? _errorMessage;

  // Instância do nosso serviço de API.
  final ApiService _apiService = ApiService();

  // 3. initState() é chamado uma vez quando o widget é criado.
  // É o lugar perfeito para iniciar a busca de dados.
  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // 4. Função para buscar todos os dados necessários para o dashboard.
  Future<void> _fetchDashboardData() async {
    try {
      // Busca os dados em paralelo para ser mais rápido.
      final results = await Future.wait([
        _apiService.getUserData(),
        _apiService.getConsumptionSummary(),
        _apiService.getResidenceData(),
      ]);

      final userData = results[0];
      final summaryData = results[1];
      final residenceData = results[2];

      // CORREÇÃO: Converte os valores da API de forma segura,
      // pois eles podem vir como String.
      final double kwh =
          double.tryParse(summaryData['current_month_kwh'].toString()) ?? 0.0;
      final double kwhCost =
          double.tryParse(residenceData['kwh_cost'].toString()) ?? 0.0;
      final cost = kwh * kwhCost;

      // 5. Atualiza o estado com os dados recebidos.
      // setState() notifica o Flutter que a tela precisa ser redesenhada.
      if (mounted) {
        setState(() {
          _userName = userData['name']?.split(' ')[0] ?? 'Usuário';
          _currentMonthConsumption = kwh.toStringAsFixed(2);
          _estimatedCost = cost.toStringAsFixed(2);
          _isLoading = false; // Desativa o loading
        });
      }
    } catch (e) {
      // Em caso de erro, atualiza o estado com uma mensagem.
      if (mounted) {
        setState(() {
          _errorMessage = 'Não foi possível carregar os dados.';
          _isLoading = false;
        });
      }
      print('Erro ao buscar dados do dashboard: $e');
    }
  }

  // Widget para os cartões de resumo.
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6C757D), // Cinza secundário
                ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 6. O corpo da tela muda dependendo do estado.
      body: SafeArea(
        child: _isLoading
            // Se estiver carregando, mostra um indicador de progresso.
            ? const Center(child: CircularProgressIndicator())
            // Se houver um erro, mostra a mensagem.
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
            // Se tudo estiver certo, constrói a tela principal.
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
                    // TODO: Adicionar o gráfico e os outros cards aqui.
                  ],
                ),
              ),
      ),
    );
  }
}

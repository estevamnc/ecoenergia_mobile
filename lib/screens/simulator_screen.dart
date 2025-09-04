import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

// Classe auxiliar para guardar os dados de entrada da simulação
class SimulationInput {
  final TextEditingController hoursController;
  final TextEditingController daysController;

  SimulationInput()
    : hoursController = TextEditingController(text: '1'),
      daysController = TextEditingController(text: '7');

  void dispose() {
    hoursController.dispose();
    daysController.dispose();
  }
}

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  // Variáveis de estado
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _allAppliances = [];
  double _kwhCost = 0.0;

  // Mapa para guardar os inputs dos aparelhos selecionados
  // A chave é o ID do aparelho (int)
  final Map<int, SimulationInput> _simulationInputs = {};

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchSimulatorData();
  }

  // Limpa os controladores de texto da memória
  @override
  void dispose() {
    for (var input in _simulationInputs.values) {
      input.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchSimulatorData() async {
    try {
      final results = await Future.wait([
        _apiService.getAppliances(),
        _apiService.getResidenceData(),
      ]);

      final appliances = results[0] as List<dynamic>;
      final residence = results[1] as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _allAppliances = appliances;
          _kwhCost = double.tryParse(residence['kwh_cost'].toString()) ?? 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Não foi possível carregar os dados do simulador.';
          _isLoading = false;
        });
      }
    }
  }

  // Calcula os resultados da simulação
  Map<String, double> _calculateSimulation() {
    double totalKwhPerMonth = 0.0;

    _simulationInputs.forEach((applianceId, input) {
      final appliance = _allAppliances.firstWhere(
        (a) => a['id'] == applianceId,
      );
      final hours = int.tryParse(input.hoursController.text) ?? 0;
      final days = int.tryParse(input.daysController.text) ?? 0;
      final power = (appliance['power_watts'] as num).toDouble();

      if (power > 0) {
        final kwhPerDay = (power * hours) / 1000;
        final kwhPerMonth =
            (kwhPerDay * days * 4.345); // Média de semanas no mês
        totalKwhPerMonth += kwhPerMonth;
      }
    });

    return {
      'monthlyKwh': totalKwhPerMonth,
      'monthlyCost': totalKwhPerMonth * _kwhCost,
    };
  }

  // Lida com a seleção/desseleção de um aparelho
  void _handleSelectionChange(int applianceId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _simulationInputs[applianceId] = SimulationInput();
      } else {
        _simulationInputs[applianceId]?.dispose();
        _simulationInputs.remove(applianceId);
      }
    });
  }

  // Widgets de construção da UI
  Widget _buildResultCard() {
    final results = _calculateSimulation();
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
          children: [
            const Text(
              "Estimativa Mensal",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              "Consumo: ${results['monthlyKwh']!.toStringAsFixed(2)} kWh",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Custo: R\$ ${results['monthlyCost']!.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplianceList() {
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
              "Selecione os Aparelhos e o Uso",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            // ListView para os aparelhos
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _allAppliances.length,
              itemBuilder: (context, index) {
                final appliance = _allAppliances[index];
                final applianceId = appliance['id'] as int;
                final isSelected = _simulationInputs.containsKey(applianceId);

                return Column(
                  children: [
                    CheckboxListTile(
                      title: Text(appliance['name']),
                      subtitle: Text('${appliance['power_watts']} W'),
                      value: isSelected,
                      onChanged: (bool? value) {
                        _handleSelectionChange(applianceId, value ?? false);
                      },
                      activeColor: const Color(0xFF3B82F6),
                    ),
                    // Mostra os campos de input se o aparelho estiver selecionado
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildUsageInput(
                              _simulationInputs[applianceId]!.hoursController,
                              "h/dia",
                            ),
                            _buildUsageInput(
                              _simulationInputs[applianceId]!.daysController,
                              "dias/sem",
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageInput(TextEditingController controller, String label) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (_) => setState(() {}), // Recalcula a cada mudança
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
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
                      'Simulador',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildResultCard(),
                    const SizedBox(height: 20),
                    _buildApplianceList(),
                  ],
                ),
              ),
      ),
    );
  }
}

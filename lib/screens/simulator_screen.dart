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

  final Map<int, SimulationInput> _simulationInputs = {};

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchSimulatorData();
  }

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
        final kwhPerMonth = (kwhPerDay * days * 4.345);
        totalKwhPerMonth += kwhPerMonth;
      }
    });

    return {
      'monthlyKwh': totalKwhPerMonth,
      'monthlyCost': totalKwhPerMonth * _kwhCost,
    };
  }

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
    final theme = Theme.of(context);
    final results = _calculateSimulation();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              "Estimativa Mensal",
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "Consumo: ${results['monthlyKwh']!.toStringAsFixed(2)} kWh",
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              "Custo: R\$ ${results['monthlyCost']!.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplianceList() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Selecione os Aparelhos e o Uso",
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 10),
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
                      subtitle: Text(
                        '${appliance['power_watts']} W',
                        style: theme.textTheme.bodyMedium,
                      ),
                      value: isSelected,
                      onChanged: (bool? value) {
                        _handleSelectionChange(applianceId, value ?? false);
                      },
                      activeColor: theme.primaryColor,
                    ),
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
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              fillColor: theme.scaffoldBackgroundColor,
              filled: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
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
                      'Simulador',
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 28),
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

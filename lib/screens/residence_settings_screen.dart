import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ResidenceSettingsScreen extends StatefulWidget {
  const ResidenceSettingsScreen({super.key});

  @override
  State<ResidenceSettingsScreen> createState() =>
      _ResidenceSettingsScreenState();
}

class _ResidenceSettingsScreenState extends State<ResidenceSettingsScreen> {
  final _apiService = ApiService();
  final _controllers = {
    'city': TextEditingController(),
    'state': TextEditingController(),
    'residents': TextEditingController(),
    'kwh_cost': TextEditingController(),
    'monthly_goal_kwh': TextEditingController(),
  };

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadResidenceData();
  }

  Future<void> _loadResidenceData() async {
    try {
      final data = await _apiService.getResidenceData();
      if (mounted) {
        setState(() {
          _controllers['city']?.text = data['city'] ?? '';
          _controllers['state']?.text = data['state'] ?? '';
          _controllers['residents']?.text = (data['residents'] ?? '')
              .toString();
          _controllers['kwh_cost']?.text = (data['kwh_cost'] ?? '').toString();
          _controllers['monthly_goal_kwh']?.text =
              (data['monthly_goal_kwh'] ?? '').toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      // Tratar erro
    }
  }

  Future<void> _saveResidence() async {
    if (mounted) setState(() => _isSaving = true);
    try {
      // Prepara os dados para enviar, convertendo para os tipos corretos
      final dataToSave = {
        'city': _controllers['city']!.text,
        'state': _controllers['state']!.text,
        'residents': int.tryParse(_controllers['residents']!.text) ?? 0,
        'kwh_cost':
            double.tryParse(
              _controllers['kwh_cost']!.text.replaceAll(',', '.'),
            ) ??
            0.0,
        'monthly_goal_kwh':
            int.tryParse(_controllers['monthly_goal_kwh']!.text) ?? 0,
      };
      await _apiService.updateResidenceData(dataToSave);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Residência atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao atualizar a residência.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Residência')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  TextField(
                    controller: _controllers['city'],
                    decoration: const InputDecoration(labelText: 'Cidade'),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controllers['state'],
                    decoration: const InputDecoration(labelText: 'Estado (UF)'),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controllers['residents'],
                    decoration: const InputDecoration(labelText: 'Moradores'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controllers['kwh_cost'],
                    decoration: const InputDecoration(
                      labelText: 'Custo por kWh (R\$)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controllers['monthly_goal_kwh'],
                    decoration: const InputDecoration(
                      labelText: 'Meta Mensal (kWh)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveResidence,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Salvar Configurações'),
                  ),
                ],
              ),
            ),
    );
  }
}

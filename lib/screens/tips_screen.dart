import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  // Variáveis de estado
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _allTips = [];
  String _activeCategory = 'Geral';

  final ApiService _apiService = ApiService();
  final List<String> _categories = const [
    'Geral',
    'Cozinha',
    'Quarto',
    'Sala',
    'Banheiro',
    'Lavanderia',
  ];

  @override
  void initState() {
    super.initState();
    _fetchTips();
  }

  Future<void> _fetchTips() async {
    try {
      final tips = await _apiService.getTips();
      if (mounted) {
        setState(() {
          _allTips = tips;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Não foi possível carregar as dicas.';
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> get _filteredTips {
    if (_activeCategory == 'Geral') {
      return _allTips;
    }
    return _allTips.where((tip) => tip['category'] == _activeCategory).toList();
  }

  // Widgets de construção da UI
  Widget _buildCategoryTabs() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((category) {
          final isSelected = category == _activeCategory;
          return GestureDetector(
            onTap: () {
              setState(() {
                _activeCategory = category;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? theme.primaryColor : theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? theme.primaryColor : theme.dividerColor,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTipsList() {
    final theme = Theme.of(context);
    final tipsToShow = _filteredTips;

    if (tipsToShow.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              "Nenhuma dica encontrada para esta categoria.",
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tipsToShow.length,
      itemBuilder: (context, index) {
        final tip = tipsToShow[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: theme.primaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tip['title'] ?? 'Dica',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  tip['description'] ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        );
      },
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
                      'Dicas de Economia',
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 20),
                    _buildCategoryTabs(),
                    const SizedBox(height: 20),
                    _buildTipsList(),
                  ],
                ),
              ),
      ),
    );
  }
}

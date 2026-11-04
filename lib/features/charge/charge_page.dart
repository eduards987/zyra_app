import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../history/history_page.dart';
import '../simulation/simulation_page.dart';

class ChargePage extends StatefulWidget {
  const ChargePage({super.key});

  @override
  State<ChargePage> createState() => _ChargePageState();
}

class _ChargePageState extends State<ChargePage> {
  final TextEditingController _valueController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _goToSimulation() {
    final parsed =
        double.tryParse(_valueController.text.trim().replaceAll(',', '.'));

    if (parsed == null || parsed <= 0 || parsed > SupabaseService.maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Digite um valor entre R\$ 0,01 e '
            'R\$ ${SupabaseService.maxAmount.toStringAsFixed(2)}',
          ),
        ),
      );
      return;
    }

    // Arredonda para centavos (evita valores como 10.005).
    final value = double.parse(parsed.toStringAsFixed(2));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SimulationPage(amount: value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zyra'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              'Quanto você quer cobrar?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _valueController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor',
                border: OutlineInputBorder(),
                prefixText: 'R\$ ',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _goToSimulation,
                child: const Text('Continuar'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

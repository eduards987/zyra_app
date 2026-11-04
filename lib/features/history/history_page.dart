import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/logger.dart';
import '../../core/models/transaction_model.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Vendas'),
        centerTitle: true,
      ),
      body: userId == null
          ? const Center(child: Text('Sessão expirada. Entre novamente.'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              // Atualiza em tempo real. A RLS no banco garante que só
              // chegam transações do próprio usuário.
              stream: supabase
                  .from('transactions')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', userId)
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  logDebug('Erro no histórico: ${snapshot.error}');
                  return const Center(
                    child: Text('Não foi possível carregar o histórico.'),
                  );
                }

                final transactions = (snapshot.data ?? [])
                    .map(TransactionModel.fromMap)
                    .toList();

                if (transactions.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhuma venda realizada ainda.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final t = transactions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _methodColor(t.method),
                        child:
                            const Icon(Icons.attach_money, color: Colors.white),
                      ),
                      title: Text(
                        'R\$ ${t.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle:
                          Text('${dateFormat.format(t.date)} • ${t.method}'),
                      trailing: _StatusChip(status: t.status),
                    );
                  },
                );
              },
            ),
    );
  }

  Color _methodColor(String method) {
    switch (method.toLowerCase()) {
      case 'pix':
        return Colors.teal;
      case 'credito':
        return Colors.blue;
      case 'debito':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'paid' => ('Pago', Colors.green),
      'failed' => ('Falhou', Colors.red),
      'canceled' => ('Cancelado', Colors.grey),
      _ => ('Pendente', Colors.orange),
    };
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
    );
  }
}

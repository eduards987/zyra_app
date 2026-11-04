import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/transaction_model.dart';

class DailyDashboard extends StatelessWidget {
  const DailyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('transactions')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId),
      builder: (context, snapshot) {
        double totalDay = 0;
        int paidCount = 0;
        int pendingCount = 0;

        if (snapshot.hasData) {
          final now = DateTime.now();
          final startOfDay = DateTime(now.year, now.month, now.day);

          final today = snapshot.data!
              .map(TransactionModel.fromMap)
              .where((t) => !t.date.isBefore(startOfDay));

          for (final t in today) {
            if (t.isPaid) {
              // Só entra no faturamento o que foi confirmado pelo servidor.
              totalDay += t.amount;
              paidCount++;
            } else if (t.status == 'pending') {
              pendingCount++;
            }
          }
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.shade700,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Faturamento de Hoje',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'R\$ ${totalDay.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$paidCount vendas confirmadas'
                '${pendingCount > 0 ? ' • $pendingCount pendentes' : ''}',
                style: const TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }
}

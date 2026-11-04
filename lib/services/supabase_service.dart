import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/models/transaction_model.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Valor máximo por cobrança (proteção contra erro de digitação).
  static const double maxAmount = 50000;

  /// Cria a cobrança como PENDENTE e retorna o id.
  /// O status 'paid' só pode ser gravado pelo servidor (webhook),
  /// garantido pelas políticas de RLS do banco.
  Future<String> createPendingTransaction(TransactionModel transaction) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sessão expirada. Entre novamente.');
    }
    if (transaction.amount <= 0 || transaction.amount > maxAmount) {
      throw ArgumentError('Valor fora do limite permitido.');
    }

    final row = await _supabase
        .from('transactions')
        .insert({
          ...transaction.toMap(),
          'user_id': user.id,
        })
        .select('id')
        .single();

    return row['id'].toString();
  }

  Future<List<TransactionModel>> getTransactions() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    // O filtro por user_id é só otimização: quem garante que cada usuário
    // só vê os próprios dados é a política de RLS no banco.
    final response = await _supabase
        .from('transactions')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => TransactionModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/logger.dart';
import '../../core/models/transaction_model.dart';
import '../../services/supabase_service.dart';
import 'payment_webview_page.dart';

class SimulationPage extends StatefulWidget {
  final double amount;

  const SimulationPage({super.key, required this.amount});

  @override
  State<SimulationPage> createState() => _SimulationPageState();
}

class _SimulationPageState extends State<SimulationPage> {
  bool _isLoading = false;

  // Taxas exibidas ao lojista (apenas estimativa; o valor cobrado de fato
  // é definido pelo servidor/provedor de pagamento).
  static const double _pixRate = 0.005;
  static const double _debitRate = 0.012;
  static const double _creditRate = 0.035;

  String _mapMethodKey(String method) {
    final normalized = method.toLowerCase();
    if (normalized.contains('pix')) return 'pix';
    if (normalized.contains('débito') || normalized.contains('debito')) {
      return 'debito';
    }
    return 'credito';
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _handlePayment(String method, double fee) async {
    if (_isLoading) return; // evita cobrança duplicada por toque duplo
    setState(() => _isLoading = true);

    try {
      final methodKey = _mapMethodKey(method);

      // 1. Registra a cobrança como PENDENTE (não conta como venda ainda).
      final transactionId = await SupabaseService().createPendingTransaction(
        TransactionModel(
          amount: widget.amount,
          method: methodKey,
          fee: double.parse(fee.toStringAsFixed(2)),
          date: DateTime.now(),
        ),
      );

      // 2. Edge Function gera o link de pagamento. O usuário é identificado
      //    pelo JWT da sessão, enviado automaticamente pelo SDK.
      //    O servidor NÃO deve confiar em user_id/amount vindos daqui:
      //    deve ler a transação pelo transaction_id e validar o dono.
      final res = await Supabase.instance.client.functions.invoke(
        'checkout',
        body: {
          'transaction_id': transactionId,
          'amount': widget.amount,
          'method': methodKey,
        },
      ).timeout(const Duration(seconds: 15));

      final data = res.data;
      final rawUrl = data is Map ? data['url'] : null;
      final uri = rawUrl is String ? Uri.tryParse(rawUrl) : null;

      // 3. Só abre links https válidos.
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        logDebug('Resposta do checkout sem URL válida: $data');
        _showMessage('Não foi possível gerar o link de pagamento.');
        return;
      }

      if (!mounted) return;
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => PaymentWebViewPage(url: uri)),
      );

      if (result == PaymentWebViewPage.resultSuccess) {
        // O retorno da página indica que o cliente concluiu o fluxo, mas a
        // confirmação oficial (status 'paid') vem do webhook do provedor.
        _showMessage('Pagamento enviado! Aguardando confirmação.');
      }
    } on TimeoutException {
      _showMessage('O servidor demorou a responder. Tente novamente.');
    } on AuthException {
      _showMessage('Sua sessão expirou. Entre novamente.');
    } catch (e) {
      logDebug('Erro ao gerar cobrança: $e');
      _showMessage('Erro ao gerar a cobrança. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pixFee = widget.amount * _pixRate;
    final debitFee = widget.amount * _debitRate;
    final creditFee = widget.amount * _creditRate;

    return Scaffold(
      appBar: AppBar(title: const Text('Escolha como cobrar')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _paymentOption('Pix', pixFee),
                  _paymentOption('Débito', debitFee),
                  _paymentOption('Crédito', creditFee),
                ],
              ),
            ),
    );
  }

  Widget _paymentOption(String method, double fee) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(method, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Taxa estimada: R\$ ${fee.toStringAsFixed(2)}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _handlePayment(method, fee),
      ),
    );
  }
}

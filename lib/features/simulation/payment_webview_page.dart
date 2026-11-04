import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/config/env.dart';

class PaymentWebViewPage extends StatefulWidget {
  static const String resultSuccess = 'success';

  final Uri url;

  const PaymentWebViewPage({super.key, required this.url});

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _loading = true;

  /// Confere o domínio exato. Antes, `url.contains('zyra.app/success')`
  /// aceitava qualquer site com esse texto na URL (ex.: um parâmetro).
  bool _isSuccessUrl(Uri uri) {
    final host = Env.paymentSuccessHost;
    final hostMatches = uri.host == host || uri.host == 'www.$host';
    return uri.scheme == 'https' &&
        hostMatches &&
        uri.path.startsWith('/success');
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      // Páginas de checkout precisam de JavaScript.
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;

            if (_isSuccessUrl(uri)) {
              Navigator.pop(context, PaymentWebViewPage.resultSuccess);
              return NavigationDecision.prevent;
            }

            // Bloqueia http e esquemas estranhos (javascript:, file:, intent:).
            if (uri.scheme != 'https') return NavigationDecision.prevent;

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento Seguro')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

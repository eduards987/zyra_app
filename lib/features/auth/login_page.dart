import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/logger.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static const _minPasswordLength = 8;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _showMessage(String text, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  /// Valida os campos. Retorna a mensagem de erro ou null se estiver ok.
  String? _validate({required bool isSignUp}) {
    final email = _emailController.text.trim();
    final password = _senhaController.text;
    if (!_emailRegex.hasMatch(email)) return 'Digite um email válido.';
    if (password.isEmpty) return 'Digite sua senha.';
    if (isSignUp && password.length < _minPasswordLength) {
      return 'A senha precisa ter pelo menos $_minPasswordLength caracteres.';
    }
    return null;
  }

  Future<void> _login() async {
    final error = _validate(isSignUp: false);
    if (error != null) return _showMessage(error);

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        // A senha NÃO é alterada (sem trim): espaços fazem parte dela.
        password: _senhaController.text,
      );
      if (response.session != null && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      logDebug('Falha no login: ${e.message} (status ${e.statusCode})');
      // Mensagem genérica: não revela se o email existe ou não.
      _showMessage('Email ou senha inválidos.');
    } catch (e) {
      logDebug('Erro inesperado no login: $e');
      _showMessage('Não foi possível entrar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    final error = _validate(isSignUp: true);
    if (error != null) return _showMessage(error);

    setState(() => _isLoading = true);
    try {
      // O registro na tabela public.users é criado por um trigger no banco
      // (ver supabase/migrations), não pelo app. Assim o cliente não
      // consegue inserir dados de outros usuários.
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _senhaController.text,
      );

      if (response.session != null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Confirmação de email ativada no Supabase.
        _showMessage(
          'Conta criada! Confirme pelo link enviado ao seu email e depois entre.',
          error: false,
        );
      }
    } on AuthException catch (e) {
      logDebug('Falha no cadastro: ${e.message} (status ${e.statusCode})');
      // Em modo debug mostra o motivo real para facilitar o diagnóstico.
      _showMessage(kDebugMode
          ? 'Cadastro falhou: ${e.message}'
          : 'Não foi possível criar a conta. Verifique os dados.');
    } catch (e) {
      logDebug('Erro inesperado no cadastro: $e');
      _showMessage('Não foi possível criar a conta. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acessar Zyra')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AutofillGroup(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wallet, size: 64, color: Colors.green),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _senhaController,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _login,
                          child: const Text('ENTRAR'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _register,
                        child: const Text('Ainda não tem conta? Criar agora'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

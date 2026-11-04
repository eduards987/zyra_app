/// Configuração do Supabase lida em tempo de build.
///
/// Os valores NÃO ficam no código-fonte. Eles vêm do arquivo `env.json`
/// (ignorado pelo Git) passado no build:
///
///   flutter run --dart-define-from-file=env.json
///   flutter build appbundle --release --dart-define-from-file=env.json
///
/// Atenção: a anon key do Supabase é pública por natureza (ela vai dentro
/// do APK). A proteção real dos dados são as políticas de RLS no banco
/// (ver supabase/migrations). Nunca coloque a service_role key no app.
class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Domínio para onde o checkout redireciona após pagamento concluído.
  static const String paymentSuccessHost =
      String.fromEnvironment('PAYMENT_SUCCESS_HOST', defaultValue: 'zyra.app');

  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL e SUPABASE_ANON_KEY não definidos. '
        'Rode com --dart-define-from-file=env.json',
      );
    }
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null || uri.scheme != 'https') {
      throw StateError('SUPABASE_URL precisa ser uma URL https válida.');
    }
  }
}

import 'package:flutter/foundation.dart';

/// Log apenas em modo debug. Em release nada é impresso,
/// evitando vazar dados de pagamento ou do usuário no logcat.
void logDebug(String message) {
  if (kDebugMode) debugPrint(message);
}

// ============================================================
// AIプロバイダー
// ============================================================

abstract class AiProvider {
  /// systemPrompt   : AIへの役割・制約指示
  /// userMessage    : ユーザーからの入力
  /// responseSchema : Structured Output用JSONスキーマ（省略時はテキスト返却）
  Future<Map<String, dynamic>> generateJson({
    required String systemPrompt,
    required String userMessage,
    required Map<String, dynamic> responseSchema,
    int maxTokens = 1200,
  });
}

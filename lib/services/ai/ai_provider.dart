// ============================================================
// services/ai/ai_provider.dart — AIプロバイダー 抽象クラス
// ============================================================

abstract class AiProvider {
  /// システムプロンプトとユーザーメッセージを受け取り、
  /// レスポンステキストを返す
  Future<String> generate({
    required String systemPrompt,
    required String userMessage,
    int maxTokens = 1200,
  });
}

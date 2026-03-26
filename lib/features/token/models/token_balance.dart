// ============================================================
// トークンデータモデル
// ============================================================

// ── トークン ────────────────────────────────────────────────
class TokenBalance {
  final int free; // 合
  final int paid; // 升

  const TokenBalance({this.free = 0, this.paid = 0});

  factory TokenBalance.fromMap(Map<String, dynamic> m) => TokenBalance(
        free: (m['free'] ?? 0) as int,
        paid: (m['paid'] ?? 0) as int,
      );
  Map<String, dynamic> toMap() => {'free': free, 'paid': paid};

  TokenBalance copyWith({int? free, int? paid}) => TokenBalance(free: free ?? this.free, paid: paid ?? this.paid);
}

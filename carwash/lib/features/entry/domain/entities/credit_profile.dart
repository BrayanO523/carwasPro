class CreditProfile {
  final bool active;
  final double limit;
  final double currentBalance;
  final int days;
  final String? notes;

  const CreditProfile({
    this.active = false,
    this.limit = 0.0,
    this.currentBalance = 0.0,
    this.days = 30,
    this.notes,
  });

  CreditProfile copyWith({
    bool? active,
    double? limit,
    double? currentBalance,
    int? days,
    String? notes,
  }) {
    return CreditProfile(
      active: active ?? this.active,
      limit: limit ?? this.limit,
      currentBalance: currentBalance ?? this.currentBalance,
      days: days ?? this.days,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'credito_activo': active,
      'limite_credito': limit,
      'saldo_actual': currentBalance,
      'dias_credito': days,
      'notas_credito': notes,
    };
  }

  factory CreditProfile.fromMap(Map<String, dynamic> map) {
    return CreditProfile(
      active: map['credito_activo'] ?? false,
      limit: (map['limite_credito'] ?? 0.0).toDouble(),
      currentBalance: (map['saldo_actual'] ?? 0.0).toDouble(),
      days: map['dias_credito'] ?? 30,
      notes: map['notas_credito'],
    );
  }
}

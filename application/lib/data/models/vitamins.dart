class Vitamins {
  final double vitaminA;
  final double vitaminC;
  final double vitaminD;
  final double vitaminB12;

  const Vitamins({
    required this.vitaminA,
    required this.vitaminC,
    required this.vitaminD,
    required this.vitaminB12,
  });

  Vitamins scale(double factor) {
    return Vitamins(
      vitaminA: vitaminA * factor,
      vitaminC: vitaminC * factor,
      vitaminD: vitaminD * factor,
      vitaminB12: vitaminB12 * factor,
    );
  }

  Map<String, dynamic> toJson() => {
        'vitaminA': vitaminA,
        'vitaminC': vitaminC,
        'vitaminD': vitaminD,
        'vitaminB12': vitaminB12,
      };

  factory Vitamins.fromJson(Map<String, dynamic> json) => Vitamins(
        vitaminA: (json['vitaminA'] as num?)?.toDouble() ?? 0,
        vitaminC: (json['vitaminC'] as num?)?.toDouble() ?? 0,
        vitaminD: (json['vitaminD'] as num?)?.toDouble() ?? 0,
        vitaminB12: (json['vitaminB12'] as num?)?.toDouble() ?? 0,
      );

  static const empty =
      Vitamins(vitaminA: 0, vitaminC: 0, vitaminD: 0, vitaminB12: 0);
}

import '../../core/constants/app_constants.dart';

class UserProfile {
  final String id;
  final String name;
  final double height;
  final double weight;
  final String? profileImagePath;
  final double dailyCaloriesGoal;
  final double dailyProteinGoal;
  final double dailyFatGoal;
  final int dailyStepsGoal;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    this.profileImagePath,
    required this.dailyCaloriesGoal,
    required this.dailyProteinGoal,
    required this.dailyFatGoal,
    required this.dailyStepsGoal,
    required this.createdAt,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    double? height,
    double? weight,
    String? profileImagePath,
    double? dailyCaloriesGoal,
    double? dailyProteinGoal,
    double? dailyFatGoal,
    int? dailyStepsGoal,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      dailyCaloriesGoal: dailyCaloriesGoal ?? this.dailyCaloriesGoal,
      dailyProteinGoal: dailyProteinGoal ?? this.dailyProteinGoal,
      dailyFatGoal: dailyFatGoal ?? this.dailyFatGoal,
      dailyStepsGoal: dailyStepsGoal ?? this.dailyStepsGoal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'height': height,
        'weight': weight,
        'profileImagePath': profileImagePath,
        'dailyCaloriesGoal': dailyCaloriesGoal,
        'dailyProteinGoal': dailyProteinGoal,
        'dailyFatGoal': dailyFatGoal,
        'dailyStepsGoal': dailyStepsGoal,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        height: (json['height'] as num).toDouble(),
        weight: (json['weight'] as num).toDouble(),
        profileImagePath: json['profileImagePath'] as String?,
        dailyCaloriesGoal: (json['dailyCaloriesGoal'] as num).toDouble(),
        dailyProteinGoal: (json['dailyProteinGoal'] as num).toDouble(),
        dailyFatGoal: (json['dailyFatGoal'] as num).toDouble(),
        dailyStepsGoal: (json['dailyStepsGoal'] as num?)?.toInt() ??
            AppConstants.dailyStepsGoal,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

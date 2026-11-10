import '../../domain/entities/admin_user_entity.dart';

class AdminUserModel extends AdminUserEntity {
  const AdminUserModel({
    required super.id,
    super.userCode = '',
    required super.name,
    required super.email,
    super.phone,
    super.currency,
    required super.role,
    super.avatar = '',
    super.balance,
    super.totalSpent,
    super.totalProfit,
    super.score,
    super.isActive,
    super.plainPassword = '',
    super.level,
    super.levelName,
    super.manualLevel,
    super.nextLevel,
    super.nextLevelName,
    super.remainingForNextLevel,
    super.levelProgress,
    super.createdAt,
    super.isVerified = false,
    super.verificationStatus = 'unverified',
    super.customProfitPercentage,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    final totalSpentVal = (json['totalSpent'] as num?)?.toDouble() ?? 0.0;
    String parsedLevel = json['level'] as String? ?? '';
    String parsedLevelName = json['levelName'] as String? ?? '';
    final parsedManualLevel = json['manualLevel'] as String? ?? 'auto';
    String? parsedNextLevel = json['nextLevel'] as String?;
    String? parsedNextLevelName = json['nextLevelName'] as String?;
    double parsedRemaining = (json['remainingForNextLevel'] as num?)?.toDouble() ?? 51.0;
    double parsedProgress = (json['levelProgress'] as num?)?.toDouble() ?? 0.0;

    if (parsedLevel.isEmpty) {
      if (parsedManualLevel != 'auto') {
        parsedLevel = parsedManualLevel;
        switch (parsedManualLevel) {
          case 'vip':
            parsedLevelName = 'VIP';
            break;
          case 'diamond':
            parsedLevelName = 'ماسي';
            break;
          case 'gold':
            parsedLevelName = 'ذهبي';
            break;
          case 'silver':
            parsedLevelName = 'فضي';
            break;
          case 'bronze':
          default:
            parsedLevelName = 'برونزي';
            break;
        }
      } else if (totalSpentVal >= 1001) {
        parsedLevel = 'vip';
        parsedLevelName = 'VIP';
      } else if (totalSpentVal >= 501) {
        parsedLevel = 'diamond';
        parsedLevelName = 'ماسي';
      } else if (totalSpentVal >= 101) {
        parsedLevel = 'gold';
        parsedLevelName = 'ذهبي';
      } else if (totalSpentVal >= 51) {
        parsedLevel = 'silver';
        parsedLevelName = 'فضي';
      } else {
        parsedLevel = 'bronze';
        parsedLevelName = 'برونزي';
      }
    }

    return AdminUserModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      userCode: json['userCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      currency: (json['currency'] as String? ?? 'USD').toUpperCase(),
      role: json['role'] as String? ?? 'user',
      avatar: json['avatar'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      totalSpent: totalSpentVal,
      totalProfit: (json['totalProfit'] as num?)?.toDouble() ?? 0.0,
      score: (json['score'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      plainPassword: json['plainPassword'] as String? ?? '',
      level: parsedLevel,
      levelName: parsedLevelName,
      manualLevel: parsedManualLevel,
      nextLevel: parsedNextLevel,
      nextLevelName: parsedNextLevelName,
      remainingForNextLevel: parsedRemaining,
      levelProgress: parsedProgress,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      isVerified: json['isVerified'] == true,
      verificationStatus: (json['verificationStatus'] as String?) ?? (json['isVerified'] == true ? 'verified' : 'unverified'),
      customProfitPercentage: (json['customProfitPercentage'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userCode': userCode,
      'name': name,
      'email': email,
      'phone': phone,
      'currency': currency,
      'role': role,
      'avatar': avatar,
      'balance': balance,
      'totalSpent': totalSpent,
      'totalProfit': totalProfit,
      'score': score,
      'isActive': isActive,
      'plainPassword': plainPassword,
      'level': level,
      'levelName': levelName,
      'manualLevel': manualLevel,
      'nextLevel': nextLevel,
      'nextLevelName': nextLevelName,
      'remainingForNextLevel': remainingForNextLevel,
      'levelProgress': levelProgress,
      'isVerified': isVerified,
      'verificationStatus': verificationStatus,
      'customProfitPercentage': customProfitPercentage,
    };
  }
}

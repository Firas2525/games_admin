class AdminUserEntity {
  final String id;
  final String userCode;
  final String name;
  final String email;
  final String phone;
  final String currency;
  final String role;
  final String avatar;
  final double balance;
  final double totalSpent;
  final double totalProfit;
  final int score;
  final bool isActive;
  final String plainPassword;
  final String level;
  final String levelName;
  final String manualLevel;
  final String? nextLevel;
  final String? nextLevelName;
  final double remainingForNextLevel;
  final double levelProgress;
  final DateTime? createdAt;
  final bool isVerified;
  final String verificationStatus;
  final double? customProfitPercentage;

  const AdminUserEntity({
    required this.id,
    this.userCode = '',
    required this.name,
    required this.email,
    this.phone = '',
    this.currency = 'USD',
    required this.role,
    this.avatar = '',
    this.balance = 0.0,
    this.totalSpent = 0.0,
    this.totalProfit = 0.0,
    this.score = 0,
    this.isActive = true,
    this.plainPassword = '',
    this.level = 'bronze',
    this.levelName = 'برونزي',
    this.manualLevel = 'auto',
    this.nextLevel = 'silver',
    this.nextLevelName = 'فضي',
    this.remainingForNextLevel = 51.0,
    this.levelProgress = 0.0,
    this.createdAt,
    this.isVerified = false,
    this.verificationStatus = 'unverified',
    this.customProfitPercentage,
  });

  String get displayId => userCode.isNotEmpty
      ? userCode
      : (id.length > 6 ? id.substring(id.length - 6) : id);

  bool get isSyp => currency.toUpperCase() == 'SYP';
  String get currencySymbol => isSyp ? 'ل.س' : '\$';
  String get currencyName => isSyp ? 'ليرة سورية' : 'دولار أمريكي';
}

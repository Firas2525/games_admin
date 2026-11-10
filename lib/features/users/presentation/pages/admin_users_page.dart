import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../bloc/admin_users_bloc.dart';
import '../bloc/admin_users_event.dart';
import '../bloc/admin_users_state.dart';
import '../../domain/entities/admin_user_entity.dart';
import '../widgets/admin_user_activity_dialog.dart';
import 'admin_levels_page.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'active', 'blocked', 'has_balance'
  final Set<String> _visiblePasswords = {};
  final Set<String> _expandedUserIds = {};

  @override
  void initState() {
    super.initState();
    context.read<AdminUsersBloc>().add(LoadUsersEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getUserTier(AdminUserEntity user) {
    return '${_getLevelEmoji(user.level)} ${user.levelName}';
  }

  Color _getUserTierColor(String level) {
    switch (level.toLowerCase()) {
      case 'vip':
        return const Color(0xFFA855F7);
      case 'diamond':
        return const Color(0xFF06B6D4);
      case 'gold':
        return const Color(0xFFF59E0B);
      case 'silver':
        return const Color(0xFF94A3B8);
      case 'bronze':
      default:
        return const Color(0xFFCD7F32);
    }
  }

  String _getLevelEmoji(String level) {
    switch (level.toLowerCase()) {
      case 'vip':
        return '👑';
      case 'diamond':
        return '💎';
      case 'gold':
        return '🥇';
      case 'silver':
        return '🥈';
      case 'bronze':
      default:
        return '🥉';
    }
  }

  Widget _buildUserAvatar(AdminUserEntity user, {double radius = 20, Color? borderColor}) {
    final hasAvatar = user.avatar.trim().isNotEmpty;
    final tierColor = _getUserTierColor(user.level);

    Widget fallback() {
      return Center(
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: tierColor,
            fontSize: radius * 0.75,
          ),
        ),
      );
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tierColor.withValues(alpha: 0.18),
        border: Border.all(
          color: borderColor ?? tierColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: hasAvatar
            ? AppNetworkImage(
                user.avatar.trim(),
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback(),
              )
            : fallback(),
      ),
    );
  }

  void _showBalanceDialog({
    required BuildContext context,
    required AdminUserEntity user,
    required bool isDeposit,
  }) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final presets = user.isSyp
        ? (isDeposit
            ? [25000, 50000, 100000, 250000, 500000, 1000000]
            : [25000, 50000, 100000, 250000, 500000])
        : (isDeposit ? [5, 10, 25, 50, 100, 250] : [5, 10, 20, 50, 100]);
    final reasonPresets = isDeposit
        ? ['شحن رصيد نقدي', 'حوالة بنكية/محفظة', 'مكافأة عميل', 'استرداد قيمة طلب']
        : ['خصم مقابل طلب يدوي', 'تسوية رصيد', 'استرجاع مبلغ'];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double enteredAmount = double.tryParse(amountController.text.trim()) ?? 0.0;
            final double projectedBalance = isDeposit
                ? user.balance + enteredAmount
                : (user.balance - enteredAmount).clamp(0.0, double.infinity);

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: BorderSide(
                    color: isDeposit
                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                        : const Color(0xFFF43F5E).withValues(alpha: 0.3),
                  ),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDeposit ? const Color(0xFF10B981) : const Color(0xFFF43F5E))
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDeposit ? Icons.add_circle_rounded : Icons.remove_circle_rounded,
                        color: isDeposit ? const Color(0xFF34D399) : const Color(0xFFFB7185),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isDeposit
                            ? 'شحن رصيد (${user.currencySymbol})'
                            : 'خصم رصيد (${user.currencySymbol})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User info card with projected balance and currency
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131D31),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  _buildUserAvatar(user, radius: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                user.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (user.isSyp ? Colors.amber : const Color(0xFF10B981)).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: (user.isSyp ? Colors.amber : const Color(0xFF10B981)).withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Text(
                                                user.currency,
                                                style: TextStyle(
                                                  color: user.isSyp ? Colors.amber : const Color(0xFF34D399),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          user.email,
                                          style: TextStyle(color: Colors.grey.shade400, fontSize: 10.5),
                                        ),
                                        if (user.phone.isNotEmpty)
                                          Text(
                                            'هاتف: ${user.phone}',
                                            style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(height: 1, color: Colors.white10),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('الرصيد الحالي', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                                      Text(
                                        '${user.balance.toStringAsFixed(user.isSyp ? 0 : 2)} ${user.currencySymbol}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white30),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('الرصيد بعد العملية', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                                      Text(
                                        '${projectedBalance.toStringAsFixed(user.isSyp ? 0 : 2)} ${user.currencySymbol}',
                                        style: TextStyle(
                                          color: isDeposit ? const Color(0xFF34D399) : const Color(0xFFFB7185),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Amount input
                        TextFormField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'المبلغ المطلوب (${user.currencySymbol})',
                            labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                            prefixIcon: Icon(
                              user.isSyp ? Icons.account_balance_wallet_rounded : Icons.attach_money_rounded,
                              color: const Color(0xFF38BDF8),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF131D31),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                          ),
                          onChanged: (_) => setDialogState(() {}),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'يرجى إدخال المبلغ';
                            final parsed = double.tryParse(val);
                            if (parsed == null || parsed <= 0) return 'المبلغ يجب أن يكون أكبر من 0';
                            if (!isDeposit && parsed > user.balance) return 'المبلغ أكبر من رصيد المستخدم!';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        // Fast Amount Presets
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: presets.map((p) {
                            return ActionChip(
                              label: Text('$p ${user.currencySymbol}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                              backgroundColor: const Color(0xFF1E293B),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                              onPressed: () {
                                setDialogState(() {
                                  amountController.text = p.toString();
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),

                        // Note input
                        TextFormField(
                          controller: noteController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'ملاحظة العملية (سبب الشحن/الخصم)',
                            labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                            hintText: isDeposit ? 'شحن رصيد يدوي' : 'خصم أو تعديل رصيد',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                            prefixIcon: const Icon(Icons.note_alt_outlined, color: Color(0xFF38BDF8), size: 18),
                            filled: true,
                            fillColor: const Color(0xFF131D31),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Reason Chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: reasonPresets.map((r) {
                            return InkWell(
                              onTap: () {
                                setDialogState(() {
                                  noteController.text = r;
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Text(r, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDeposit ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final amount = double.parse(amountController.text.trim());
                        final note = noteController.text.trim();
                        Navigator.pop(dialogCtx);

                        if (isDeposit) {
                          context.read<AdminUsersBloc>().add(
                                DepositUserBalanceEvent(
                                  userId: user.id,
                                  amount: amount,
                                  note: note.isNotEmpty ? note : null,
                                ),
                              );
                        } else {
                          context.read<AdminUsersBloc>().add(
                                DeductUserBalanceEvent(
                                  userId: user.id,
                                  amount: amount,
                                  note: note.isNotEmpty ? note : null,
                                ),
                              );
                        }
                      }
                    },
                    child: Text(isDeposit ? 'تأكيد شحن المبلغ' : 'تأكيد خصم المبلغ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog(AdminUserEntity user) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.35)),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF38BDF8), size: 24),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تغيير كلمة المرور',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                          Text(
                            user.name,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current password info
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131D31),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF38BDF8)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  user.plainPassword.isNotEmpty
                                      ? 'كلمة المرور الحالية: ${user.plainPassword}'
                                      : 'لم يتم حفظ كلمة مرور سابقة لهذا الحساب',
                                  style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // New password input
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscure,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور الجديدة',
                            labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                            hintText: '6 أحرف أو أرقام على الأقل',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF38BDF8), size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                color: Colors.white60,
                                size: 18,
                              ),
                              onPressed: () => setDialogState(() => obscure = !obscure),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF131D31),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'يرجى إدخال كلمة المرور';
                            if (val.trim().length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        // Fast Random Password Generator Button
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF38BDF8),
                            side: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.autorenew_rounded, size: 16),
                          label: const Text('توليد كلمة مرور عشوائية', style: TextStyle(fontSize: 11.5)),
                          onPressed: () {
                            final randomDigits = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
                            final generated = 'Pass$randomDigits';
                            setDialogState(() {
                              passwordController.text = generated;
                              obscure = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final newPassword = passwordController.text.trim();
                        Navigator.pop(dialogCtx);
                        context.read<AdminUsersBloc>().add(
                              ChangeUserPasswordEvent(
                                userId: user.id,
                                newPassword: newPassword,
                              ),
                            );
                      }
                    },
                    child: const Text('حفظ التغيير', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCustomProfitDialog(AdminUserEntity user) {
    final controller = TextEditingController(
      text: user.customProfitPercentage != null ? user.customProfitPercentage.toString() : '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dlgCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF1E293B)),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.percent_rounded, color: Color(0xFF10B981), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'نسبة الربح المخصصة',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      user.name,
                      style: const TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.customProfitPercentage != null
                            ? 'النسبة المخصصة الحالية: ${user.customProfitPercentage}%'
                            : 'النسبة الحالية: يتبع النظام الافتراضي',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: user.customProfitPercentage != null ? const Color(0xFF10B981) : Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '• تطبق هذه النسبة على منتجات المستخدم بدلاً من النسبة العامة.\n• للأقسام ذات النسب الخاصة، يتم تخفيضها تناسبياً.\n• يضمن النظام عدم هبوط ربح الأدمن عن 0.4% كحد أدنى مطلق في أسوأ الحالات.',
                        style: TextStyle(fontSize: 10.5, color: Colors.white54, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'نسبة الربح (%)',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    hintText: 'مثال: 2.5 أو 1.0',
                    hintStyle: const TextStyle(color: Colors.white24),
                    suffixText: '%',
                    suffixStyle: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return null;
                    final parsed = double.tryParse(val.trim());
                    if (parsed == null || parsed < 0) {
                      return 'يرجى إدخال نسبة صحيحة (0 أو أكبر)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            if (user.customProfitPercentage != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(dlgCtx);
                  context.read<AdminUsersBloc>().add(
                        UpdateUserCustomProfitEvent(
                          userId: user.id,
                          customProfitPercentage: null,
                        ),
                      );
                },
                child: const Text('إعادة للافتراضي', style: TextStyle(color: Colors.redAccent)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final text = controller.text.trim();
                  final val = text.isNotEmpty ? double.tryParse(text) : null;
                  Navigator.pop(dlgCtx);
                  context.read<AdminUsersBloc>().add(
                        UpdateUserCustomProfitEvent(
                          userId: user.id,
                          customProfitPercentage: val,
                        ),
                      );
                }
              },
              child: const Text('حفظ النسبة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeLevelSheet(AdminUserEntity user) {
    String selectedLevel = user.manualLevel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                  boxShadow: [
                    BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, -6)),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header: Icon + Title + Close Button
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.military_tech_rounded,
                            color: Color(0xFF38BDF8),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'تحديد مستوى العضوية',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16.5,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${user.name} (#${user.displayId})',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white60),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // User Spending Info Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131D31),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.shopping_bag_outlined, size: 16, color: Color(0xFF38BDF8)),
                                const SizedBox(width: 6),
                                Text(
                                  'المشتريات: \$${user.totalSpent.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getUserTierColor(user.level).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _getUserTierColor(user.level).withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'الحالي: ${_getLevelEmoji(user.level)} ${user.levelName}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _getUserTierColor(user.level),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'اختر المستوى المطلوب للمستخدم:',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                    const SizedBox(height: 10),

                    // Level Selection Cards
                    _buildLevelOptionCard(
                      emoji: '⚡',
                      title: 'تلقائي (حسب المشتريات)',
                      range: 'يتم احتساب المستوى آلياً بناءً على إجمالي المشتريات',
                      value: 'auto',
                      selectedValue: selectedLevel,
                      accentColor: const Color(0xFF38BDF8),
                      onTap: () => setSheetState(() => selectedLevel = 'auto'),
                    ),
                    const SizedBox(height: 8),

                    _buildLevelOptionCard(
                      emoji: '🥉',
                      title: 'المستوى البرونزي',
                      range: 'من \$0 إلى أقل من \$51',
                      value: 'bronze',
                      selectedValue: selectedLevel,
                      accentColor: const Color(0xFFCD7F32),
                      onTap: () => setSheetState(() => selectedLevel = 'bronze'),
                    ),
                    const SizedBox(height: 8),

                    _buildLevelOptionCard(
                      emoji: '🥈',
                      title: 'المستوى الفضي',
                      range: 'من \$51 إلى أقل من \$101',
                      value: 'silver',
                      selectedValue: selectedLevel,
                      accentColor: const Color(0xFF94A3B8),
                      onTap: () => setSheetState(() => selectedLevel = 'silver'),
                    ),
                    const SizedBox(height: 8),

                    _buildLevelOptionCard(
                      emoji: '🥇',
                      title: 'المستوى الذهبي',
                      range: 'من \$101 إلى أقل من \$501',
                      value: 'gold',
                      selectedValue: selectedLevel,
                      accentColor: const Color(0xFFF59E0B),
                      onTap: () => setSheetState(() => selectedLevel = 'gold'),
                    ),
                    const SizedBox(height: 8),

                    _buildLevelOptionCard(
                      emoji: '💎',
                      title: 'المستوى الماسي',
                      range: 'من \$501 إلى أقل من \$1001',
                      value: 'diamond',
                      selectedValue: selectedLevel,
                      accentColor: const Color(0xFF06B6D4),
                      onTap: () => setSheetState(() => selectedLevel = 'diamond'),
                    ),
                    const SizedBox(height: 8),

                    _buildLevelOptionCard(
                      emoji: '👑',
                      title: 'مستوى VIP كبار الشخصيات',
                      range: 'من \$1001 فما فوق',
                      value: 'vip',
                      selectedValue: selectedLevel,
                      accentColor: const Color(0xFFA855F7),
                      onTap: () => setSheetState(() => selectedLevel = 'vip'),
                    ),

                    const SizedBox(height: 20),

                    // Apply Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text(
                        'حفظ وتطبيق المستوى',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                      ),
                      onPressed: () {
                        context.read<AdminUsersBloc>().add(
                              UpdateUserLevelEvent(
                                userId: user.id,
                                manualLevel: selectedLevel,
                              ),
                            );
                        Navigator.pop(sheetCtx);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLevelOptionCard({
    required String emoji,
    required String title,
    required String range,
    required String value,
    required String selectedValue,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final isSelected = value == selectedValue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.15)
              : const Color(0xFF131D31),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white10,
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    range,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isSelected ? accentColor : Colors.grey.shade400,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? accentColor : Colors.white30,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showUserInspector(AdminUserEntity user) {
    final tier = _getUserTier(user);
    final tierColor = _getUserTierColor(user.level);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isPasswordVisible = _visiblePasswords.contains(user.id);
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, -6)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildUserAvatar(user, radius: 26),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                              if (user.isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 18),
                              ],
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tierColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: tierColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(tier, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tierColor)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(user.email, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white10),
                const SizedBox(height: 12),

                // Financial Metrics for this User (Profit & Total Spent)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131D31),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('أرباح المستخدم الإجمالية',
                              style: TextStyle(fontSize: 11, color: Color(0xFF6EE7B7))),
                          const SizedBox(height: 3),
                          Text(
                            '+${user.totalProfit.toStringAsFixed(user.isSyp ? 0 : 2)} ${user.currencySymbol}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF34D399)),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 35, color: Colors.white12),
                      Column(
                        children: [
                          const Text('إجمالي إنفاق ومشتريات العميل',
                              style: TextStyle(fontSize: 11, color: Colors.white60)),
                          const SizedBox(height: 3),
                          Text(
                            '${user.totalSpent.toStringAsFixed(user.isSyp ? 0 : 2)} ${user.currencySymbol}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF38BDF8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Custom Profit Setting Tile
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: (user.customProfitPercentage != null ? const Color(0xFF10B981) : const Color(0xFF64748B)).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (user.customProfitPercentage != null ? const Color(0xFF10B981) : const Color(0xFF64748B)).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.percent_rounded,
                        size: 15,
                        color: user.customProfitPercentage != null ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user.customProfitPercentage != null
                              ? 'نسبة ربح خاصة: ${user.customProfitPercentage}%'
                              : 'نسبة الربح: الافتراضية (يتبع النظام)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: user.customProfitPercentage != null ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _showCustomProfitDialog(user),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_rounded, size: 12, color: Color(0xFF10B981)),
                              SizedBox(width: 3),
                              Text(
                                'تعديل',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Specs
                Row(
                  children: [
                    Expanded(
                      child: _buildInspectorDetailBox(
                        title: 'الرصيد الرقمي الحالي',
                        value: '${user.balance.toStringAsFixed(user.isSyp ? 0 : 2)} ${user.currencySymbol}',
                        color: const Color(0xFF34D399),
                        icon: Icons.account_balance_wallet_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInspectorDetailBox(
                        title: 'عملة الحساب (ثابتة)',
                        value: '${user.currencyName} (${user.currency})',
                        color: user.isSyp ? Colors.amber : const Color(0xFF38BDF8),
                        icon: Icons.currency_exchange_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildInspectorDetailBox(
                        title: 'رقم الهاتف',
                        value: user.phone.isNotEmpty ? user.phone : 'غير متوفر',
                        color: const Color(0xFF38BDF8),
                        icon: Icons.phone_android_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInspectorDetailBox(
                        title: 'حالة الحساب',
                        value: user.isActive ? '🟢 نشط وغير محظور' : '🔴 محظور وموقوف',
                        color: user.isActive ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                        icon: user.isActive ? Icons.verified_user_rounded : Icons.block_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildInspectorDetailBox(
                  title: 'رقم حساب العميل (الآيدي القصير)',
                  value: '#${user.displayId}',
                  color: const Color(0xFF0284C7),
                  icon: Icons.tag_rounded,
                ),
                const SizedBox(height: 10),
                _buildInspectorDetailBox(
                  title: 'معرف النظام (UID)',
                  value: user.id,
                  color: const Color(0xFF94A3B8),
                  icon: Icons.fingerprint_rounded,
                ),
                const SizedBox(height: 10),

                // Password box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131D31),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_rounded, size: 20, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('كلمة مرور الحساب', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                            const SizedBox(height: 2),
                            Text(
                              isPasswordVisible
                                  ? (user.plainPassword.isNotEmpty ? user.plainPassword : 'غير مسجلة بعد')
                                  : (user.plainPassword.isNotEmpty ? '••••••••' : 'غير مسجلة بعد'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: user.plainPassword.isNotEmpty ? Colors.white : Colors.white38,
                                letterSpacing: (isPasswordVisible || user.plainPassword.isEmpty) ? 0.5 : 2.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (user.plainPassword.isNotEmpty) ...[
                        IconButton(
                          icon: Icon(
                            isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 18,
                            color: Colors.white70,
                          ),
                          tooltip: isPasswordVisible ? 'إخفاء' : 'إظهار',
                          onPressed: () {
                            setSheetState(() {
                              if (_visiblePasswords.contains(user.id)) {
                                _visiblePasswords.remove(user.id);
                              } else {
                                _visiblePasswords.add(user.id);
                              }
                            });
                            setState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF38BDF8)),
                          tooltip: 'نسخ كلمة المرور',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: user.plainPassword));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم نسخ كلمة المرور إلى الحافظة'),
                                backgroundColor: Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.25),
                          foregroundColor: const Color(0xFF38BDF8),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.45)),
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 13),
                        label: const Text('تغيير', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(bottomCtx);
                          _showChangePasswordDialog(user);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // User Level Management Tile
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131D31),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tierColor.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Text(_getLevelEmoji(user.level), style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مستوى الحساب',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${user.levelName} ${user.manualLevel != "auto" ? "(تحديد يدوي)" : "(تلقائي)"}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: tierColor,
                              ),
                            ),
                            Text(
                              'إجمالي المشتريات: \$${user.totalSpent.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tierColor.withValues(alpha: 0.25),
                          foregroundColor: tierColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(color: tierColor.withValues(alpha: 0.45)),
                        ),
                        icon: const Icon(Icons.tune_rounded, size: 13),
                        label: const Text(
                          'تغيير المستوى',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.pop(bottomCtx);
                          _showChangeLevelSheet(user);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  icon: const Icon(Icons.receipt_long_rounded, size: 20),
                  label: const Text(
                    'الطلبات والعمليات',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: () {
                    Navigator.pop(bottomCtx);
                    AdminUserActivityDialog.show(context, user: user);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add_circle_rounded, size: 18),
                        label: const Text('شحن رصيد', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(bottomCtx);
                          _showBalanceDialog(context: context, user: user, isDeposit: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF43F5E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.remove_circle_rounded, size: 18),
                        label: const Text('خصم رصيد', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(bottomCtx);
                          _showBalanceDialog(context: context, user: user, isDeposit: false);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  },
);
}

  Widget _buildInspectorDetailBox({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                Text(
                  value,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPurgeAllUsersDialog() {
    final confirmController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 26),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'حذف جميع المستخدمين',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'إجراء تنظيف شامل لقاعدة البيانات',
                        style: TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'ما الذي سيتم حذفه نهائياً؟',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• جميع حسابات المستخدمين (غير المدراء).\n• جميع سجلات الطلبات والمشتريات.\n• جميع طلبات الإيداع وحركات الأرصدة.\n• سجلات المفضلات وسجلات النظام الخاصة بالمستخدمين.',
                          style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'ما الذي لن يتأثر وسيبقى محفوظاً 100%؟',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• حسابات الأدمن والمدراء محمية بالكامل ولن تُحذف.\n• جميع المنتجات وأسعارها وتكاليفها.\n• نسب أرباح المتجر والخصومات.\n• الأقسام والمجلدات وترتيب المنتجات لن تتأثر أبداً.',
                          style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لتأكيد الحذف النهائي، اكتب كلمة "حذف" في الحقل أدناه:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    enabled: !isLoading,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'اكتب "حذف" هنا...',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFEF4444)),
                      ),
                    ),
                    onChanged: (_) {
                      setDialogState(() {
                        errorMessage = null;
                      });
                    },
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(dlgCtx).pop(),
                child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        final text = confirmController.text.trim();
                        if (text != 'حذف') {
                          setDialogState(() {
                            errorMessage = 'يرجى كتابة كلمة "حذف" للتأكيد';
                          });
                          return;
                        }

                        setDialogState(() {
                          isLoading = true;
                          errorMessage = null;
                        });

                        try {
                          final response = await sl<ApiClient>().post(
                            '/users/purge-all-users',
                            data: {'confirmation': 'CONFIRM_DELETE_ALL_USERS'},
                          );

                          if (!mounted) return;
                          Navigator.of(dlgCtx).pop();

                          final data = response.data;
                          final msg = (data is Map && data['message'] != null)
                              ? data['message'].toString()
                              : 'تم حذف جميع المستخدمين وعملياتهم بنجاح مع الحفاظ على حساب الأدمن والمنتجات.';

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 6),
                            ),
                          );

                          context.read<AdminUsersBloc>().add(LoadUsersEvent());
                        } catch (e) {
                          if (!mounted) return;
                          setDialogState(() {
                            isLoading = false;
                            errorMessage = 'فشلت العملية: ${e.toString()}';
                          });
                        }
                      },
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.delete_forever_rounded, size: 18),
                label: Text(
                  isLoading ? 'جاري الحذف...' : 'تأكيد الحذف النهائي',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07111F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07111F),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'إدارة المستخدمين والأرصدة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'حذف جميع المستخدمين وعملياتهم',
            icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444)),
            onPressed: _showPurgeAllUsersDialog,
          ),
          IconButton(
            tooltip: 'شارات ومستويات الحساب',
            icon: const Icon(Icons.military_tech_rounded, color: Color(0xFFF59E0B)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminLevelsPage()),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<AdminUsersBloc, AdminUsersState>(
        listener: (context, state) {
          if (state is AdminUsersLoaded && state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is AdminUsersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFF43F5E),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminUsersLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0284C7)),
            );
          }

          if (state is AdminUsersError && state.currentUsers == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(state.message, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<AdminUsersBloc>().add(LoadUsersEvent()),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          List<AdminUserEntity> allUsers = [];
          String? updatingUserId;
          if (state is AdminUsersLoaded) {
            allUsers = state.users;
          } else if (state is AdminUsersActionLoading) {
            allUsers = state.users;
            updatingUserId = state.updatingUserId;
          } else if (state is AdminUsersError && state.currentUsers != null) {
            allUsers = state.currentUsers!;
          }

          final usersUsd = allUsers.where((u) => !u.isSyp).toList();
          final usersSyp = allUsers.where((u) => u.isSyp).toList();
          final totalUsd = usersUsd.fold(0.0, (sum, u) => sum + u.balance);
          final totalSyp = usersSyp.fold(0.0, (sum, u) => sum + u.balance);
          final activeUsersCount = allUsers.where((u) => u.isActive).length;

          final filteredUsers = allUsers.where((u) {
            if (_selectedFilter == 'usd' && u.isSyp) return false;
            if (_selectedFilter == 'syp' && !u.isSyp) return false;
            if (_selectedFilter == 'active' && !u.isActive) return false;
            if (_selectedFilter == 'blocked' && u.isActive) return false;
            if (_selectedFilter == 'has_balance' && u.balance <= 0) return false;

            if (_searchQuery.isNotEmpty) {
              final raw = _searchQuery.toLowerCase();
              final stripped = raw
                  .replaceAll('#', '')
                  .replaceFirst(RegExp(r'^id[:\s\-]*'), '')
                  .trim();
              final q = stripped.isNotEmpty ? stripped : raw.trim();

              return u.name.toLowerCase().contains(q) ||
                  u.email.toLowerCase().contains(q) ||
                  u.phone.toLowerCase().contains(q) ||
                  u.id.toLowerCase().contains(q) ||
                  u.userCode.toLowerCase().contains(q) ||
                  u.displayId.toLowerCase().contains(q);
            }
            return true;
          }).toList();

          return RefreshIndicator(
            color: const Color(0xFF0284C7),
            backgroundColor: const Color(0xFF0F172A),
            onRefresh: () async {
              context.read<AdminUsersBloc>().add(LoadUsersEvent());
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. KPI Metric Summary Cards (Separating USD and SYP)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        _buildKpiCard(
                          title: 'أموال الدولار',
                          value: '\$${totalUsd.toStringAsFixed(1)}',
                          icon: Icons.monetization_on_rounded,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        _buildKpiCard(
                          title: 'أموال السوري',
                          value: '${totalSyp.toStringAsFixed(0)} ل.س',
                          icon: Icons.account_balance_wallet_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 8),
                        _buildKpiCard(
                          title: 'حسابات الدولار',
                          value: '${usersUsd.length}',
                          icon: Icons.people_alt_rounded,
                          color: const Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 8),
                        _buildKpiCard(
                          title: 'حسابات السوري',
                          value: '${usersSyp.length}',
                          icon: Icons.people_outline_rounded,
                          color: const Color(0xFF38BDF8),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Search & Filter Bar
                SliverToBoxAdapter(
                  child: Container(
                    color: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        // Search bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'ابحث برقم الآيدي (ID)، الكود، الاسم، الهاتف...',
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
                              prefixIcon: IconButton(
                                icon: const Icon(Icons.search_rounded, color: Color(0xFF38BDF8), size: 20),
                                tooltip: 'بحث في السيرفر',
                                onPressed: () {
                                  final q = _searchController.text.trim();
                                  context.read<AdminUsersBloc>().add(LoadUsersEvent(search: q.isNotEmpty ? q : null));
                                },
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_searchQuery.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.clear_rounded, color: Colors.white60, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                        context.read<AdminUsersBloc>().add(LoadUsersEvent());
                                      },
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.send_rounded, color: Color(0xFF38BDF8), size: 16),
                                    tooltip: 'بحث شامل في السيرفر',
                                    onPressed: () {
                                      final q = _searchController.text.trim();
                                      context.read<AdminUsersBloc>().add(LoadUsersEvent(search: q.isNotEmpty ? q : null));
                                    },
                                  ),
                                ],
                              ),
                              filled: true,
                              fillColor: const Color(0xFF131D31),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                            ),
                            onChanged: (val) {
                              setState(() => _searchQuery = val.trim());
                            },
                            onSubmitted: (val) {
                              context.read<AdminUsersBloc>().add(LoadUsersEvent(search: val.trim().isNotEmpty ? val.trim() : null));
                            },
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Filter chips with currency separation
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              _buildUserFilterChip('الكل (${allUsers.length})', 'all'),
                              const SizedBox(width: 8),
                              _buildUserFilterChip('دولار USD (${usersUsd.length})', 'usd'),
                              const SizedBox(width: 8),
                              _buildUserFilterChip('سوري SYP (${usersSyp.length})', 'syp'),
                              const SizedBox(width: 8),
                              _buildUserFilterChip('النشطين 🟢 ($activeUsersCount)', 'active'),
                              const SizedBox(width: 8),
                              _buildUserFilterChip('المحظورين 🔴 (${allUsers.length - activeUsersCount})', 'blocked'),
                              const SizedBox(width: 8),
                              _buildUserFilterChip('لديهم رصيد 💰 (${allUsers.where((u) => u.balance > 0).length})', 'has_balance'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. User Cards List
                if (filteredUsers.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'لا يوجد مستخدمين مطابقين للبحث أو الفلتر',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(14),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final user = filteredUsers[index];
                          return _buildUserCard(user, isUpdating: updatingUserId == user.id);
                        },
                        childCount: filteredUsers.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: const Color(0xFF0284C7).withValues(alpha: 0.25),
      backgroundColor: const Color(0xFF131D31),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? const Color(0xFF0284C7) : Colors.white10),
      ),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF38BDF8) : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) {
        setState(() => _selectedFilter = value);
      },
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 16, color: color),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(fontSize: 9.5, color: Colors.grey.shade400),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(AdminUserEntity user, {bool isUpdating = false}) {
    final isExpanded = _expandedUserIds.contains(user.id);
    final tier = _getUserTier(user);
    final tierColor = _getUserTierColor(user.level);
    final isPasswordVisible = _visiblePasswords.contains(user.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.isActive
              ? (isExpanded ? const Color(0xFF0284C7).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08))
              : const Color(0xFFF43F5E).withValues(alpha: 0.35),
          width: isExpanded ? 1.3 : 1.0,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedUserIds.remove(user.id);
            } else {
              _expandedUserIds.add(user.id);
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Compact Header: Avatar + User Info + Balance + Expand arrow
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  _buildUserAvatar(user, radius: 20),
                  const SizedBox(width: 10),

                  // User Name + Badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (user.isVerified) ...[
                              const SizedBox(width: 4),
                              const Tooltip(
                                message: 'حساب موثق رسميًا ✅',
                                child: Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 15),
                              ),
                            ],
                            const SizedBox(width: 6),
                            // Short code badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '#${user.displayId}',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF38BDF8),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            // ID Badge with copy feature
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: user.id));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تم نسخ الآيدي: ${user.id}'),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.fingerprint_rounded, size: 10, color: Colors.white70),
                                    const SizedBox(width: 3),
                                    Text(
                                      'ID: ${user.id.length > 8 ? user.id.substring(user.id.length - 8) : user.id}',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Subline Badges: Currency + Level Badge + Status Pill
                        Row(
                          children: [
                            // Currency Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: (user.isSyp ? Colors.amber : const Color(0xFF10B981)).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                user.currency,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: user.isSyp ? const Color(0xFFFBBF24) : const Color(0xFF34D399),
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),

                            // Level Badge (Clickable to change level!)
                            InkWell(
                              onTap: () => _showChangeLevelSheet(user),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: tierColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: tierColor.withValues(alpha: 0.4), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      tier,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: tierColor,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(Icons.tune_rounded, size: 10, color: tierColor),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),

                            // Active / Blocked mini badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: (user.isActive ? Colors.green : Colors.redAccent).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                user.isActive ? 'نشط' : 'محظور',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: user.isActive ? const Color(0xFF34D399) : const Color(0xFFF87171),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Left Side: Balance + Expand Toggle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${user.balance.toStringAsFixed(user.isSyp ? 0 : 2)} ${user.currencySymbol}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: user.isSyp ? const Color(0xFFFBBF24) : const Color(0xFF34D399),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isExpanded ? 'إخفاء' : 'تفاصيل',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: const Color(0xFF38BDF8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // 2. Expanded Details Section
              if (isExpanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: Colors.white10),
                const SizedBox(height: 12),

                // Contact Info (Email / Phone)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131D31),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alternate_email_rounded, size: 14, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          user.email,
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.phone.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          user.phone,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF34D399)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Financial Overview 3-Box Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131D31),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            Text('الرصيد المتاح', style: TextStyle(fontSize: 9.5, color: Colors.grey.shade400)),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${user.balance.toStringAsFixed(user.isSyp ? 0 : 2)} ${user.currencySymbol}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.5,
                                  color: user.isSyp ? const Color(0xFFFBBF24) : const Color(0xFF34D399),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131D31),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            Text('إجمالي المشتريات', style: TextStyle(fontSize: 9.5, color: Colors.grey.shade400)),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${user.totalSpent.toStringAsFixed(user.isSyp ? 0 : 2)} ${user.currencySymbol}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.5,
                                  color: Color(0xFF38BDF8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131D31),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            Text('أرباح المستخدم', style: TextStyle(fontSize: 9.5, color: Colors.grey.shade400)),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '+${user.totalProfit.toStringAsFixed(user.isSyp ? 0 : 2)} ${user.currencySymbol}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.5,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Password bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131D31),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.key_rounded, size: 14, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 6),
                      Text(
                        'كلمة المرور: ',
                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade400),
                      ),
                      Expanded(
                        child: Text(
                          isPasswordVisible
                              ? (user.plainPassword.isNotEmpty ? user.plainPassword : 'غير مسجلة بعد')
                              : (user.plainPassword.isNotEmpty ? '••••••••' : 'غير مسجلة بعد'),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: user.plainPassword.isNotEmpty ? Colors.white : Colors.white38,
                            letterSpacing: (isPasswordVisible || user.plainPassword.isEmpty) ? 0.5 : 2.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.plainPassword.isNotEmpty) ...[
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (_visiblePasswords.contains(user.id)) {
                                _visiblePasswords.remove(user.id);
                              } else {
                                _visiblePasswords.add(user.id);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Icon(
                              isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              size: 15,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: user.plainPassword));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم نسخ كلمة المرور إلى الحافظة'),
                                backgroundColor: Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Icon(Icons.copy_rounded, size: 14, color: Color(0xFF38BDF8)),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      InkWell(
                        onTap: () => _showChangePasswordDialog(user),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.35)),
                          ),
                          child: const Text(
                            'تغيير',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Membership & Level Setting Tile
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tierColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Text(_getLevelEmoji(user.level), style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'المستوى: ${user.levelName} (${user.manualLevel != "auto" ? "يدوي" : "تلقائي"})',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: tierColor,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _showChangeLevelSheet(user),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tierColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: tierColor.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune_rounded, size: 12, color: tierColor),
                              const SizedBox(width: 3),
                              Text(
                                'تعديل المستوى',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: tierColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Custom Profit Setting Tile
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: (user.customProfitPercentage != null ? const Color(0xFF10B981) : const Color(0xFF64748B)).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (user.customProfitPercentage != null ? const Color(0xFF10B981) : const Color(0xFF64748B)).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.percent_rounded,
                        size: 15,
                        color: user.customProfitPercentage != null ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user.customProfitPercentage != null
                              ? 'نسبة ربح خاصة: ${user.customProfitPercentage}%'
                              : 'نسبة الربح: الافتراضية (يتبع النظام)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: user.customProfitPercentage != null ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _showCustomProfitDialog(user),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_rounded, size: 12, color: Color(0xFF10B981)),
                              SizedBox(width: 3),
                              Text(
                                'تعديل',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action Buttons (Separated into clean rows without flex overflow!)
                // Row 1: Orders Activity full width
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.18),
                      foregroundColor: const Color(0xFF38BDF8),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.35)),
                    ),
                    icon: const Icon(Icons.receipt_long_rounded, size: 16),
                    label: const Text(
                      'الطلبات والعمليات',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => AdminUserActivityDialog.show(context, user: user),
                  ),
                ),
                const SizedBox(height: 8),

                // Row 2: Deposit / Deduct Balance
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                          foregroundColor: const Color(0xFF34D399),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('شحن رصيد', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _showBalanceDialog(context: context, user: user, isDeposit: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF43F5E).withValues(alpha: 0.2),
                          foregroundColor: const Color(0xFFFB7185),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: const Color(0xFFF43F5E).withValues(alpha: 0.3)),
                        ),
                        icon: const Icon(Icons.remove_rounded, size: 16),
                        label: const Text('خصم رصيد', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _showBalanceDialog(context: context, user: user, isDeposit: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 3: Status Switch + Full Inspector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.isActive ? 'الحساب: نشط' : 'الحساب: محظور',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: user.isActive ? const Color(0xFF34D399) : const Color(0xFFF87171),
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (isUpdating)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                          )
                        else
                          Transform.scale(
                            scale: 0.72,
                            child: Switch(
                              value: user.isActive,
                              activeThumbColor: Colors.green,
                              activeTrackColor: Colors.green.withValues(alpha: 0.4),
                              inactiveThumbColor: Colors.redAccent,
                              inactiveTrackColor: Colors.redAccent.withValues(alpha: 0.3),
                              onChanged: (_) {
                                context.read<AdminUsersBloc>().add(ToggleUserStatusEvent(userId: user.id));
                              },
                            ),
                          ),
                      ],
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      icon: const Icon(Icons.info_outline_rounded, size: 15),
                      label: const Text('بيانات إضافية', style: TextStyle(fontSize: 11.5)),
                      onPressed: () => _showUserInspector(user),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

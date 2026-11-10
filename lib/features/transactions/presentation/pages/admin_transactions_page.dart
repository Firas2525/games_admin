import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/transactions_bloc.dart';
import '../bloc/transactions_event.dart';
import '../bloc/transactions_state.dart';
import '../../domain/entities/transaction_entity.dart';

class AdminTransactionsPage extends StatefulWidget {
  const AdminTransactionsPage({super.key});

  @override
  State<AdminTransactionsPage> createState() => _AdminTransactionsPageState();
}

class _AdminTransactionsPageState extends State<AdminTransactionsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'purchase', 'deposit', 'deduction'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<TransactionsBloc>().add(LoadTransactionsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showReceiptSheet(TransactionEntity tx) {
    final isDeposit = tx.isDeposit;
    final isPurchase = tx.isPurchase;
    final isRefund = tx.isRefund;
    final isDeduction = tx.isDeduction;

    final Color color;
    final String sign;
    final String titleText;
    final IconData headerIcon;

    if (isDeposit) {
      color = const Color(0xFF10B981);
      sign = '+';
      titleText = 'إيصال شحن / تحويل رصيد موثق';
      headerIcon = Icons.add_circle_outline_rounded;
    } else if (isPurchase) {
      color = const Color(0xFF0284C7);
      sign = '-';
      titleText = 'تفاصيل عملية الشراء والربح';
      headerIcon = Icons.shopping_bag_rounded;
    } else if (isRefund) {
      color = const Color(0xFF8B5CF6);
      sign = '+';
      titleText = 'إيصال استرجاع رصيد (إلغاء طلب)';
      headerIcon = Icons.replay_rounded;
    } else if (isDeduction) {
      color = const Color(0xFFF43F5E);
      sign = '-';
      titleText = 'إيصال خصم رصيد يدوي من الإدارة';
      headerIcon = Icons.remove_circle_outline_rounded;
    } else {
      color = const Color(0xFF64748B);
      sign = '';
      titleText = 'قيد مالي موثق';
      headerIcon = Icons.receipt_long_rounded;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomCtx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 30,
                  offset: Offset(0, -6),
                ),
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
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Digital Receipt Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(headerIcon, color: color, size: 32),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        titleText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$sign${tx.amount.toStringAsFixed(tx.isSyp ? 0 : 2)} ${tx.currencySymbol}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                      if (isPurchase && tx.profit > 0) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.trending_up_rounded,
                                color: Color(0xFF34D399),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'صافي الربح: +${tx.profit.toStringAsFixed(tx.isSyp ? 0 : 2)} ${tx.currencySymbol}',
                                style: const TextStyle(
                                  color: Color(0xFF34D399),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (isRefund) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(
                                0xFF8B5CF6,
                              ).withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.replay_rounded,
                                color: Color(0xFFA78BFA),
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'تمت استعادة المبلغ بالكامل إلى محفظة المستخدم',
                                style: TextStyle(
                                  color: Color(0xFFA78BFA),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Financial Breakdown (Cost vs Paid vs Profit)
                if (isPurchase) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131D31),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFinancialMetric(
                          'سعر التكلفة للمزود',
                          '${tx.costPrice.toStringAsFixed(tx.isSyp ? 0 : 2)} ${tx.currencySymbol}',
                          const Color(0xFF94A3B8),
                        ),
                        Container(width: 1, height: 30, color: Colors.white12),
                        _buildFinancialMetric(
                          'ما دفعه المستخدم',
                          '${tx.amount.toStringAsFixed(tx.isSyp ? 0 : 2)} ${tx.currencySymbol}',
                          const Color(0xFF38BDF8),
                        ),
                        Container(width: 1, height: 30, color: Colors.white12),
                        _buildFinancialMetric(
                          'صافي ربح المتجر',
                          '+${tx.profit.toStringAsFixed(tx.isSyp ? 0 : 2)} ${tx.currencySymbol}',
                          const Color(0xFF34D399),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                const Divider(color: Colors.white10),
                const SizedBox(height: 10),

                // Receipt Breakdown Table
                _buildReceiptRow(
                  'المستفيد / المستخدم',
                  tx.userName,
                  Icons.person_rounded,
                ),
                const SizedBox(height: 10),
                if (tx.productName.isNotEmpty) ...[
                  _buildReceiptRow(
                    'المنتج / الباقة',
                    tx.productName,
                    Icons.sports_esports_rounded,
                    valueColor: const Color(0xFFFBBF24),
                  ),
                  const SizedBox(height: 10),
                ],
                if (tx.targetId.isNotEmpty) ...[
                  _buildReceiptRow(
                    'رقم الآيدي / الحساب',
                    tx.targetId,
                    Icons.badge_rounded,
                    valueColor: const Color(0xFF38BDF8),
                  ),
                  const SizedBox(height: 10),
                ],
                if (tx.orderId.isNotEmpty) ...[
                  _buildReceiptRow(
                    'رقم الطلب',
                    '#${tx.orderId}',
                    Icons.receipt_rounded,
                    valueColor: const Color(0xFF38BDF8),
                  ),
                  const SizedBox(height: 10),
                ],
                _buildReceiptRow(
                  'عملة العملية',
                  '${tx.isSyp ? 'ليرة سورية' : 'دولار أمريكي'} (${tx.currency})',
                  Icons.currency_exchange_rounded,
                  valueColor: tx.isSyp ? Colors.amber : const Color(0xFF38BDF8),
                ),
                const SizedBox(height: 10),
                _buildReceiptRow(
                  'معرف العملية المالي',
                  tx.id,
                  Icons.tag_rounded,
                ),
                const SizedBox(height: 10),
                _buildReceiptRow(
                  'تاريخ ووقت التنفيذ',
                  _formatDate(tx.createdAt),
                  Icons.access_time_rounded,
                ),
                const SizedBox(height: 10),
                _buildReceiptRow(
                  'الملاحظة / البيان',
                  tx.note.isNotEmpty
                      ? tx.note
                      : (isDeposit
                            ? 'شحن رصيد نقدي معتمد من الإدارة'
                            : (isRefund
                                  ? 'استرجاع رصيد لمحفظة الزبون'
                                  : (isPurchase
                                        ? 'شراء منتج'
                                        : 'خصم رصيد إداري'))),
                  Icons.notes_rounded,
                ),
                const SizedBox(height: 10),
                _buildReceiptRow(
                  'حالة القيد المالي',
                  'موثق ومكتمل بنجاح ✅',
                  Icons.verified_rounded,
                  valueColor: const Color(0xFF34D399),
                ),

                const SizedBox(height: 22),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('نسخ المعرف'),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: tx.id));
                          Navigator.pop(bottomCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ معرف العملية إلى الحافظة'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(bottomCtx),
                        child: const Text(
                          'إغلاق الإيصال',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinancialMetric(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
        centerTitle: true,
        title: const Text(
          'المالية والعمليات',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16.5,
            color: Colors.white,
          ),
        ),
      ),
      body: BlocBuilder<TransactionsBloc, TransactionsState>(
        builder: (context, state) {
          if (state is TransactionsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0284C7)),
            );
          }

          if (state is TransactionsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFF43F5E),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      context.read<TransactionsBloc>().add(
                        LoadTransactionsEvent(),
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          if (state is TransactionsLoaded) {
            final allList = state.transactions;
            final filteredList = allList.where((t) {
              if (_selectedFilter != 'all' && t.type != _selectedFilter) {
                return false;
              }
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                return t.userName.toLowerCase().contains(q) ||
                    t.note.toLowerCase().contains(q) ||
                    t.id.toLowerCase().contains(q) ||
                    t.productName.toLowerCase().contains(q) ||
                    t.targetId.toLowerCase().contains(q);
              }
              return true;
            }).toList();

            // Financial metrics calculations (Strict separation of USD & SYP)
            final double rawProfitsUsd =
                allList
                    .where((t) => t.isPurchase && !t.isSyp)
                    .fold(0.0, (sum, t) => sum + t.profit) -
                allList
                    .where((t) => t.isRefund && !t.isSyp)
                    .fold(0.0, (sum, t) => sum + t.profit);
            final double totalProfitsUsd = rawProfitsUsd > 0
                ? double.parse(rawProfitsUsd.toStringAsFixed(2))
                : 0.0;

            final double rawProfitsSyp =
                allList
                    .where((t) => t.isPurchase && t.isSyp)
                    .fold(0.0, (sum, t) => sum + t.profit) -
                allList
                    .where((t) => t.isRefund && t.isSyp)
                    .fold(0.0, (sum, t) => sum + t.profit);
            final double totalProfitsSyp = rawProfitsSyp > 0
                ? double.parse(rawProfitsSyp.toStringAsFixed(0))
                : 0.0;

            final double rawCostUsd =
                allList
                    .where((t) => t.isPurchase && !t.isSyp)
                    .fold(0.0, (sum, t) => sum + t.costPrice) -
                allList
                    .where((t) => t.isRefund && !t.isSyp)
                    .fold(0.0, (sum, t) => sum + t.costPrice);
            final double totalCostToProviders = rawCostUsd > 0
                ? double.parse(rawCostUsd.toStringAsFixed(2))
                : 0.0;

            final double rawCostSyp =
                allList
                    .where((t) => t.isPurchase && t.isSyp)
                    .fold(0.0, (sum, t) => sum + t.costPrice) -
                allList
                    .where((t) => t.isRefund && t.isSyp)
                    .fold(0.0, (sum, t) => sum + t.costPrice);
            final double totalCostToProvidersSyp = rawCostSyp > 0
                ? double.parse(rawCostSyp.toStringAsFixed(0))
                : 0.0;

            final double rawPaidUsd =
                allList
                    .where((t) => t.isPurchase && !t.isSyp)
                    .fold(0.0, (sum, t) => sum + t.amount) -
                allList
                    .where((t) => t.isRefund && !t.isSyp)
                    .fold(0.0, (sum, t) => sum + t.amount);
            final double totalPaidByUsers = rawPaidUsd > 0
                ? double.parse(rawPaidUsd.toStringAsFixed(2))
                : 0.0;

            final double rawPaidSyp =
                allList
                    .where((t) => t.isPurchase && t.isSyp)
                    .fold(0.0, (sum, t) => sum + t.amount) -
                allList
                    .where((t) => t.isRefund && t.isSyp)
                    .fold(0.0, (sum, t) => sum + t.amount);
            final double totalPaidByUsersSyp = rawPaidSyp > 0
                ? double.parse(rawPaidSyp.toStringAsFixed(0))
                : 0.0;

            final double rawDepositsUsd = allList
                .where((t) => t.isDeposit && !t.isSyp)
                .fold(0.0, (sum, t) => sum + t.amount);
            final double depositsUsd = double.parse(
              rawDepositsUsd.toStringAsFixed(2),
            );

            final double rawDepositsSyp = allList
                .where((t) => t.isDeposit && t.isSyp)
                .fold(0.0, (sum, t) => sum + t.amount);
            final double depositsSyp = double.parse(
              rawDepositsSyp.toStringAsFixed(0),
            );

            final double rawRefunds = allList
                .where((t) => t.isRefund && !t.isSyp)
                .fold(0.0, (sum, t) => sum + t.amount);
            final double totalRefundsUsd = double.parse(
              rawRefunds.toStringAsFixed(2),
            );
            final double rawRefundsSyp = allList
                .where((t) => t.isRefund && t.isSyp)
                .fold(0.0, (sum, t) => sum + t.amount);
            final double totalRefundsSyp = double.parse(
              rawRefundsSyp.toStringAsFixed(0),
            );

            final double rawDeductions = allList
                .where((t) => t.isDeduction && !t.isSyp)
                .fold(0.0, (sum, t) => sum + t.amount);
            final double totalDeductionsUsd = double.parse(
              rawDeductions.toStringAsFixed(2),
            );
            final double rawDeductionsSyp = allList
                .where((t) => t.isDeduction && t.isSyp)
                .fold(0.0, (sum, t) => sum + t.amount);
            final double totalDeductionsSyp = double.parse(
              rawDeductionsSyp.toStringAsFixed(0),
            );

            return RefreshIndicator(
              color: const Color(0xFF0284C7),
              backgroundColor: const Color(0xFF0F172A),
              onRefresh: () async {
                context.read<TransactionsBloc>().add(LoadTransactionsEvent());
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // KPI Summary Cards: Executive Financial Board (USD & SYP Net Profits Separated)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 10.0,
                      ),
                      child: Column(
                        children: [
                          // Row 1: Net Profit USD vs Net Profit SYP
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  title: 'صافي الربح دولار (USD)',
                                  value:
                                      '+\$${totalProfitsUsd.toStringAsFixed(2)}',
                                  subtitle: 'صافي أرباح مبيعات الدولار',
                                  color: const Color(0xFF10B981),
                                  icon: Icons.trending_up_rounded,
                                  isHighlighted: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildSummaryCard(
                                  title: 'صافي الربح سوري (SYP)',
                                  value:
                                      '+${totalProfitsSyp.toStringAsFixed(0)} ل.س',
                                  subtitle: 'صافي أرباح مبيعات السوري',
                                  color: const Color(0xFF14B8A6),
                                  icon: Icons.insights_rounded,
                                  isHighlighted: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Row 2: Provider Cost, Admin Deposits, Customer Purchases
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  title: 'المدفوع لمواقع الشراء',
                                  value:
                                      '\$${totalCostToProviders.toStringAsFixed(2)}',
                                  subtitle: totalCostToProvidersSyp > 0
                                      ? '+ ${totalCostToProvidersSyp.toStringAsFixed(0)} ل.س'
                                      : 'تكلفة المزود الأصلية',
                                  color: const Color(0xFF94A3B8),
                                  icon: Icons.inventory_2_rounded,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildSummaryCard(
                                  title: 'المحول للمستخدمين',
                                  value: '+\$${depositsUsd.toStringAsFixed(2)}',
                                  subtitle: depositsSyp > 0
                                      ? '+ ${depositsSyp.toStringAsFixed(0)} ل.س'
                                      : 'شحن رصيد معتمد',
                                  color: const Color(0xFFF59E0B),
                                  icon: Icons.account_balance_wallet_rounded,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildSummaryCard(
                                  title: 'ما دفعه المستخدمون',
                                  value:
                                      '\$${totalPaidByUsers.toStringAsFixed(2)}',
                                  subtitle: totalPaidByUsersSyp > 0
                                      ? '+ ${totalPaidByUsersSyp.toStringAsFixed(0)} ل.س'
                                      : 'صافي مشتريات الزبائن',
                                  color: const Color(0xFF0284C7),
                                  icon: Icons.payments_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Row 3: Refunds Returned, Manual Deductions
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  title: 'ما يعود بالإرجاع',
                                  value:
                                      '+\$${totalRefundsUsd.toStringAsFixed(2)}',
                                  subtitle: totalRefundsSyp > 0
                                      ? '+ ${totalRefundsSyp.toStringAsFixed(0)} ل.س'
                                      : 'استرجاع إلغاء الطلبات',
                                  color: const Color(0xFF8B5CF6),
                                  icon: Icons.replay_rounded,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildSummaryCard(
                                  title: 'ما يخصمه الأدمن',
                                  value:
                                      '-\$${totalDeductionsUsd.toStringAsFixed(2)}',
                                  subtitle: totalDeductionsSyp > 0
                                      ? '- ${totalDeductionsSyp.toStringAsFixed(0)} ل.س'
                                      : 'خصومات إدارية يدوية',
                                  color: const Color(0xFFF43F5E),
                                  icon: Icons.remove_circle_outline_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search and Filter Bar
                  SliverToBoxAdapter(
                    child: Container(
                      color: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          // Search Input
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'بحث باسم المستخدم أو المنتج أو الآيدي أو المعرف...',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  fontSize: 12,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: Color(0xFF38BDF8),
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear_rounded,
                                          size: 18,
                                          color: Colors.white60,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: const Color(0xFF131D31),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                              ),
                              onChanged: (val) {
                                setState(() => _searchQuery = val.trim());
                              },
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Filter Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                _buildFilterChip(
                                  'الكل (${allList.length})',
                                  'all',
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  'أرباح ومشتريات (${allList.where((t) => t.isPurchase).length})',
                                  'purchase',
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  'شحن معتمد (${allList.where((t) => t.isDeposit).length})',
                                  'deposit',
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  'استرجاع رصيد (${allList.where((t) => t.isRefund).length})',
                                  'refund',
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  'خصم يدوي (${allList.where((t) => t.isDeduction).length})',
                                  'deduction',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // List of Transactions
                  if (filteredList.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.white.withValues(alpha: 0.2),
                              size: 48,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'لا توجد نتائج تطابق بحثك'
                                  : 'لا توجد قيود مالية حتى الآن',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final tx = filteredList[index];
                          return _buildTransactionCard(tx);
                        }, childCount: filteredList.length),
                      ),
                    ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    String? subtitle,
    required Color color,
    required IconData icon,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      decoration: BoxDecoration(
        color: isHighlighted
            ? color.withValues(alpha: 0.12)
            : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? color.withValues(alpha: 0.5)
              : color.withValues(alpha: 0.2),
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 16, color: color),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: isHighlighted ? color : Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 8.5, color: Colors.grey.shade400),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: const Color(0xFF0284C7).withValues(alpha: 0.25),
      backgroundColor: const Color(0xFF131D31),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0284C7) : Colors.white10,
        ),
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

  Widget _buildTransactionCard(TransactionEntity tx) {
    final isDeposit = tx.isDeposit;
    final isPurchase = tx.isPurchase;
    final isRefund = tx.isRefund;
    final isDeduction = tx.isDeduction;

    final Color color;
    final String sign;
    final String typeBadge;
    final IconData icon;

    if (isDeposit) {
      color = const Color(0xFF10B981);
      sign = '+';
      typeBadge = 'شحن معتمد';
      icon = Icons.add_circle_outline_rounded;
    } else if (isPurchase) {
      color = const Color(0xFF0284C7);
      sign = '-';
      typeBadge = 'شراء منتج';
      icon = Icons.shopping_bag_rounded;
    } else if (isRefund) {
      color = const Color(0xFF8B5CF6);
      sign = '+';
      typeBadge = 'استرجاع ↩️';
      icon = Icons.replay_rounded;
    } else if (isDeduction) {
      color = const Color(0xFFF43F5E);
      sign = '-';
      typeBadge = 'خصم يدوي';
      icon = Icons.remove_circle_outline_rounded;
    } else {
      color = const Color(0xFF64748B);
      sign = '';
      typeBadge = 'عملية مالية';
      icon = Icons.receipt_long_rounded;
    }

    return InkWell(
      onTap: () => _showReceiptSheet(tx),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPurchase && tx.profit > 0
                ? const Color(0xFF10B981).withValues(alpha: 0.25)
                : (isRefund
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.07)),
          ),
        ),
        child: Row(
          children: [
            // Icon Circle
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),

            // User name & note & date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tx.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPurchase && tx.profit > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.3),
                              width: 0.7,
                            ),
                          ),
                          child: Text(
                            'ربح +${tx.profit.toStringAsFixed(tx.isSyp ? 0 : 2)} ${tx.currencySymbol}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF34D399),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                      if (isRefund) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(
                                0xFF8B5CF6,
                              ).withValues(alpha: 0.3),
                              width: 0.7,
                            ),
                          ),
                          child: const Text(
                            'مسترجع بالكامل',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFFA78BFA),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tx.productName.isNotEmpty
                        ? '${tx.productName}${tx.targetId.isNotEmpty ? ' (${tx.targetId})' : ''}'
                        : (tx.note.isNotEmpty
                              ? tx.note
                              : (isDeposit
                                    ? 'شحن رصيد نقدي'
                                    : (isRefund
                                          ? 'استرجاع رصيد الطلب'
                                          : 'خصم رصيد'))),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        _formatDate(tx.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131D31),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          typeBadge,
                          style: TextStyle(
                            fontSize: 9,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (tx.isSyp
                                      ? Colors.amber
                                      : const Color(0xFF10B981))
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color:
                                (tx.isSyp
                                        ? Colors.amber
                                        : const Color(0xFF10B981))
                                    .withValues(alpha: 0.3),
                            width: 0.7,
                          ),
                        ),
                        child: Text(
                          tx.currency,
                          style: TextStyle(
                            fontSize: 8.5,
                            color: tx.isSyp
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFF34D399),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Financial Summary Tag on right
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '$sign${tx.amount.toStringAsFixed(tx.isSyp ? 0 : 2)} ${tx.currencySymbol}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: color,
                    ),
                  ),
                ),
                if (isPurchase && tx.costPrice > 0) ...[
                  const SizedBox(height: 3),
                  Text(
                    'التكلفة: ${tx.costPrice.toStringAsFixed(tx.isSyp ? 0 : 2)} ${tx.currencySymbol}',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
                if (isRefund) ...[
                  const SizedBox(height: 3),
                  const Text(
                    'إرجاع للمحفظة ↩️',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFFA78BFA),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/app_network_image.dart';

class AdminVerificationField {
  String id;
  String name;
  String type; // 'text' | 'image'
  bool required;

  AdminVerificationField({
    required this.id,
    required this.name,
    this.type = 'text',
    this.required = true,
  });

  factory AdminVerificationField.fromJson(dynamic json) {
    if (json is String) {
      final s = json.trim();
      return AdminVerificationField(id: s, name: s, type: 'text', required: true);
    }
    if (json is Map) {
      final n = (json['name'] ?? json['label'] ?? json['id'] ?? '').toString().trim();
      final id = (json['id'] ?? n).toString().trim();
      final type = json['type'] == 'image' ? 'image' : 'text';
      final req = json['required'] != false;
      return AdminVerificationField(
        id: id.isNotEmpty ? id : n,
        name: n.isNotEmpty ? n : id,
        type: type,
        required: req,
      );
    }
    return AdminVerificationField(id: 'field', name: 'حقل', type: 'text', required: true);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'required': required,
  };
}

class AdminVerificationRequestsPage extends StatefulWidget {
  const AdminVerificationRequestsPage({super.key});

  @override
  State<AdminVerificationRequestsPage> createState() => _AdminVerificationRequestsPageState();
}

class _AdminVerificationRequestsPageState extends State<AdminVerificationRequestsPage> {
  bool _isLoading = true;
  String _selectedStatus = 'pending'; // all, pending, approved, rejected
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _requests = [];
  List<AdminVerificationField> _requiredFields = [
    AdminVerificationField(id: 'full_name', name: 'الاسم الثلاثي', type: 'text', required: true),
  ];
  final Set<String> _expandedRequestIds = <String>{};
  Map<String, int> _counts = {
    'all': 0,
    'pending': 0,
    'approved': 0,
    'rejected': 0,
  };

  final Color _kBg = const Color(0xFF07111F);
  final Color _kCard = const Color(0xFF0F172A);
  final Color _kInner = const Color(0xFF131F35);
  final Color _kPrimary = const Color(0xFF0284C7);
  final Color _kGreen = const Color(0xFF10B981);
  final Color _kAmber = const Color(0xFFF59E0B);
  final Color _kRed = const Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final dio = sl<ApiClient>().dio;
      final q = <String, dynamic>{};
      if (_selectedStatus != 'all') q['status'] = _selectedStatus;
      if (_searchController.text.trim().isNotEmpty) {
        q['search'] = _searchController.text.trim();
      }

      final res = await dio.get('/verification/admin/requests', queryParameters: q);
      if (res.data != null && res.data['data'] != null) {
        final d = res.data['data'];
        setState(() {
          _requests = (d['requests'] as List?) ?? [];
          if (d['requiredFields'] is List) {
            _requiredFields = (d['requiredFields'] as List)
                .map((e) => AdminVerificationField.fromJson(e))
                .where((f) => f.name.isNotEmpty)
                .toList();
            if (_requiredFields.isEmpty) {
              _requiredFields = [
                AdminVerificationField(id: 'full_name', name: 'الاسم الثلاثي', type: 'text', required: true),
              ];
            }
          }
          if (d['counts'] is Map) {
            final c = d['counts'] as Map;
            _counts = {
              'all': (c['all'] as num?)?.toInt() ?? 0,
              'pending': (c['pending'] as num?)?.toInt() ?? 0,
              'approved': (c['approved'] as num?)?.toInt() ?? 0,
              'rejected': (c['rejected'] as num?)?.toInt() ?? 0,
            };
          }
          final validIds = _requests.map((r) => r['_id']?.toString() ?? '').toSet();
          _expandedRequestIds.removeWhere((id) => !validIds.contains(id));
          if (_requests.length == 1) {
            _expandedRequestIds.add(_requests.first['_id']?.toString() ?? '');
          }
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحميل طلبات التوثيق: $e'), backgroundColor: _kRed),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _updateStatus(String requestId, String status, {String rejectionReason = ''}) async {
    try {
      final dio = sl<ApiClient>().dio;
      final payload = <String, dynamic>{
        'status': status,
      };
      if (status == 'rejected') {
        payload['rejectionReason'] = rejectionReason;
      }

      await dio.patch('/verification/admin/requests/$requestId/status', data: payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved'
                  ? '✅ تم قبول طلب التوثيق بنجاح وأصبح الحساب موثقاً'
                  : 'تم رفض طلب التوثيق وحفظ السبب للمستخدم',
            ),
            backgroundColor: status == 'approved' ? _kGreen : _kAmber,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحديث الحالة: $e'), backgroundColor: _kRed),
        );
      }
    }
  }

  void _showApproveDialog(dynamic req) {
    final userName = (req['userName'] ?? 'المستخدم').toString();
    final userCode = (req['userCode'] ?? '').toString();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _kInner,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 22),
              SizedBox(width: 8),
              Text('الموافقة على توثيق الحساب', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Text(
            'هل أنت متأكد من قبول توثيق حساب "$userName" (#$userCode)؟\n\nستتم ترقية الحساب إلى موثق رسميًا وتظهر الشارة الزرقاء بجانب اسمه مباشرةً.',
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: const Color(0xFF064E3B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: const Text('تأكيد القبول والتفعيل', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(ctx);
                _updateStatus(req['_id'], 'approved');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(dynamic req) {
    final noteCtrl = TextEditingController();
    final userName = (req['userName'] ?? 'المستخدم').toString();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _kInner,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 22),
              SizedBox(width: 8),
              Text('رفض طلب التوثيق', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تحديد سبب رفض طلب "$userName" (يظهر للمستخدم ليتمكن من تصحيحه):',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'مثال: الصورة غير واضحة، الهوية منتهية الصلاحية، الاسم لا يطابق الحساب...',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                  filled: true,
                  fillColor: _kCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final reason = noteCtrl.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى كتابة سبب الرفض لتوضيحه للمستخدم'), backgroundColor: Colors.redAccent),
                  );
                  return;
                }
                Navigator.pop(ctx);
                _updateStatus(req['_id'], 'rejected', rejectionReason: reason);
              },
              child: const Text('تأكيد الرفض'),
            ),
          ],
        ),
      ),
    );
  }

  void _showManageFieldsDialog() {
    final newFieldCtrl = TextEditingController();
    String newFieldType = 'text'; // 'text' or 'image'
    bool newFieldRequired = true;
    final tempFields = _requiredFields
        .map((f) => AdminVerificationField(
              id: f.id,
              name: f.name,
              type: f.type,
              required: f.required,
            ))
        .toList();
    bool isSaving = false;

    final suggestions = [
      {'name': 'الاسم الثلاثي', 'type': 'text'},
      {'name': 'صورة الهوية وجه أول', 'type': 'image'},
      {'name': 'صورة الهوية وجه ثاني', 'type': 'image'},
      {'name': 'صورة سيلفي مع الهوية', 'type': 'image'},
      {'name': 'الرقم الوطني / رقم الهوية', 'type': 'text'},
      {'name': 'تاريخ ومكان الولادة', 'type': 'text'},
      {'name': 'مكان الإقامة الحالي', 'type': 'text'},
      {'name': 'صورة جواز السفر', 'type': 'image'},
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: _kInner,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Color(0xFF38BDF8), size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'إدارة الحقول المطلوبة للتوثيق ⚙️',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'حدد الحقول التي يجب على المستخدم تقديمها عند إرسال طلب التوثيق (صورة أو نص):',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                    ),
                    const SizedBox(height: 14),

                    // Current fields
                    Row(
                      children: [
                        const Text(
                          'الحقول المحددة حالياً:',
                          style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          '${tempFields.length} حقول',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (tempFields.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _kCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Text(
                          'لا توجد حقول محددة',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          color: _kCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: tempFields.length,
                          separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                          itemBuilder: (ctx, idx) {
                            final field = tempFields[idx];
                            final isImage = field.type == 'image';
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: (isImage ? const Color(0xFFA855F7) : const Color(0xFF0284C7))
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  isImage ? Icons.image_rounded : Icons.text_fields_rounded,
                                  size: 16,
                                  color: isImage ? const Color(0xFFC084FC) : const Color(0xFF38BDF8),
                                ),
                              ),
                              title: Text(
                                field.name,
                                style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: (isImage ? const Color(0xFFA855F7) : const Color(0xFF0284C7))
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isImage ? '📸 صورة مرفقة' : '📝 نص يكتبه المستخدم',
                                      style: TextStyle(
                                        color: isImage ? const Color(0xFFC084FC) : const Color(0xFF38BDF8),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        field.required = !field.required;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: (field.required ? const Color(0xFF10B981) : Colors.white24)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        field.required ? 'إجباري' : 'اختياري',
                                        style: TextStyle(
                                          color: field.required ? const Color(0xFF34D399) : Colors.white60,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                onPressed: () {
                                  setDialogState(() {
                                    tempFields.removeAt(idx);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 16),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 10),

                    // Add new field input
                    const Text(
                      'إضافة حقل جديد مخصص:',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: newFieldCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'مثال: صورة الهوية وجه أول أو مكان الإقامة...',
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                        filled: true,
                        fillColor: _kCard,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Type selector & Required toggle
                    Row(
                      children: [
                        const Text('نوع الحقل:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          selectedColor: const Color(0xFF0284C7).withValues(alpha: 0.3),
                          backgroundColor: _kCard,
                          side: BorderSide(
                            color: newFieldType == 'text' ? const Color(0xFF0284C7) : Colors.white12,
                          ),
                          avatar: Icon(
                            Icons.text_fields_rounded,
                            size: 14,
                            color: newFieldType == 'text' ? const Color(0xFF38BDF8) : Colors.white60,
                          ),
                          label: Text(
                            'نص 📝',
                            style: TextStyle(
                              color: newFieldType == 'text' ? Colors.white : Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: newFieldType == 'text',
                          onSelected: (val) {
                            if (val) setDialogState(() => newFieldType = 'text');
                          },
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          selectedColor: const Color(0xFFA855F7).withValues(alpha: 0.3),
                          backgroundColor: _kCard,
                          side: BorderSide(
                            color: newFieldType == 'image' ? const Color(0xFFA855F7) : Colors.white12,
                          ),
                          avatar: Icon(
                            Icons.image_rounded,
                            size: 14,
                            color: newFieldType == 'image' ? const Color(0xFFC084FC) : Colors.white60,
                          ),
                          label: Text(
                            'صورة 📸',
                            style: TextStyle(
                              color: newFieldType == 'image' ? Colors.white : Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: newFieldType == 'image',
                          onSelected: (val) {
                            if (val) setDialogState(() => newFieldType = 'image');
                          },
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            setDialogState(() => newFieldRequired = !newFieldRequired);
                          },
                          child: Row(
                            children: [
                              Checkbox(
                                value: newFieldRequired,
                                activeColor: const Color(0xFF0284C7),
                                onChanged: (v) => setDialogState(() => newFieldRequired = v ?? true),
                              ),
                              const Text('إجباري', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('إضافة الحقل إلى القائمة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                        onPressed: () {
                          final val = newFieldCtrl.text.trim();
                          if (val.isEmpty) return;
                          if (tempFields.any((f) => f.name == val)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('هذا الحقل موجود بالفعل')),
                            );
                            return;
                          }
                          setDialogState(() {
                            tempFields.add(AdminVerificationField(
                              id: 'field_${DateTime.now().millisecondsSinceEpoch}',
                              name: val,
                              type: newFieldType,
                              required: newFieldRequired,
                            ));
                            newFieldCtrl.clear();
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 14),
                    // Suggestions
                    const Text(
                      'اقتراحات سريعة للإضافة:',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: suggestions
                          .where((s) => !tempFields.any((f) => f.name == s['name']))
                          .map((s) {
                            final sName = s['name'] as String;
                            final sType = s['type'] as String;
                            final isImg = sType == 'image';
                            return InkWell(
                              onTap: () {
                                setDialogState(() {
                                  tempFields.add(AdminVerificationField(
                                    id: 'field_${DateTime.now().millisecondsSinceEpoch}',
                                    name: sName,
                                    type: sType,
                                    required: true,
                                  ));
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isImg ? Icons.add_a_photo_rounded : Icons.add_rounded,
                                      size: 13,
                                      color: isImg ? const Color(0xFFC084FC) : const Color(0xFF38BDF8),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$sName (${isImg ? 'صورة' : 'نص'})',
                                      style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: const Color(0xFF064E3B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF064E3B)),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  isSaving ? 'جارٍ الحفظ...' : 'حفظ التغييرات 💾',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        setDialogState(() => isSaving = true);
                        try {
                          final dio = sl<ApiClient>().dio;
                          await dio.post('/verification/admin/fields', data: {
                            'fields': tempFields.map((f) => f.toJson()).toList(),
                          });

                          setState(() {
                            _requiredFields = List<AdminVerificationField>.from(tempFields);
                          });

                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ تم حفظ وتحديث حقول التوثيق بنجاح!'),
                                backgroundColor: Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('فشل حفظ الحقول: $e'), backgroundColor: Colors.redAccent),
                            );
                          }
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePreviewDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AppNetworkImage(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ $label: $text'),
        backgroundColor: _kPrimary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw.toString())?.toLocal();
    if (dt == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}/${two(dt.month)}/${two(dt.day)}  ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kCard,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 20,
              textDirection: TextDirection.ltr,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'طلبات توثيق الحسابات 🛡️',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.5),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.tune_rounded, color: Color(0xFF38BDF8), size: 18),
              ),
              tooltip: 'إدارة الحقول المطلوبة للتوثيق',
              onPressed: _showManageFieldsDialog,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Filter Pills & Search Header
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              color: _kCard,
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: _kInner,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 12.5),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _loadRequests(),
                      decoration: InputDecoration(
                        hintText: 'بحث بالاسم، الإيميل، الهاتف، كود المستخدم...',
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white38, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  _loadRequests();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Filter Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterPill('قيد الانتظار', 'pending', _kAmber, _counts['pending'] ?? 0),
                        const SizedBox(width: 8),
                        _buildFilterPill('المقبولة', 'approved', _kGreen, _counts['approved'] ?? 0),
                        const SizedBox(width: 8),
                        _buildFilterPill('المرفوضة', 'rejected', _kRed, _counts['rejected'] ?? 0),
                        const SizedBox(width: 8),
                        _buildFilterPill('الكل', 'all', _kPrimary, _counts['all'] ?? 0),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Summary & Expand/Collapse All Bar
            if (!_isLoading && _requests.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                color: _kBg,
                child: Row(
                  children: [
                    Text(
                      'إجمالي الطلبات المعروضة: ${_requests.length}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (_expandedRequestIds.length == _requests.length) {
                            _expandedRequestIds.clear();
                          } else {
                            _expandedRequestIds.addAll(
                              _requests.map((r) => r['_id']?.toString() ?? ''),
                            );
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _expandedRequestIds.length == _requests.length
                                  ? Icons.unfold_less_rounded
                                  : Icons.unfold_more_rounded,
                              size: 15,
                              color: const Color(0xFF38BDF8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _expandedRequestIds.length == _requests.length ? 'طي الكل' : 'توسيع الكل',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
                  : _requests.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: _kPrimary,
                          backgroundColor: _kCard,
                          onRefresh: _loadRequests,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            itemCount: _requests.length,
                            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                            itemBuilder: (ctx, i) => _buildRequestCard(_requests[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, String value, Color color, int count) {
    final isSel = _selectedStatus == value;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        if (_selectedStatus != value) {
          setState(() => _selectedStatus = value);
          _loadRequests();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? color.withValues(alpha: 0.22) : _kInner,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSel ? color : Colors.white12, width: isSel ? 1.4 : 1),
          boxShadow: isSel ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8)] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSel ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSel ? color.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSel ? Colors.white : Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, size: 56, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          const Text(
            'لا توجد طلبات توثيق في هذا القسم',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedStatus == 'pending'
                ? 'كافة طلبات التوثيق تمت معالجتها بالكامل! ✨'
                : 'جرب تغيير شروط الفلترة أو البحث',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(dynamic req) {
    final requestId = req['_id']?.toString() ?? '';
    final isExpanded = _expandedRequestIds.contains(requestId);

    final status = (req['status'] ?? 'pending').toString();
    final isPending = status == 'pending';
    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';

    final userName = (req['userName'] ?? 'مستخدم').toString();
    final userEmail = (req['userEmail'] ?? '').toString();
    final userPhone = (req['userPhone'] ?? '').toString();
    final userCode = (req['userCode'] ?? '').toString();
    final documentUrl = (req['documentUrl'] ?? '').toString();
    final notes = (req['notes'] ?? '').toString();
    final rejectionReason = (req['rejectionReason'] ?? '').toString();
    final reviewedByName = (req['reviewedByName'] ?? 'الإدارة').toString();
    final createdAt = _formatDate(req['createdAt']);

    final Map<String, dynamic> fieldsData = (req['fieldsData'] is Map)
        ? Map<String, dynamic>.from(req['fieldsData'])
        : {};

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isApproved) {
      statusColor = _kGreen;
      statusText = 'موثق ومقبول ✅';
      statusIcon = Icons.check_circle_rounded;
    } else if (isRejected) {
      statusColor = _kRed;
      statusText = 'مرفوض ❌';
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = _kAmber;
      statusText = 'قيد الانتظار ⏳';
      statusIcon = Icons.hourglass_top_rounded;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? statusColor.withValues(alpha: 0.55)
              : (isPending ? _kAmber.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08)),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded
                ? statusColor.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.22),
            blurRadius: isExpanded ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedRequestIds.remove(requestId);
              } else {
                _expandedRequestIds.add(requestId);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Compact Clickable Header (Always visible)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Status avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: statusColor.withValues(alpha: 0.16),
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // User name + Code + Date + Quick summary
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isApproved) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 15),
                              ],
                              if (userCode.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: _kPrimary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '#$userCode',
                                    style: const TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                createdAt,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
                              ),
                              if (!isExpanded) ...[
                                if (documentUrl.isNotEmpty) ...[
                                  Text(
                                    ' • ',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                                  ),
                                  const Icon(Icons.attach_file_rounded, size: 12, color: Color(0xFF38BDF8)),
                                  const SizedBox(width: 2),
                                  const Text(
                                    'صورة',
                                    style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5),
                                  ),
                                ],
                                if (fieldsData.isNotEmpty) ...[
                                  Text(
                                    ' • ',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                                  ),
                                  Text(
                                    '${fieldsData.length} حقول',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10.5),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status Badge + Expand / Collapse arrow button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, color: statusColor, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isExpanded ? 'طي الطلب' : 'عرض التفاصيل',
                              style: TextStyle(
                                color: isExpanded ? statusColor : Colors.white38,
                                fontSize: 10.5,
                                fontWeight: isExpanded ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              size: 17,
                              color: isExpanded ? statusColor : Colors.white38,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                // 2. Expanded Body (Visible only when expanded)
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 12),

                  // Contact Details
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kInner,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      children: [
                        if (userPhone.isNotEmpty)
                          _buildDetailRow(
                            icon: Icons.phone_android_rounded,
                            label: 'رقم الهاتف:',
                            value: userPhone,
                            copyable: true,
                          ),
                        if (userPhone.isNotEmpty && userEmail.isNotEmpty)
                          const SizedBox(height: 5),
                        if (userEmail.isNotEmpty)
                          _buildDetailRow(
                            icon: Icons.email_outlined,
                            label: 'البريد الإلكتروني:',
                            value: userEmail,
                            copyable: true,
                          ),
                        if (notes.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          _buildDetailRow(
                            icon: Icons.notes_rounded,
                            label: 'ملاحظات المستخدم:',
                            value: notes,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Custom Required Fields Data filled by User
                  if (fieldsData.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _kInner,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.assignment_ind_rounded, size: 15, color: Color(0xFF38BDF8)),
                              const SizedBox(width: 6),
                              const Text(
                                'البيانات والحقول المدخلة:',
                                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: _kPrimary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${fieldsData.length} حقول',
                                  style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...fieldsData.entries.map((entry) {
                                final key = entry.key;
                                final val = entry.value?.toString().trim() ?? '';
                                final isImage = val.startsWith('http://') ||
                                    val.startsWith('https://') ||
                                    val.startsWith('data:image/') ||
                                    val.contains('/uploads/');

                                if (isImage && val.isNotEmpty) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _kCard,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.image_rounded, size: 14, color: Color(0xFFC084FC)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                key,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            TextButton.icon(
                                              style: TextButton.styleFrom(
                                                visualDensity: VisualDensity.compact,
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              ),
                                              onPressed: () => _showImagePreviewDialog(val),
                                              icon: const Icon(Icons.fullscreen_rounded, size: 14, color: Color(0xFF38BDF8)),
                                              label: const Text('تكبير', style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8))),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        InkWell(
                                          onTap: () => _showImagePreviewDialog(val),
                                          borderRadius: BorderRadius.circular(8),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: SizedBox(
                                              height: 140,
                                              width: double.infinity,
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  AppNetworkImage(val, fit: BoxFit.cover),
                                                  Positioned(
                                                    bottom: 4,
                                                    right: 4,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black87,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.zoom_in_rounded, size: 12, color: Colors.white),
                                                          SizedBox(width: 3),
                                                          Text('اضغط للتكبير', style: TextStyle(color: Colors.white, fontSize: 10)),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: _buildDetailRow(
                                    icon: Icons.check_circle_outline_rounded,
                                    label: '$key:',
                                    value: val,
                                    copyable: true,
                                  ),
                                );
                              }),
                        ],
                      ),
                    ),
                  ],

                  // Document Image Preview
                  if (documentUrl.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.attachment_rounded, size: 14, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 5),
                        const Text(
                          'صورة وثيقة الهوية:',
                          style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          ),
                          onPressed: () => _showImagePreviewDialog(documentUrl),
                          icon: const Icon(Icons.fullscreen_rounded, size: 15, color: Color(0xFF38BDF8)),
                          label: const Text('تكبير ومعاينة', style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _showImagePreviewDialog(documentUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          color: _kInner,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AppNetworkImage(documentUrl, fit: BoxFit.cover),
                              Positioned(
                                bottom: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.zoom_in_rounded, size: 13, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text('اضغط للتكبير', style: TextStyle(color: Colors.white, fontSize: 10.5)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Rejection Reason display if rejected
                  if (isRejected && rejectionReason.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _kRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kRed.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 15),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'سبب الرفض: $rejectionReason',
                              style: const TextStyle(color: Colors.redAccent, fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Approved Info display if approved
                  if (isApproved) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'تم اعتماد التوثيق رسمياً بواسطة $reviewedByName',
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 11),
                      ),
                    ),
                  ],

                  // Action Buttons if pending
                  if (isPending) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kGreen,
                              foregroundColor: const Color(0xFF064E3B),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.check_circle_rounded, size: 17),
                            label: const Text('قبول التوثيق ✅', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                            onPressed: () => _showApproveDialog(req),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kRed,
                              side: BorderSide(color: _kRed),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.cancel_rounded, size: 16),
                            label: const Text('رفض ❌', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            onPressed: () => _showRejectDialog(req),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool copyable = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (copyable) ...[
          InkWell(
            onTap: () => _copy(value, label),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(Icons.copy_rounded, size: 13, color: Color(0xFF38BDF8)),
            ),
          ),
        ],
      ],
    );
  }
}


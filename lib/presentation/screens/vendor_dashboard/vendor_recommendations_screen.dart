import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';

class VendorRecommendationsScreen extends ConsumerStatefulWidget {
  const VendorRecommendationsScreen({super.key});

  @override
  ConsumerState<VendorRecommendationsScreen> createState() =>
      _VendorRecommendationsScreenState();
}

class _VendorRecommendationsScreenState
    extends ConsumerState<VendorRecommendationsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final user = ref.watch(authProvider).asData?.value;
    final vendorId = user?.id ?? '';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.cream,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        title: Text(
          'Recommended Partners',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark ? Colors.white : AppColors.deepNavy,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppColors.deepNavy,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddRecommendationModal(context, isDark, vendorId),
        backgroundColor: AppColors.roseGold,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text(
          'Recommend Partner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: vendorId.isEmpty
          ? Center(
              child: Text(
                'Please log in as a vendor.',
                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vendor_registrations')
                  .doc(vendorId)
                  .collection('recommendations')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.roseGold),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.handshake_outlined,
                            size: 64,
                            color: isDark ? Colors.white30 : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Recommended Partners Yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.deepNavy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Recommend trusted vendors (Photographers, Salons, Venues, etc.) to your clients to boost mutual bookings!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _openAddRecommendationModal(context, isDark, vendorId),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add First Recommendation'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.roseGold,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final recData = docs[index].data() as Map<String, dynamic>;
                    final recDocId = docs[index].id;
                    final partnerId = recData['partner_id'] ?? '';
                    final note = recData['note'] ?? '';

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('vendor_registrations')
                          .doc(partnerId)
                          .get(),
                      builder: (context, partnerSnap) {
                        if (!partnerSnap.hasData) {
                          return Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.roseGold,
                              ),
                            ),
                          );
                        }

                        final partner =
                            partnerSnap.data?.data() as Map<String, dynamic>? ??
                                {};
                        final name = partner['name'] ?? 'Vendor';
                        final category = (partner['category'] ?? 'Vendor')
                            .toString()
                            .replaceAll('_', ' ')
                            .toUpperCase();
                        final district = partner['district'] ?? 'Sri Lanka';
                        final rating =
                            (partner['rating'] as num?)?.toDouble() ?? 0.0;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.roseGold.withValues(alpha: 0.2)
                                  : AppColors.warmGray,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor:
                                        AppColors.roseGold.withValues(alpha: 0.2),
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        color: AppColors.roseGold,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : AppColors.deepNavy,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$category • $district • ⭐ ${rating.toStringAsFixed(1)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded,
                                        color: Colors.redAccent),
                                    onPressed: () => _deleteRecommendation(
                                        vendorId, recDocId),
                                  ),
                                ],
                              ),
                              if (note.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.roseGold
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '💬 "$note"',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.roseGold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  void _deleteRecommendation(String vendorId, String recDocId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Recommendation?'),
        content:
            const Text('Are you sure you want to remove this vendor recommendation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('vendor_registrations')
          .doc(vendorId)
          .collection('recommendations')
          .doc(recDocId)
          .delete();
    }
  }

  void _openAddRecommendationModal(
      BuildContext context, bool isDark, String myVendorId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddRecommendationSheet(
        isDark: isDark,
        myVendorId: myVendorId,
      ),
    );
  }
}

class _AddRecommendationSheet extends StatefulWidget {
  final bool isDark;
  final String myVendorId;

  const _AddRecommendationSheet({
    required this.isDark,
    required this.myVendorId,
  });

  @override
  State<_AddRecommendationSheet> createState() =>
      __AddRecommendationSheetState();
}

class __AddRecommendationSheetState extends State<_AddRecommendationSheet> {
  String _searchQuery = '';
  String? _selectedPartnerId;
  String? _selectedPartnerName;
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '🤝 Recommend a Partner Vendor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? Colors.white : AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 16),

          // Search Field
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            style: TextStyle(
                color: widget.isDark ? Colors.white : AppColors.deepNavy),
            decoration: InputDecoration(
              hintText: 'Search vendor by name...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: widget.isDark ? AppColors.darkBg : AppColors.cream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Vendor Search Stream
          SizedBox(
            height: 180,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vendor_registrations')
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.roseGold),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final filtered = docs.where((doc) {
                  if (doc.id == widget.myVendorId) return false;
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return _searchQuery.isEmpty ||
                      name.contains(_searchQuery.toLowerCase());
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No matching vendors found.',
                      style: TextStyle(
                          color: widget.isDark ? Colors.white54 : Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final data =
                        filtered[index].data() as Map<String, dynamic>;
                    final vid = filtered[index].id;
                    final name = data['name'] ?? 'Vendor';
                    final cat = (data['category'] ?? '')
                        .toString()
                        .replaceAll('_', ' ')
                        .toUpperCase();
                    final dist = data['district'] ?? '';
                    final isSelected = _selectedPartnerId == vid;

                    return ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      tileColor: isSelected
                          ? AppColors.roseGold.withValues(alpha: 0.15)
                          : null,
                      leading: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.storefront_rounded,
                        color: isSelected ? AppColors.roseGold : Colors.grey,
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? Colors.white : AppColors.deepNavy,
                        ),
                      ),
                      subtitle: Text('$cat • $dist'),
                      onTap: () {
                        setState(() {
                          _selectedPartnerId = vid;
                          _selectedPartnerName = name;
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),
          // Note field
          TextField(
            controller: _noteController,
            style: TextStyle(
                color: widget.isDark ? Colors.white : AppColors.deepNavy),
            decoration: InputDecoration(
              hintText: 'Add a recommendation note (e.g. Highly recommended!)',
              filled: true,
              fillColor: widget.isDark ? AppColors.darkBg : AppColors.cream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (_selectedPartnerId == null || _isSaving)
                  ? null
                  : _saveRecommendation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roseGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _selectedPartnerName == null
                          ? 'Select a Vendor Above'
                          : 'Recommend $_selectedPartnerName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveRecommendation() async {
    if (_selectedPartnerId == null) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('vendor_registrations')
          .doc(widget.myVendorId)
          .collection('recommendations')
          .doc(_selectedPartnerId)
          .set({
        'partner_id': _selectedPartnerId,
        'note': _noteController.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Recommended $_selectedPartnerName!'),
            backgroundColor: AppColors.whatsappGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

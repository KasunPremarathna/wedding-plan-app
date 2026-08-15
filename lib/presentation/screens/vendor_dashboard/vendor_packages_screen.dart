import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class VendorPackagesScreen extends ConsumerWidget {
  const VendorPackagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final user = ref.watch(authProvider).asData?.value;
    final vendorId = user?.id ?? '';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.cream,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        title: Text('Manage Packages',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18,
                color: isDark ? Colors.white : AppColors.deepNavy)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : AppColors.deepNavy),
          onPressed: () => context.pop(),
        ),
      ),
      body: vendorId.isEmpty
          ? Center(child: Text('Please log in.',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vendor_registrations')
                  .doc(vendorId)
                  .collection('packages')
                  .orderBy('created_at', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.roseGold));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64,
                            color: isDark ? Colors.white24 : Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No packages yet',
                            style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showAddModal(context, isDark, vendorId),
                          icon: const Icon(Icons.add_rounded, color: Colors.white),
                          label: const Text('Create First Package',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.roseGold,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final pkg = doc.data() as Map<String, dynamic>;
                    return _PackageCard(
                      package: pkg,
                      isDark: isDark,
                      onDelete: () async {
                        await doc.reference.delete();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Package deleted')));
                        }
                      },
                    );
                  },
                );
              },
            ),
      floatingActionButton: vendorId.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddModal(context, isDark, vendorId),
              backgroundColor: AppColors.roseGold,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  void _showAddModal(BuildContext context, bool isDark, String vendorId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          _AddPackageBottomSheet(isDark: isDark, vendorId: vendorId),
    );
  }
}

// ─── Package Card ─────────────────────────────────────────────────────────────

class _PackageCard extends StatelessWidget {
  final Map<String, dynamic> package;
  final bool isDark;
  final VoidCallback onDelete;

  const _PackageCard(
      {required this.package,
      required this.isDark,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final features = (package['features'] as List<dynamic>?) ?? [];
    final price = package['price_lkr'] ?? package['price'] ?? 0;
    final pdfUrl = package['pdf_url'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.roseGold.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(package['name'] ?? '',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isDark ? Colors.white : AppColors.deepNavy)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                    (package['tier'] ?? '').toString().toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold)),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('LKR $price',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.roseGold)),
          if (features.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: isDark ? Colors.white10 : Colors.grey[200]),
            const SizedBox(height: 8),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 14, color: AppColors.whatsappGreen),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(f.toString(),
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey[700]))),
                    ],
                  ),
                )),
            if (pdfUrl != null && pdfUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(pdfUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 16),
                label: const Text('View Attached PDF', style: TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepNavy,
                  minimumSize: const Size(double.infinity, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ─── Add Package Bottom Sheet ─────────────────────────────────────────────────

class _AddPackageBottomSheet extends StatefulWidget {
  final String vendorId;
  final bool isDark;
  const _AddPackageBottomSheet(
      {required this.vendorId, required this.isDark});

  @override
  State<_AddPackageBottomSheet> createState() =>
      _AddPackageBottomSheetState();
}

class _AddPackageBottomSheetState extends State<_AddPackageBottomSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _featureCtrl = TextEditingController();
  String _selectedTier = 'standard';
  final List<String> _features = [];
  bool _isSaving = false;
  File? _selectedPdf;
  String? _pdfName;
  double _uploadProgress = 0.0;
  bool _isUploadingPdf = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _featureCtrl.dispose();
    super.dispose();
  }

  void _addFeature() {
    if (_featureCtrl.text.trim().isNotEmpty) {
      setState(() {
        _features.add(_featureCtrl.text.trim());
        _featureCtrl.clear();
      });
    }
  }
  
  Future<void> _pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedPdf = File(result.files.single.path!);
          _pdfName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking PDF: $e');
    }
  }

  Future<String?> _uploadPdf(String vendorId) async {
    if (_selectedPdf == null) return null;
    setState(() {
      _isUploadingPdf = true;
      _uploadProgress = 0.0;
    });

    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(_selectedPdf!.path, filename: _pdfName),
        'vendor_id': vendorId, // We use the existing upload.php which expects 'image' key but accepts pdfs if mime type allows or if we just bypass check
      });
      
      // Note: Make sure upload.php on server accepts .pdf!
      final response = await dio.post(
        'https://apiwedding.kasunpremarathna.com/upload.php',
        data: formData,
        onSendProgress: (int sent, int total) {
          setState(() {
            _uploadProgress = sent / total;
          });
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['url'] as String;
      } else {
        throw Exception(response.data['message'] ?? 'Upload failed');
      }
    } catch (e) {
      debugPrint('Upload Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF Upload Error: $e')));
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPdf = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name and Price are required')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      String? uploadedPdfUrl;
      if (_selectedPdf != null) {
        uploadedPdfUrl = await _uploadPdf(widget.vendorId);
        // If upload failed but they selected one, maybe we stop or just proceed. We proceed without pdf if it failed.
      }

      await FirebaseFirestore.instance
          .collection('vendor_registrations')
          .doc(widget.vendorId)
          .collection('packages')
          .add({
        'name': _nameCtrl.text.trim(),
        'price_lkr': int.tryParse(_priceCtrl.text.trim()) ?? 0,
        'tier': _selectedTier,
        'features': _features,
        'is_popular': _selectedTier == 'gold',
        if (uploadedPdfUrl != null) 'pdf_url': uploadedPdfUrl,
        'created_at': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Package saved! ✅')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Create New Package',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: widget.isDark ? Colors.white : AppColors.deepNavy)),
              const SizedBox(height: 24),
              _field(_nameCtrl, 'Package Name'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _field(_priceCtrl, 'Price (LKR)',
                    type: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedTier,
                    dropdownColor:
                        widget.isDark ? AppColors.darkCard : Colors.white,
                    style: TextStyle(
                        color:
                            widget.isDark ? Colors.white : Colors.black),
                    decoration: _inputDec('Tier'),
                    items: const [
                      DropdownMenuItem(value: 'basic', child: Text('Basic')),
                      DropdownMenuItem(
                          value: 'standard', child: Text('Standard')),
                      DropdownMenuItem(value: 'gold', child: Text('Gold')),
                      DropdownMenuItem(
                          value: 'premium', child: Text('Premium')),
                    ],
                    onChanged: (v) => setState(() => _selectedTier = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Text('Features',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: widget.isDark
                          ? Colors.white
                          : AppColors.deepNavy)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _featureCtrl,
                    style: TextStyle(
                        color:
                            widget.isDark ? Colors.white : Colors.black),
                    decoration: _inputDec('e.g. 100 Printed Photos'),
                    onSubmitted: (_) => _addFeature(),
                  ),
                ),
                IconButton(
                  onPressed: _addFeature,
                  icon: const Icon(Icons.add_circle_rounded,
                      color: AppColors.roseGold, size: 32),
                ),
              ]),
              if (_features.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _features
                      .map((f) => Chip(
                            label: Text(f,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: widget.isDark
                                        ? Colors.white
                                        : Colors.black)),
                            onDeleted: () =>
                                setState(() => _features.remove(f)),
                            backgroundColor: widget.isDark
                                ? AppColors.darkBg
                                : Colors.white,
                            side: BorderSide(
                                color: AppColors.roseGold
                                    .withValues(alpha: 0.3)),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              
              // PDF Picker Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.roseGold.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                  color: widget.isDark ? AppColors.darkBg : Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attach PDF Brochure (Optional)', style: TextStyle(fontWeight: FontWeight.w600, color: widget.isDark ? Colors.white : AppColors.deepNavy)),
                    const SizedBox(height: 8),
                    if (_pdfName != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_pdfName!, style: TextStyle(color: widget.isDark ? Colors.white70 : Colors.black87))),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                            onPressed: () => setState(() { _selectedPdf = null; _pdfName = null; }),
                          )
                        ],
                      ),
                      if (_isUploadingPdf) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: AppColors.roseGold.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.roseGold),
                        ),
                        const SizedBox(height: 4),
                        Text('Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: AppColors.roseGold)),
                      ],
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: _pickPdf,
                        icon: const Icon(Icons.upload_file_rounded, color: AppColors.roseGold),
                        label: const Text('Select PDF File', style: TextStyle(color: AppColors.roseGold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.roseGold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepNavy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save Package',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType? type}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style:
          TextStyle(color: widget.isDark ? Colors.white : Colors.black),
      decoration: _inputDec(label),
    );
  }

  InputDecoration _inputDec(String label) => InputDecoration(
        labelText: label,
        hintText: label,
        labelStyle:
            TextStyle(color: widget.isDark ? Colors.white54 : Colors.grey),
        hintStyle:
            TextStyle(color: widget.isDark ? Colors.white38 : Colors.grey),
        filled: true,
        fillColor: widget.isDark ? AppColors.darkBg : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      );
}

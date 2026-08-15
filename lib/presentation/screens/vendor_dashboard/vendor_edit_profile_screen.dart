import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/localization_helper.dart';

class VendorEditProfileScreen extends ConsumerStatefulWidget {
  const VendorEditProfileScreen({super.key});

  @override
  ConsumerState<VendorEditProfileScreen> createState() =>
      _VendorEditProfileScreenState();
}

class _VendorEditProfileScreenState
    extends ConsumerState<VendorEditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _shortDescCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  String? _selectedCategory;
  String? _selectedDistrict;
  String _coverImageUrl = '';
  File? _newCoverFile;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingCover = false;
  String _vendorId = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _descCtrl.dispose();
    _shortDescCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = ref.read(authProvider).asData?.value;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    _vendorId = user.id;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vendor_registrations')
          .doc(_vendorId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameCtrl.text = data['name'] ?? '';
        _phoneCtrl.text = data['phone'] ?? '';
        _whatsappCtrl.text = data['whatsapp'] ?? '';
        _emailCtrl.text = data['email'] ?? '';
        _websiteCtrl.text = data['website'] ?? '';
        _descCtrl.text = data['description'] ?? '';
        _shortDescCtrl.text = data['short_description'] ?? '';
        _priceCtrl.text = (data['starting_price_lkr'] ?? 0).toString();
        _selectedCategory = data['category'];
        _selectedDistrict = data['district'];
        _coverImageUrl = data['cover_image_url'] ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading: $e')));
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _newCoverFile = File(picked.path);
      });
    }
  }

  Future<String?> _uploadCoverImage() async {
    if (_newCoverFile == null) return null;
    setState(() => _isUploadingCover = true);
    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(_newCoverFile!.path),
        'vendor_id': _vendorId,
      });

      final response = await dio.post(
        'https://apiwedding.kasunpremarathna.com/upload.php',
        data: formData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['url'] as String;
      }
    } catch (e) {
      debugPrint('Error uploading cover photo: $e');
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
    return null;
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business name is required')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      String? uploadedUrl;
      if (_newCoverFile != null) {
        uploadedUrl = await _uploadCoverImage();
      }

      final finalCoverUrl = uploadedUrl ?? _coverImageUrl;

      await FirebaseFirestore.instance
          .collection('vendor_registrations')
          .doc(_vendorId)
          .update({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'whatsapp': _whatsappCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'short_description': _shortDescCtrl.text.trim(),
        'starting_price_lkr':
            int.tryParse(_priceCtrl.text.trim()) ?? 0,
        if (_selectedCategory != null) 'category': _selectedCategory,
        if (_selectedDistrict != null) 'district': _selectedDistrict,
        if (finalCoverUrl.isNotEmpty) 'cover_image_url': finalCoverUrl,
        'updated_at': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated! ✅')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    AppLocalizations? t;
    try { t = AppLocalizations.of(locale); } catch (_) {}
    t ??= AppLocalizations.of('en');

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.cream,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        title: Text('Edit Business Profile',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: isDark ? Colors.white : AppColors.deepNavy)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : AppColors.deepNavy),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.roseGold))
                : const Text('Save',
                    style: TextStyle(
                        color: AppColors.roseGold,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.roseGold))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _sectionLabel('Cover Photo', isDark),
                GestureDetector(
                  onTap: _pickCoverImage,
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.roseGold.withValues(alpha: 0.3)),
                      image: _newCoverFile != null
                          ? DecorationImage(image: FileImage(_newCoverFile!), fit: BoxFit.cover)
                          : (_coverImageUrl.isNotEmpty
                              ? DecorationImage(image: CachedNetworkImageProvider(_coverImageUrl), fit: BoxFit.cover)
                              : null),
                    ),
                    child: Stack(
                      children: [
                        if (_newCoverFile == null && _coverImageUrl.isEmpty)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo_rounded, size: 36, color: AppColors.roseGold),
                                const SizedBox(height: 8),
                                Text('Tap to upload Cover Photo',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : Colors.grey[700])),
                              ],
                            ),
                          ),
                        if (_isUploadingCover)
                          Container(
                            color: Colors.black45,
                            child: const Center(
                              child: CircularProgressIndicator(color: AppColors.roseGold),
                            ),
                          ),
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Change', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _sectionLabel('Business Info', isDark),
                _card(isDark, [
                  _field(_nameCtrl, 'Business Name', Icons.store_rounded,
                      isDark),
                  _divider(isDark),
                  _field(_shortDescCtrl, 'Short Description (tagline)',
                      Icons.short_text_rounded, isDark),
                ]),
                const SizedBox(height: 16),
                _sectionLabel('Category & Location', isDark),
                _card(isDark, [
                  _dropdown(
                    label: 'Category',
                    value: _selectedCategory,
                    items: AppConstants.allCategories,
                    onChanged: (v) =>
                        setState(() => _selectedCategory = v),
                    display: (c) => t!.categoryName(c),
                    icon: Icons.category_rounded,
                    isDark: isDark,
                  ),
                  _divider(isDark),
                  _dropdown(
                    label: 'District',
                    value: _selectedDistrict,
                    items: AppConstants.allDistricts
                        .where((d) => d != 'all')
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedDistrict = v),
                    display: (d) => t!.districtName(d),
                    icon: Icons.location_on_rounded,
                    isDark: isDark,
                  ),
                ]),
                const SizedBox(height: 16),
                _sectionLabel('Pricing', isDark),
                _card(isDark, [
                  _field(_priceCtrl, 'Starting Price (LKR)',
                      Icons.payments_rounded, isDark,
                      type: TextInputType.number),
                ]),
                const SizedBox(height: 16),
                _sectionLabel('Contact Details', isDark),
                _card(isDark, [
                  _field(_phoneCtrl, 'Phone Number',
                      Icons.phone_rounded, isDark,
                      type: TextInputType.phone),
                  _divider(isDark),
                  _field(_whatsappCtrl, 'WhatsApp Number',
                      Icons.chat_rounded, isDark,
                      type: TextInputType.phone),
                  _divider(isDark),
                  _field(_emailCtrl, 'Email', Icons.email_rounded, isDark,
                      type: TextInputType.emailAddress),
                  _divider(isDark),
                  _field(_websiteCtrl, 'Website (optional)',
                      Icons.language_rounded, isDark),
                ]),
                const SizedBox(height: 16),
                _sectionLabel('Description', isDark),
                _card(isDark, [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _descCtrl,
                      maxLines: 5,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14),
                      decoration: InputDecoration(
                        hintText:
                            'Tell couples about your services, experience, and what makes you unique...',
                        hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey,
                            fontSize: 13),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepNavy,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Save Changes',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _sectionLabel(String label, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isDark ? Colors.white38 : Colors.grey)),
      );

  Widget _card(bool isDark, List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(children: children),
      );

  Widget _divider(bool isDark) => Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: isDark ? Colors.white10 : Colors.grey[100]);

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      bool isDark,
      {TextInputType? type}) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: AppColors.roseGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppColors.roseGold, size: 18),
      ),
      title: TextField(
        controller: ctrl,
        keyboardType: type,
        style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: label,
          hintStyle:
              TextStyle(color: isDark ? Colors.white38 : Colors.grey[400],
                  fontSize: 14),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String Function(String) display,
    required IconData icon,
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: AppColors.roseGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppColors.roseGold, size: 18),
      ),
      title: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label,
              style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey[400],
                  fontSize: 14)),
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87, fontSize: 14),
          dropdownColor: isDark ? AppColors.darkCard : Colors.white,
          isExpanded: true,
          icon: Icon(Icons.expand_more_rounded,
              color: isDark ? Colors.white54 : Colors.grey),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(display(item)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

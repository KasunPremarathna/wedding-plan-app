import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../../core/network/api_client.dart';

class VendorPortfolioScreen extends ConsumerStatefulWidget {
  const VendorPortfolioScreen({super.key});

  @override
  ConsumerState<VendorPortfolioScreen> createState() =>
      _VendorPortfolioScreenState();
}

class _VendorPortfolioScreenState
    extends ConsumerState<VendorPortfolioScreen> {
  List<String> _images = [];
  bool _isUploading = false;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final user = ref.read(authProvider).asData?.value;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vendor_registrations')
          .doc(user.id)
          .get();
      final gallery =
          (doc.data()?['gallery_images'] as List<dynamic>?)?.cast<String>() ??
              [];
      setState(() {
        _images = gallery;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final user = ref.read(authProvider).asData?.value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in first.')));
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;

      setState(() => _isUploading = true);

      final file = File(image.path);
      final fileName = image.path.split('/').last;

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(file.path, filename: fileName),
        'vendor_id': user.id, // ← Real vendor ID now used
      });

      final response = await ApiClient().dio.post(
        'https://apiwedding.kasunpremarathna.com/upload.php',
        data: formData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final imageUrl = response.data['url'] as String;

        // Save URL to Firestore gallery_images array
        await FirebaseFirestore.instance
            .collection('vendor_registrations')
            .doc(user.id)
            .update({
          'gallery_images': FieldValue.arrayUnion([imageUrl]),
        });

        setState(() => _images.insert(0, imageUrl));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image uploaded! 📸')));
        }
      } else {
        throw Exception(response.data['message'] ?? 'Upload failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteImage(String imageUrl) async {
    final user = ref.read(authProvider).asData?.value;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('vendor_registrations')
          .doc(user.id)
          .update({
        'gallery_images': FieldValue.arrayRemove([imageUrl]),
      });
      setState(() => _images.remove(imageUrl));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image removed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.cream,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        title: Text('Portfolio Gallery',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: isDark ? Colors.white : AppColors.deepNavy)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : AppColors.deepNavy),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.roseGold))
          : _images.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined,
                          size: 64,
                          color: isDark ? Colors.white24 : Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No images yet',
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey)),
                      const SizedBox(height: 8),
                      const Text('Tap + to upload your first photo',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.roseGold)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    final url = _images[index];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (_, __) => Container(
                                color: isDark
                                    ? AppColors.darkCard
                                    : Colors.grey[200]),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.roseGold.withValues(alpha: 0.1),
                              child: const Icon(Icons.broken_image_rounded,
                                  color: AppColors.roseGold),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () => _deleteImage(url),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUpload,
        backgroundColor: AppColors.roseGold,
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
        label: Text(_isUploading ? 'Uploading...' : 'Upload Image',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

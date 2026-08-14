import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../../core/network/api_client.dart';

class VendorPortfolioScreen extends ConsumerStatefulWidget {
  const VendorPortfolioScreen({super.key});

  @override
  ConsumerState<VendorPortfolioScreen> createState() => _VendorPortfolioScreenState();
}

class _VendorPortfolioScreenState extends ConsumerState<VendorPortfolioScreen> {
  final List<String> _uploadedImages = [];
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;

      setState(() => _isUploading = true);

      final file = File(image.path);
      final fileName = image.path.split('/').last;
      
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(file.path, filename: fileName),
        'vendor_id': '123', // Demo vendor ID
      });

      // Point this to the user's custom upload endpoint
      // We are sending a POST request to upload.php on Hostinger
      final response = await ApiClient().dio.post(
        'https://apiwedding.kasunpremarathna.com/upload.php',
        data: formData,
        options: Options(
          // Sometimes Hostinger rejects without standard Content-Type
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final imageUrl = response.data['url'];
        setState(() {
          _uploadedImages.insert(0, imageUrl); // add to top
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploaded successfully! 📸')));
        }
      } else {
        throw Exception(response.data['message'] ?? 'Upload failed');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
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
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : AppColors.deepNavy)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.deepNavy),
          onPressed: () => context.pop(),
        ),
      ),
      body: _uploadedImages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: isDark ? Colors.white24 : Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No images uploaded yet', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Images will be sent to your server', style: TextStyle(fontSize: 12, color: AppColors.roseGold)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _uploadedImages.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _uploadedImages[index],
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUploadImage,
        backgroundColor: AppColors.roseGold,
        icon: _isUploading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
        label: Text(_isUploading ? 'Uploading...' : 'Upload Image', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

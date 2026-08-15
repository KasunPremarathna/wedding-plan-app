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
    extends ConsumerState<VendorPortfolioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String _uploadStatusText = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          'Manage Work Portfolio',
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.roseGold,
          labelColor: AppColors.roseGold,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: '📁 Projects (Albums)'),
            Tab(text: '📸 All Gallery Photos'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading
            ? null
            : () => _openAddProjectDialog(context, isDark, vendorId),
        backgroundColor: AppColors.roseGold,
        icon: _isUploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
        label: Text(
          _isUploading ? _uploadStatusText : '+ New Work (Max 5 Photos)',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: vendorId.isEmpty
          ? Center(
              child: Text(
                'Please log in as vendor.',
                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _ProjectsTab(vendorId: vendorId, isDark: isDark),
                _AllPhotosTab(vendorId: vendorId, isDark: isDark),
              ],
            ),
    );
  }

  void _openAddProjectDialog(
      BuildContext context, bool isDark, String vendorId) {
    final titleCtrl = TextEditingController();
    List<XFile> selectedImages = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
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
                    '📸 Add Work Project (Max 5 Photos)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload up to 5 high-quality photos for an event or project (e.g. Shangri-La Wedding Shoot).',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Project Title
                  TextField(
                    controller: titleCtrl,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.deepNavy,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Event / Work Title (e.g. Kandy Royal Wedding)',
                      filled: true,
                      fillColor: isDark ? AppColors.darkBg : AppColors.cream,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pick photos button
                  InkWell(
                    onTap: () async {
                      final images = await _picker.pickMultiImage(
                        imageQuality: 75,
                      );
                      if (images.isNotEmpty) {
                        if (!context.mounted) return;
                        if (images.length > 5) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  '⚠️ Maximum 5 photos allowed per work project. Selected first 5 photos.'),
                              backgroundColor: Colors.orangeAccent,
                            ),
                          );
                        }
                        setModalState(() {
                          selectedImages = images.take(5).toList();
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.roseGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.roseGold.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.collections_rounded,
                              color: AppColors.roseGold),
                          const SizedBox(width: 8),
                          Text(
                            selectedImages.isEmpty
                                ? 'Select Photos (Max 5)'
                                : '${selectedImages.length} Photo(s) Selected (Tap to Change)',
                            style: const TextStyle(
                              color: AppColors.roseGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 70,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedImages.length,
                        itemBuilder: (context, idx) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(
                                    File(selectedImages[idx].path)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Upload submit button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (selectedImages.isEmpty || _isUploading)
                          ? null
                          : () {
                              final title = titleCtrl.text.trim().isEmpty
                                  ? 'Recent Work'
                                  : titleCtrl.text.trim();
                              Navigator.pop(context);
                              _uploadProject(vendorId, title, selectedImages);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.roseGold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Upload Work Project',
                        style: TextStyle(
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
          },
        );
      },
    );
  }

  Future<void> _uploadProject(
      String vendorId, String title, List<XFile> images) async {
    setState(() {
      _isUploading = true;
      _uploadStatusText = 'Uploading 0/${images.length}...';
    });

    List<String> uploadedUrls = [];

    try {
      for (int i = 0; i < images.length; i++) {
        setState(() {
          _uploadStatusText = 'Uploading ${i + 1}/${images.length}...';
        });

        final image = images[i];
        final file = File(image.path);
        final fileName = image.path.split('/').last;

        final formData = FormData.fromMap({
          'image':
              await MultipartFile.fromFile(file.path, filename: fileName),
          'vendor_id': vendorId,
        });

        final response = await ApiClient().dio.post(
          'https://apiwedding.kasunpremarathna.com/upload.php',
          data: formData,
        );

        if (response.statusCode == 200 && response.data['success'] == true) {
          final url = response.data['url'] as String;
          uploadedUrls.add(url);
        }
      }

      if (uploadedUrls.isNotEmpty) {
        // Save to Firestore subcollection 'portfolio_projects'
        await FirebaseFirestore.instance
            .collection('vendor_registrations')
            .doc(vendorId)
            .collection('portfolio_projects')
            .add({
          'title': title,
          'images': uploadedUrls,
          'created_at': FieldValue.serverTimestamp(),
        });

        // Also add to global vendor gallery_images array
        await FirebaseFirestore.instance
            .collection('vendor_registrations')
            .doc(vendorId)
            .update({
          'gallery_images': FieldValue.arrayUnion(uploadedUrls),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Successfully published "$title" with ${uploadedUrls.length} photos!'),
              backgroundColor: AppColors.whatsappGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatusText = '';
        });
      }
    }
  }
}

// ─── Projects Tab ─────────────────────────────────────────────────────────────

class _ProjectsTab extends StatelessWidget {
  final String vendorId;
  final bool isDark;

  const _ProjectsTab({required this.vendorId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vendor_registrations')
          .doc(vendorId)
          .collection('portfolio_projects')
          .orderBy('created_at', descending: true)
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
                    Icons.photo_album_outlined,
                    size: 64,
                    color: isDark ? Colors.white24 : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Work Projects Added Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap "+ New Work (Max 5 Photos)" to upload and showcase your best event photos to potential clients!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            final title = data['title'] ?? 'Work Project';
            final images =
                (data['images'] as List<dynamic>?)?.cast<String>() ?? [];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.collections_bookmark_rounded,
                                color: AppColors.roseGold, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.deepNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.roseGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${images.length} Photos',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.roseGold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Colors.redAccent, size: 20),
                        onPressed: () => _deleteProject(
                            context, vendorId, docId, images),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, imgIdx) {
                        final url = images[imgIdx];
                        return Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 130,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: isDark
                                    ? AppColors.darkBg
                                    : Colors.grey[200],
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color:
                                    AppColors.roseGold.withValues(alpha: 0.1),
                                child: const Icon(Icons.broken_image_rounded,
                                    color: AppColors.roseGold),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _deleteProject(BuildContext context, String vendorId, String docId,
      List<String> images) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Work Project?'),
        content: const Text(
            'Are you sure you want to delete this work project album?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('vendor_registrations')
          .doc(vendorId)
          .collection('portfolio_projects')
          .doc(docId)
          .delete();

      if (images.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('vendor_registrations')
            .doc(vendorId)
            .update({
          'gallery_images': FieldValue.arrayRemove(images),
        });
      }
    }
  }
}

// ─── All Photos Tab ──────────────────────────────────────────────────────────

class _AllPhotosTab extends StatelessWidget {
  final String vendorId;
  final bool isDark;

  const _AllPhotosTab({required this.vendorId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vendor_registrations')
          .doc(vendorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.roseGold),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final images =
            (data['gallery_images'] as List<dynamic>?)?.cast<String>() ?? [];

        if (images.isEmpty) {
          return Center(
            child: Text(
              'No gallery images uploaded yet.',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            final url = images[index];
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (_, __) => Container(
                      color: isDark ? AppColors.darkCard : Colors.grey[200],
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.roseGold.withValues(alpha: 0.1),
                      child: const Icon(Icons.broken_image_rounded,
                          color: AppColors.roseGold),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () async {
                      await FirebaseFirestore.instance
                          .collection('vendor_registrations')
                          .doc(vendorId)
                          .update({
                        'gallery_images': FieldValue.arrayRemove([url]),
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';

class VendorPackagesScreen extends ConsumerStatefulWidget {
  const VendorPackagesScreen({super.key});

  @override
  ConsumerState<VendorPackagesScreen> createState() => _VendorPackagesScreenState();
}

class _VendorPackagesScreenState extends ConsumerState<VendorPackagesScreen> {
  final List<Map<String, dynamic>> _packages = [];

  void _showAddPackageModal(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddPackageBottomSheet(
        isDark: isDark,
        onAdd: (pkg) {
          setState(() {
            _packages.add(pkg);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.cream,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        title: Text('Manage Packages',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : AppColors.deepNavy)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.deepNavy),
          onPressed: () => context.pop(),
        ),
      ),
      body: _packages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: isDark ? Colors.white24 : Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No packages created yet', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddPackageModal(isDark),
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: const Text('Create First Package', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.roseGold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _packages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final pkg = _packages[index];
                return _PackageCard(package: pkg, isDark: isDark);
              },
            ),
      floatingActionButton: _packages.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddPackageModal(isDark),
              backgroundColor: AppColors.roseGold,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }
}

class _PackageCard extends StatelessWidget {
  final Map<String, dynamic> package;
  final bool isDark;

  const _PackageCard({required this.package, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.roseGold.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(package['name'], style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : AppColors.deepNavy)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(package['tier'].toString().toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.gold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('LKR ${package['price']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.roseGold)),
          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.white10 : Colors.grey[200]),
          const SizedBox(height: 8),
          ...List.generate(
            (package['features'] as List).length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.whatsappGreen),
                  const SizedBox(width: 8),
                  Text(package['features'][i], style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey[700])),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _AddPackageBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  final bool isDark;
  const _AddPackageBottomSheet({required this.onAdd, required this.isDark});

  @override
  State<_AddPackageBottomSheet> createState() => _AddPackageBottomSheetState();
}

class _AddPackageBottomSheetState extends State<_AddPackageBottomSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _featureCtrl = TextEditingController();
  
  String _selectedTier = 'standard';
  final List<String> _features = [];

  void _addFeature() {
    if (_featureCtrl.text.trim().isNotEmpty) {
      setState(() {
        _features.add(_featureCtrl.text.trim());
        _featureCtrl.clear();
      });
    }
  }

  void _savePackage() {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Price are required')));
      return;
    }
    
    widget.onAdd({
      'name': _nameCtrl.text.trim(),
      'price': _priceCtrl.text.trim(),
      'tier': _selectedTier,
      'features': _features,
      'isPopular': _selectedTier == 'gold',
    });
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Create New Package', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: widget.isDark ? Colors.white : AppColors.deepNavy)),
              const SizedBox(height: 24),
              TextField(
                controller: _nameCtrl,
                style: TextStyle(color: widget.isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Package Name',
                  labelStyle: TextStyle(color: widget.isDark ? Colors.white54 : Colors.grey),
                  filled: true, fillColor: widget.isDark ? AppColors.darkBg : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: widget.isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Price (LKR)',
                        labelStyle: TextStyle(color: widget.isDark ? Colors.white54 : Colors.grey),
                        filled: true, fillColor: widget.isDark ? AppColors.darkBg : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedTier,
                      dropdownColor: widget.isDark ? AppColors.darkCard : Colors.white,
                      style: TextStyle(color: widget.isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Tier',
                        labelStyle: TextStyle(color: widget.isDark ? Colors.white54 : Colors.grey),
                        filled: true, fillColor: widget.isDark ? AppColors.darkBg : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'basic', child: Text('Basic')),
                        DropdownMenuItem(value: 'standard', child: Text('Standard')),
                        DropdownMenuItem(value: 'gold', child: Text('Gold')),
                        DropdownMenuItem(value: 'premium', child: Text('Premium')),
                      ],
                      onChanged: (v) => setState(() => _selectedTier = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Features Included', style: TextStyle(fontWeight: FontWeight.w600, color: widget.isDark ? Colors.white : AppColors.deepNavy)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _featureCtrl,
                      style: TextStyle(color: widget.isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: 'e.g. 100 Printed Photos',
                        hintStyle: TextStyle(color: widget.isDark ? Colors.white38 : Colors.grey),
                        filled: true, fillColor: widget.isDark ? AppColors.darkBg : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _addFeature(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addFeature,
                    icon: const Icon(Icons.add_circle_rounded, color: AppColors.roseGold, size: 32),
                  )
                ],
              ),
              if (_features.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _features.map((f) => Chip(
                    label: Text(f, style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.white : Colors.black)),
                    onDeleted: () => setState(() => _features.remove(f)),
                    backgroundColor: widget.isDark ? AppColors.darkBg : Colors.white,
                    side: BorderSide(color: AppColors.roseGold.withValues(alpha: 0.3)),
                  )).toList(),
                )
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _savePackage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepNavy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Package', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

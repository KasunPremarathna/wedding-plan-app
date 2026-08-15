import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/localization_helper.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final t = AppLocalizations.of(locale);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.cream,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        title: Text(t.settings,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20,
                color: isDark ? Colors.white : AppColors.deepNavy)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile / App header card
          _AppHeaderCard(isDark: isDark, t: t),
          const SizedBox(height: 20),

          // Preferences section
          _SectionLabel(label: 'Preferences', isDark: isDark),
          _SettingsCard(isDark: isDark, children: [
            _LanguageTile(isDark: isDark, t: t),
            _Divider(isDark: isDark),
            _ThemeTile(isDark: isDark, t: t),
          ]),
          const SizedBox(height: 16),

          // Account section
          _SectionLabel(label: 'Account', isDark: isDark),
          _SettingsCard(isDark: isDark, children: [
            _VendorRegistrationTile(isDark: isDark, t: t),
            _Divider(isDark: isDark),
            _VendorDashboardTile(isDark: isDark),
            _Divider(isDark: isDark),
            _PartnerSyncTile(isDark: isDark, t: t),
          ]),
          const SizedBox(height: 16),

          // About section
          _SectionLabel(label: 'About', isDark: isDark),
          _SettingsCard(isDark: isDark, children: [
            _InfoTile(icon: Icons.info_rounded, label: '${t.version} 1.1.0', isDark: isDark),
            _Divider(isDark: isDark),
            _InfoTile(icon: Icons.privacy_tip_rounded, label: t.privacyPolicy, isDark: isDark, onTap: () async {
              final Uri url = Uri.parse('https://weddingplannerlk.com/privacy');
              try {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Privacy Policy')));
                }
              }
            }),
            _Divider(isDark: isDark),
            _InfoTile(icon: Icons.support_agent_rounded, label: t.contactSupport, isDark: isDark, onTap: () async {
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'htckasun@gmail.com',
                query: 'subject=App Support Request',
              );
              try {
                await launchUrl(emailLaunchUri);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open email client')));
                }
              }
            }),
          ]),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AppHeaderCard extends StatelessWidget {
  final bool isDark;
  final AppLocalizations t;

  const _AppHeaderCard({required this.isDark, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.navyGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.deepNavy.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            gradient: AppColors.roseGoldGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.roseGold.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.appName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 4),
          Text(t.tagline, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: const Text('🇱🇰 Sri Lanka Edition', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ])),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(label.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2,
              color: isDark ? Colors.white38 : Colors.grey)),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;
  const _SettingsCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? Colors.white10 : Colors.grey[100]);
  }
}

class _LanguageTile extends ConsumerWidget {
  final bool isDark;
  final AppLocalizations t;

  const _LanguageTile({required this.isDark, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isSi = locale == 'si';

    return ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(gradient: AppColors.roseGoldGradient, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.translate_rounded, color: Colors.white, size: 20),
      ),
      title: Text(t.language, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.deepNavy)),
      subtitle: Text(isSi ? 'සිංහල' : 'English', style: const TextStyle(fontSize: 12, color: AppColors.roseGold)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('EN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: !isSi ? AppColors.roseGold : (isDark ? Colors.white38 : Colors.grey))),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => ref.read(localeProvider.notifier).toggle(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 46, height: 26,
            decoration: BoxDecoration(
              gradient: isSi ? AppColors.roseGoldGradient : AppColors.goldGradient,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Align(
              alignment: isSi ? Alignment.centerRight : Alignment.centerLeft,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 3),
                child: CircleAvatar(radius: 10, backgroundColor: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('සිං', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSi ? AppColors.roseGold : (isDark ? Colors.white38 : Colors.grey))),
      ]),
    );
  }
}

class _ThemeTile extends ConsumerWidget {
  final bool isDark;
  final AppLocalizations t;

  const _ThemeTile({required this.isDark, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(gradient: isDark ? AppColors.navyGradient : AppColors.goldGradient, borderRadius: BorderRadius.circular(10)),
        child: Icon(isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded, color: Colors.white, size: 20),
      ),
      title: Text(t.theme, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.deepNavy)),
      subtitle: Text(isDark ? t.darkMode : t.lightMode, style: const TextStyle(fontSize: 12, color: AppColors.roseGold)),
      trailing: Switch.adaptive(
        value: isDark,
        activeTrackColor: AppColors.roseGold,
        onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback? onTap;

  const _InfoTile({required this.icon, required this.label, required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: AppColors.roseGold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.roseGold, size: 20),
      ),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : AppColors.deepNavy)),
      trailing: onTap != null ? Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white38 : Colors.grey) : null,
      onTap: onTap,
    );
  }
}

class _VendorRegistrationTile extends StatefulWidget {
  final bool isDark;
  final AppLocalizations t;

  const _VendorRegistrationTile({required this.isDark, required this.t});

  @override
  State<_VendorRegistrationTile> createState() => _VendorRegistrationTileState();
}

class _VendorRegistrationTileState extends State<_VendorRegistrationTile> {
  bool _isLoading = false;

  Future<void> _handleVendorRegistration() async {
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn();
      var account = googleSignIn.currentUser;
      account ??= await googleSignIn.signIn();

      if (account == null) {
        setState(() => _isLoading = false);
        return; // User canceled
      }

      // Check if already registered
      final doc = await FirebaseFirestore.instance.collection('vendor_registrations').doc(account.id).get();
      if (doc.exists) {
        final status = doc.data()?['status'] ?? 'pending';
        final reason = doc.data()?['rejection_reason'] as String?;
        if (mounted) {
          String message;
          if (status == 'approved') {
            message = 'Your vendor registration is APPROVED! ✅\n\nGo to Vendor Dashboard to manage your business.';
          } else if (status == 'rejected') {
            message = 'Your registration was REJECTED.${reason != null && reason.isNotEmpty ? '\n\nReason: $reason' : ''}\n\nPlease contact htckasun@gmail.com for assistance.';
          } else {
            message = 'Your vendor registration is currently PENDING.\n\nPlease wait for admin approval.';
          }
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Registration Status'),
              content: Text(message),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
              ],
            )
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Show form
      if (mounted) {
        _showRegistrationForm(account);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    setState(() => _isLoading = false);
  }

  void _showRegistrationForm(GoogleSignInAccount account) {
    final phoneCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final shortDescCtrl = TextEditingController();
    String? selectedCategory;
    String? selectedDistrict;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Vendor Registration'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Signed in as: ${account.email}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: AppConstants.allCategories.map((c) => DropdownMenuItem(value: c, child: Text(widget.t.categoryName(c)))).toList(),
                  onChanged: (v) => setStateDialog(() => selectedCategory = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedDistrict,
                  decoration: const InputDecoration(labelText: 'District'),
                  items: AppConstants.allDistricts.where((d) => d != 'all').map((d) => DropdownMenuItem(value: d, child: Text(widget.t.districtName(d)))).toList(),
                  onChanged: (v) => setStateDialog(() => selectedDistrict = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Contact Number'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Starting Price (LKR)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: shortDescCtrl,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Short Description (tagline)',
                    hintText: 'e.g. Professional wedding photography in Colombo',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'About Your Business',
                    hintText: 'Describe your services, experience...',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (!isSubmitting)
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (selectedCategory == null || selectedDistrict == null || phoneCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
                  return;
                }
                setStateDialog(() => isSubmitting = true);
                try {
                  final slug = account.displayName
                      ?.toLowerCase()
                      .replaceAll(RegExp(r'[^a-z0-9]+'), '-') ?? account.id;
                  await FirebaseFirestore.instance.collection('vendor_registrations').doc(account.id).set({
                    'uid': account.id,
                    'email': account.email,
                    'name': account.displayName ?? '',
                    'slug': slug,
                    'category': selectedCategory,
                    'district': selectedDistrict,
                    'starting_price_lkr': int.tryParse(priceCtrl.text.trim()) ?? 0,
                    'phone': phoneCtrl.text.trim(),
                    'whatsapp': phoneCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'short_description': shortDescCtrl.text.trim(),
                    'cover_image_url': account.photoUrl ?? '',
                    'gallery_images': [],
                    'rating': 0.0,
                    'review_count': 0,
                    'inquiries_count': 0,
                    'profile_views': 0,
                    'favorites_count': 0,
                    'is_boosted': false,
                    'is_featured': false,
                    'boost_badge': '',
                    'status': 'pending',
                    'timestamp': FieldValue.serverTimestamp(),
                    'created_at': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (ctx2) => AlertDialog(
                        title: const Text('Registration Pending', style: TextStyle(color: AppColors.roseGold)),
                        content: const Text('Your registration is pending approval.\n\nPlease wait for admin approval.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('OK'))
                        ],
                      )
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                  setStateDialog(() => isSubmitting = false);
                }
              },
              child: isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: _isLoading 
            ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
            : const Icon(Icons.storefront_rounded, color: AppColors.gold, size: 20),
      ),
      title: Text('Vendor Registration', style: TextStyle(fontWeight: FontWeight.w600, color: widget.isDark ? Colors.white : AppColors.deepNavy)),
      subtitle: const Text('Register your business', style: TextStyle(fontSize: 12, color: AppColors.roseGold)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: widget.isDark ? Colors.white38 : Colors.grey),
      onTap: _isLoading ? null : _handleVendorRegistration,
    );
  }
}

class _PartnerSyncTile extends ConsumerWidget {
  final bool isDark;
  final AppLocalizations t;

  const _PartnerSyncTile({required this.isDark, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: AppColors.roseGold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.sync_rounded, color: AppColors.roseGold, size: 20),
      ),
      title: Text('Connect Partner', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.deepNavy)),
      subtitle: const Text('Bride & Groom Sync', style: TextStyle(fontSize: 12, color: AppColors.roseGold)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white38 : Colors.grey),
      onTap: () {
        // Navigate to role selection / setup screen
        context.push('/role');
      },
    );
  }
}

class _VendorDashboardTile extends StatefulWidget {
  final bool isDark;

  const _VendorDashboardTile({required this.isDark});

  @override
  State<_VendorDashboardTile> createState() => _VendorDashboardTileState();
}

class _VendorDashboardTileState extends State<_VendorDashboardTile> {
  bool _isLoading = false;

  Future<void> _handleDashboardTap() async {
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn();
      var account = googleSignIn.currentUser;
      
      account ??= await googleSignIn.signInSilently();

      if (account == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please register as a Vendor first.')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('vendor_registrations').doc(account.id).get();
      
      if (doc.exists) {
        final status = doc.data()?['status'] ?? 'pending';
        if (status == 'approved') {
          if (mounted) {
            context.push('/vendor-dashboard');
          }
        } else {
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Access Denied', style: TextStyle(color: Colors.red)),
                content: const Text('Your vendor registration is currently PENDING.\n\nPlease wait for admin approval to access the dashboard.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
                ],
              )
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are not registered as a Vendor. Please register first.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: _isLoading 
            ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
            : const Icon(Icons.dashboard_rounded, color: AppColors.gold, size: 20),
      ),
      title: Text('Vendor Dashboard', style: TextStyle(fontWeight: FontWeight.w600, color: widget.isDark ? Colors.white : AppColors.deepNavy)),
      subtitle: const Text('Manage your business', style: TextStyle(fontSize: 12, color: AppColors.roseGold)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: widget.isDark ? Colors.white38 : Colors.grey),
      onTap: _isLoading ? null : _handleDashboardTap,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/localization_helper.dart';
import '../../providers/app_providers.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  bool _isLoading = false;
  String? _selectedRole;
  final _weddingIdCtrl = TextEditingController();

  @override
  void dispose() {
    _weddingIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your role first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final googleSignIn = GoogleSignIn();
      var account = googleSignIn.currentUser;
      account ??= await googleSignIn.signIn();

      if (account == null) {
        setState(() => _isLoading = false);
        return; // User canceled
      }

      // Check if user already has a profile
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(account.id);
      final docSnap = await userDocRef.get();

      final inputId = _weddingIdCtrl.text.trim();
      final weddingId = inputId.isNotEmpty ? inputId : DateTime.now().millisecondsSinceEpoch.toString().substring(5);
      
      if (!docSnap.exists) {
        // Create new user profile
        await userDocRef.set({
          'uid': account.id,
          'email': account.email,
          'name': account.displayName ?? '',
          'role': _selectedRole,
          'wedding_id': weddingId,
          'created_at': FieldValue.serverTimestamp(),
        });
      } else {
        // Update role and wedding ID
        await userDocRef.update({
          'role': _selectedRole,
          'wedding_id': weddingId,
        });
      }
      
      // Save locally to trigger sync in providers
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('wedding_id', weddingId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile synced! Wedding ID: $weddingId')));
        context.go('/');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    AppLocalizations.load(locale);
    AppLocalizations? t;
    try { t = AppLocalizations.of(locale); } catch (_) {}

    if (t == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                'Welcome to\nWedding Planner LK',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.deepNavy,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Let\'s set up your profile to sync your wedding planning.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              
              Text(
                'Who are you?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.deepNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Role selection cards
              Row(
                children: [
                  Expanded(child: _buildRoleCard('bride', 'Bride', '👰‍♀️', isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildRoleCard('groom', 'Groom', '🤵‍♂️', isDark)),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _weddingIdCtrl,
                decoration: InputDecoration(
                  labelText: 'Partner\'s Wedding ID (Optional)',
                  hintText: 'Enter ID to sync with partner',
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              
              const Spacer(),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _handleContinue,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Continue with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String roleValue, String title, String emoji, bool isDark) {
    final isSelected = _selectedRole == roleValue;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = roleValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.roseGold.withValues(alpha: 0.1) 
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.roseGold : (isDark ? Colors.white10 : Colors.grey[200]!),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.roseGold.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected 
                    ? AppColors.roseGold 
                    : (isDark ? Colors.white : AppColors.deepNavy),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

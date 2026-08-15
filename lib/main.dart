import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/vendors/vendors_screen.dart';
import 'presentation/screens/planning/planning_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/vendor_detail/vendor_detail_screen.dart';
import 'presentation/screens/vendor_dashboard/vendor_dashboard_screen.dart';
import 'presentation/screens/vendor_dashboard/vendor_notifications_screen.dart';
import 'presentation/screens/vendor_dashboard/vendor_portfolio_screen.dart';
import 'presentation/screens/vendor_dashboard/vendor_packages_screen.dart';
import 'presentation/screens/vendor_dashboard/vendor_edit_profile_screen.dart';
import 'presentation/screens/vendor_dashboard/vendor_reviews_screen.dart';
import 'presentation/screens/chat/chat_list_screen.dart';
import 'presentation/screens/chat/chat_detail_screen.dart';
import 'presentation/screens/onboarding/role_selection_screen.dart';
import 'presentation/widgets/common/localization_helper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:upgrader/upgrader.dart';
import 'data/datasources/firebase_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Firebase.initializeApp();
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM Message received in foreground: ${message.notification?.title}');
    });
    
    // Auto-seed Firestore data if needed (runs only in debug mode)
    await FirebaseSeeder.seedDataIfNeeded();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final initialLocale = prefs.getString(AppConstants.localeKey) ?? AppConstants.english;
  await AppLocalizations.load(initialLocale);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const WeddingPlannerApp(),
    ),
  );
}

class WeddingPlannerApp extends ConsumerWidget {
  const WeddingPlannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Wedding Planner LK',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(locale),
      supportedLocales: const [Locale('en', ''), Locale('si', '')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}

// ============================================================
// ROUTER CONFIGURATION
// ============================================================
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/vendors',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: VendorsScreen(),
          ),
        ),
        GoRoute(
          path: '/planning',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PlanningScreen(),
          ),
        ),
        GoRoute(
          path: '/chat',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ChatListScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/chat/:roomId',
      builder: (context, state) {
        final roomId = state.pathParameters['roomId']!;
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ChatDetailScreen(
          roomId: roomId,
          vendorId: extra['vendorId'] ?? '',
          vendorName: extra['vendorName'] ?? 'Vendor',
          vendorImage: extra['vendorImage'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/vendor/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return VendorDetailScreen(vendorId: id);
      },
    ),
    GoRoute(
      path: '/role',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/vendor-dashboard',
      builder: (context, state) => const VendorDashboardScreen(),
    ),
    GoRoute(
      path: '/vendor-notifications',
      builder: (context, state) => const VendorNotificationsScreen(),
    ),
    GoRoute(
      path: '/vendor-portfolio',
      builder: (context, state) => const VendorPortfolioScreen(),
    ),
    GoRoute(
      path: '/vendor-packages',
      builder: (context, state) => const VendorPackagesScreen(),
    ),
    GoRoute(
      path: '/vendor-edit-profile',
      builder: (context, state) => const VendorEditProfileScreen(),
    ),
    GoRoute(
      path: '/vendor-reviews',
      builder: (context, state) => const VendorReviewsScreen(),
    ),
  ],
);

// ============================================================
// MAIN SHELL WITH BOTTOM NAV
// ============================================================
class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final List<String> _routes = ['/', '/vendors', '/planning', '/chat', '/settings'];

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final t = AppLocalizations.of(locale);

    return Scaffold(
      body: UpgradeAlert(
        child: widget.child,
      ),
      bottomNavigationBar: _buildBottomNavBar(t, isDark),
    );
  }

  Widget _buildBottomNavBar(AppLocalizations t, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.roseGold.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                index: 0,
                currentIndex: _currentIndex,
                icon: Icons.home_rounded,
                label: t.home,
                onTap: () => _onTap(0),
              ),
              _NavItem(
                index: 1,
                currentIndex: _currentIndex,
                icon: Icons.storefront_rounded,
                label: t.vendors,
                onTap: () => _onTap(1),
              ),
              _NavItem(
                index: 2,
                currentIndex: _currentIndex,
                icon: Icons.calendar_month_rounded,
                label: t.planning,
                onTap: () => _onTap(2),
              ),
              _NavItem(
                index: 3,
                currentIndex: _currentIndex,
                icon: Icons.chat_bubble_rounded,
                label: 'Chat', // Ideally t.chat
                onTap: () => _onTap(3),
              ),
              _NavItem(
                index: 4,
                currentIndex: _currentIndex,
                icon: Icons.settings_rounded,
                label: t.settings,
                onTap: () => _onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    setState(() => _currentIndex = index);
    context.go(_routes[index]);
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.roseGold.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isSelected ? AppColors.roseGold : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.roseGold : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

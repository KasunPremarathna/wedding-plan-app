import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/models/models.dart';
import '../../data/repositories/vendor_repository.dart';
import '../widgets/common/localization_helper.dart';

// ============================================================
// SHARED PREFERENCES PROVIDER
// ============================================================
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main.dart with override');
});

// ============================================================
// REPOSITORY PROVIDERS
// ============================================================
final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  return VendorRepository();
});

// ============================================================
// THEME PROVIDER
// ============================================================
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs)
      : super(_prefs.getBool(AppConstants.themeKey) ?? false);

  void toggle() {
    state = !state;
    _prefs.setBool(AppConstants.themeKey, state);
  }

  void setDark(bool isDark) {
    state = isDark;
    _prefs.setBool(AppConstants.themeKey, isDark);
  }
}

// ============================================================
// LOCALE PROVIDER
// ============================================================
final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;

  LocaleNotifier(this._prefs)
      : super(_prefs.getString(AppConstants.localeKey) ?? AppConstants.english);

  Future<void> toggle() async {
    final next = state == AppConstants.english
        ? AppConstants.sinhala
        : AppConstants.english;
    await AppLocalizations.load(next);
    state = next;
    _prefs.setString(AppConstants.localeKey, next);
  }

  Future<void> setLocale(String locale) async {
    await AppLocalizations.load(locale);
    state = locale;
    _prefs.setString(AppConstants.localeKey, locale);
  }

  bool get isSinhala => state == AppConstants.sinhala;
}

// ============================================================
// VENDOR FILTER PROVIDER
// ============================================================
final vendorFilterProvider =
    StateNotifierProvider<VendorFilterNotifier, VendorFilter>((ref) {
  return VendorFilterNotifier();
});

class VendorFilterNotifier extends StateNotifier<VendorFilter> {
  VendorFilterNotifier() : super(const VendorFilter());

  void updateCategory(String? category) {
    state = state.copyWith(category: category);
  }

  void updateDistrict(String? district) {
    state = state.copyWith(district: district);
  }

  void updatePriceRange(int? minPrice, int? maxPrice) {
    state = state.copyWith(minPrice: minPrice, maxPrice: maxPrice);
  }

  void updateSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateBoosted(bool? isBoosted) {
    state = state.copyWith(isBoosted: isBoosted);
  }

  void updateMinRating(double? rating) {
    state = state.copyWith(minRating: rating);
  }

  void clearAll() {
    state = const VendorFilter();
  }
}

// ============================================================
// VENDORS ASYNC PROVIDER
// ============================================================
final vendorsProvider =
    AsyncNotifierProvider<VendorsNotifier, List<Vendor>>(VendorsNotifier.new);

class VendorsNotifier extends AsyncNotifier<List<Vendor>> {
  @override
  Future<List<Vendor>> build() async {
    final filter = ref.watch(vendorFilterProvider);
    return _fetchVendors(filter);
  }

  Future<List<Vendor>> _fetchVendors(VendorFilter filter) async {
    final repo = ref.read(vendorRepositoryProvider);
    final result = await repo.getVendors(filter);
    switch (result) {
      case ApiSuccess(:final data):
        return data;
      case ApiFailure(:final exception):
        throw exception;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final filter = ref.read(vendorFilterProvider);
    state = await AsyncValue.guard(() => _fetchVendors(filter));
  }
}

// ============================================================
// FEATURED VENDORS PROVIDER
// ============================================================
final featuredVendorsProvider = FutureProvider<List<Vendor>>((ref) async {
  final repo = ref.read(vendorRepositoryProvider);
  final result = await repo.getVendors(const VendorFilter(isBoosted: true));
  switch (result) {
    case ApiSuccess(:final data):
      return data.take(10).toList();
    case ApiFailure(:final exception):
      throw exception;
  }
});

// ============================================================
// SPONSORED BANNERS PROVIDER
// ============================================================
final sponsoredBannersProvider =
    FutureProvider<List<SponsoredBanner>>((ref) async {
  final repo = ref.read(vendorRepositoryProvider);
  final result = await repo.getSponsoredBanners();
  switch (result) {
    case ApiSuccess(:final data):
      return data;
    case ApiFailure(:final exception):
      throw exception;
  }
});

// ============================================================
// VENDOR DETAIL PROVIDER
// ============================================================
final vendorDetailProvider =
    FutureProvider.family<Vendor, String>((ref, vendorId) async {
  final repo = ref.read(vendorRepositoryProvider);
  final result = await repo.getVendorById(vendorId);
  switch (result) {
    case ApiSuccess(:final data):
      return data;
    case ApiFailure(:final exception):
      throw exception;
  }
});

// ============================================================
// FAVORITES PROVIDER
// ============================================================
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FavoritesNotifier(prefs);
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  final SharedPreferences _prefs;

  FavoritesNotifier(this._prefs) : super(_loadFavorites(_prefs));

  static Set<String> _loadFavorites(SharedPreferences prefs) {
    final list = prefs.getStringList(AppConstants.favoritesKey) ?? [];
    return list.toSet();
  }

  void toggle(String vendorId) {
    if (state.contains(vendorId)) {
      state = {...state}..remove(vendorId);
    } else {
      state = {...state, vendorId};
    }
    _prefs.setStringList(
        AppConstants.favoritesKey, state.toList());
  }

  bool isFavorite(String vendorId) => state.contains(vendorId);
}

// ============================================================
// AUSPICIOUS TIMES PROVIDER
// ============================================================
final auspiciousTimesProvider =
    FutureProvider<List<AuspiciousTime>>((ref) async {
  final repo = ref.read(vendorRepositoryProvider);
  final result = await repo.getAuspiciousTimes();
  switch (result) {
    case ApiSuccess(:final data):
      return data;
    case ApiFailure(:final exception):
      throw exception;
  }
});

// ============================================================
// BUDGET PROVIDER
// ============================================================
final budgetProvider =
    StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BudgetNotifier(prefs);
});

class BudgetState {
  final int totalBudget;
  final List<BudgetExpense> expenses;

  const BudgetState({
    required this.totalBudget,
    required this.expenses,
  });

  int get totalSpent =>
      expenses.fold(0, (sum, e) => sum + e.amount);
  int get remaining => totalBudget - totalSpent;
  double get spentPercentage =>
      totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
}

class BudgetExpense {
  final String id;
  final String category;
  final String note;
  final int amount;
  final String date;

  const BudgetExpense({
    required this.id,
    required this.category,
    required this.note,
    required this.amount,
    required this.date,
  });
}

class BudgetNotifier extends StateNotifier<BudgetState> {
  final SharedPreferences _prefs;

  BudgetNotifier(this._prefs)
      : super(BudgetState(
          totalBudget: _prefs.getInt(AppConstants.budgetKey) ?? 500000,
          expenses: [],
        ));

  void setTotalBudget(int amount) {
    state = BudgetState(totalBudget: amount, expenses: state.expenses);
    _prefs.setInt(AppConstants.budgetKey, amount);
  }

  void addExpense(BudgetExpense expense) {
    state = BudgetState(
        totalBudget: state.totalBudget,
        expenses: [...state.expenses, expense]);
  }

  void removeExpense(String id) {
    state = BudgetState(
        totalBudget: state.totalBudget,
        expenses: state.expenses.where((e) => e.id != id).toList());
  }
}

// ============================================================
// GUEST LIST PROVIDER
// ============================================================

final guestProvider = StateNotifierProvider<GuestNotifier, List<Guest>>((ref) {
  return GuestNotifier();
});

class GuestNotifier extends StateNotifier<List<Guest>> {
  GuestNotifier() : super([]);

  void addGuest(Guest guest) {
    state = [...state, guest];
  }

  void updateGuest(Guest updated) {
    state = [for (final g in state) if (g.id == updated.id) updated else g];
  }

  void removeGuest(String id) {
    state = state.where((g) => g.id != id).toList();
  }
}

// ============================================================
// MEAL COST PROVIDER
// ============================================================

final mealCostProvider = StateNotifierProvider<MealCostNotifier, int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MealCostNotifier(prefs);
});

class MealCostNotifier extends StateNotifier<int> {
  final SharedPreferences _prefs;

  MealCostNotifier(this._prefs)
      : super(_prefs.getInt('meal_cost_per_plate') ?? 3000);

  void setCost(int cost) {
    state = cost;
    _prefs.setInt('meal_cost_per_plate', cost);
  }
}

// ============================================================
// USER NEKATH PROVIDER
// ============================================================

final userNekathProvider = StateNotifierProvider<UserNekathNotifier, List<UserNekath>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserNekathNotifier(prefs);
});

class UserNekathNotifier extends StateNotifier<List<UserNekath>> {
  final SharedPreferences _prefs;
  static const _key = 'user_nekath_times';

  UserNekathNotifier(this._prefs) : super(_load(_prefs));

  static List<UserNekath> _load(SharedPreferences prefs) {
    final list = prefs.getStringList(_key) ?? [];
    return list.map((e) => UserNekath.fromJson(json.decode(e))).toList();
  }

  void addNekath(UserNekath nekath) {
    state = [...state, nekath];
    _save();
  }

  void removeNekath(String id) {
    state = state.where((n) => n.id != id).toList();
    _save();
  }

  void _save() {
    final list = state.map((n) => json.encode(n.toJson())).toList();
    _prefs.setStringList(_key, list);
  }
}

import 'dart:convert';
import 'package:flutter/services.dart';

/// Simple localization helper that reads from JSON translation files.
class AppLocalizations {
  final String locale;
  late final Map<String, dynamic> _translations;

  AppLocalizations._(this.locale, this._translations);

  static final Map<String, AppLocalizations> _cache = {};

  static AppLocalizations of(String locale) {
    if (!_cache.containsKey(locale)) {
      throw StateError('AppLocalizations for $locale not initialized. Call load() first.');
    }
    return _cache[locale]!;
  }

  static Future<AppLocalizations> load(String locale) async {
    if (_cache.containsKey(locale)) {
      return _cache[locale]!;
    }
    final jsonString =
        await rootBundle.loadString('assets/translations/$locale.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final instance = AppLocalizations._(locale, data);
    _cache[locale] = instance;
    return instance;
  }

  String _get(String key) {
    final parts = key.split('.');
    dynamic value = _translations;
    for (final part in parts) {
      if (value is Map<String, dynamic>) {
        value = value[part];
      } else {
        return key;
      }
    }
    return value?.toString() ?? key;
  }

  // Core
  String get appName => _get('app_name');
  String get tagline => _get('tagline');
  String get searchHint => _get('search_hint');
  String get filter => _get('filter');
  String get filters => _get('filters');
  String get applyFilters => _get('apply_filters');
  String get clearFilters => _get('clear_filters');
  String get district => _get('district');
  String get priceRange => _get('price_range');
  String get category => _get('category');
  String get rating => _get('rating');
  String get minPrice => _get('min_price');
  String get maxPrice => _get('max_price');
  String get viewAll => _get('view_all');
  String get loading => _get('loading');
  String get errorOccurred => _get('error_occurred');
  String get retry => _get('retry');

  // Nav
  String get home => _get('home');
  String get vendors => _get('vendors');
  String get planning => _get('planning');
  String get favourites => _get('favourites');
  String get settings => _get('settings');

  // Home sections
  String get sponsoredBanners => _get('sponsored_banners');
  String get featuredVendors => _get('featured_vendors');
  String get boostedVendors => _get('boosted_vendors');
  String get allVendors => _get('all_vendors');
  String get popularCategories => _get('popular_categories');

  // Badges
  String get sponsored => _get('sponsored');
  String get featured => _get('featured');
  String get boosted => _get('boosted');

  // Vendor detail
  String get packages => _get('packages');
  String get gallery => _get('gallery');
  String get reviews => _get('reviews');
  String get contact => _get('contact');
  String get whatsappInquiry => _get('whatsapp_inquiry');
  String get callVendor => _get('call_vendor');
  String get requestQuote => _get('request_quote');
  String get startingFrom => _get('starting_from');
  String get lkr => _get('lkr');

  // Planning
  String get budgetTracker => _get('budget_tracker');
  String get weddingChecklist => _get('wedding_checklist');
  String get guestList => _get('guest_list');
  String get auspiciousTimes => _get('auspicious_times');
  String get countdown => _get('countdown');
  String get daysToGo => _get('days_to_go');
  String get totalBudget => _get('total_budget');
  String get spent => _get('spent');
  String get remaining => _get('remaining');
  String get addExpense => _get('add_expense');
  String get nekathTimes => _get('nekath_times');

  // Settings
  String get language => _get('language');
  String get theme => _get('theme');
  String get darkMode => _get('dark_mode');
  String get lightMode => _get('light_mode');
  String get about => _get('about');
  String get version => _get('version');
  String get privacyPolicy => _get('privacy_policy');
  String get contactSupport => _get('contact_support');

  // Saved
  String get savedVendors => _get('saved_vendors');
  String get noSavedVendors => _get('no_saved_vendors');
  String get noVendorsFound => _get('no_vendors_found');
  String get tryDifferentFilters => _get('try_different_filters');

  // Categories
  String categoryName(String key) => _get('categories.$key');

  // Districts
  String districtName(String key) => _get('districts.$key');
}

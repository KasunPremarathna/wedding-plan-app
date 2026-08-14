class AppConstants {
  // API
  static const String baseUrl = 'https://apiwedding.kasunpremarathna.com/v1';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Shared Preferences Keys
  static const String themeKey = 'app_theme';
  static const String localeKey = 'app_locale';
  static const String favoritesKey = 'saved_vendors';
  static const String weddingDateKey = 'wedding_date';
  static const String budgetKey = 'total_budget';
  static const String checklistKey = 'checklist_items';

  // Supported Languages
  static const String english = 'en';
  static const String sinhala = 'si';

  // Vendor Categories
  static const String catHotelsVenues = 'hotels_venues';
  static const String catPhotography = 'photography';
  static const String catDjBands = 'dj_bands';
  static const String catBridalSalons = 'bridal_salons';
  static const String catDecorators = 'decorators';
  static const String catPoruAshtaka = 'poru_ashtaka';
  static const String catCatering = 'catering';
  static const String catTransport = 'transport';
  static const String catWeddingCards = 'wedding_cards';
  static const String catCakes = 'cakes';

  static const List<String> allCategories = [
    catHotelsVenues,
    catPhotography,
    catDjBands,
    catBridalSalons,
    catDecorators,
    catPoruAshtaka,
    catCatering,
    catTransport,
    catWeddingCards,
    catCakes,
  ];

  // Category Icons (emoji based, replace with actual asset icons)
  static const Map<String, String> categoryIcons = {
    catHotelsVenues: '🏨',
    catPhotography: '📸',
    catDjBands: '🎵',
    catBridalSalons: '💄',
    catDecorators: '🌸',
    catPoruAshtaka: '🪘',
    catCatering: '🍽️',
    catTransport: '🚗',
    catWeddingCards: '💌',
    catCakes: '🎂',
  };

  // Districts of Sri Lanka
  static const List<String> allDistricts = [
    'all',
    'colombo',
    'kandy',
    'galle',
    'matara',
    'jaffna',
    'negombo',
    'anuradhapura',
    'polonnaruwa',
    'kurunegala',
    'ratnapura',
    'badulla',
    'trincomalee',
    'batticaloa',
    'hambantota',
    'ampara',
  ];

  // Price Ranges (LKR)
  static const double minPriceLKR = 0;
  static const double maxPriceLKR = 5000000;

  // Package Tiers
  static const String packageBasic = 'basic';
  static const String packageStandard = 'standard';
  static const String packageGold = 'gold';
  static const String packagePremium = 'premium';
}

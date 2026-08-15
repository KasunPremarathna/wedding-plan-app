// ============================================================
// VENDOR MODEL
// ============================================================

class Vendor {
  final String id;
  final String name;
  final String slug;
  final String category;
  final String district;
  final String description;
  final String shortDescription;
  final String phone;
  final String whatsapp;
  final String email;
  final String website;
  final double rating;
  final int reviewCount;
  final int startingPriceLkr;
  final bool isBoosted;
  final bool isFeatured;
  final String boostBadge;
  final String coverImageUrl;
  final List<String> galleryImages;
  final List<VendorPackage> packages;
  final List<Review> reviews;
  final bool isAvailable;
  final bool isVerified;
  final String createdAt;

  const Vendor({
    required this.id,
    required this.name,
    required this.slug,
    required this.category,
    required this.district,
    required this.description,
    required this.shortDescription,
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.website,
    required this.rating,
    required this.reviewCount,
    required this.startingPriceLkr,
    required this.isBoosted,
    required this.isFeatured,
    required this.boostBadge,
    required this.coverImageUrl,
    required this.galleryImages,
    required this.packages,
    required this.reviews,
    this.isAvailable = true,
    this.isVerified = false,
    required this.createdAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) => Vendor(
        id: json['id']?.toString() ?? json['uid']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        category: json['category'] as String? ?? '',
        district: json['district'] as String? ?? '',
        description: json['description'] as String? ?? '',
        shortDescription: json['short_description'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        whatsapp: json['whatsapp'] as String? ?? '',
        email: json['email'] as String? ?? '',
        website: json['website'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: json['review_count'] as int? ?? 0,
        startingPriceLkr: json['starting_price_lkr'] as int? ?? 0,
        isBoosted: json['is_boosted'] as bool? ?? false,
        isFeatured: json['is_featured'] as bool? ?? false,
        boostBadge: json['boost_badge'] as String? ?? '',
        coverImageUrl: json['cover_image_url'] as String? ?? '',
        isAvailable: json['is_available'] as bool? ?? true,
        isVerified: json['is_verified'] as bool? ?? false,
        galleryImages: (json['gallery_images'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        packages: (json['packages'] as List<dynamic>?)
                ?.map((e) => VendorPackage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        reviews: (json['reviews'] as List<dynamic>?)
                ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: json['created_at']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'category': category,
        'district': district,
        'description': description,
        'short_description': shortDescription,
        'phone': phone,
        'whatsapp': whatsapp,
        'email': email,
        'website': website,
        'rating': rating,
        'review_count': reviewCount,
        'starting_price_lkr': startingPriceLkr,
        'is_boosted': isBoosted,
        'is_featured': isFeatured,
        'is_verified': isVerified,
        'boost_badge': boostBadge,
        'cover_image_url': coverImageUrl,
        'gallery_images': galleryImages,
        'packages': packages.map((e) => e.toJson()).toList(),
        'reviews': reviews.map((e) => e.toJson()).toList(),
        'created_at': createdAt,
      };
}

// ============================================================
// VENDOR PACKAGE MODEL
// ============================================================

class VendorPackage {
  final int id;
  final String tier; // basic | standard | gold | premium
  final String name;
  final int priceLkr;
  final String description;
  final List<String> features;
  final bool isPopular;
  final String? pdfUrl;

  const VendorPackage({
    required this.id,
    required this.tier,
    required this.name,
    required this.priceLkr,
    required this.description,
    required this.features,
    required this.isPopular,
    this.pdfUrl,
  });

  factory VendorPackage.fromJson(Map<String, dynamic> json) => VendorPackage(
        id: json['id'] as int,
        tier: json['tier'] as String,
        name: json['name'] as String,
        priceLkr: json['price_lkr'] as int,
        description: json['description'] as String? ?? '',
        features: (json['features'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        isPopular: json['is_popular'] as bool? ?? false,
        pdfUrl: json['pdf_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tier': tier,
        'name': name,
        'price_lkr': priceLkr,
        'description': description,
        'features': features,
        'is_popular': isPopular,
        if (pdfUrl != null) 'pdf_url': pdfUrl,
      };
}

// ============================================================
// REVIEW MODEL
// ============================================================

class Review {
  final int id;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final String date;

  const Review({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as int,
        userName: json['user_name'] as String,
        userAvatar: json['user_avatar'] as String? ?? '',
        rating: (json['rating'] as num).toDouble(),
        comment: json['comment'] as String? ?? '',
        date: json['date'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_name': userName,
        'user_avatar': userAvatar,
        'rating': rating,
        'comment': comment,
        'date': date,
      };
}

// ============================================================
// SPONSORED BANNER MODEL
// ============================================================

class SponsoredBanner {
  final int id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String linkUrl;
  final String ctaText;
  final bool isActive;

  const SponsoredBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.linkUrl,
    required this.ctaText,
    required this.isActive,
  });

  factory SponsoredBanner.fromJson(Map<String, dynamic> json) =>
      SponsoredBanner(
        id: json['id'] as int,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String? ?? '',
        imageUrl: json['image_url'] as String,
        linkUrl: json['link_url'] as String? ?? '',
        ctaText: json['cta_text'] as String? ?? 'Learn More',
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'image_url': imageUrl,
        'link_url': linkUrl,
        'cta_text': ctaText,
        'is_active': isActive,
      };
}

// ============================================================
// AUSPICIOUS TIME MODEL
// ============================================================

class AuspiciousTime {
  final int id;
  final String month;
  final String year;
  final List<NekathEntry> entries;

  const AuspiciousTime({
    required this.id,
    required this.month,
    required this.year,
    required this.entries,
  });

  factory AuspiciousTime.fromJson(Map<String, dynamic> json) => AuspiciousTime(
        id: json['id'] as int,
        month: json['month'] as String,
        year: json['year'] as String,
        entries: (json['entries'] as List<dynamic>)
            .map((e) => NekathEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class NekathEntry {
  final String date;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String type; // e.g. "Poruwa", "Homecoming"
  final String nakatha;
  final String description;
  final String descriptionSi;

  const NekathEntry({
    required this.date,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.nakatha,
    required this.description,
    required this.descriptionSi,
  });

  factory NekathEntry.fromJson(Map<String, dynamic> json) => NekathEntry(
        date: json['date'] as String,
        dayOfWeek: json['day_of_week'] as String,
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String,
        type: json['type'] as String,
        nakatha: json['nakatha'] as String? ?? '',
        description: json['description'] as String? ?? '',
        descriptionSi: json['description_si'] as String? ?? '',
      );
}

// ============================================================
// VENDOR FILTER MODEL
// ============================================================

class VendorFilter {
  final String? category;
  final String? district;
  final int? minPrice;
  final int? maxPrice;
  final bool? isBoosted;
  final double? minRating;
  final String? searchQuery;

  const VendorFilter({
    this.category,
    this.district,
    this.minPrice,
    this.maxPrice,
    this.isBoosted,
    this.minRating,
    this.searchQuery,
  });

  VendorFilter copyWith({
    String? category,
    String? district,
    int? minPrice,
    int? maxPrice,
    bool? isBoosted,
    double? minRating,
    String? searchQuery,
  }) {
    return VendorFilter(
      category: category ?? this.category,
      district: district ?? this.district,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      isBoosted: isBoosted ?? this.isBoosted,
      minRating: minRating ?? this.minRating,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (category != null && category!.isNotEmpty) params['category'] = category;
    if (district != null && district != 'all' && district!.isNotEmpty) {
      params['district'] = district;
    }
    if (minPrice != null) params['min_price'] = minPrice;
    if (maxPrice != null) params['max_price'] = maxPrice;
    if (isBoosted == true) params['is_boosted'] = 1;
    if (minRating != null) params['min_rating'] = minRating;
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      params['q'] = searchQuery;
    }
    return params;
  }

  bool get hasActiveFilters =>
      (category != null && category!.isNotEmpty) ||
      (district != null && district != 'all' && district!.isNotEmpty) ||
      minPrice != null ||
      maxPrice != null ||
      isBoosted == true ||
      (searchQuery != null && searchQuery!.isNotEmpty);
}

// ============================================================
// GUEST MODEL
// ============================================================

class Guest {
  final String id;
  final String name;
  final String group;
  final String rsvpStatus;
  final String mealPreference;
  final bool consumesLiquor;

  const Guest({
    required this.id,
    required this.name,
    required this.group,
    this.rsvpStatus = 'Pending',
    this.mealPreference = 'Non-Veg',
    this.consumesLiquor = false,
  });

  factory Guest.fromJson(Map<String, dynamic> json) => Guest(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        group: json['group'] as String? ?? '',
        rsvpStatus: json['rsvp_status'] as String? ?? 'Pending',
        mealPreference: json['meal_preference'] as String? ?? 'Non-Veg',
        consumesLiquor: json['consumes_liquor'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'group': group,
        'rsvp_status': rsvpStatus,
        'meal_preference': mealPreference,
        'consumes_liquor': consumesLiquor,
      };

  Guest copyWith({String? name, String? group, String? rsvpStatus, String? mealPreference, bool? consumesLiquor}) {
    return Guest(
      id: id,
      name: name ?? this.name,
      group: group ?? this.group,
      rsvpStatus: rsvpStatus ?? this.rsvpStatus,
      mealPreference: mealPreference ?? this.mealPreference,
      consumesLiquor: consumesLiquor ?? this.consumesLiquor,
    );
  }
}

// ============================================================
// USER NEKATH MODEL
// ============================================================

class UserNekath {
  final String id;
  final String eventType;
  final String date;
  final String startTime;
  final String endTime;

  const UserNekath({
    required this.id,
    required this.eventType,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  factory UserNekath.fromJson(Map<String, dynamic> json) => UserNekath(
        id: json['id'] as String,
        eventType: json['event_type'] as String,
        date: json['date'] as String,
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'event_type': eventType,
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
      };
}

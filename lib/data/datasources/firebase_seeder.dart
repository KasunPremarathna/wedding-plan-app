import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseSeeder {
  static Future<void> seedDataIfNeeded() async {
    if (!kDebugMode) return; // Only run in debug mode

    final firestore = FirebaseFirestore.instance;

    try {
      // 1. Seed Auspicious Times
      final timesSnap = await firestore.collection('auspicious_times').limit(1).get();
      if (timesSnap.docs.isEmpty) {
        debugPrint('🌱 Seeding Auspicious Times...');
        await firestore.collection('auspicious_times').add({
          'id': '1',
          'month': 'May 2026',
          'dates': ['12', '15', '22', '28'],
          'description': 'Very good month for marriages according to astrology.',
        });
        await firestore.collection('auspicious_times').add({
          'id': '2',
          'month': 'June 2026',
          'dates': ['04', '08', '19', '21', '25'],
          'description': 'Ideal for morning wedding ceremonies.',
        });
        await firestore.collection('auspicious_times').add({
          'id': '3',
          'month': 'August 2026',
          'dates': ['10', '11', '20'],
          'description': 'A highly demanded month for outdoor weddings.',
        });
      }

      // 2. Seed Sponsored Banners
      final bannersSnap = await firestore.collection('sponsored_banners').limit(1).get();
      if (bannersSnap.docs.isEmpty) {
        debugPrint('🌱 Seeding Sponsored Banners...');
        await firestore.collection('sponsored_banners').add({
          'id': '1',
          'image_url': 'https://images.unsplash.com/photo-1519225421980-715cb0215aed?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
          'link': 'https://example.com/promo1',
          'vendor_id': 'demo_vendor_1'
        });
        await firestore.collection('sponsored_banners').add({
          'id': '2',
          'image_url': 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
          'link': 'https://example.com/promo2',
          'vendor_id': 'demo_vendor_2'
        });
      }
      
      debugPrint('✅ Seeding check complete.');
    } catch (e) {
      debugPrint('Error seeding Firebase: $e');
    }
  }
}

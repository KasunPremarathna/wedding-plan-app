import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_exceptions.dart';
import '../models/models.dart';

class VendorDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<ApiResult<List<Vendor>>> getVendors(VendorFilter filter) async {
    try {
      Query query = _firestore.collection('vendor_registrations')
          .where('status', isEqualTo: 'approved');

      if (filter.category != null && filter.category!.isNotEmpty) {
        query = query.where('category', isEqualTo: filter.category);
      }
      if (filter.district != null && filter.district != 'all' && filter.district!.isNotEmpty) {
        query = query.where('district', isEqualTo: filter.district);
      }
      
      final snapshot = await query.get();
      
      var vendorList = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Vendor.fromJson(data);
      }).toList();

      if (filter.minPrice != null) {
        vendorList = vendorList.where((v) => v.startingPriceLkr >= filter.minPrice!).toList();
      }
      if (filter.maxPrice != null) {
        vendorList = vendorList.where((v) => v.startingPriceLkr <= filter.maxPrice!).toList();
      }
      if (filter.minRating != null) {
        vendorList = vendorList.where((v) => v.rating >= filter.minRating!).toList();
      }
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final q = filter.searchQuery!.toLowerCase();
        vendorList = vendorList.where((v) => v.name.toLowerCase().contains(q) || v.category.toLowerCase().contains(q)).toList();
      }

      return ApiSuccess(vendorList);
    } catch (e) {
      return ApiFailure(AppException(message: 'Failed to fetch vendors: $e'));
    }
  }

  Future<ApiResult<Vendor>> getVendorById(String id) async {
    try {
      final doc = await _firestore.collection('vendor_registrations').doc(id).get();
      if (!doc.exists) return ApiFailure(NotFoundException(message: 'Vendor not found'));
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return ApiSuccess(Vendor.fromJson(data));
    } catch (e) {
      return ApiFailure(AppException(message: 'Failed to fetch vendor details: $e'));
    }
  }

  Future<ApiResult<List<SponsoredBanner>>> getSponsoredBanners() async {
    try {
      final snap = await _firestore.collection('sponsored_banners').get();
      final list = snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return SponsoredBanner.fromJson(data);
      }).toList();
      return ApiSuccess(list);
    } catch (e) {
      return ApiFailure(AppException(message: 'Failed to fetch banners: $e'));
    }
  }

  Future<ApiResult<List<AuspiciousTime>>> getAuspiciousTimes() async {
    try {
      final snap = await _firestore.collection('auspicious_times').get();
      final list = snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return AuspiciousTime.fromJson(data);
      }).toList();
      return ApiSuccess(list);
    } catch (e) {
      return ApiFailure(AppException(message: 'Failed to fetch times: $e'));
    }
  }

  Future<ApiResult<bool>> sendWhatsappInquiry({
    required String vendorId,
    required String name,
    required String phone,
    required String message,
  }) async {
    try {
      // 1. Add notification to Firestore so it shows in the vendor's dashboard
      await _firestore.collection('vendor_notifications').add({
        'vendor_id': vendorId,
        'type': 'new_message',
        'title': 'New Inquiry from $name',
        'message': 'Phone: $phone\nMessage: $message',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Increment inquiries_count analytics counter
      await _firestore.collection('vendor_registrations').doc(vendorId).update({
        'inquiries_count': FieldValue.increment(1),
      });

      // 2. Fetch vendor's FCM token
      final vendorDoc = await _firestore.collection('vendor_registrations').doc(vendorId).get();
      String? fcmToken = vendorDoc.data()?['fcm_token'];

      if (fcmToken == null || fcmToken.isEmpty) {
        final userDoc = await _firestore.collection('users').doc(vendorId).get();
        fcmToken = userDoc.data()?['fcm_token'];
      }

      // 3. Send push notification via PHP backend
      if (fcmToken != null && fcmToken.isNotEmpty) {
        final dio = Dio();
        await dio.post(
          'https://apiwedding.kasunpremarathna.com/send_notification.php',
          data: {
            'token': fcmToken,
            'title': 'New Inquiry from $name',
            'body': 'Phone: $phone\n$message',
            'data': {
              'type': 'inquiry',
              'vendor_id': vendorId,
            }
          },
        );
      }

      return const ApiSuccess(true);
    } catch (e) {
      return ApiFailure(AppException(message: 'Failed to send inquiry notification: $e'));
    }
  }
}

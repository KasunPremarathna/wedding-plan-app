import 'package:cloud_firestore/cloud_firestore.dart';
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
    return const ApiSuccess([]); // Fallback to empty for now
  }

  Future<ApiResult<List<AuspiciousTime>>> getAuspiciousTimes() async {
    return const ApiSuccess([]); // Fallback to empty for now
  }

  Future<ApiResult<bool>> sendWhatsappInquiry({
    required String vendorId,
    required String name,
    required String phone,
    required String message,
  }) async {
    // In a real app we'd log this or send an email/notification.
    // We already have Firebase push notifications coming up in Phase 3.
    return const ApiSuccess(true);
  }
}

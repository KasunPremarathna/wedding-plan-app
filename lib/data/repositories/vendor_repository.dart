import '../../core/network/api_exceptions.dart';
import '../datasources/vendor_data_source.dart';
import '../models/models.dart';

class VendorRepository {
  final VendorDataSource _dataSource;

  VendorRepository({VendorDataSource? dataSource})
      : _dataSource = dataSource ?? VendorDataSource();

  Future<ApiResult<List<Vendor>>> getVendors(VendorFilter filter) =>
      _dataSource.getVendors(filter);

  Future<ApiResult<Vendor>> getVendorById(String id) =>
      _dataSource.getVendorById(id);

  Future<ApiResult<List<SponsoredBanner>>> getSponsoredBanners() =>
      _dataSource.getSponsoredBanners();

  Future<ApiResult<List<AuspiciousTime>>> getAuspiciousTimes() =>
      _dataSource.getAuspiciousTimes();

  Future<ApiResult<bool>> sendWhatsappInquiry({
    required String vendorId,
    required String name,
    required String phone,
    required String message,
  }) =>
      _dataSource.sendWhatsappInquiry(
        vendorId: vendorId,
        name: name,
        phone: phone,
        message: message,
      );
}

import 'package:dio/dio.dart';
import 'package:qa3ty_app/core/networking/api_exceptions.dart';
import 'package:qa3ty_app/core/networking/dio_factory.dart';

class VenueSettings {
  final String venueName;
  final String ownerName;
  final String phone;
  final String email;
  final String planName; // الباقة الذهبية
  final DateTime planStartDate;
  final DateTime planEndDate;
  final bool isTrial;

  const VenueSettings({
    this.venueName = 'قاعات الأندلس والمروج',
    this.ownerName = 'أحمد المنشاوي',
    this.phone = '٠١٠٠٠٠٠٠٠٠٠',
    this.email = 'almanchawi@qa3aty.com',
    this.planName = 'الباقة الاحترافية السنوية',
    required this.planStartDate,
    required this.planEndDate,
    this.isTrial = true,
  });

  int get daysLeft => planEndDate.difference(DateTime.now()).inDays;
}

abstract class SettingsRepository {
  Future<VenueSettings> getSettings();
  Future<void> updateSettings(VenueSettings settings);
}

class RemoteSettingsRepository implements SettingsRepository {
  final Dio _dio = DioFactory.getDio();

  @override
  Future<VenueSettings> getSettings() async {
    try {
      final response = await _dio.get('/auth/me');
      final data = response.data is Map && response.data['data'] != null
          ? response.data['data']
          : {};

      final name = data['full_name']?.toString() ?? 'مدير المنشأة';
      final username = data['username']?.toString() ?? 'admin';

      return VenueSettings(
        venueName: 'قاعات $name',
        ownerName: name,
        phone: data['phone']?.toString() ?? '٠١٠٠٠٠٠٠٠٠٠',
        email: '$username@qa3aty.com',
        planName: 'الباقة الاحترافية السنوية',
        planStartDate: DateTime(2026, 1, 1),
        planEndDate: DateTime(2026, 12, 31),
        isTrial: false,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> updateSettings(VenueSettings settings) async {
    // Subscription details are managed on cloud per Section 8.11
  }
}

class MockSettingsRepository implements SettingsRepository {
  // TODO(API): Replace in-memory mock data with Retrofit / Dio API service
  VenueSettings _settings = VenueSettings(
    planStartDate: DateTime(2026, 1, 1),
    planEndDate: DateTime(2026, 12, 31),
    isTrial: true,
  );

  @override
  Future<VenueSettings> getSettings() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _settings;
  }

  @override
  Future<void> updateSettings(VenueSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _settings = settings;
  }
}

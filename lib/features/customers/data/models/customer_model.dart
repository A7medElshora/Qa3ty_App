import 'package:dio/dio.dart';
import 'package:qa3ty_app/core/helpers/booking_financials.dart';
import 'package:qa3ty_app/core/helpers/phone_number_normalizer.dart';
import 'package:qa3ty_app/core/networking/api_exceptions.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final int totalBookings;
  final int totalSpent;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.totalBookings,
    required this.totalSpent,
  });
}

abstract class CustomersRepository {
  Future<List<Customer>> getCustomers({String? search});
  Future<Customer?> findCustomerByPhone(String phone);
  Future<Customer?> getCustomerById(String id);
  Future<Customer> addCustomer(Customer customer);
  Future<void> updateCustomer(Customer customer);
  Future<void> deleteCustomer(String id);
}

class RemoteCustomersRepository implements CustomersRepository {
  final Dio _dio;

  RemoteCustomersRepository(this._dio);

  List<Map<String, dynamic>> _extractItems(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is Map<String, dynamic> && data['items'] is List) {
        return (data['items'] as List)
            .whereType<Map<String, dynamic>>()
            .toList();
      }
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
    } else if (responseData is List) {
      return responseData.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  @override
  Future<List<Customer>> getCustomers({String? search}) async {
    try {
      final responses = await Future.wait([
        _dio.get(
          '/customers',
          queryParameters: {
            'limit': 50,
            'offset': 0,
            if (search != null && search.isNotEmpty) 'search': search,
          },
        ),
        _dio.get('/bookings'),
      ]);

      final customers = _extractItems(responses[0].data);
      final bookings = _extractItems(responses[1].data);
      final bookingCounts = <String, int>{};
      final paidTotals = <String, int>{};
      for (final booking in bookings) {
        if (booking['status'] == 'cancelled') continue;
        final customer = booking['customers'] as Map<String, dynamic>?;
        final customerId =
            booking['customer_id']?.toString() ?? customer?['id']?.toString();
        if (customerId == null || customerId.isEmpty) continue;

        bookingCounts.update(customerId, (count) => count + 1,
            ifAbsent: () => 1);
        paidTotals.update(
          customerId,
          (total) => total + bookingPaidAmount(booking).round(),
          ifAbsent: () => bookingPaidAmount(booking).round(),
        );
      }

      return customers.map((json) {
        final id = json['id']?.toString() ?? '';
        final reportedBookings = (json['bookings_count'] as num?)?.toInt() ?? 0;
        final reportedSpent =
            ((json['total_spent'] ?? json['total_paid']) as num?)?.round() ?? 0;
        final aggregatedBookings = bookingCounts[id] ?? 0;
        final aggregatedSpent = paidTotals[id] ?? 0;
        return Customer(
          id: id,
          name: json['full_name']?.toString() ?? '',
          phone: json['phone']?.toString() ?? '',
          email: json['address']?.toString(),
          totalBookings: reportedBookings > aggregatedBookings
              ? reportedBookings
              : aggregatedBookings,
          totalSpent:
              reportedSpent > aggregatedSpent ? reportedSpent : aggregatedSpent,
        );
      }).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Customer?> findCustomerByPhone(String phone) async {
    final normalizedPhone = normalizePhoneNumber(phone);
    if (normalizedPhone.isEmpty) return null;

    try {
      final response = await _dio.get(
        '/customers',
        queryParameters: {
          'limit': 50,
          'offset': 0,
          'search': normalizedPhone,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
        ),
      );

      var customers = _extractItems(response.data).map((json) => Customer(
            id: json['id']?.toString() ?? '',
            name: json['full_name']?.toString() ?? '',
            phone: json['phone']?.toString() ?? '',
            email: json['address']?.toString(),
            totalBookings: (json['bookings_count'] as num?)?.toInt() ?? 0,
            totalSpent: ((json['total_spent'] ?? json['total_paid']) as num?)
                    ?.round() ??
                0,
          ));

      for (final customer in customers) {
        if (phoneNumbersMatch(customer.phone, phone)) return customer;
      }

      if (normalizedPhone.length >= 7) {
        var offset = 0;
        const pageSize = 50;
        while (offset < 500) {
          final fallbackResponse = await _dio.get(
            '/customers',
            queryParameters: {'limit': pageSize, 'offset': offset},
            options: Options(
              receiveTimeout: const Duration(seconds: 8),
              sendTimeout: const Duration(seconds: 8),
            ),
          );
          final items = _extractItems(fallbackResponse.data);
          customers = items.map((json) => Customer(
                id: json['id']?.toString() ?? '',
                name: json['full_name']?.toString() ?? '',
                phone: json['phone']?.toString() ?? '',
                email: json['address']?.toString(),
                totalBookings: (json['bookings_count'] as num?)?.toInt() ?? 0,
                totalSpent:
                    ((json['total_spent'] ?? json['total_paid']) as num?)
                            ?.round() ??
                        0,
              ));

          for (final customer in customers) {
            if (phoneNumbersMatch(customer.phone, phone)) return customer;
          }
          if (items.length < pageSize) break;
          offset += pageSize;
        }
      }
      return null;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Customer?> getCustomerById(String id) async {
    try {
      final response = await _dio.get('/customers/$id');
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          final json = data['data'] as Map<String, dynamic>;
          final bookings = (json['bookings'] as List<dynamic>?) ?? [];
          double spent = 0;
          for (final b in bookings) {
            if (b is Map<String, dynamic>) {
              spent += bookingPaidAmount(b);
            }
          }
          final reportedSpent =
              ((json['total_spent'] ?? json['total_paid']) as num?)
                      ?.toDouble() ??
                  0;

          return Customer(
            id: json['id']?.toString() ?? id,
            name: json['full_name']?.toString() ?? '',
            phone: json['phone']?.toString() ?? '',
            email: json['address']?.toString(),
            totalBookings: bookings.length >
                    ((json['bookings_count'] as num?)?.toInt() ?? 0)
                ? bookings.length
                : ((json['bookings_count'] as num?)?.toInt() ?? 0),
            totalSpent: spent.round() > reportedSpent
                ? spent.round()
                : reportedSpent.round(),
          );
        }
      }
      return null;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Customer> addCustomer(Customer customer) async {
    try {
      final response = await _dio.post(
        '/customers',
        data: {
          'full_name': customer.name,
          'phone': customer.phone,
          'address': customer.email ?? '',
          'notes': '',
        },
      );
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        final data = responseData['data'];
        if (data is Map<String, dynamic> &&
            data['id']?.toString().isNotEmpty == true) {
          return Customer(
            id: data['id'].toString(),
            name: data['full_name']?.toString() ?? customer.name,
            phone: data['phone']?.toString() ?? customer.phone,
            email: data['address']?.toString() ?? customer.email,
            totalBookings: 0,
            totalSpent: 0,
          );
        }
      }
      throw StateError(
          'The server created a customer without returning its ID.');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    try {
      await _dio.put(
        '/customers/${customer.id}',
        data: {
          'full_name': customer.name,
          'phone': customer.phone,
          'address': customer.email ?? '',
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    try {
      await _dio.delete('/customers/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

class MockCustomersRepository implements CustomersRepository {
  // TODO(API): Replace in-memory mock data with Retrofit / Dio API service
  final List<Customer> _customers = [
    const Customer(
      id: 'cust_1',
      name: 'محمد عبد الله',
      phone: '٠١٠١٢٣٤٥٦٧٨',
      email: 'mohamed@example.com',
      totalBookings: 2,
      totalSpent: 66000,
    ),
    const Customer(
      id: 'cust_2',
      name: 'سارة محمود',
      phone: '٠١١٩٨٧٦٥٤٣٢',
      email: 'sarah@example.com',
      totalBookings: 1,
      totalSpent: 40000,
    ),
    const Customer(
      id: 'cust_3',
      name: 'كريم ياسر',
      phone: '٠١٢٣٤٥٦٧٨٩٠',
      email: 'kareem@example.com',
      totalBookings: 1,
      totalSpent: 33000,
    ),
    const Customer(
      id: 'cust_4',
      name: 'طارق حسام',
      phone: '٠١٥١١٢٢٣٣٤٤',
      totalBookings: 1,
      totalSpent: 40000,
    ),
  ];

  @override
  Future<List<Customer>> getCustomers({String? search}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (search != null && search.isNotEmpty) {
      final normalizedSearch = normalizePhoneNumber(search);
      return _customers
          .where((c) =>
              c.name.contains(search) ||
              c.phone.contains(search) ||
              (normalizedSearch.isNotEmpty &&
                  normalizePhoneNumber(c.phone).contains(normalizedSearch)))
          .toList();
    }
    return List.from(_customers);
  }

  @override
  Future<Customer?> findCustomerByPhone(String phone) async {
    final normalizedPhone = normalizePhoneNumber(phone);
    if (normalizedPhone.isEmpty) return null;

    for (final customer in _customers) {
      if (normalizePhoneNumber(customer.phone) == normalizedPhone) {
        return customer;
      }
    }
    return null;
  }

  @override
  Future<Customer?> getCustomerById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Customer> addCustomer(Customer customer) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final createdCustomer = Customer(
      id: customer.id.isNotEmpty
          ? customer.id
          : 'cust_${DateTime.now().millisecondsSinceEpoch}',
      name: customer.name,
      phone: customer.phone,
      email: customer.email,
      totalBookings: customer.totalBookings,
      totalSpent: customer.totalSpent,
    );
    _customers.add(createdCustomer);
    return createdCustomer;
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final idx = _customers.indexWhere((c) => c.id == customer.id);
    if (idx != -1) _customers[idx] = customer;
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _customers.removeWhere((c) => c.id == id);
  }
}

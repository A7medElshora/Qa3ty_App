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
  Future<List<Customer>> getCustomers();
  Future<Customer?> getCustomerById(String id);
  Future<void> addCustomer(Customer customer);
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
  Future<List<Customer>> getCustomers() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.from(_customers);
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
  Future<void> addCustomer(Customer customer) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _customers.add(customer);
  }
}

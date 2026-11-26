// In-memory database — works on ALL platforms (web, Android, iOS, desktop)
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static bool _initialized = false;

  // ─── In-memory tables ───────────────────────────────────────────────────────
  static final List<Map<String, dynamic>> _users = [];
  static final List<Map<String, dynamic>> _providers = [];
  static final List<Map<String, dynamic>> _categories = [];
  static final List<Map<String, dynamic>> _bookings = [];

  static int _userId = 1;
  static int _providerId = 1;
  static int _categoryId = 1;
  static int _bookingId = 1;

  DatabaseHelper._init();

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    await _seedData();
  }

  Future<void> _seedData() async {
    final now = DateTime.now().toIso8601String();

    // Admin
    _users.add({
      'id': _userId++,
      'name': 'Admin',
      'email': 'admin@hyperlocal.com',
      'password': 'admin123',
      'phone': '9999999999',
      'address': 'Admin Office',
      'role': 'admin',
      'created_at': now,
    });

    // Categories
    final cats = [
      {'name': 'Plumbing', 'icon': '🔧', 'description': 'Pipe repairs, leaks, installations'},
      {'name': 'Electrician', 'icon': '⚡', 'description': 'Wiring, switches, appliances'},
      {'name': 'Cleaning', 'icon': '🧹', 'description': 'Home and office cleaning'},
      {'name': 'Carpentry', 'icon': '🪚', 'description': 'Furniture, doors, windows'},
      {'name': 'Painting', 'icon': '🎨', 'description': 'Interior and exterior painting'},
      {'name': 'Gardening', 'icon': '🌿', 'description': 'Lawn care, pruning, planting'},
    ];
    for (final c in cats) {
      _categories.add({...c, 'id': _categoryId++});
    }

    // Providers
    final provs = [
      {'name': 'Ramesh Kumar', 'email': 'ramesh@example.com', 'password': 'pass123', 'phone': '9876543210', 'address': 'Sector 15, Delhi', 'category_id': 1, 'description': 'Expert plumber with 10 years of experience', 'rating': 4.5},
      {'name': 'Suresh Verma', 'email': 'suresh@example.com', 'password': 'pass123', 'phone': '9876543211', 'address': 'Lajpat Nagar, Delhi', 'category_id': 2, 'description': 'Certified electrician, 24/7 available', 'rating': 4.2},
      {'name': 'Priya Sharma', 'email': 'priya@example.com', 'password': 'pass123', 'phone': '9876543212', 'address': 'Noida, UP', 'category_id': 3, 'description': 'Professional home cleaning specialist', 'rating': 4.8},
      {'name': 'Ajay Singh', 'email': 'ajay@example.com', 'password': 'pass123', 'phone': '9876543213', 'address': 'Gurgaon, Haryana', 'category_id': 4, 'description': 'Expert carpenter for all wood works', 'rating': 4.3},
      {'name': 'Mohan Das', 'email': 'mohan@example.com', 'password': 'pass123', 'phone': '9876543214', 'address': 'Dwarka, Delhi', 'category_id': 5, 'description': 'Interior and exterior painting expert', 'rating': 4.0},
      {'name': 'Geeta Devi', 'email': 'geeta@example.com', 'password': 'pass123', 'phone': '9876543215', 'address': 'Faridabad, Haryana', 'category_id': 6, 'description': 'Garden design and maintenance expert', 'rating': 4.6},
    ];
    for (final p in provs) {
      _providers.add({...p, 'id': _providerId++, 'is_active': 1, 'created_at': now});
    }
  }

  // ─── Users ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    await ensureInitialized();
    try {
      return _users.firstWhere(
        (u) => u['email'] == email && u['password'] == password,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> loginProvider(String email, String password) async {
    await ensureInitialized();
    try {
      return _providers.firstWhere(
        (p) => p['email'] == email && p['password'] == password,
      );
    } catch (_) {
      return null;
    }
  }

  Future<int> registerUser(Map<String, dynamic> user) async {
    await ensureInitialized();
    final newUser = {...user, 'id': _userId++};
    _users.add(newUser);
    return newUser['id'];
  }

  Future<bool> emailExists(String email) async {
    await ensureInitialized();
    return _users.any((u) => u['email'] == email);
  }

  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    await ensureInitialized();
    return _users.where((u) => u['role'] == 'customer').toList();
  }

  Future<int> deleteUser(int id) async {
    final before = _users.length;
    _users.removeWhere((u) => u['id'] == id);
    return before - _users.length;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    await ensureInitialized();
    try {
      return _users.firstWhere((u) => u['id'] == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Providers ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllProviders() async {
    await ensureInitialized();
    return List.from(_providers);
  }

  Future<List<Map<String, dynamic>>> getProvidersByCategory(int categoryId) async {
    await ensureInitialized();
    return _providers
        .where((p) => p['category_id'] == categoryId && p['is_active'] == 1)
        .toList();
  }

  Future<int> addProvider(Map<String, dynamic> provider) async {
    await ensureInitialized();
    final newProv = {...provider, 'id': _providerId++};
    _providers.add(newProv);
    return newProv['id'];
  }

  Future<int> updateProvider(Map<String, dynamic> provider) async {
    final idx = _providers.indexWhere((p) => p['id'] == provider['id']);
    if (idx != -1) {
      _providers[idx] = provider;
      return 1;
    }
    return 0;
  }

  Future<int> deleteProvider(int id) async {
    final before = _providers.length;
    _providers.removeWhere((p) => p['id'] == id);
    return before - _providers.length;
  }

  Future<int> toggleProviderStatus(int id, int status) async {
    final idx = _providers.indexWhere((p) => p['id'] == id);
    if (idx != -1) {
      _providers[idx] = {..._providers[idx], 'is_active': status};
      return 1;
    }
    return 0;
  }

  Future<Map<String, dynamic>?> getProviderById(int id) async {
    await ensureInitialized();
    try {
      return _providers.firstWhere((p) => p['id'] == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Categories ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    await ensureInitialized();
    return List.from(_categories);
  }

  Future<Map<String, dynamic>?> getCategoryById(int id) async {
    await ensureInitialized();
    try {
      return _categories.firstWhere((c) => c['id'] == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Bookings ───────────────────────────────────────────────────────────────

  Future<int> createBooking(Map<String, dynamic> booking) async {
    await ensureInitialized();
    final newBooking = {...booking, 'id': _bookingId++};
    _bookings.add(newBooking);
    return newBooking['id'];
  }

  Future<List<Map<String, dynamic>>> getBookingsByCustomer(int customerId) async {
    await ensureInitialized();
    final result = _bookings
        .where((b) => b['customer_id'] == customerId)
        .toList()
      ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return result;
  }

  Future<List<Map<String, dynamic>>> getBookingsByProvider(int providerId) async {
    await ensureInitialized();
    final result = _bookings
        .where((b) => b['provider_id'] == providerId)
        .toList()
      ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return result;
  }

  Future<List<Map<String, dynamic>>> getAllBookings() async {
    await ensureInitialized();
    final result = List<Map<String, dynamic>>.from(_bookings)
      ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return result;
  }

  Future<int> updateBookingStatus(int id, String status) async {
    final idx = _bookings.indexWhere((b) => b['id'] == id);
    if (idx != -1) {
      _bookings[idx] = {
        ..._bookings[idx],
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      return 1;
    }
    return 0;
  }
}

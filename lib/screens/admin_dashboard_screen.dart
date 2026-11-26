import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../database/database_helper.dart';
import '../models/provider_model.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Customers'),
            Tab(icon: Icon(Icons.handyman), text: 'Providers'),
            Tab(icon: Icon(Icons.book_online), text: 'Bookings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CustomersTab(),
          _ProvidersTab(),
          _BookingsTab(),
        ],
      ),
    );
  }
}

// ─── Customers Tab ───────────────────────────────────────────────────────────

class _CustomersTab extends StatefulWidget {
  @override
  State<_CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<_CustomersTab> {
  List<UserModel> _customers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await DatabaseHelper.instance.getAllCustomers();
    setState(() {
      _customers = data.map((e) => UserModel.fromMap(e)).toList();
      _loading = false;
    });
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Remove this customer from the system?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteUser(id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_customers.isEmpty) {
      return const Center(child: Text('No customers registered yet', style: TextStyle(color: kTextSecondary)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _customers.length,
        itemBuilder: (_, i) {
          final c = _customers[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: kPrimaryColor,
                child: Text(c.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.email, style: const TextStyle(fontSize: 12)),
                  Text(c.phone, style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _delete(c.id!),
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}

// ─── Providers Tab ───────────────────────────────────────────────────────────

class _ProvidersTab extends StatefulWidget {
  @override
  State<_ProvidersTab> createState() => _ProvidersTabState();
}

class _ProvidersTabState extends State<_ProvidersTab> {
  List<ProviderModel> _providers = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await DatabaseHelper.instance.getAllProviders();
    final c = await DatabaseHelper.instance.getAllCategories();
    setState(() {
      _providers = p.map((e) => ProviderModel.fromMap(e)).toList();
      _categories = c;
      _loading = false;
    });
  }

  String _catName(int catId) {
    final cat = _categories.firstWhere((c) => c['id'] == catId, orElse: () => {'name': 'Unknown'});
    return cat['name'];
  }

  Future<void> _toggleStatus(ProviderModel p) async {
    await DatabaseHelper.instance.toggleProviderStatus(p.id!, p.isActive == 1 ? 0 : 1);
    _load();
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Provider'),
        content: const Text('Remove this provider permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteProvider(id);
      _load();
    }
  }

  void _showAddProvider() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddProviderSheet(
        categories: _categories,
        onAdded: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: _providers.isEmpty
            ? const Center(
                child: Text('No providers yet', style: TextStyle(color: kTextSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _providers.length,
                itemBuilder: (_, i) {
                  final p = _providers[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: p.isActive == 1 ? kPrimaryColor : Colors.grey,
                            child: Text(p.name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('${_catName(p.categoryId)} · ⭐${p.rating}',
                                    style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                                Text(p.phone,
                                    style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Switch(
                                value: p.isActive == 1,
                                onChanged: (_) => _toggleStatus(p),
                                activeColor: kPrimaryColor,
                              ),
                              Text(p.isActive == 1 ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: p.isActive == 1 ? Colors.green : Colors.grey)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _delete(p.id!),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProvider,
        icon: const Icon(Icons.add),
        label: const Text('Add Provider'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _AddProviderSheet extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final VoidCallback onAdded;

  const _AddProviderSheet({required this.categories, required this.onAdded});

  @override
  State<_AddProviderSheet> createState() => _AddProviderSheetState();
}

class _AddProviderSheetState extends State<_AddProviderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int? _selectedCategoryId;
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a category')));
      return;
    }
    setState(() => _saving = true);
    final provider = ProviderModel(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      categoryId: _selectedCategoryId!,
      description: _descCtrl.text.trim(),
      isActive: 1,
      rating: 0.0,
      createdAt: DateTime.now().toIso8601String(),
    );
    await DatabaseHelper.instance.addProvider(provider.toMap());
    if (!mounted) return;
    Navigator.pop(context);
    widget.onAdded();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add New Provider',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v == null || !v.contains('@') ? 'Valid email' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) => v == null || v.length < 4 ? 'Min 4 chars' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (v) => v == null || v.length < 10 ? 'Valid phone' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Service Category'),
                items: widget.categories
                    .map((c) => DropdownMenuItem<int>(
                          value: c['id'],
                          child: Text('${c['icon']} ${c['name']}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
                validator: (v) => v == null ? 'Select category' : null,
              ),
              const SizedBox(height: 20),
              _saving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(onPressed: _save, child: const Text('Add Provider')),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bookings Tab ─────────────────────────────────────────────────────────────

class _BookingsTab extends StatefulWidget {
  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab> {
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final b = await DatabaseHelper.instance.getAllBookings();
    final c = await DatabaseHelper.instance.getAllCategories();
    setState(() {
      _bookings = b;
      _categories = c;
      _loading = false;
    });
  }

  String _catName(int catId) {
    final cat = _categories.firstWhere((c) => c['id'] == catId, orElse: () => {'name': '?', 'icon': ''});
    return '${cat['icon']} ${cat['name']}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_bookings.isEmpty) {
      return const Center(child: Text('No bookings in system', style: TextStyle(color: kTextSecondary)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        itemBuilder: (_, i) {
          final b = _bookings[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(b['service_description'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor(b['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(b['status'],
                            style: TextStyle(
                                color: statusColor(b['status']),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Category: ${_catName(b['category_id'])}',
                      style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                  Text('Date: ${b['scheduled_date']}',
                      style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                  Text('Customer ID: ${b['customer_id']} · Provider ID: ${b['provider_id']}',
                      style: const TextStyle(fontSize: 11, color: kTextSecondary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


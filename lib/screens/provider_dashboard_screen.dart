import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../models/booking_model.dart';
import '../database/database_helper.dart';
import '../utils/app_theme.dart';


class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.currentProvider != null) {
      await context.read<BookingProvider>().loadProviderBookings(auth.currentProvider!['id']);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bp = context.watch<BookingProvider>();
    final provider = auth.currentProvider;

    final allBookings = bp.bookings;
    final pending = allBookings.where((b) => b.status == 'pending').toList();
    final filtered = _filter == 'all'
        ? allBookings
        : allBookings.where((b) => b.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(provider?['name'] ?? 'Provider Dashboard'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) async {
              if (value == 'logout') {
                await auth.logout();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(provider?['email'] ?? '',
                    style: const TextStyle(fontSize: 13, color: kTextSecondary)),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'New Requests (${pending.length})'),
            const Tab(text: 'All Bookings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Pending requests
          bp.isLoading
              ? const Center(child: CircularProgressIndicator())
              : pending.isEmpty
                  ? const _EmptyState(
                      icon: Icons.inbox,
                      message: 'No new booking requests')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: pending.length,
                        itemBuilder: (_, i) => _ProviderBookingCard(
                          booking: pending[i],
                          showActions: true,
                          onAccept: () => _handleStatus(pending[i].id!, 'accepted'),
                          onReject: () => _handleStatus(pending[i].id!, 'rejected'),
                        ),
                      ),
                    ),

          // Tab 2: All bookings with filter
          Column(
            children: [
              Container(
                color: kPrimaryColor,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['all', 'pending', 'accepted', 'rejected', 'cancelled', 'completed']
                        .map((s) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(s == 'all' ? 'All' : _capitalize(s)),
                                selected: _filter == s,
                                onSelected: (_) => setState(() => _filter = s),
                                selectedColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: _filter == s ? kPrimaryColor : Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                backgroundColor: Colors.transparent,
                                side: const BorderSide(color: Colors.white54),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              Expanded(
                child: bp.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? _EmptyState(
                            icon: Icons.calendar_today,
                            message: _filter == 'all' ? 'No bookings yet' : 'No ${_capitalize(_filter)} bookings')
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) => _ProviderBookingCard(
                                booking: filtered[i],
                                showActions: filtered[i].status == 'pending',
                                onAccept: () => _handleStatus(filtered[i].id!, 'accepted'),
                                onReject: () => _handleStatus(filtered[i].id!, 'rejected'),
                                onComplete: filtered[i].status == 'accepted'
                                    ? () => _handleStatus(filtered[i].id!, 'completed')
                                    : null,
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleStatus(int bookingId, String status) async {
    final auth = context.read<AuthProvider>();
    await context.read<BookingProvider>().updateStatus(
      bookingId,
      status,
      providerId: auth.currentProvider?['id'],
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking ${_capitalize(status)}'),
        backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
      ),
    );
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}

class _ProviderBookingCard extends StatefulWidget {
  final BookingModel booking;
  final bool showActions;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onComplete;

  const _ProviderBookingCard({
    required this.booking,
    this.showActions = false,
    this.onAccept,
    this.onReject,
    this.onComplete,
  });

  @override
  State<_ProviderBookingCard> createState() => _ProviderBookingCardState();
}

class _ProviderBookingCardState extends State<_ProviderBookingCard> {
  Map<String, dynamic>? _customer;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    final c = await DatabaseHelper.instance.getUserById(widget.booking.customerId);
    if (mounted) setState(() => _customer = c);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.booking.serviceDescription,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor(widget.booking.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.booking.statusLabel,
                    style: TextStyle(
                        color: statusColor(widget.booking.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_customer != null)
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: kTextSecondary),
                  const SizedBox(width: 4),
                  Text(_customer!['name'],
                      style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                  const SizedBox(width: 12),
                  const Icon(Icons.phone, size: 14, color: kTextSecondary),
                  const SizedBox(width: 4),
                  Text(_customer!['phone'],
                      style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                ],
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: kTextSecondary),
                const SizedBox(width: 4),
                Text(widget.booking.scheduledDate,
                    style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                const SizedBox(width: 12),
                const Icon(Icons.location_on, size: 14, color: kTextSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(widget.booking.address,
                      style: const TextStyle(color: kTextSecondary, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            if (widget.booking.notes != null && widget.booking.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Note: ${widget.booking.notes}',
                  style: const TextStyle(color: kTextSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
            ],
            if (widget.showActions || widget.onComplete != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (widget.showActions) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onReject,
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onAccept,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ),
                  ],
                  if (widget.onComplete != null) ...[
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: widget.onComplete,
                      icon: const Icon(Icons.done_all, size: 16),
                      label: const Text('Mark Complete'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: kTextSecondary),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: kTextSecondary)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking_model.dart';
import '../providers/booking_provider.dart';
import '../providers/auth_provider.dart';
import '../database/database_helper.dart';
import '../utils/app_theme.dart';

class BookingStatusScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingStatusScreen({super.key, required this.booking});

  @override
  State<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

class _BookingStatusScreenState extends State<BookingStatusScreen> {
  Map<String, dynamic>? _provider;
  Map<String, dynamic>? _category;
  late BookingModel _booking;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final prov = await DatabaseHelper.instance.getProviderById(_booking.providerId);
    final cat = await DatabaseHelper.instance.getCategoryById(_booking.categoryId);
    setState(() {
      _provider = prov;
      _category = cat;
    });
  }

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final auth = context.read<AuthProvider>();
      await context.read<BookingProvider>().updateStatus(
        _booking.id!,
        'cancelled',
        customerId: auth.currentUser?.id,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCancel = _booking.status == 'pending' || _booking.status == 'accepted';

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: statusColor(_booking.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor(_booking.status).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(statusIcon(_booking.status),
                      color: statusColor(_booking.status), size: 56),
                  const SizedBox(height: 8),
                  Text(
                    _booking.statusLabel,
                    style: TextStyle(
                      color: statusColor(_booking.status),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusMessage(_booking.status),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: kTextSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Booking info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Booking Information',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(height: 20),
                    _InfoRow(icon: Icons.confirmation_number, label: 'Booking ID',
                        value: '#${_booking.id}'),
                    _InfoRow(icon: Icons.build_circle_outlined, label: 'Service',
                        value: _booking.serviceDescription),
                    if (_category != null)
                      _InfoRow(icon: Icons.category_outlined, label: 'Category',
                          value: '${_category!['icon']} ${_category!['name']}'),
                    _InfoRow(icon: Icons.calendar_today, label: 'Scheduled Date',
                        value: _booking.scheduledDate),
                    _InfoRow(icon: Icons.location_on_outlined, label: 'Address',
                        value: _booking.address),
                    if (_booking.notes != null && _booking.notes!.isNotEmpty)
                      _InfoRow(icon: Icons.note_outlined, label: 'Notes',
                          value: _booking.notes!),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Provider info
            if (_provider != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Service Provider',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Divider(height: 20),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: kPrimaryColor,
                            radius: 24,
                            child: Text(
                              _provider!['name'][0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_provider!['name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(_provider!['phone'],
                                    style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                                if (_provider!['address'] != null)
                                  Text(_provider!['address'],
                                      style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              Text('${(_provider!['rating'] as num).toStringAsFixed(1)}'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            if (canCancel)
              ElevatedButton.icon(
                onPressed: _cancel,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Booking'),
              ),
          ],
        ),
      ),
    );
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Your booking is waiting for provider confirmation';
      case 'accepted':
        return 'Provider has accepted your booking';
      case 'rejected':
        return 'Provider has rejected your booking';
      case 'cancelled':
        return 'This booking was cancelled';
      case 'completed':
        return 'Service has been completed';
      default:
        return '';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: kTextSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                Text(value, style: const TextStyle(color: kTextPrimary, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


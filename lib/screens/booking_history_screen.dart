import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../models/booking_model.dart';
import '../utils/app_theme.dart';
import 'booking_status_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context.read<BookingProvider>().loadCustomerBookings(auth.currentUser!.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BookingProvider>();
    final bookings = _filter == 'all'
        ? bp.bookings
        : bp.bookings.where((b) => b.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: kPrimaryColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                : bookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today, size: 64, color: kTextSecondary),
                            const SizedBox(height: 12),
                            Text(
                              _filter == 'all'
                                  ? 'No bookings yet'
                                  : 'No ${_capitalize(_filter)} bookings',
                              style: const TextStyle(color: kTextSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          final auth = context.read<AuthProvider>();
                          if (auth.currentUser != null) {
                            await context
                                .read<BookingProvider>()
                                .loadCustomerBookings(auth.currentUser!.id!);
                          }
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: bookings.length,
                          itemBuilder: (_, i) => _BookingCard(
                            booking: bookings[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingStatusScreen(booking: bookings[i]),
                              ),
                            ).then((_) {
                              final auth = context.read<AuthProvider>();
                              if (auth.currentUser != null) {
                                context
                                    .read<BookingProvider>()
                                    .loadCustomerBookings(auth.currentUser!.id!);
                              }
                            }),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.serviceDescription,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor(booking.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon(booking.status),
                            color: statusColor(booking.status), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          booking.statusLabel,
                          style: TextStyle(
                              color: statusColor(booking.status),
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: kTextSecondary),
                  const SizedBox(width: 4),
                  Text(booking.scheduledDate,
                      style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                  const SizedBox(width: 16),
                  const Icon(Icons.location_on, size: 14, color: kTextSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(booking.address,
                        style: const TextStyle(color: kTextSecondary, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Booked on: ${_formatDate(booking.createdAt)}',
                style: const TextStyle(color: kTextSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final d = DateTime.parse(isoDate);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return isoDate;
    }
  }
}


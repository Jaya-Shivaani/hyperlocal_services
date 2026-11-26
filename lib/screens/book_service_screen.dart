import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/category_model.dart';
import '../models/provider_model.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../utils/app_theme.dart';

class BookServiceScreen extends StatefulWidget {
  final CategoryModel category;

  const BookServiceScreen({super.key, required this.category});

  @override
  State<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends State<BookServiceScreen> {
  List<ProviderModel> _providers = [];
  ProviderModel? _selectedProvider;
  bool _loading = true;
  bool _showBookingForm = false;

  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    final data = await DatabaseHelper.instance.getProvidersByCategory(widget.category.id!);
    setState(() {
      _providers = data.map((e) => ProviderModel.fromMap(e)).toList();
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _book() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date'), backgroundColor: Colors.orange),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await context.read<BookingProvider>().createBooking(
      customerId: auth.currentUser!.id!,
      providerId: _selectedProvider!.id!,
      categoryId: widget.category.id!,
      serviceDescription: _descCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      scheduledDate: '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking created successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create booking'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    // Pre-fill address from user profile
    if (_addressCtrl.text.isEmpty && auth.currentUser?.address != null) {
      _addressCtrl.text = auth.currentUser!.address!;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category.icon} ${widget.category.name}'),
      ),
      body: AiBackground(
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _providers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 64, color: kTextSecondary),
                      SizedBox(height: 12),
                      Text('No providers available for this category',
                          textAlign: TextAlign.center, style: TextStyle(color: kTextSecondary)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_showBookingForm) ...[
                        const Text(
                          'Select a Provider',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._providers.map((p) => _ProviderCard(
                              provider: p,
                              selected: _selectedProvider?.id == p.id,
                              onSelect: () => setState(() => _selectedProvider = p),
                            )),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _selectedProvider == null
                              ? null
                              : () => setState(() => _showBookingForm = true),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Continue to Book'),
                        ),
                      ] else ...[
                        // Booking Form
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: kPrimaryColor,
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_selectedProvider!.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(_selectedProvider!.phone,
                                          style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    Text(_selectedProvider!.rating.toStringAsFixed(1)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _descCtrl,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Describe the problem/service needed',
                                  prefixIcon: Icon(Icons.description_outlined),
                                  alignLabelWithHint: true,
                                ),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty ? 'Please describe the service' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _addressCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Service Address',
                                  prefixIcon: Icon(Icons.location_on_outlined),
                                ),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty ? 'Enter service address' : null,
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: _pickDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, color: kTextSecondary),
                                      const SizedBox(width: 12),
                                      Text(
                                        _selectedDate == null
                                            ? 'Select Preferred Date'
                                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                        style: TextStyle(
                                          color: _selectedDate == null ? kTextSecondary : kTextPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _notesCtrl,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Additional Notes (optional)',
                                  prefixIcon: Icon(Icons.note_outlined),
                                  alignLabelWithHint: true,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => setState(() => _showBookingForm = false),
                                      child: const Text('Back'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: Consumer<BookingProvider>(
                                      builder: (_, bp, __) => bp.isLoading
                                          ? const Center(child: CircularProgressIndicator())
                                          : ElevatedButton.icon(
                                              onPressed: _book,
                                              icon: const Icon(Icons.check),
                                              label: const Text('Confirm Booking'),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final ProviderModel provider;
  final bool selected;
  final VoidCallback onSelect;

  const _ProviderCard({
    required this.provider,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? kPrimaryColor : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: selected ? kPrimaryColor : kPrimaryColor.withValues(alpha: 0.1),
              radius: 24,
              child: Text(
                provider.name[0].toUpperCase(),
                style: TextStyle(
                  color: selected ? Colors.white : kPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(provider.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: kTextPrimary)),
                  if (provider.description != null)
                    Text(provider.description!,
                        style: const TextStyle(color: kTextSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      Text(' ${provider.rating.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      const Icon(Icons.phone, size: 14, color: kTextSecondary),
                      Text(' ${provider.phone}',
                          style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: kPrimaryColor),
          ],
        ),
      ),
    );
  }
}


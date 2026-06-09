import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/auth_gate.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/spot.dart';
import '../../models/trip.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trips_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/feedback.dart';

class CreateTripScreen extends StatefulWidget {
  final Spot? seedSpot;
  const CreateTripScreen({super.key, this.seedSpot});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  late final TextEditingController _destination =
      TextEditingController(text: widget.seedSpot?.city ?? '');
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  int _days = 3;
  bool _creating = false;

  @override
  void dispose() {
    _destination.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _create() async {
    if (_destination.text.trim().isEmpty) {
      AppSnackbar.error(context, 'Where are you headed?');
      return;
    }
    if (!await ensureLoggedIn(context) || !mounted) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final tripsP = context.read<TripsProvider>();

    var days = List.generate(
      _days,
      (i) => TripDay(dayNumber: i + 1, date: _startDate.add(Duration(days: i))),
    );

    final seed = widget.seedSpot;
    if (seed != null) {
      final stop = TripStop(
        spotId: seed.id,
        name: seed.name,
        photo: seed.coverPhoto,
        categoryId: seed.categoryId,
        lat: seed.lat,
        lng: seed.lng,
        dayPart: DayPart.morning,
      );
      days = [days.first.copyWith(stops: [stop]), ...days.skip(1)];
    }

    final trip = Trip(
      id: '',
      userId: user.id,
      destination: _destination.text.trim(),
      country: seed?.country ?? '',
      lat: seed?.lat,
      lng: seed?.lng,
      startDate: _startDate,
      endDate: _startDate.add(Duration(days: _days - 1)),
      days: days,
      coverPhoto: seed?.coverPhoto,
      createdAt: DateTime.now(),
    );

    setState(() => _creating = true);
    final id = await tripsP.createTrip(trip);
    if (!mounted) return;
    final created = tripsP.byId(id) ?? trip;
    Navigator.pushReplacementNamed(context, AppRoutes.tripDetails, arguments: created);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('New trip')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppTextField(
            controller: _destination,
            label: 'Destination',
            hint: 'e.g. Cairo',
            prefixIcon: Icons.place_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Start date', style: text.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: _pickDate,
            borderRadius: AppRadius.brMd,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: AppRadius.brMd,
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 18),
                  const SizedBox(width: AppSpacing.md),
                  Text(Formatters.date(_startDate), style: text.bodyLarge),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('How many days?', style: text.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: _days > 1 ? () => setState(() => _days--) : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Text('$_days ${_days == 1 ? 'day' : 'days'}',
                    textAlign: TextAlign.center, style: text.titleLarge),
              ),
              IconButton.filledTonal(
                onPressed: _days < 14 ? () => setState(() => _days++) : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (widget.seedSpot != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: AppRadius.brMd,
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_location_alt_outlined, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text('“${widget.seedSpot!.name}” will be added to day 1.')),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          AppButton('Create trip', icon: Icons.check_rounded, loading: _creating, onPressed: _create),
        ],
      ),
    );
  }
}

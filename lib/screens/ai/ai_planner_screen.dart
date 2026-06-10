import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/auth_gate.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../providers/ai_planner_provider.dart';
import '../../providers/spots_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_menu_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/feedback.dart';

/// Conversational AI planner brief (Mindtrip/Layla style): destination, dates,
/// interests, budget, pace → a day-by-day itinerary.
class AiPlannerScreen extends StatefulWidget {
  const AiPlannerScreen({super.key});

  @override
  State<AiPlannerScreen> createState() => _AiPlannerScreenState();
}

class _AiPlannerScreenState extends State<AiPlannerScreen> {
  final _destination = TextEditingController();
  final _budget = TextEditingController();

  @override
  void initState() {
    super.initState();
    final aiP = context.read<AiPlannerProvider>();
    _destination.text = aiP.destination;
    if (aiP.budgetCap != null) _budget.text = aiP.budgetCap!.round().toString();
  }

  @override
  void dispose() {
    _destination.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _pickDate(AiPlannerProvider aiP) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: aiP.startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) aiP.setStartDate(picked);
  }

  Future<void> _generate() async {
    if (!await ensureLoggedIn(context) || !mounted) return;
    final aiP = context.read<AiPlannerProvider>();
    final spotsP = context.read<SpotsProvider>();
    final ok = await aiP.generate(spotsP.spots);
    if (!mounted) return;
    if (ok && aiP.result != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.itineraryResult,
        arguments: aiP.result,
      );
    } else if (aiP.error != null) {
      AppSnackbar.error(context, aiP.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiP = context.watch<AiPlannerProvider>();
    final spotsP = context.watch<SpotsProvider>();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: const AppMenuButton(),
        title: const Text('Plan with AI'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: Chip(
                avatar: Icon(
                  aiP.isLive ? Icons.bolt_rounded : Icons.smart_toy_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                label: Text(aiP.isLive ? 'Gemini' : 'On-device AI'),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
        ),
        children: [
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final heroBg = isDark ? AppColors.darkInk : AppColors.ink;
              final heroFg = isDark ? AppColors.darkBg : Colors.white;
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: heroBg,
                  borderRadius: AppRadius.brCard,
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: heroFg, size: 28),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Tell me your vibe and I\'ll craft a day-by-day plan from real, approved spots.',
                        style: text.bodyMedium?.copyWith(color: heroFg),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            controller: _destination,
            label: 'Where to?',
            hint: 'e.g. Cairo',
            prefixIcon: Icons.place_outlined,
            onChanged: aiP.setDestinationText,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final city in spotsP.cities.take(6))
                ActionChip(
                  label: Text(city),
                  onPressed: () {
                    _destination.text = city;
                    aiP.setDestinationText(city);
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _Field(
                  label: 'Start date',
                  child: InkWell(
                    onTap: () => _pickDate(aiP),
                    borderRadius: AppRadius.brMd,
                    child: _box(
                      context,
                      Formatters.date(aiP.startDate),
                      Icons.calendar_today_rounded,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Field(
                  label: 'Days',
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: aiP.dayCount > 1
                            ? () => aiP.setDays(aiP.dayCount - 1)
                            : null,
                        style: _stepperStyle(context),
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Expanded(
                        child: Text(
                          '${aiP.dayCount}',
                          textAlign: TextAlign.center,
                          style: text.titleLarge,
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: aiP.dayCount < 14
                            ? () => aiP.setDays(aiP.dayCount + 1)
                            : null,
                        style: _stepperStyle(context),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Interests', style: text.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final interest in AiPlannerProvider.suggestedInterests)
                FilterChip(
                  label: Text(interest),
                  selected: aiP.interests.contains(interest),
                  onSelected: (_) => aiP.toggleInterest(interest),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Budget', style: text.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final p in PriceRange.values)
                ChoiceChip(
                  label: Text(p.label),
                  selected: aiP.budget == p,
                  onSelected: (_) => aiP.setBudget(p),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _budget,
            label: 'Max budget — optional (USD)',
            hint: 'e.g. 300',
            prefixIcon: Icons.account_balance_wallet_outlined,
            keyboardType: TextInputType.number,
            onChanged: (v) => aiP.setBudgetCap(double.tryParse(v.trim())),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'SpotWise estimates the trip cost from spot prices, meals & transport.',
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Pace', style: text.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final pace in TripPace.values)
                ChoiceChip(
                  label: Text('${pace.label} · ${pace.stopsPerDay}/day'),
                  selected: aiP.pace == pace,
                  onSelected: (_) => aiP.setPace(pace),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            'Generate itinerary',
            icon: Icons.auto_awesome_rounded,
            loading: aiP.generating,
            onPressed: aiP.canGenerate ? _generate : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              aiP.isLive
                  ? 'Powered by Google Gemini'
                  : 'Using the on-device planner · add a Gemini key in Settings to go live',
              style: text.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Neutral fill for the +/− day steppers (default tonal is coral-tinted).
  ButtonStyle _stepperStyle(BuildContext context) => IconButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    foregroundColor: Theme.of(context).colorScheme.onSurface,
  );

  Widget _box(BuildContext context, String label, IconData icon) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      borderRadius: AppRadius.brMd,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    ),
    child: Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

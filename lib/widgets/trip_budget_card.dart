import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/formatters.dart';
import '../models/trip.dart';
import '../services/ai/trip_estimator.dart';

/// Transparent, price-based budget summary for a trip: a breakdown of stop
/// spend vs daily extras, the estimated total, and (if set) progress against
/// the traveller's budget cap.
class TripBudgetCard extends StatelessWidget {
  final Trip trip;
  const TripBudgetCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const sym = TripEstimator.symbol;
    final stops = TripEstimator.stopsCost(trip.days);
    final total = trip.estimatedCost > 0
        ? trip.estimatedCost
        : TripEstimator.total(trip.days);
    final extras = (total - stops).clamp(0, double.infinity).toDouble();
    final cap = trip.budgetCap;
    final over = cap != null && total > cap;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: AppRadius.brLg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Estimated budget', style: text.titleMedium),
                const Spacer(),
                Text(
                  Formatters.money(total, symbol: sym),
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _line(context, 'Attractions & food', stops),
            _line(context, 'Meals & transport', extras),
            const Divider(),
            if (cap != null) ...[
              Row(
                children: [
                  Text('Your budget', style: text.bodyMedium),
                  const Spacer(),
                  Text(
                    Formatters.money(cap, symbol: sym),
                    style: text.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: AppRadius.brSm,
                child: LinearProgressIndicator(
                  value: cap > 0 ? (total / cap).clamp(0, 1).toDouble() : 0,
                  minHeight: 8,
                  color: over ? AppColors.danger : AppColors.success,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    over
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_rounded,
                    size: 16,
                    color: over ? AppColors.danger : AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    over
                        ? '${Formatters.money(total - cap, symbol: sym)} over your budget'
                        : '${Formatters.money(cap - total, symbol: sym)} under your budget',
                    style: text.bodySmall?.copyWith(
                      color: over ? AppColors.danger : AppColors.success,
                    ),
                  ),
                ],
              ),
            ] else
              Text(
                'Per person · ${trip.dayCount} ${trip.dayCount == 1 ? 'day' : 'days'}',
                style: text.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String label, double amount) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          Formatters.money(amount, symbol: TripEstimator.symbol),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}

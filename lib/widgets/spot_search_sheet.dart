import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../models/spot.dart';
import 'app_text_field.dart';
import 'spot_list_tile.dart';

/// Forgiving spot-name search over the in-memory catalog. Ranked tiers:
/// exact name > name prefix > word prefix > substring in name > substring in
/// city/tags > a typo-tolerant tier (per-word edit distance) so "pyram" finds
/// "Pyramids of Giza" and "tour" still finds "Eiffel Tower".
List<Spot> searchSpots(List<Spot> spots, String query, {int limit = 5}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  int score(Spot s) {
    final name = s.name.toLowerCase();
    if (name == q) return 100;
    if (name.startsWith(q)) return 90;
    final words = name.split(RegExp(r'[^a-z0-9]+'));
    if (words.any((w) => w.startsWith(q))) return 75;
    if (name.contains(q)) return 60;
    final extras = '${s.city} ${s.country} ${s.tags.join(' ')}'.toLowerCase();
    if (extras.contains(q)) return 40;
    // Typo-tolerant: close enough to any word (or its same-length prefix).
    final maxEdits = q.length <= 3 ? 1 : 2;
    for (final w in words) {
      if (w.isEmpty) continue;
      final prefix = w.length > q.length ? w.substring(0, q.length) : w;
      if (_editDistance(q, w, maxEdits) <= maxEdits ||
          _editDistance(q, prefix, maxEdits) <= maxEdits) {
        return 25;
      }
    }
    return 0;
  }

  final scored = [
    for (final s in spots)
      if (score(s) > 0) MapEntry(s, score(s)),
  ]..sort((a, b) {
      final byScore = b.value.compareTo(a.value);
      if (byScore != 0) return byScore;
      final byRating = b.key.rating.compareTo(a.key.rating);
      return byRating != 0 ? byRating : a.key.name.compareTo(b.key.name);
    });
  return scored.take(limit).map((e) => e.key).toList();
}

/// Levenshtein distance, capped at [cap]+1 for speed (we only care whether
/// it's within the typo budget).
int _editDistance(String a, String b, int cap) {
  if ((a.length - b.length).abs() > cap) return cap + 1;
  var prev = List<int>.generate(b.length + 1, (j) => j);
  for (var i = 1; i <= a.length; i++) {
    final curr = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final sub = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      curr[j] = [
        prev[j] + 1,
        curr[j - 1] + 1,
        prev[j - 1] + sub,
      ].reduce((x, y) => x < y ? x : y);
    }
    prev = curr;
  }
  return prev[b.length];
}

/// Bottom-sheet spot search: type a name, get suggestions, tap one. Pops with
/// the chosen [Spot] or null.
///
/// With [browseAll] the sheet also lists every passed spot while the query is
/// empty (a browse-and-search picker) and returns more matches when typing —
/// used by the trip editor's "Add a spot" / "Replace by search".
Future<Spot?> showSpotSearch(
  BuildContext context, {
  required List<Spot> spots,
  String title = 'Find a spot',
  bool browseAll = false,
}) {
  return showModalBottomSheet<Spot>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        _SpotSearchSheet(spots: spots, title: title, browseAll: browseAll),
  );
}

class _SpotSearchSheet extends StatefulWidget {
  final List<Spot> spots;
  final String title;
  final bool browseAll;
  const _SpotSearchSheet({
    required this.spots,
    this.title = 'Find a spot',
    this.browseAll = false,
  });

  @override
  State<_SpotSearchSheet> createState() => _SpotSearchSheetState();
}

class _SpotSearchSheetState extends State<_SpotSearchSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final empty = _query.trim().isEmpty;
    // Browse the whole list while empty (browseAll), otherwise rank matches.
    final results = empty
        ? (widget.browseAll ? widget.spots : const <Spot>[])
        : searchSpots(widget.spots, _query, limit: widget.browseAll ? 50 : 5);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.sm,
                ),
                child: Text(widget.title, style: text.titleLarge),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: AppSearchField(
                  controller: _controller,
                  hint: 'Type a spot name…',
                  // Don't grab the keyboard when there's a list to browse first.
                  autofocus: !widget.browseAll,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Flexible(
                child: results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          empty
                              ? 'Start typing — even part of a name works.'
                              : 'No spots match “${_query.trim()}”.',
                          style: text.bodyMedium,
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.xs,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        children: [
                          for (final s in results)
                            SpotListTile(
                              spot: s,
                              onTap: () => Navigator.pop(context, s),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

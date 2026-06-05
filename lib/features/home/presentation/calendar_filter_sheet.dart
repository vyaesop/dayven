import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/holidays/holidays_service.dart';
import '../application/planner_controller.dart';

Future<void> showCalendarFilterSheet({
  required BuildContext context,
  required ValueChanged<String> onToggleCalendar,
  required VoidCallback onShowAll,
  required Future<void> Function(String name, Color color) onCreateCalendar,
  required Future<void> Function(String countryCode) onLoadHolidays,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CalendarFilterSheet(
      onToggleCalendar: onToggleCalendar,
      onShowAll: onShowAll,
      onCreateCalendar: onCreateCalendar,
      onLoadHolidays: onLoadHolidays,
    ),
  );
}

class _CalendarFilterSheet extends ConsumerStatefulWidget {
  const _CalendarFilterSheet({
    required this.onToggleCalendar,
    required this.onShowAll,
    required this.onCreateCalendar,
    required this.onLoadHolidays,
  });

  final ValueChanged<String> onToggleCalendar;
  final VoidCallback onShowAll;
  final Future<void> Function(String name, Color color) onCreateCalendar;
  final Future<void> Function(String countryCode) onLoadHolidays;

  @override
  ConsumerState<_CalendarFilterSheet> createState() =>
      _CalendarFilterSheetState();
}

class _CalendarFilterSheetState extends ConsumerState<_CalendarFilterSheet> {
  @override
  Widget build(BuildContext context) {
    final plannerState =
        ref.watch(plannerControllerProvider).asData?.value;
    final textTheme = Theme.of(context).textTheme;
    final tones = context.plannerTones;
    final calendars = plannerState?.calendars ?? [];
    final visibleIds =
        plannerState?.visibleCalendarIds.toSet() ?? <String>{};

    return FractionallySizedBox(
      heightFactor: 0.72,
      child: Container(
        decoration: BoxDecoration(
          color: tones.menuSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'CALENDARS',
                      style: textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: widget.onShowAll,
                      child: const Text('Show all'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Choose which calendars are visible in the timeline and month heatmap.',
                  style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _NewCalendarTile(
                        onCreateCalendar: widget.onCreateCalendar,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HolidaysTile(
                          onLoadHolidays: widget.onLoadHolidays),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: calendars.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final calendar = calendars[index];
                      final isVisible = visibleIds.contains(calendar.id);
                      return InkWell(
                        onTap: () => widget.onToggleCalendar(calendar.id),
                        borderRadius: BorderRadius.circular(22),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: calendar.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  calendar.name,
                                  style: textTheme.bodyLarge
                                      ?.copyWith(color: Colors.white),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isVisible
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  key: ValueKey(isVisible),
                                  color: isVisible
                                      ? const Color(0xFFE1C06C)
                                      : Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HolidaysTile extends StatefulWidget {
  const _HolidaysTile({required this.onLoadHolidays});
  final Future<void> Function(String countryCode) onLoadHolidays;

  @override
  State<_HolidaysTile> createState() => _HolidaysTileState();
}

class _HolidaysTileState extends State<_HolidaysTile> {
  bool _loading = false;
  String _status = '';

  Future<void> _openPicker() async {
    final codes = await showDialog<List<String>>(
      context: context,
      builder: (_) => const _CountryPickerDialog(),
    );
    if (codes == null || codes.isEmpty) return;
    setState(() { _loading = true; _status = ''; });
    for (var i = 0; i < codes.length; i++) {
      if (!mounted) break;
      setState(() => _status = '${codes[i]} (${i + 1}/${codes.length})');
      await widget.onLoadHolidays(codes[i]);
    }
    if (mounted) setState(() { _loading = false; _status = ''; });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: _loading ? null : _openPicker,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFE1C06C).withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            if (_loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFFE1C06C)),
              )
            else
              const Icon(Icons.flag_rounded,
                  color: Color(0xFFE1C06C), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _loading && _status.isNotEmpty
                    ? 'Loading $_status…'
                    : 'Add public holidays',
                style: textTheme.bodyLarge
                    ?.copyWith(color: const Color(0xFFE1C06C)),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFE1C06C), size: 18),
          ],
        ),
      ),
    );
  }
}

class _CountryPickerDialog extends StatefulWidget {
  const _CountryPickerDialog();

  @override
  State<_CountryPickerDialog> createState() => _CountryPickerDialogState();
}

class _CountryPickerDialogState extends State<_CountryPickerDialog> {
  final _search = TextEditingController();
  String _query = '';
  List<HolidayCountry>? _countries;
  Set<String> _alreadyAdded = {};
  final Set<String> _selected = {};
  bool _loadingCountries = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final year = DateTime.now().year;
    final results = await Future.wait([
      HolidaysService.instance.availableCountries(),
      HolidaysService.instance.loadedCountriesForYear(year),
    ]);
    if (!mounted) return;
    setState(() {
      _countries = results[0] as List<HolidayCountry>;
      _alreadyAdded = results[1] as Set<String>;
      _loadingCountries = false;
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countries = _countries ?? [];
    final filtered = countries
        .where((c) =>
            c.name.toLowerCase().contains(_query.toLowerCase()) ||
            c.code.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return AlertDialog(
      title: const Text('Public Holidays'),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: _loadingCountries
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  TextField(
                    controller: _search,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search country…',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  if (_alreadyAdded.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_alreadyAdded.length} already added · select more below',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        final added = _alreadyAdded.contains(c.code);
                        final selected = _selected.contains(c.code);
                        return CheckboxListTile(
                          dense: true,
                          value: selected,
                          tristate: false,
                          title: Row(
                            children: [
                              Expanded(child: Text(c.name)),
                              Text(
                                c.code,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                          subtitle: added
                              ? const Text('already added',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 11))
                              : null,
                          secondary: added
                              ? const Icon(Icons.check_circle_outline_rounded,
                                  color: Colors.grey, size: 18)
                              : null,
                          onChanged: (_) => setState(() {
                            if (selected) {
                              _selected.remove(c.code);
                            } else {
                              _selected.add(c.code);
                            }
                          }),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selected.toList()),
          child: Text(
            _selected.isEmpty
                ? 'Add'
                : 'Add ${_selected.length} ${_selected.length == 1 ? "country" : "countries"}',
          ),
        ),
      ],
    );
  }
}

class _NewCalendarTile extends StatefulWidget {
  const _NewCalendarTile({
    required this.onCreateCalendar,
  });
  final Future<void> Function(String name, Color color) onCreateCalendar;

  @override
  State<_NewCalendarTile> createState() => _NewCalendarTileState();
}

class _NewCalendarTileState extends State<_NewCalendarTile> {
  bool _loading = false;
  String? _error;

  Future<void> _openDialog() async {
    final result = await showDialog<(String, Color)?>(
      context: context,
      builder: (_) => const _NewCalendarDialog(),
    );
    if (result == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      await widget.onCreateCalendar(result.$1, result.$2);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not create calendar.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: _loading ? null : _openDialog,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            if (_loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              )
            else
              const Icon(Icons.add_circle_outline_rounded,
                  color: Colors.white54, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _error ?? 'New calendar',
                style: textTheme.bodyLarge?.copyWith(
                  color: _error != null ? Colors.redAccent : Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewCalendarDialog extends StatefulWidget {
  const _NewCalendarDialog();

  @override
  State<_NewCalendarDialog> createState() => _NewCalendarDialogState();
}

class _NewCalendarDialogState extends State<_NewCalendarDialog> {
  final _ctrl = TextEditingController();
  Color _selected = const Color(0xFFD1ACEA);

  static const _palette = [
    Color(0xFFD1ACEA),
    Color(0xFFF197A6),
    Color(0xFFF4C382),
    Color(0xFFBCE58F),
    Color(0xFF74706B),
    Color(0xFF6BBCB8),
    Color(0xFFE1C06C),
    Color(0xFFADD8E6),
    Color(0xFFB0A8C8),
    Color(0xFF9BA8A8),
    Color(0xFFFF8A65),
    Color(0xFF80CBC4),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('New Calendar'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Calendar name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text('Color', style: theme.textTheme.labelLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _palette.map((color) {
              final isSelected = color == _selected;
              return GestureDetector(
                onTap: () => setState(() => _selected = color),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: theme.colorScheme.onSurface,
                            width: 2.5,
                          )
                        : null,
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(Icons.check_rounded,
                          size: 18,
                          color: ThemeData.estimateBrightnessForColor(color) ==
                                  Brightness.dark
                              ? Colors.white
                              : Colors.black)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _ctrl.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop((_ctrl.text.trim(), _selected)),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

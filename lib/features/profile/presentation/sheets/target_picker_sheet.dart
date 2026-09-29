import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/services/user_preferences_service.dart';
import '_sheet_chrome.dart';

const _years = [2026, 2027, 2028];
const _states = [
  'Andhra Pradesh',
  'Delhi',
  'Gujarat',
  'Karnataka',
  'Maharashtra',
  'Tamil Nadu',
  'Telangana',
  'Uttar Pradesh',
];

// Colleges grouped by state — the "Target College" list filters to the
// picked state. States without entries fall back to the full list so the
// dropdown is never empty. (A central-institute list could be added later.)
const _collegesByState = <String, List<String>>{
  'Delhi': ['AIIMS Delhi', 'Lady Hardinge Medical College'],
  'Tamil Nadu': ['CMC Vellore', 'Madras Medical College'],
  'Uttar Pradesh': ['KGMU Lucknow', 'IMS BHU Varanasi'],
  'Maharashtra': ['Seth GS Medical College', 'BJ Medical Pune'],
};

const _colleges = [
  'AIIMS Delhi',
  'JIPMER Puducherry',
  'CMC Vellore',
  'KGMU Lucknow',
  'IMS BHU Varanasi',
  'Madras Medical College',
  'Seth GS Medical College',
  'BJ Medical Pune',
  'Lady Hardinge Medical College',
];

/// Colleges offered for [state]: the state's own list, or all of them when
/// no state is picked / the state has no entries.
List<String> _collegesFor(String? state) {
  final forState = state == null ? null : _collegesByState[state];
  if (forState == null || forState.isEmpty) return _colleges;
  return forState;
}

/// Show the target picker sheet. Returns true if saved.
Future<bool?> showTargetPickerSheet(BuildContext context) {
  // Selection state MUST live outside the StatefulBuilder builder. It used
  // to be re-initialized from storage on every rebuild, so picking an
  // option updated the variable, triggered setModal, and the rebuild
  // immediately snapped the dropdown back to the saved value — the
  // "cannot select any option" bug.
  final initial = UserPreferencesService.instance.current;
  // Clamp to the picker's list: DropdownButton asserts when its value is
  // not present among the items.
  int year =
      _years.contains(initial.targetYear) ? initial.targetYear! : _years.first;
  String? state = initial.targetState;
  // Clamp the college to the state-filtered list (same pattern as year):
  // a saved college outside the picked state's list would make
  // DropdownButton assert on its missing value.
  String? college = _collegesFor(state).contains(initial.targetCollege)
      ? initial.targetCollege
      : null;

  return showTallAppSheet<bool>(
    context,
    StatefulBuilder(
      builder: (ctx, setModal) {
        final palette = ColorPaletteController.instance.current;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sheetTitle('Your Target', context: ctx),
            const SizedBox(height: 4),
            _DropdownRow(
              label: 'Target Year',
              value: year,
              values: _years.map((y) => y.toString()).toList(),
              onChanged: (v) {
                setModal(() => year = int.tryParse(v ?? '') ?? year);
              },
              formatLabel: (v) => 'NEET $v',
            ),
            _DropdownRow(
              label: 'State',
              value: state,
              values: _states,
              onChanged: (v) => setModal(() {
                state = v;
                // A college from the old state may not exist in the new
                // state's list — clear it rather than assert.
                if (college != null && !_collegesFor(state).contains(college)) {
                  college = null;
                }
              }),
              allowClear: true,
            ),
            _DropdownRow(
              label: 'Target College',
              value: college,
              values: _collegesFor(state),
              onChanged: (v) => setModal(() => college = v),
              allowClear: true,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: sheetPrimaryButton(
                label: 'Save',
                primary: palette.primary,
                onPressed: () async {
                  await UserPreferencesService.instance.setTarget(
                    year: year,
                    state: state,
                    college: college,
                  );
                  if (context.mounted) Navigator.of(ctx).pop(true);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: sheetSecondaryButton(
                context: ctx,
                label: 'Cancel',
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _DropdownRow extends StatelessWidget {
  final String label;
  final Object? value;
  final List<String> values;
  final ValueChanged<String?> onChanged;
  final bool allowClear;
  final String Function(String)? formatLabel;

  const _DropdownRow({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    this.allowClear = false,
    this.formatLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value?.toString(),
                // Explicit onSurface style: the light theme's textTheme is
                // built from AppColors.text (white), which made the
                // selected text invisible on the light sheet. onSurface
                // resolves correctly in BOTH themes.
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                hint: Text(allowClear ? 'Not set' : 'Select…',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                isExpanded: true,
                items: [
                  if (allowClear)
                    DropdownMenuItem<String>(
                      value: '',
                      child: Text('— Not set —',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ),
                  for (final v in values)
                    DropdownMenuItem<String>(
                      value: v,
                      child: Text(
                        formatLabel != null ? formatLabel!(v) : v,
                        // Same light-theme visibility fix as above: menu
                        // rows previously inherited the white textTheme.
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                ],
                onChanged: (v) {
                  if (v == '' && allowClear) {
                    onChanged(null);
                  } else {
                    onChanged(v);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

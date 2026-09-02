import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
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

// TODO: filter colleges by selected state in a later iteration.
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

/// Show the target picker sheet. Returns true if saved.
Future<bool?> showTargetPickerSheet(BuildContext context) {
  return showTallAppSheet<bool>(
    context,
    StatefulBuilder(
      builder: (ctx, setModal) {
        final initial = UserPreferencesService.instance.current;
        int? year = initial.targetYear ?? _years.first;
        String? state = initial.targetState;
        String? college = initial.targetCollege;
        final palette = ColorPaletteController.instance.current;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sheetTitle('Your Target'),
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
              onChanged: (v) => setModal(() => state = v),
              allowClear: true,
            ),
            _DropdownRow(
              label: 'Target College',
              value: college,
              values: _colleges,
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD6D0E4)),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value?.toString(),
                hint: Text(allowClear ? 'Not set' : 'Select…',
                    style: const TextStyle(color: AppColors.subtitle)),
                isExpanded: true,
                items: [
                  if (allowClear)
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('— Not set —',
                          style: TextStyle(color: AppColors.subtitle)),
                    ),
                  for (final v in values)
                    DropdownMenuItem<String>(
                      value: v,
                      child: Text(formatLabel != null ? formatLabel!(v) : v),
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

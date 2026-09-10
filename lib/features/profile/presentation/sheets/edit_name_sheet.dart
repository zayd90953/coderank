import 'package:flutter/material.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/services/user_preferences_service.dart';
import '_sheet_chrome.dart';

/// Show the "Edit Display Name" sheet. Returns true if a name was saved.
Future<bool?> showEditNameSheet(BuildContext context,
    {required String initial}) {
  return showAppSheet<bool>(
    context,
    _EditNameSheetContent(initial: initial),
  );
}

/// Sheet content as a real StatefulWidget so the [TextEditingController]
/// is created once and disposed, instead of being rebuilt on every sheet
/// rebuild (the keyboard opening would otherwise recreate the controller
/// and wipe whatever the user had typed).
class _EditNameSheetContent extends StatefulWidget {
  final String initial;

  const _EditNameSheetContent({required this.initial});

  @override
  State<_EditNameSheetContent> createState() =>
      _EditNameSheetContentState();
}

class _EditNameSheetContentState extends State<_EditNameSheetContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _controller = TextEditingController(
      text: initial == 'NEET Aspirant' ? '' : initial,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Display name cannot be empty.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    await UserPreferencesService.instance.setDisplayName(value);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sheetTitle('Edit Display Name', context: context),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Display name',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: sheetPrimaryButton(
            label: 'Save',
            primary: palette.primary,
            onPressed: _save,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: sheetSecondaryButton(
            context: context,
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
      ],
    );
  }
}
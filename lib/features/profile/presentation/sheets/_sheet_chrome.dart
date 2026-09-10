import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';

/// Shared bottom-sheet chrome. Two helpers: [showAppSheet] for short
/// sheets and [showTallAppSheet] for sheets that need a draggable,
/// resizable surface. Both match the styling used by the mock-test
/// review sheet (`lib/features/mock_test/presentation/mock_test_question_screen.dart`).
const double kSheetTopRadius = 28;

/// The standard sheet frame used by all four profile sheets.
Widget _sheetFrame({
  required BuildContext context,
  required Widget child,
  bool tall = false,
}) {
  return SafeArea(
    top: false,
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(kSheetTopRadius)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Flexible(child: child),
        ],
      ),
    ),
  );
}

/// The standard title used by all four profile sheets.
Widget sheetTitle(String text, {required BuildContext context}) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );

/// The standard primary button used by the sheets. Takes [primary] so
/// the caller can pass the live brand color from the active
/// [ColorPalette] (otherwise sheets would always be purple).
Widget sheetPrimaryButton({
  required String label,
  required VoidCallback onPressed,
  required Color primary,
}) {
  return SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label,
          style:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    ),
  );
}

/// The standard secondary button used by the sheets.
Widget sheetSecondaryButton({
  required String label,
  required VoidCallback onPressed,
  required BuildContext context,
}) {
  return SizedBox(
    width: double.infinity,
    height: 48,
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      child: Text(label,
          style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    ),
  );
}

/// Show a short bottom sheet.
Future<T?> showAppSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(kSheetTopRadius)),
    ),
    builder: (ctx) => Padding(
      // Use the sheet's own context: the outer [context] is not an
      // ancestor of the modal route, so its MediaQuery never updates
      // when the keyboard opens — the field would sit under the
      // keyboard on small screens (A-6).
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: _sheetFrame(context: ctx, child: child),
    ),
  );
}

/// Show a tall, draggable bottom sheet (used for the target picker).
Future<T?> showTallAppSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(kSheetTopRadius)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => _sheetFrame(
        context: ctx,
        tall: true,
        child: SingleChildScrollView(
          controller: controller,
          // Same A-6 fix as [showAppSheet]: track the keyboard via the
          // sheet's own context, not the launcher's.
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: child,
        ),
      ),
    ),
  );
}

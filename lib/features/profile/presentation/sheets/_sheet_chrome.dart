import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/color_palette.dart';

/// Shared bottom-sheet chrome. Two helpers: [showAppSheet] for short
/// sheets and [showTallAppSheet] for sheets that need a draggable,
/// resizable surface. Both match the styling used by the mock-test
/// review sheet (`lib/features/mock_test/presentation/mock_test_question_screen.dart`).
const double kSheetTopRadius = 28;
const Color kSheetDragHandleColor = Color(0xFFD1C9E8);

/// The standard sheet frame used by all four profile sheets.
Widget _sheetFrame({required Widget child, bool tall = false}) {
  return SafeArea(
    top: false,
    child: Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(kSheetTopRadius)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kSheetDragHandleColor,
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
Widget sheetTitle(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
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
}) {
  return SizedBox(
    width: double.infinity,
    height: 48,
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: AppColors.subtitle),
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
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(kSheetTopRadius)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _sheetFrame(child: child),
    ),
  );
}

/// Show a tall, draggable bottom sheet (used for the target picker).
Future<T?> showTallAppSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(kSheetTopRadius)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => _sheetFrame(
        tall: true,
        child: SingleChildScrollView(
          controller: controller,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: child,
        ),
      ),
    ),
  );
}

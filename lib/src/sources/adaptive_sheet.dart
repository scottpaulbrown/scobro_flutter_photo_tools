import 'package:flutter/material.dart';

/// Opens [builder] as a modal bottom sheet on screens narrower than 650, or
/// as a centred dialog [dialogWidth] wide on larger screens.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double dialogWidth = 480,
}) {
  if (MediaQuery.sizeOf(context).width >= 650) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: dialogWidth),
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: builder(dialogContext),
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: builder,
  );
}

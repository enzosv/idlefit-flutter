import 'package:flutter/material.dart';
import 'package:idlefit/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DevResetButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  const DevResetButton({super.key, this.onPressed});

  void _handleReset(WidgetRef ref) {
    final objectBox = ref.read(objectBoxProvider);
    objectBox.reset();
    if (onPressed != null) {
      onPressed!();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ButtonTheme(
      child: ElevatedButton(
        onPressed: () => _handleReset(ref),
        child: const Text("DEV RESET"),
      ),
    );
  }
}

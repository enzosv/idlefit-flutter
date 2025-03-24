import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/providers/providers.dart';

class Sidebar extends ConsumerWidget {
  final bool isOpen;
  final VoidCallback toggleSidebar;

  const Sidebar({super.key, required this.isOpen, required this.toggleSidebar});

  void _handleReset(WidgetRef ref) {
    ref.read(generatorProvider.notifier).reset();
  }

  Future<void> _handleDevReset(WidgetRef ref) async {
    await ref.read(gameStateProvider.notifier).fullReset();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        // Semi-transparent overlay
        if (isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: toggleSidebar,
              child: Container(color: Colors.black54),
            ),
          ),
        // Sidebar
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          left: isOpen ? 0 : -screenWidth * 0.8,
          top: 0,
          bottom: 0,
          width: screenWidth * 0.8,
          child: Material(
            elevation: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SidebarButton(
                  text: "Reset Generators",
                  onPressed: () => _handleReset(ref),
                ),
                _SidebarButton(
                  text: "DEV RESET",
                  onPressed: () => _handleDevReset(ref),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SidebarButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final String text;
  const _SidebarButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ButtonTheme(
      child: ElevatedButton(onPressed: onPressed, child: Text(text)),
    );
  }
}

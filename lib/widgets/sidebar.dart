import 'package:flutter/material.dart';
import 'package:idlefit/widgets/dev_reset_button.dart';

class Sidebar extends StatelessWidget {
  final bool isOpen;
  final VoidCallback toggleSidebar;

  const Sidebar({super.key, required this.isOpen, required this.toggleSidebar});

  @override
  Widget build(BuildContext context) {
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
              children: [DevResetButton()],
            ),
          ),
        ),
      ],
    );
  }
}

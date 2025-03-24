import 'package:flutter/material.dart';
import 'package:idlefit/widgets/dev_reset_button.dart';

class Sidebar extends StatelessWidget {
  final bool isOpen;
  final VoidCallback toggleSidebar;

  const Sidebar({super.key, required this.isOpen, required this.toggleSidebar});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: isOpen ? 0 : -screenWidth * (2 / 3),
      top: 0,
      bottom: 0,
      width: screenWidth * (2 / 3),
      child: Material(
        elevation: 8,
        child: Container(
          color: Theme.of(context).drawerTheme.backgroundColor ?? Colors.white,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: toggleSidebar,
                  ),
                  title: const Text(
                    'IdleFit Menu',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Reset Game'),
                  subtitle: const Text('Reset all progress'),
                  trailing: DevResetButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

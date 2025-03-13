import 'package:flutter/material.dart';
import 'package:idlefit/constants.dart';

class CardButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Color? backgroundColor;
  final Color? color;
  final Color? textColor;
  final IconData? icon;

  const CardButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.color,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final Widget label =
        icon != null
            ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(icon), const SizedBox(width: 8), Text(text)],
            )
            : Text(text);

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? backgroundColor ?? Constants.primaryColor,
        foregroundColor: textColor ?? Colors.black,
        elevation: 2,
        // padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: label,
    );
  }
}

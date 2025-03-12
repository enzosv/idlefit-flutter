import 'package:flutter/material.dart';
import 'package:idlefit/widgets/card_button.dart';

class CommonCard extends StatelessWidget {
  final String title;
  final String? rightText;
  final String description;
  final List<Widget> additionalInfo;
  final String? costText;
  final Color? costColor;
  final Widget? costIcon;
  final String buttonText;
  final VoidCallback? onButtonPressed;
  final Widget? progressIndicator;
  final EdgeInsets margin;
  final GestureTapDownCallback? onTapDown;

  const CommonCard({
    super.key,
    required this.title,
    this.rightText,
    required this.description,
    this.additionalInfo = const [],
    this.costText,
    this.costColor,
    this.costIcon,
    required this.buttonText,
    this.onButtonPressed,
    this.progressIndicator,
    this.margin = const EdgeInsets.only(bottom: 16),
    this.onTapDown,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      child: InkWell(
        onTapDown: onTapDown,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (rightText != null) Text(rightText!),
                ],
              ),
              const SizedBox(height: 8),
              Text(description),
              ...additionalInfo,
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (costText != null)
                    Row(
                      children: [
                        Text(
                          costText!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: costColor,
                          ),
                        ),
                        if (costIcon != null) ...[
                          const SizedBox(width: 4),
                          costIcon!,
                        ],
                      ],
                    ),
                  const Spacer(),
                  CardButton(text: buttonText, onPressed: onButtonPressed),
                ],
              ),
              if (progressIndicator != null) ...[
                const SizedBox(height: 8),
                progressIndicator!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

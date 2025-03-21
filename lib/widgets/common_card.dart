import 'package:flutter/material.dart';
import 'package:idlefit/helpers/util.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/widgets/card_button.dart';

class CommonCard extends StatelessWidget {
  final String title;
  final String rightText;
  final String? description;
  final List<Widget> additionalInfo;
  final double? cost;
  final String buttonText;
  final VoidCallback? onButtonPressed;
  final Widget? progressIndicator;
  final EdgeInsets margin;
  final GestureTapDownCallback? onTapDown;
  final bool affordable;
  final bool disabled;
  final CurrencyType? costCurrency;

  const CommonCard({
    super.key,
    required this.title,
    required this.rightText,
    this.description,
    this.additionalInfo = const [],
    this.cost,
    this.costCurrency,
    required this.buttonText,
    this.onButtonPressed,
    this.progressIndicator,
    this.margin = const EdgeInsets.only(bottom: 16),
    this.onTapDown,
    this.affordable = false,
    this.disabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = affordable ? costCurrency?.color : Colors.red;
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
                  Text(rightText),
                ],
              ),
              if (description != null) ...[
                const SizedBox(height: 8),
                Text(description!),
              ],
              ...additionalInfo,
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (cost != null)
                    Row(
                      children: [
                        Text(
                          "Cost: ${toLettersNotation(cost!)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        if (costCurrency != null) ...[
                          const SizedBox(width: 4),
                          Icon(costCurrency!.icon, color: color, size: 20),
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

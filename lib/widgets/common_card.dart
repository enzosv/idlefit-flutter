import 'package:flutter/material.dart';
import 'package:idlefit/helpers/util.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/widgets/card_button.dart';

class _CardBody extends StatelessWidget {
  final String? description;
  final List<Widget> additionalInfo;
  final Widget? animation;

  const _CardBody({
    required this.description,
    required this.additionalInfo,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    if (animation != null) {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description != null) ...[
                  const SizedBox(height: 8),
                  Text(description!),
                ],
                ...additionalInfo,
              ],
            ),
          ),
          Expanded(flex: 1, child: animation!),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(description!),
        ],
        ...additionalInfo,
      ],
    );
  }
}

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
  final Widget? animation;

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
    this.animation,
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
              _CardBody(
                description: description,
                additionalInfo: additionalInfo,
                animation: animation,
              ),
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

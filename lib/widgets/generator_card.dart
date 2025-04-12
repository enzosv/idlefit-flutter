import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/helpers/util.dart';
import 'package:idlefit/widgets/current_coins.dart';
import 'package:lottie/lottie.dart';
import 'common_card.dart';
import 'package:idlefit/providers/providers.dart';
import 'package:idlefit/utils/animation_utils.dart';

class GeneratorCard extends ConsumerStatefulWidget {
  final int generatorIndex;

  const GeneratorCard({super.key, required this.generatorIndex});

  @override
  ConsumerState<GeneratorCard> createState() => _GeneratorCardState();
}

class _GeneratorCardState extends ConsumerState<GeneratorCard>
    with TickerProviderStateMixin {
  double progress = 0.0;
  bool showProgress = false;
  late AnimationController _progressController;
  final progressDuration = 500;
  Offset? _tapLocation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: progressDuration),
    );
  }

  void startProgress(TapDownDetails details) {
    final coinGenerators = ref.read(generatorProvider);
    if (showProgress || coinGenerators[widget.generatorIndex].count < 1) {
      return;
    }

    _tapLocation = details.localPosition;

    setState(() {
      progress = 0.0;
      showProgress = true;
    });
    Future.delayed(Duration(milliseconds: 50), () {
      if (!mounted) return;
      setState(() => progress = 1.0);
    });

    Future.delayed(Duration(milliseconds: progressDuration), () {
      if (!mounted) return;
      setState(() {
        showProgress = false;
      });

      final RenderBox? cardRenderBox = context.findRenderObject() as RenderBox?;
      if (cardRenderBox != null && _tapLocation != null) {
        final globalTapPosition = cardRenderBox.localToGlobal(_tapLocation!);
        AnimationUtils.startFlyingCurrencyAnimation(
          context: context,
          vsync: this,
          startPosition: globalTapPosition,
          currencyType: CurrencyType.coin,
        );
      }

      CurrentCoins.triggerAnimation();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Widget? _animation(CoinGenerator generator) {
    if (generator.count < 1) {
      return null;
    }
    return Lottie.asset(
      generator.animationPath,
      width: 80,
      height: 80,
      fit: BoxFit.contain,
      repeat: true,
      animate: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final coinGenerators = ref.watch(generatorProvider);
    final coins = ref.watch(coinProvider);
    final coinGeneratorNotifier = ref.read(generatorProvider.notifier);
    final generator = coinGenerators[widget.generatorIndex];
    final screenWidth = MediaQuery.of(context).size.width;
    final icon = CurrencyType.coin.iconWithSize(16);

    final additionalInfo = [
      Row(
        children: [
          Text(
            'Produces: ${toLettersNotation(generator.singleOutput)} ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          icon,
          Text('/s', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    ];
    additionalInfo.add(
      Row(
        children: [
          Text(
            'Output: ${toLettersNotation(generator.output)} ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          icon,
          Text('/s', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CommonCard(
          title: generator.name,
          rightText: 'Reps: ${generator.count}',
          description: generator.description,
          additionalInfo: additionalInfo,
          cost: generator.cost,
          animation: _animation(generator),
          // TODO: sometimes visually affordable but not mathematically avaoidable
          affordable: coins.count >= generator.cost,
          costCurrency: CurrencyType.coin,
          buttonText: 'Add Rep',
          onButtonPressed:
              coins.count >= generator.cost
                  ? () => coinGeneratorNotifier.buyCoinGenerator(generator)
                  : null,
          onTapDown:
              showProgress || generator.count < 1
                  ? null
                  : (details) => startProgress(details),
          progressIndicator:
              showProgress
                  ? AnimatedContainer(
                    duration: Duration(milliseconds: progressDuration),
                    height: 5,
                    width: progress * (screenWidth - 32),
                    color: Colors.blue,
                  )
                  : null,
        ),
      ],
    );
  }
}

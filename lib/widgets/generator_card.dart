import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/models/coin_generator.dart';
import 'package:idlefit/models/currency.dart';
import 'package:idlefit/helpers/util.dart';
import 'package:idlefit/widgets/current_coins.dart';
import 'package:lottie/lottie.dart';
import 'common_card.dart';
import 'package:idlefit/providers/providers.dart';
import 'dart:math';

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
  late AnimationController _coinController;
  final progressDuration = 500;
  final coinAnimDuration = 800;
  Offset? _tapLocation;
  OverlayEntry? _overlayEntry;
  List<Animation<Offset>> _coinAnimations = [];
  List<Animation<double>> _coinOpacityAnimations = [];
  Offset? _targetPosition;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: progressDuration),
    );

    _coinController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: coinAnimDuration),
    );

    _coinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        _coinController.reset();
        _coinAnimations = [];
        _coinOpacityAnimations = [];
      }
    });
  }

  void startProgress(TapDownDetails details) {
    final coinGenerators = ref.read(generatorProvider);
    if (showProgress || coinGenerators[widget.generatorIndex].count < 1) {
      return;
    }

    _tapLocation = details.localPosition;

    final RenderBox? targetBox =
        CurrentCoins.globalKey.currentContext?.findRenderObject() as RenderBox?;
    if (targetBox != null) {
      _targetPosition = targetBox.localToGlobal(
        targetBox.size.center(Offset.zero),
      );
    }

    setState(() {
      progress = 0.0;
      showProgress = true;
    });
    Future.delayed(Duration(milliseconds: 50), () {
      if (!mounted) return;
      setState(() => progress = 1.0);
    });

    // hide progress bar and trigger animation
    Future.delayed(Duration(milliseconds: progressDuration), () {
      if (!mounted) return;
      setState(() {
        showProgress = false;
      });

      final generator = coinGenerators[widget.generatorIndex];
      final output = ref
          .read(generatorProvider.notifier)
          .tapGenerator(generator);
      _startCoinAnimation(toLettersNotation(output));
      CurrentCoins.triggerAnimation();
    });
  }

  void _startCoinAnimation(String amount) {
    if (!mounted ||
        _tapLocation == null ||
        !context.mounted ||
        _targetPosition == null) {
      return;
    }

    final RenderBox? cardRenderBox = context.findRenderObject() as RenderBox?;
    if (cardRenderBox == null) return;

    final globalTapPosition = cardRenderBox.localToGlobal(_tapLocation!);

    _overlayEntry?.remove();
    _coinAnimations = [];
    _coinOpacityAnimations = [];

    final int numberOfCoins = (5 + (amount.length / 2)).clamp(5, 15).toInt();
    final random = Random();

    for (int i = 0; i < numberOfCoins; i++) {
      final startOffset = Offset(
        globalTapPosition.dx + random.nextDouble() * 30 - 15,
        globalTapPosition.dy + random.nextDouble() * 20 - 10,
      );

      final endOffset = Offset(
        _targetPosition!.dx + random.nextDouble() * 20 - 10,
        _targetPosition!.dy + random.nextDouble() * 10 - 5,
      );

      final startDelay = i * (coinAnimDuration * 0.3 / numberOfCoins);
      final endDelay = coinAnimDuration;
      final intervalStart = startDelay / endDelay;
      final intervalEnd = 0.8;

      final curve = CurvedAnimation(
        parent: _coinController,
        curve: Interval(
          intervalStart,
          intervalEnd,
          curve: Curves.easeInOutQuad,
        ),
      );

      _coinAnimations.add(
        Tween<Offset>(begin: startOffset, end: endOffset).animate(curve),
      );

      _coinOpacityAnimations.add(
        Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: _coinController,
            curve: Interval(
              intervalStart + (intervalEnd - intervalStart) * 0.7,
              1.0,
              curve: Curves.easeIn,
            ),
          ),
        ),
      );
    }

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: _coinController,
          builder: (context, child) {
            return Stack(
              children: List.generate(numberOfCoins, (index) {
                if (index >= _coinAnimations.length ||
                    index >= _coinOpacityAnimations.length) {
                  return const SizedBox.shrink();
                }
                final position = _coinAnimations[index].value;
                final opacity = _coinOpacityAnimations[index].value;
                return Positioned(
                  left: position.dx - 8,
                  top: position.dy - 8,
                  child: FadeTransition(
                    opacity: AlwaysStoppedAnimation(opacity),
                    child: CurrencyType.coin.iconWithSize(16),
                  ),
                );
              }),
            );
          },
        );
      },
    );

    if (context.mounted) {
      Overlay.of(context).insert(_overlayEntry!);
      _coinController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _progressController.dispose();
    _coinController.dispose();
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
          onTapDown: showProgress || generator.count < 1 ? null : startProgress,
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

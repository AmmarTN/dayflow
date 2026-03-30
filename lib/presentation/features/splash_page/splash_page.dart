import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:dayflow/presentation/common/routes/router.dart';
import 'package:dayflow/presentation/features/splash_page/contents/hia_splash_content.dart';

const _splashAnimationDuration = Duration(seconds: 2);

@RoutePage()
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashContent();
  }
}

class SplashContent extends StatefulWidget {
  const SplashContent({super.key});

  @override
  State<SplashContent> createState() => _SplashContentState();
}

class _SplashContentState extends State<SplashContent> with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500), value: 1.0);
    animationController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        context.router.replace(HomeRoute());
      }
    });
    Future.delayed(_splashAnimationDuration, () {
      animationController.reverse(from: 1.0);
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainSplashContent(controller: animationController);
  }
}

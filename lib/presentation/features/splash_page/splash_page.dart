import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:dayflow/main.dart' show pendingAlarmTaskId;
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

    // If an alarm is already ringing (cold-start from notification),
    // skip the splash animation and go directly to the alarm screen.
    final alarmTaskId = pendingAlarmTaskId;
    if (alarmTaskId != null) {
      pendingAlarmTaskId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.router.replaceAll([HomeRoute(), AlarmRoute(taskId: alarmTaskId)]);
      });
      // Still create the controller (required by the mixin) but don't animate.
      animationController = AnimationController(vsync: this, duration: Duration.zero);
      return;
    }

    animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500), value: 1.0);
    animationController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        context.router.replace(HomeRoute());
      }
    });
    Future.delayed(_splashAnimationDuration, () {
      if (mounted) animationController.reverse(from: 1.0);
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

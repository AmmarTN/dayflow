import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum SvgType { network, asset, string }

class MainSvgImage extends StatelessWidget {
  const MainSvgImage({
    super.key,
    required this.path,
    this.height,
    this.width,
    this.type = SvgType.asset,
    this.fit = BoxFit.contain,
    this.darkPath,
  });

  final String path;
  final String? darkPath;
  final double? height;
  final double? width;
  final SvgType type;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    switch (type) {
      case SvgType.asset:
        return SizedBox(
          height: height,
          width: width,
          child: SvgPicture.asset(
            path,
            fit: fit,
          ),
        );
      case SvgType.string:
        return SizedBox(
          height: height,
          width: width,
          child: SvgPicture.string(
            path,
            fit: fit,
          ),
        );
      case SvgType.network:
        return SizedBox(
          height: height,
          width: width,
          child: SvgPicture.network(
            path,
            fit: fit,
          ),
        );
    }
  }
}

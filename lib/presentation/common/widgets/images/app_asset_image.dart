import 'package:flutter/material.dart';

class MainImageAsset extends StatelessWidget {
  final String path;
  final String? darkPath;
  final BoxFit? fit;
  final double? height;
  final double? width;
  final Alignment? alignment;
  const MainImageAsset(
      {super.key,
      required this.path,
      this.darkPath,
      this.height,
      this.width,
      this.fit,
      this.alignment});

  @override
  Widget build(BuildContext context) {
    return Image(
      width: width,
      height: height,
      alignment: alignment ?? Alignment.center,
      image: AssetImage(
        path,
      ),
      fit: fit ?? BoxFit.cover,
    );
  }
}

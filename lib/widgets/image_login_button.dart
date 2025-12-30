import 'package:flutter/material.dart';

class ImageLoginButton extends StatelessWidget {
  const ImageLoginButton({
    super.key,
    required this.assetPath,
    required this.width,
    required this.height,
    required this.fallbackLabel,
    required this.fallbackBackgroundColor,
    required this.fallbackTextColor,
    required this.progressColor,
    required this.isLoading,
    required this.onTap,
  });

  final String assetPath;
  final double width;
  final double height;
  final String fallbackLabel;
  final Color fallbackBackgroundColor;
  final Color fallbackTextColor;
  final Color progressColor;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: isLoading ? null : onTap,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: fallbackBackgroundColor,
                      alignment: Alignment.center,
                      child: Text(
                        fallbackLabel,
                        style: TextStyle(
                          color: fallbackTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isLoading)
            CircularProgressIndicator(
              strokeWidth: 2.5,
              color: progressColor,
            ),
        ],
      ),
    );
  }
}

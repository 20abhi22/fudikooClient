import 'package:flutter/material.dart';

class OfferMarkerWidget extends StatelessWidget {
  const OfferMarkerWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.isDimmed,
  });

  final String label;
  final bool isSelected;
  final bool isDimmed;

  @override
  Widget build(BuildContext context) {
    final scale = isSelected ? 1.18 : 1.0;
    final opacity = isDimmed ? 0.54 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: SizedBox(
          width: 50,
          height: 38,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [

              Positioned(
                bottom: 6,
                child: Transform.rotate(
                  angle: 0.785398,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF87B0D)
                          : const Color(0xFF36651F),
                      border: const Border(
                        // right: BorderSide(color: Colors.white, width: 3),
                        // bottom: BorderSide(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFF87B0D)
                        : const Color(0xFF36651F),
                    borderRadius: BorderRadius.circular(7),
                    // border: Border.all(color: Colors.white, width: 3),
                    // boxShadow: const [
                    //   BoxShadow(
                    //     color: Color(0x33000000),
                    //     blurRadius: 18,
                    //     offset: Offset(0, 8),
                    //   ),
                    // ],
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}

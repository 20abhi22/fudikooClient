import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';

class MenuCard extends StatelessWidget {
  final String url;

  const MenuCard({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(url, height: 120, width: 120, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: "Chicken Biriyani",
                        size: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 4),
                      AppText(
                        text: "650 ₽",
                        size: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 8),
                      AppText(
                        text:
                            "A fragrant and flavorful rice dish cooked with tender meat, aromatic spices, and herbs, offering a rich and royal taste in every bite",
                        size: 10,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                        lineSpacing: 1.2,
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}

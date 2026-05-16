import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';

class MenuCard extends StatelessWidget {
  final String url;
  final String name;
  final String price;
  final String description;
  final String category;
 const MenuCard({
    super.key,
    required this.url,
    this.name = '',
    this.price = '',
    this.description = '',
    this.category = '',
  });

  @override
  Widget build(BuildContext context) {
    final Widget imageWidget = _buildImage();

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: SizedBox(
              height: 96,
              width: 96,
              child: imageWidget,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    text: name,
                    size: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    text: "Rs: ${price}",
                    size: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    text: description,
                    size: 10,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                    lineSpacing: 1.2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    text: category,
                    size: 10,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                    lineSpacing: 1.2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (url.trim().isEmpty) {
      return Image.asset(
        'assets/images/dish.png',
        fit: BoxFit.cover,
      );
    }

    final Uri? parsed = Uri.tryParse(url);
    final bool isNetworkImage = parsed != null && parsed.scheme.startsWith('http');

    if (isNetworkImage) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/dish.png',
          fit: BoxFit.cover,
        ),
      );
    }

    return Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/dish.png',
        fit: BoxFit.cover,
      ),
    );
  }
}

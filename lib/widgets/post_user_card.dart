import 'package:flutter/material.dart';

class PostUserCard extends StatelessWidget {
  final String imageUrl;
  final String caption;
  final PageController? pageController;
  final int? index;

  const PostUserCard({
    Key? key,
    required this.imageUrl,
    required this.caption,
    this.pageController,
    this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double cardSize =
        screenWidth; // Set your desired size based on screen width

    return GestureDetector(
      onTap: () {
        // Handle tap action here (if needed)
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40.0),
        child: Container(
          width: cardSize,
          height: cardSize,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              if (caption.isNotEmpty) // Check if caption is not empty
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: Colors.black.withOpacity(0.6),
                      ),
                      child: Text(
                        caption,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
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

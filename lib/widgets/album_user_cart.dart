import 'package:flutter/material.dart';

class AlbumUserCard extends StatelessWidget {
  final String imageUrl;

  const AlbumUserCard({
    Key? key,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double cardSize = (screenWidth - 20.0) / 3;

    return Padding(
      padding: EdgeInsets.all(0.01),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.0),
        child: Container(
          width: cardSize,
          height: cardSize,
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

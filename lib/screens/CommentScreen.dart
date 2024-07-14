import 'package:flutter/material.dart';

class CommentScreen extends StatelessWidget {
  final String userName;
  final String timeAgo;
  final String imageUrl;
  final Widget chatInput;

  const CommentScreen({
    Key? key,
    required this.userName,
    required this.timeAgo,
    required this.imageUrl,
    required this.chatInput,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
      ),
      body: Column(
        children: [
          ListTile(
            leading: Image.network(imageUrl),
            title: Text(userName),
            subtitle: Text(timeAgo),
          ),
          Expanded(
            child: Container(
              color: Colors.grey[200], // Placeholder for comment list
              child: Center(
                child: Text('Comments go here'),
              ),
            ),
          ),
          chatInput, // Display the chat input widget
        ],
      ),
    );
  }
}

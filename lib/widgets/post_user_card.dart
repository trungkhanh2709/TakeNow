import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostUserCard extends StatelessWidget {
  final String imageUrl;
  final String caption;
  final String userId;
  final Timestamp timestamp;
  final PageController? pageController;
  final int? index;

  const PostUserCard({
    Key? key,
    required this.imageUrl,
    required this.caption,
    required this.userId,
    required this.timestamp,
    this.pageController,
    this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text('Không tìm thấy người dùng'));
        }

        String userName = snapshot.data!.get('name');
        DateTime now = DateTime.now();
        DateTime postTime = timestamp.toDate();
        Duration difference = now.difference(postTime);
        String timeAgo = _formatTimestamp(difference);

        return Center(
          child: Container(
            height: screenWidth + 50,
            width: screenWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40.0),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (caption.isNotEmpty)
                      Positioned(
                        bottom: 20,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40.0),
                            color: Color.fromARGB(121, 12, 12, 12),
                          ),
                          child: Text(
                            caption,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 19),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(Duration difference) {
    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.toDate().day}-${timestamp.toDate().month}-${timestamp.toDate().year}';
    }
  }
}

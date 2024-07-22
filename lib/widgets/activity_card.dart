import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

List<T> takeLast<T>(List<T> list, int n) {
  if (n >= list.length) {
    return List.from(list);
  } else {
    return list.sublist(list.length - n);
  }
}

class ActivityCard extends StatefulWidget {
  final List<DocumentSnapshot> posts;
  final PageController pageController;

  ActivityCard({
    required this.posts,
    required this.pageController,
  });

  @override
  _ActivityCardState createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_onPageChanged);
    super.dispose();
  }

  void _onPageChanged() {
    setState(() {
      currentPageIndex = widget.pageController.page!.round();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _getCurrentSender(currentPageIndex),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          final avatarUrls = snapshot.data!;

          return GestureDetector(
            onTap: () {
              _showReact(context, currentPageIndex);
            },
            child:
                _buildReactButton(avatarUrls), // Pass the list of avatar URLs
          );
        } else {
          return Center(child: Text(''));
        }
      },
    );
  }

  Widget _buildReactButton(List<String> avatarUrls) {
    // Limit the list to 3 avatars
    List<String> limitedAvatars = avatarUrls.take(3).toList();

    // Determine if we need to show a '+N' label
    int additionalCount = avatarUrls.length - 3;

    List<Widget> avatarWidgets = limitedAvatars.asMap().entries.map((entry) {
      int index = entry.key;
      String url = entry.value;

      if (index == 2 && additionalCount > 0) {
        // For the third avatar, add the '+N' label
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 26.0, // Adjusted size
                backgroundImage: NetworkImage(url),
                backgroundColor: Colors.transparent,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 52.0, // Double the radius for full diameter
                  height: 52.0, // Double the radius for full diameter
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '+$additionalCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.0, // Adjusted size to fit well
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // For the first and second avatars, just show the avatar
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: CircleAvatar(
            radius: 26.0, // Adjusted size
            backgroundImage: NetworkImage(url),
            backgroundColor: Colors.transparent,
          ),
        );
      }
    }).toList();

    return Container(
      margin: EdgeInsets.only(bottom: 50.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center the avatars
        children: avatarWidgets,
      ),
    );
  }

  Future<List<String>> _getCurrentSender(int pageIndex) async {
    try {
      String postId = widget.posts[pageIndex].id;
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(
              '${widget.posts[pageIndex]['userId']}_${widget.posts[pageIndex]['userId']}')
          .collection('post_image')
          .doc(postId);

      final postSnapshot = await postRef.get();

      if (postSnapshot.exists && postSnapshot.data()!.containsKey('emotions')) {
        List<dynamic> emotions = postSnapshot['emotions'] ?? [];
        if (emotions.isNotEmpty) {
          List senderIds = emotions.map((e) => e['sender']).toSet().toList();
          List<DocumentSnapshot> senderSnapshots = await Future.wait(
              senderIds.map((id) => FirebaseFirestore.instance
                  .collection('users')
                  .doc(id)
                  .get()));

          // Return a list of avatar URLs
          return senderSnapshots.map((doc) => doc['image'] as String).toList();
        } else {
          throw Exception('No sender data found');
        }
      } else {
        throw Exception('No sender data found');
      }
    } catch (e) {
      print('Error: $e');
      return []; // Return an empty list in case of error
    }
  }

  void _showReact(BuildContext context, int pageIndex) async {
    String postId = widget.posts[pageIndex].id;
    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(
            '${widget.posts[pageIndex]['userId']}_${widget.posts[pageIndex]['userId']}')
        .collection('post_image')
        .doc(postId);

    final postSnapshot = await postRef.get();
    print('Post ID: $postId');
    print('User ID Post: ${widget.posts[pageIndex]['userId']}');

    if (postSnapshot.exists) {
      if (postSnapshot.data()!.containsKey('emotions')) {
        List<dynamic> emotions = postSnapshot['emotions'] ?? [];
        print('Emotions: $emotions');

        Map<String, List<Map<String, dynamic>>> groupedEmotions = {};
        for (var emotion in emotions) {
          String sender = emotion['sender'];
          if (!groupedEmotions.containsKey(sender)) {
            groupedEmotions[sender] = [];
          }
          groupedEmotions[sender]!.add(emotion);
        }

        List<Widget> emotionWidgets = [];
        for (var entry in groupedEmotions.entries) {
          List<Map<String, dynamic>> recentEmotionsFromSender =
              takeLast(entry.value, 5);

          emotionWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(entry.key)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasData) {
                    String senderName = snapshot.data!.get('name') ?? 'Unknown';
                    String avatarUrl = snapshot.data!.get('image') ?? '';

                    // Calculate height of name and emoji
                    final textPainterName = TextPainter(
                      text: TextSpan(
                        text: senderName,
                        style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      textDirection: TextDirection.ltr,
                    )..layout();

                    final textPainterEmoji = TextPainter(
                      text: TextSpan(
                        text: recentEmotionsFromSender.isNotEmpty
                            ? recentEmotionsFromSender.first['emoji']
                            : '',
                        style: TextStyle(fontSize: 24.0, color: Colors.white),
                      ),
                      textDirection: TextDirection.ltr,
                    )..layout();

                    double totalHeight = textPainterName.size.height +
                        textPainterEmoji.size.height +
                        8.0; // +8.0 for spacing

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 60, 60, 60),
                        borderRadius: BorderRadius.circular(40.0),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: totalHeight / 2, // Set avatar height
                            backgroundImage: NetworkImage(avatarUrl),
                          ),
                          SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$senderName',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4.0),
                                Row(
                                  children:
                                      recentEmotionsFromSender.map((emotion) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: Text(
                                        emotion['emoji'],
                                        style: TextStyle(
                                          fontSize: 24.0,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 60, 60, 60),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        'Sender: Loading...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }

        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return FractionallySizedBox(
              heightFactor: 0.88,
              child: Container(
                color: Color.fromARGB(255, 48, 48, 48),
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                child: ListView(
                  children: emotionWidgets.isNotEmpty
                      ? emotionWidgets
                      : [
                          ListTile(
                            title: Text(
                              'Chưa có hoạt động nào',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                ),
              ),
            );
          },
        );
      }
    } else {
      print('Post with ID $postId does not exist.');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:takenow/screens/CommentScreen.dart';
import 'package:takenow/screens/viewAlbumScreen.dart';
import 'package:takenow/widgets/post_user_card.dart';

class ViewPhotoScreen extends StatefulWidget {
  const ViewPhotoScreen({Key? key}) : super(key: key);

  @override
  State<ViewPhotoScreen> createState() => _ViewPhotoScreenState();
}

class _ViewPhotoScreenState extends State<ViewPhotoScreen> {
  String selectedEmotion = '';
  PageController _pageController = PageController();
  List<DocumentSnapshot>? _posts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F2E2E),
      body:Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collectionGroup('post_image')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return const Center(child: CircularProgressIndicator());
                default:
                  _posts = snapshot.data?.docs;
                  return PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: _posts?.length ?? 0,
                    itemBuilder: (context, index) {
                      DocumentSnapshot document = _posts![index];
                      String imageUrlScroll = document['imageUrl'];
                      String caption = document['caption'];
                      String userId = document['userId'];
                      String timestamp = document['timestamp'];

                      int timestampInt = int.parse(timestamp);
                      return Center(
                        child: Column(
                          children: [
                            Expanded(
                              child: PostUserCard(
                                imageUrl: imageUrlScroll,
                                caption: caption,
                                userId: userId,
                                timestamp: Timestamp.fromMillisecondsSinceEpoch(
                                    timestampInt),
                                pageController: _pageController,
                                index: index,
                              ),
                            ),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                                children: [
                                  SizedBox(width: 0),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ViewAlbumScreen(),
                                        ),
                                      );
                                    },
                                    child: SvgPicture.asset(
                                      'assets/icons/darhboard.svg',
                                      width: 40,
                                      height: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10.0),
                                  EmotionSelector(
                                    selectedEmotion: selectedEmotion,
                                    imageUrlScroll: imageUrlScroll,
                                    onEmotionSelected: onEmotionSelected,
                                    onSendMessage: () {
                                      // Handle send message action here
                                    },
                                    onOpenEmojiPicker: () {
                                      _openEmojiPicker(context);
                                    },

                                    onShowSortMenu: () {
                                      _showSortMenu(context);
                                    },

                                  ),
                                  const SizedBox(width: 10.0),
                                  GestureDetector(
                                    // onTap: _showSortMenu(context),
                                    onTap: (){},

                                    child: SvgPicture.asset(
                                      'assets/icons/Sort_random_light.svg',
                                      width: 40,
                                      height: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 0),

                                ]

                            )

                          ],
                        ),
                      );
                    },
                  );
              }
            },
          ),
        ],
      )


    );
  }

  void onEmotionSelected(String emotion) {
    setState(() {
      selectedEmotion = emotion;
    });
  }

  void _openEmojiPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return EmojiPicker();
      },
    );
  }

  void _showSortMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.download),
                title: Text('Download'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.share),
                title: Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Xóa'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.report),
                title: Text('Báo cáo'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Hủy'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class EmotionSelector extends StatelessWidget {
  final String selectedEmotion;
  final String imageUrlScroll;
  final Function(String) onEmotionSelected;
  final VoidCallback? onSendMessage;
  final VoidCallback? onOpenEmojiPicker;

  final VoidCallback onShowSortMenu;

  const EmotionSelector({
    Key? key,
    required this.selectedEmotion,
    required this.imageUrlScroll,
    required this.onEmotionSelected,
    this.onSendMessage,
    this.onOpenEmojiPicker,

    required this.onShowSortMenu,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
width: 250,
      margin: const EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(88, 81, 81, 1),
        borderRadius: BorderRadius.circular(40.0),
      ),
      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 15),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [

          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommentScreen(imageUrl: imageUrlScroll),
                ),
              );
            },
            child: SvgPicture.asset(
              'assets/icons/Chat_light.svg',
              width: 38.0,
              height: 38.0,
              color: Colors.white,
            ),
          ),
          GestureDetector(
            onTap: onOpenEmojiPicker,
            child: SvgPicture.asset(
              'assets/icons/emoji-add-svgrepo-com 1.svg',
              width: 38.0,
              height: 38.0,
              color: Colors.white,
            ),
          ),

        ],
      ),
    );
  }
}

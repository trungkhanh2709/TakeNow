import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:takenow/widgets/post_user_card.dart';

class ViewPhotoFromAlbum extends StatefulWidget {
  final String imageUrl;
  final String caption;
  final String userId;
  final String timestamp;

  const ViewPhotoFromAlbum({
    Key? key,
    required this.imageUrl,
    required this.caption,
    required this.userId,
    required this.timestamp,
  }) : super(key: key);

  @override
  State<ViewPhotoFromAlbum> createState() => _ViewPhotoFromAlbumState();
}

class _ViewPhotoFromAlbumState extends State<ViewPhotoFromAlbum> {
  String selectedEmotion = '';
  PageController _pageController = PageController();
  List<DocumentSnapshot>? _posts;
  bool _showChatInput = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F2E2E),
      body: GestureDetector(
        onTap: () {
          if (_showChatInput) {
            setState(() {
              _showChatInput = false;
            });
          }
        },
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: 1, // Only one item for the selected photo
                itemBuilder: (context, index) {
                  return Center(
                    child: PostUserCard(
                      imageUrl: widget.imageUrl,
                      caption: widget.caption,
                      userId: widget.userId,
                      timestamp: Timestamp.fromMillisecondsSinceEpoch(
                          int.parse(widget.timestamp)),
                      pageController: _pageController,
                      index: index,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Visibility(
                  visible: !_showChatInput,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(
                          context); // Navigate back to previous screen
                    },
                    child: Container(
                      margin: const EdgeInsets.only(
                        left: 20.0,
                        bottom: 50.0,
                      ),
                      child: SvgPicture.asset(
                        'assets/icons/darhboard.svg',
                        width: 40,
                        height: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15.0),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _showChatInput
                            ? _chatInput()
                            : EmotionSelector(
                                selectedEmotion: selectedEmotion,
                                onEmotionSelected: onEmotionSelected,
                                onSendMessage: () {
                                  setState(() {
                                    _showChatInput = true;
                                  });
                                },
                                onOpenEmojiPicker: () {
                                  _openEmojiPicker(context);
                                },
                              ),
                      ),
                      const SizedBox(width: 15.0),
                      Visibility(
                        visible: !_showChatInput,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showChatInput = true;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(
                              right: 20.0,
                              bottom: 50.0,
                            ),
                            child: SvgPicture.asset(
                              'assets/icons/Sort_random_light.svg',
                              width: 40,
                              height: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

  Widget _chatInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter message...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 15.0,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              // Handle sending message here
            },
          ),
        ],
      ),
    );
  }
}

class EmotionSelector extends StatelessWidget {
  final String selectedEmotion;
  final Function(String) onEmotionSelected;
  final VoidCallback onSendMessage;
  final VoidCallback? onOpenEmojiPicker;

  const EmotionSelector({
    Key? key,
    required this.selectedEmotion,
    required this.onEmotionSelected,
    required this.onSendMessage,
    this.onOpenEmojiPicker,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 50.0),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(88, 81, 81, 1),
        borderRadius: BorderRadius.circular(40.0),
      ),
      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton(
            onPressed: onSendMessage,
            child: SvgPicture.asset(
              'assets/icons/Chat_light.svg',
              width: 38.0,
              height: 38.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10.0),
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

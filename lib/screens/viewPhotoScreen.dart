import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg package
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'; // Import emoji_picker_flutter package
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth package
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:takenow/Class/Globals.dart';
import 'package:takenow/main.dart';
import 'package:takenow/widgets/post_user_card.dart';
import 'package:takenow/screens/viewAlbumScreen.dart'; // Import trang ViewAlbum

class ViewPhotoScreen extends StatefulWidget {
  const ViewPhotoScreen({Key? key}) : super(key: key);

  @override
  State<ViewPhotoScreen> createState() => _ViewPhotoScreenState();
}

class _ViewPhotoScreenState extends State<ViewPhotoScreen> {
  String selectedEmotion = '';
  PageController _pageController = PageController();
  List<DocumentSnapshot>? _posts;
  bool _showChatInput = false;
  String imageUrl ='';
  User? currentUser;
  String? userID = Globals.getGoogleUserId();

  @override
  void initState() {
    super.initState();

    currentUser = FirebaseAuth.instance.currentUser; // Get the current user
  }

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
        child: StreamBuilder<QuerySnapshot>(
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
                if (snapshot.hasData && currentUser != null) {
                  _posts = snapshot.data?.docs.where((document) {
                    List<dynamic> visibleTo = document['visibleTo'];
                    String postUserId = document['userId'];
                    return visibleTo.contains(currentUser!.uid) || postUserId == currentUser!.uid;
                  }).toList();
                } else {
                  _posts = [];
                }
                return Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.vertical,
                        itemCount: _posts?.length ?? 0,
                        itemBuilder: (context, index) {
                          DocumentSnapshot document = _posts![index];
                          imageUrl = document['imageUrl'];
                          String caption = document['caption'];
                          String userId = document['userId'];
                          String timestamp = document['timestamp'];

                          int timestampInt = int.parse(timestamp);
                          return Center(
                            child: PostUserCard(
                              imageUrl: imageUrl,
                              caption: caption,
                              userId: userId,
                              timestamp: Timestamp.fromMillisecondsSinceEpoch(timestampInt),
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewAlbumScreen(),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(
                                left: 20.0,
                                bottom: 50.0,
                              ),
                              child: SvgPicture.asset(
                                'assets/icons/darhboard.svg',
                                width: 40, // Đặt kích thước cho Icon darhboard
                                height: 40, // Đặt kích thước cho Icon darhboard
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
                                child: Container(
                                  margin: const EdgeInsets.only(
                                    right: 20.0,
                                    bottom: 50.0,
                                  ), // Thêm margin bottom vào đây
                                  child: GestureDetector(
                                    onTap: () {
                                      _showSortMenu(context);
                                    },
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
                );
            }
          },
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
                hintText: 'Nhập tin nhắn...',
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
              // Xử lý gửi tin nhắn ở đây
            },
          ),
        ],
      ),
    );
  }



  Future<void> deletePost(String imageUrl, String currentUserId) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // Query the post with the given imageUrl
    QuerySnapshot querySnapshot = await _firestore
        .collectionGroup('post_image')
        .where('imageUrl', isEqualTo: imageUrl)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot postSnapshot = querySnapshot.docs.first;
      Map<String, dynamic> postData = postSnapshot.data() as Map<String, dynamic>;

      String postUserId = postData['userId'];
      List<dynamic> visibleTo = postData['visibleTo'];

      log('postSnapshot: $postSnapshot');
      log('postSnapshot id: ${postSnapshot.id}');

      if (postUserId == currentUserId) {
        // Show confirmation dialog
        bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm Deletion'),
            content: Text('No one can see your post'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('OK'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
            ],
          ),
        );

        if (confirm) {
          try {
            // Delete the post from the correct collection
            await postSnapshot.reference.delete();
            log("Post deleted successfully");
          } catch (e) {
            log("Failed to delete post: $e");
          }
        }
      } else {
        // Show confirmation dialog
        bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm Deletion'),
            content: Text('Delete on your side'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('OK'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
            ],
          ),
        );

        if (confirm) {
          try {
            // Remove the current userId from the visibleTo array
            visibleTo.remove(currentUserId);
            await postSnapshot.reference.update({
              'visibleTo': visibleTo,
            });
            log("Visibility updated successfully");
          } catch (e) {
            log("Failed to update visibility: $e");
          }
        }
      }
    } else {
      log("No post found with the given imageUrl");
    }
  }

  void _showSortMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Colors.transparent, // Màu nền trong suốt
          child: Column(
            mainAxisSize: MainAxisSize.min, // Chiều cao dựa vào nội dung
            children: [
              ListTile(
                leading: Icon(Icons.download),
                title: Text('Download'),
                onTap: () async {
                  // Xử lý khi người dùng nhấn Download
                },
              ),
              ListTile(
                leading: Icon(Icons.share),
                title: Text('Share'),
                onTap: () {
                  // Xử lý khi người dùng nhấn Share
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Xóa'),
                onTap: () async {
                  await deletePost(imageUrl, userID!);

                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.report),
                title: Text('Báo cáo'),
                onTap: () {
                  // Xử lý khi người dùng nhấn Báo cáo
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Hủy'),
                onTap: () {
                  // Xử lý khi người dùng nhấn Hủy
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
  final Function(String) onEmotionSelected;
  final VoidCallback onSendMessage; // Thêm callback để xử lý khi gửi tin nhắn
  final VoidCallback? onOpenEmojiPicker; // Callback để mở EmojiPicker

  const EmotionSelector({
    Key? key,
    required this.selectedEmotion,
    required this.onEmotionSelected,
    required this.onSendMessage, // Nhận callback này từ ViewPhotoScreen
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
          const SizedBox(width: 10.0), // Khoảng cách giữa các thành phần
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

import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_downloader/image_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:takenow/Class/Globals.dart';
import 'package:takenow/screens/CommentScreen.dart';
import 'package:takenow/screens/viewAlbumScreen.dart';
import 'package:takenow/widgets/post_user_card.dart';
import 'package:takenow/widgets/activity_card.dart';
import 'package:rxdart/rxdart.dart';

class ViewPhotoScreen extends StatefulWidget {
  const ViewPhotoScreen({Key? key}) : super(key: key);

  @override
  State<ViewPhotoScreen> createState() => _ViewPhotoScreenState();
}

class _ViewPhotoScreenState extends State<ViewPhotoScreen> {
  String selectedEmotion = '';
  PageController _pageController = PageController();
  List<DocumentSnapshot>? _posts;
  String imageUrlScroll = '';
  String userId = '';
  String userIdPost = '';
  String postId = ''; // Add this to store postId
  User? currentUser;
  List<String> _selectedFriendIds = [];
  String selectedFriendName = 'All Friends';
  String? userLogin = Globals.getGoogleUserId();
  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  String? userID = Globals.getGoogleUserId();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F2E2E),
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/Refund_back_light.svg',
            width: 30,
            height: 30,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Center(
          child: GestureDetector(
            onTap: () {
              _showFriendsList(context);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: Color.fromRGBO(88, 81, 81, 1),
                borderRadius: BorderRadius.circular(40.0),
              ),
              child: Text(
                selectedFriendName,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ),
        actions: [SizedBox(width: 50)],
      ),
      backgroundColor: const Color(0xFF2F2E2E),
      body: Stack(
        children: [
          StreamBuilder<List<DocumentSnapshot>>(
            stream: _selectedFriendIds.isEmpty
                ? CombineLatestStream.list([
                    FirebaseFirestore.instance
                        .collectionGroup('post_image')
                        .orderBy('timestamp', descending: true)
                        .where('visibleTo', arrayContains: userLogin)
                        .snapshots()
                        .map((snapshot) => snapshot.docs),
                    FirebaseFirestore.instance
                        .collectionGroup('post_image')
                        .orderBy('timestamp', descending: true)
                        .where('userId', isEqualTo: userLogin)
                        .snapshots()
                        .map((snapshot) => snapshot.docs),
                  ]).map((list) => list.expand((docs) => docs).toList())
                : FirebaseFirestore.instance
                    .collectionGroup('post_image')
                    .orderBy('timestamp', descending: true)
                    .where('visibleTo', arrayContains: userLogin)
                    .where('userId', whereIn: _selectedFriendIds)
                    .snapshots()
                    .map((snapshot) => snapshot.docs),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return const Center(child: CircularProgressIndicator());
                default:
                  _posts = snapshot.data;
                  if (_posts == null || _posts!.isEmpty) {
                    return Center(child: Text('No posts available'));
                  }
                  return PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: _posts?.length ?? 0,
                    itemBuilder: (context, index) {
                      DocumentSnapshot document = _posts![index];
                      imageUrlScroll = document['imageUrl'];
                      String caption = document['caption'];
                      userId = document['userId'];
                      userIdPost = userId;
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
                            ActivityCard(
                              posts: _posts ?? [],
                              pageController: _pageController,
                            ),
                            const SizedBox(height: 10.0),
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
                                  onSendMessage: () {},
                                  onOpenEmojiPicker: () {
                                    _openEmojiPicker(context);
                                  },
                                ),
                                const SizedBox(width: 10.0),
                                GestureDetector(
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
                                SizedBox(width: 0),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showFriendsList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (BuildContext context) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                  child: Text('Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.white)));
            } else if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                  child: Text('No friends found',
                      style: TextStyle(color: Colors.white)));
            }

            List<dynamic> friends = snapshot.data!['friends'] ?? [];
            List<String> friendIds = friends.cast<String>();

            return ListView(
              padding: EdgeInsets.only(top: 50.0),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                  leading: SvgPicture.asset(
                    'assets/icons/Group_light.svg',
                    width: 24,
                    height: 24,
                    color: Colors.white,
                  ),
                  title: Text('All Friends',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    setState(() {
                      _selectedFriendIds.clear();
                      selectedFriendName = 'All Friends';
                      userId =
                          ''; // Clear userId to show posts from all friends
                    });
                    Navigator.pop(context);
                  },
                ),
                if (friends.isNotEmpty)
                  ...friendIds.map((friendId) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(friendId)
                          .get(),
                      builder: (context, friendSnapshot) {
                        if (friendSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return ListTile(
                            title: Text('Loading...',
                                style: TextStyle(color: Colors.white)),
                          );
                        } else if (friendSnapshot.hasError) {
                          return ListTile(
                            title: Text('Error: ${friendSnapshot.error}',
                                style: TextStyle(color: Colors.white)),
                          );
                        } else if (!friendSnapshot.hasData ||
                            !friendSnapshot.data!.exists) {
                          return ListTile(
                            title: Text('Friend not found',
                                style: TextStyle(color: Colors.white)),
                          );
                        }

                        String friendName = friendSnapshot.data!['name'];

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(friendSnapshot.data!['image']),
                          ),
                          title: Text(friendName,
                              style: TextStyle(color: Colors.white)),
                          onTap: () {
                            setState(() {
                              _selectedFriendIds = [friendId];
                              selectedFriendName = friendName;
                              userId =
                                  friendId; // Set userId to show posts from this friend
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  }).toList(),
              ],
            );
          },
        );
      },
    );
  }

  void onEmotionSelected(String emotion) {
    setState(() {
      selectedEmotion = emotion;
    });

    if (_posts != null && _posts!.isNotEmpty) {
      postId =
          _posts![_pageController.page!.round()].id; // Lấy postId từ _posts
      _saveEmotionToFirestore(
          postId, emotion); // Gọi hàm để lưu emotion vào Firestore
    }
  }

  void _openEmojiPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return EmojiPicker(
          onEmojiSelected: (category, emoji) {
            onEmotionSelected(emoji.emoji);
            Navigator.pop(context); // Close the emoji picker after selection
          },
        );
      },
    );
  }

  void _saveEmotionToFirestore(String postId, String emotion) async {
    if (currentUser == null || postId.isEmpty) return;

    try {
      final userId = currentUser!.uid;
      print('postId: $postId'); // In ra postId của bài đăng
      print('userIdPost: $userIdPost'); // In ra userId của chủ bài đăng

      // Retrieve the userID of the post owner
      final postSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc('$userIdPost' +
              '_$userIdPost') // Concatenate userIdPost with "_$userIdPost"
          .collection('post_image')
          .doc(postId)
          .get();

      if (!postSnapshot.exists) {
        print('Document with postId $postId does not exist.');
        return;
      }

      // Update emotions in the specific document
      await postSnapshot.reference.update({
        'emotions': FieldValue.arrayUnion([
          {
            'emoji': emotion,
            'sender': userId,
          }
        ]),
      });
    } catch (e) {
      log('Error saving emotion: $e');
    }
  }

  Future<void> deletePost(String imageUrl, String? currentUserId) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    QuerySnapshot querySnapshot = await _firestore
        .collectionGroup('post_image')
        .where('imageUrl', isEqualTo: imageUrl)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot postSnapshot = querySnapshot.docs.first;
      Map<String, dynamic> postData =
          postSnapshot.data() as Map<String, dynamic>;

      String postUserId = postData['userId'];
      List<dynamic> visibleTo = postData['visibleTo'];

      log('postSnapshot: $postSnapshot');
      log('postSnapshot id: ${postSnapshot.id}');

      if (postUserId == currentUserId) {
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
            await postSnapshot.reference.delete();
            log("Post deleted successfully");
          } catch (e) {
            log("Failed to delete post: $e");
          }
        }
      } else {
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

  Future<void> downloadImageToAlbum(String imageUrl) async {
    bool hasPermission = await _requestPermission(Permission.storage);
    if (!hasPermission) {
      print('Storage permission denied');
      return;
    }

    try {
      log('message ' + imageUrl);
      String? imageId = await ImageDownloader.downloadImage(
        imageUrl,
        destination: AndroidDestinationType.directoryPictures
          ..subDirectory(
              "Takenow/${DateTime.now().millisecondsSinceEpoch}.jpg"),
      );

      if (imageId == null) {
        print('Download failed');
        return;
      }

      // Retrieve the image file path
      String? filePath = await ImageDownloader.findPath(imageId);
      if (filePath == null) {
        print('Could not find the downloaded image');
        return;
      }

      print('Image downloaded to: $filePath');
    } on Exception catch (error) {
      print('Error downloading image: $error');
    }
  }

  Future<bool> _requestPermission(Permission permission) async {
    final plugin = DeviceInfoPlugin();
    final android = await plugin.androidInfo;

    final storageStatus = android.version.sdkInt < 33
        ? await Permission.storage.request()
        : PermissionStatus.granted;

    if (storageStatus == PermissionStatus.granted) {
      print("granted");
      return true;
    }
    if (storageStatus == PermissionStatus.denied) {
      print("denied");
      return false;
    }
    if (storageStatus == PermissionStatus.permanentlyDenied) {
      openAppSettings();
      return false;
    }
    return false;
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
                onTap: () async {
                  log('imageUrlScroll' + imageUrlScroll);
                  await downloadImageToAlbum(imageUrlScroll);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Xóa'),
                onTap: () async {
                  String? iduserLogin = Globals.getGoogleUserId();
                  await deletePost(imageUrlScroll, iduserLogin);

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

  const EmotionSelector({
    Key? key,
    required this.selectedEmotion,
    required this.imageUrlScroll,
    required this.onEmotionSelected,
    this.onSendMessage,
    this.onOpenEmojiPicker,
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

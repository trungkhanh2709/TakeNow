import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_downloader/image_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:takenow/Class/Globals.dart';
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
  String imageUrlScroll = '';
  String userId = '';

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
                       imageUrlScroll = document['imageUrl'];
                      String caption = document['caption'];
                       userId = document['userId'];
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



                                  ),
                                  const SizedBox(width: 10.0),
                                  GestureDetector(

                                    onTap: (){
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
      log('message ' +imageUrl);
      String? imageId = await ImageDownloader.downloadImage(
        imageUrl,
        destination: AndroidDestinationType.directoryPictures
          ..subDirectory("Takenow/${DateTime.now().millisecondsSinceEpoch}.jpg"),
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
                onTap: () async  {
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
                  await deletePost(imageUrlScroll,iduserLogin );

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

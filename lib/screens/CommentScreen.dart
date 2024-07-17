import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:takenow/api/apis.dart';
import 'package:takenow/models/chat_user.dart';
import 'package:takenow/models/message.dart';

class CommentScreen extends StatefulWidget {
  final String imageUrl;

  CommentScreen({required this.imageUrl});

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  String userIdPost = '';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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
              controller: _messageController,
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
              onPressed: () async {
                setState(() {
                  _isLoading = true;
                });
                String msg = _messageController.text.trim();

                if (widget.imageUrl.isNotEmpty && msg.isNotEmpty) {
                  File file = await getImageFileFromUrl(widget.imageUrl);
                  userIdPost = await getUserIdFromImageUrl(widget.imageUrl);

                  DocumentSnapshot userSnapshot = await FirebaseFirestore
                      .instance
                      .collection('users')
                      .doc(userIdPost)
                      .get();
                  if (userSnapshot.exists) {
                    var userData = userSnapshot.data() as Map<String, dynamic>;

                    ChatUser chatUser = ChatUser(
                      id: userIdPost,
                      image: userData['image'] ?? '',
                      about: userData['about'] ?? '',
                      name: userData['name'] ?? '',
                      createdAt: (userData['createdAt'] is Timestamp)
                          ? (userData['createdAt'] as Timestamp)
                              .toDate()
                              .toString()
                          : Timestamp.now().toDate().toString(),
                      isOnline: userData['isOnline'] ?? false,
                      lastActive: (userData['lastActive'] is Timestamp)
                          ? (userData['lastActive'] as Timestamp)
                              .toDate()
                              .toString()
                          : Timestamp.now().toDate().toString(),
                      email: userData['email'] ?? '',
                      pushToken: userData['pushToken'] ?? '',
                    );
                    await APIs.sendChatImage(chatUser, file);
                    await APIs.sendMessage(chatUser, msg, MessageType.text);
                  }
                  _messageController.clear();
                  Navigator.pop(context);

                }
                setState(() {
                  _isLoading = false;
                });
              }),
        ],
      ),
    );
  }

  Future<String> getUserIdFromImageUrl(String imageUrl) async {
    try {
      // Lấy tất cả các tài liệu trong collectionGroup 'post_image'
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collectionGroup('post_image')
          .where('imageUrl', isEqualTo: imageUrl)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
        return documentSnapshot['userId'] as String;
      } else {
        print('Không tìm thấy tài liệu nào khớp với điều kiện.');
        return '';
      }
    } catch (e) {
      print('Lỗi khi lấy userId: $e');
      return '';
    }
  }

  Future<File> getImageFileFromUrl(String url) async {
    final response = await Dio()
        .get(url, options: Options(responseType: ResponseType.bytes));
    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File(filePath);
    await file.writeAsBytes(response.data);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F2E2E),
        title: Text("Photo and Chat"),
      ),
      backgroundColor: const Color(0xFF2F2E2E),
      body: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40.0), // Border radius of 40
              child: Image.network(widget.imageUrl), // Display image
            ),
          ),
          _chatInput(), // Chat input box
        ],
      ),
    );
  }
}

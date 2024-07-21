import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:takenow/helper/my_date_util.dart';
import 'package:takenow/models/chat_user.dart';
import 'package:takenow/models/post_user.dart';
import 'package:takenow/widgets/message_card.dart';
import 'package:takenow/models/message.dart'
as message_model; // Sử dụng alias cho message.
import 'package:takenow/models/post_user.dart'
as post_user_model; // Sử dụng alias cho post_user.dart

import '../api/apis.dart';
import '../main.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<message_model.Message> _list = [];

  //for handling message text changes
  final _textController = TextEditingController();

  //for storing value of showing or hiding emoji
  bool _showEmoji = false, _isUpLoading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: WillPopScope(
          //if search is on & back button is pressed then close search
          //or else simple close current screen on back button click
          onWillPop: () {
            if (_showEmoji) {
              setState(() => _showEmoji = !_showEmoji);
              return Future.value(false);
            } else {
              return Future.value(true);
            }
          },
          child: Scaffold(
            backgroundColor: Color(0xFF2F2E2E),
            appBar: AppBar(
              automaticallyImplyLeading: false,
              flexibleSpace: _appBar(),
              backgroundColor: Color(0xFF2F2E2E),
            ),
            //body
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: APIs.getAllMesage(widget.user),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                      //if data is loading
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return const SizedBox();

                      //if some or all data is loaded => show
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;
                          _list = data?.map((e) => Message.fromJson(e.data()))
                              .toList() ??
                              [];

                          if (_list.isNotEmpty) {
                            return ListView.builder(
                                reverse: true,
                                itemCount: _list.length,
                                padding: EdgeInsets.only(top: mq.height * .01),
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return MessageCard(message: _list[index]);
                                });
                          } else {
                            return const Center(
                              child: Text('Say Hii! 👋',
                                  style: TextStyle(fontSize: 20, color: Colors.white)),
                            );
                          }
                      }
                    },
                  ),
                ),

                //progress indicator for showing uploading
                if (_isUpLoading)
                  const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                          padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ))),

                _chatInput(),

                //show emojis on keyboard emoji button click & vice versa
                if (_showEmoji)
                  SizedBox(
                    height: mq.height * .35,
                    child: EmojiPicker(
                      textEditingController: _textController,
                      config: Config(
                        emojiViewConfig: EmojiViewConfig(
                          emojiSizeMax: 32 * (Platform.isIOS ? 1.20 : 1.0),
                        ),
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  //app bar widget
  Widget _appBar() {
    return InkWell(
        onTap: () {},
        child: StreamBuilder(
            stream: APIs.getUserInfo(widget.user),
            builder: (context, snapshot) {
              final data = snapshot.data?.docs;
              final list =
                  data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];

              return Row(
                children: [
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/Refund_back_light.svg',
                      width: 27,
                      height: 27,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(mq.height * .03),
                    child: CachedNetworkImage(
                      width: mq.height * .05,
                      height: mq.height * .05,
                      imageUrl:
                      list.isNotEmpty ? list[0].name : widget.user.image,
                      //placeholder: (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const CircleAvatar(
                          child: Icon(CupertinoIcons.person)),
                    ),
                  ),

                  //for adding some space
                  SizedBox(width: 10),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.user.name,
                          style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500)),

                      //for adding some space
                      const SizedBox(height: 2),

                      //last adding some space
                      Text(
                          list.isNotEmpty
                              ? list[0].isOnline
                              ? 'Online'
                              : MyDateUtil.getLastActiveTime(
                              context: context,
                              lastActive: list[0].lastActive)
                              : MyDateUtil.getLastActiveTime(
                              context: context,
                              lastActive: widget.user.lastActive),
                          style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500)),
                    ],
                  )
                ],
              );
            }));
  }

  //bottom chat input field
  Widget _chatInput() {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: mq.height * .01, horizontal: mq.width * .025),
      child: Row(
        children: [
          //input field & buttons
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  //emoji button
                  IconButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        setState(() => _showEmoji = !_showEmoji);
                      },
                      icon: const Icon(Icons.emoji_emotions,
                          color: Colors.blueAccent, size: 25)),

                  Expanded(
                      child: TextField(
                        controller: _textController,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        onTap: () {
                          if (_showEmoji) setState(() => _showEmoji = !_showEmoji);
                        },
                        decoration: const InputDecoration(
                            hintText: 'Type Something...',
                            hintStyle: TextStyle(color: Colors.blueAccent),
                            border: InputBorder.none),
                      )
                  ),

                  //pick image from gallery button
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();

                        // Pick an image.
                        final List<XFile> images =
                        await picker.pickMultiImage(imageQuality: 70);
                        for (var i in images) {
                          log('Image Path: ${i.path}');
                          setState(() => _isUpLoading = true);
                          await APIs.sendChatImage(widget.user, File(i.path));
                          setState(() => _isUpLoading = false);
                        }
                      },
                      icon: const Icon(Icons.image,
                          color: Colors.blueAccent, size: 26)),

                  //take image from camera button
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();

                        // Pick an image.
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.camera, imageQuality: 70);
                        if (image != null) {
                          log('Image Path: ${image.path}');
                          setState(() => _isUpLoading = true);

                          await APIs.sendChatImage(
                              widget.user, File(image.path));
                          setState(() => _isUpLoading = false);
                        }
                      },
                      icon: const Icon(Icons.camera_alt_rounded,
                          color: Colors.blueAccent, size: 26)),

                  //adding some space
                  SizedBox(width: mq.width * .02),
                ],
              ),
            ),
          ),

          //send message button
          MaterialButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                APIs.sendMessage(
                    widget.user, _textController.text, MessageType.text);
                _textController.text = '';
              }
            },
            minWidth: 0,
            padding:
            const EdgeInsets.only(top: 10, bottom: 10, right: 5, left: 10),
            shape: CircleBorder(),
            color: Colors.green,
            child: Icon(Icons.send, color: Colors.white, size: 28),
          )
        ],
      ),
    );
  }
}

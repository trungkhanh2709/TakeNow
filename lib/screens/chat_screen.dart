import 'dart:convert';
import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:takenow/models/chat_user.dart';
import 'package:takenow/widgets/message_card.dart';
import '../models/message.dart' as message_model; // Sử dụng alias cho message.dart

import '../api/apis.dart';
import '../main.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget{
  final ChatUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>{
  List<message_model.Message> _list = [];

  //for handling message text changes
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context){
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: _appBar(),
        ),

        backgroundColor: const Color.fromARGB(255, 234, 248, 255),

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
                      _list = data?.map((e) => Message.fromJson(e.data())).toList() ?? [];

                      if (_list.isNotEmpty) {
                        return ListView.builder(
                            itemCount: _list.length,
                            padding: EdgeInsets.only(top: mq.height * .01),
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              return MessageCard(message: _list[index]);
                            });
                      } else {
                        return const Center(
                          child: Text('Say Hii! 👋',
                              style: TextStyle(fontSize: 20)),
                        );
                      }
                  }
                },
              ),
            ),

            _chatInput()],
        ),
      ),
    );
  }

  //app bar widget
  Widget _appBar(){
    return InkWell(
      onTap: () {},
      child: Row(
        children: [
          //black button
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.black54)),
      
        ClipRRect(
          borderRadius: BorderRadius.circular(mq.height * .03),
          child: CachedNetworkImage(
            width: mq.height * .05,
            height: mq.height * .05,
            imageUrl: widget.user.image,
            //placeholder: (context, url) => CircularProgressIndicator(),
            errorWidget: (context, url, error) =>
            const CircleAvatar(child: Icon(CupertinoIcons.person)),
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
                  color: Colors.black87,
                  fontWeight: FontWeight.w500)),
      
            //for adding some space
            const SizedBox(height: 2),
      
            const Text('Last seen not available',
                style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500)),
        ],
        )
      ],),
    );
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
                shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  //emoji button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.emoji_emotions, color: Colors.blueAccent, size: 25)),

                  Expanded(
                      child: TextField(
                        controller: _textController,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        decoration: const InputDecoration(
                        hintText: 'Type Something...',
                        hintStyle: TextStyle(color: Colors.blueAccent),
                        border: InputBorder.none),
                  )),

                  //pick image from gallery button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.image, color: Colors.blueAccent, size: 26)),

                  //take image from camera button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
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
              onPressed: (){
                if(_textController.text.isNotEmpty){
                  APIs.sendMessage(widget.user, _textController.text);
                  _textController.text = '';
                }
              },
              minWidth: 0,
              padding:
                const EdgeInsets.only(top: 10, bottom: 10, right: 5, left: 10),
              shape: CircleBorder(),
              color: Colors.green,
              child: Icon(Icons.send, color: Colors.white, size: 28),)
        ],
      ),
    );
  }
}

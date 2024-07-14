import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:takenow/api/apis.dart';
import 'package:takenow/helper/my_date_util.dart';
import 'package:takenow/models/chat_user.dart';
import 'package:takenow/models/message.dart';

import '../screens/chat_screen.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;
  const ChatUserCard({Key? key, required this.user}) : super(key: key);

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  // Last message info (if null --> no message)
  Message? _message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04, vertical: 4),
      color: Color(0xFF2F2E2E),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(user: widget.user)));
        },
        child: StreamBuilder(
          stream: APIs.getLastMessage(widget.user),
          builder: (context, snapshot) {
            final data = snapshot.data?.docs;
            final list = data?.map((e) => Message.fromJson(e.data())).toList() ?? [];
            if (list.isNotEmpty) _message = list[0];

            // Determine if the message is bold based on read status and sender
            bool isBold = _message != null && (_message!.read.isEmpty && _message!.fromId != APIs.user.uid);

            return ListTile(
              contentPadding: EdgeInsets.zero, // Remove default ListTile padding

              // User profile picture
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(MediaQuery.of(context).size.height * 0.03),
                child: CachedNetworkImage(
                  width: MediaQuery.of(context).size.height * 0.065,
                  height: MediaQuery.of(context).size.height * 0.065,
                  imageUrl: widget.user.image,
                  errorWidget: (context, url, error) => const CircleAvatar(child: Icon(CupertinoIcons.person)),
                ),
              ),

              // User name
              title: Text(
                widget.user.name,
                style: TextStyle(
                  color: isBold ? Colors.white : Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),

              // Last message
              subtitle: Text(
                _message != null ? (_message!.fromId == APIs.user.uid ? 'You: ' : '') + (_message!.type == MessageType.image ? 'image' : _message!.msg) : widget.user.about,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isBold ? Colors.white : Colors.white.withOpacity(0.7),
                  fontSize: 15,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal, // Apply bold font weight conditionally
                ),
              ),

              // Last message time or unread indicator
              trailing: _message == null
                  ? null // Show nothing when no message is sent
                  : _message!.read.isEmpty && _message!.fromId != APIs.user.uid
                  ? Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: Colors.greenAccent.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              )
                  : Text(
                MyDateUtil.getLastMessageTime(context: context, time: _message!.sent),
                style: TextStyle(color: Colors.white),
              ),
            );
          },
        ),
      ),
    );
  }
}

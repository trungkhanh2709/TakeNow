import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:takenow/api/apis.dart';
import 'package:takenow/helper/my_date_util.dart';
import 'package:takenow/models/message.dart';
import 'dart:developer';

import '../main.dart';

class MessageCard extends StatefulWidget {
  const MessageCard({Key? key, required this.message}) : super(key: key);

  final Message message;

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {
    return APIs.user.uid == widget.message.fromId
        ? _greenMessage()
        : _blueMessage();
  }

  //sender or another user message
  Widget _blueMessage(){
    //update last read message if sender and receive are different
    if(widget.message.read.isEmpty){
      APIs.updateMessageReadStatus(widget.message);
      log('message read update');
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        //message content
        Flexible(
          child: Container(
            padding: EdgeInsets.all(widget.message.type == MessageType.image
                ? mq.width * .03
                : mq.width * .04),
            margin: EdgeInsets.symmetric(
              horizontal: mq.width * .04, vertical: mq.height * .01
            ),
            decoration: BoxDecoration(
                color: const Color.fromARGB(255, 221, 245, 255),
                border: Border.all(color: Colors.lightBlue),
                //making borders curved
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  bottomRight: Radius.circular(30))),
            child: widget.message.type == MessageType.text ?
            Text(
                widget.message.msg,
                style: TextStyle(fontSize: 15, color: Colors.black87),
            )
            //show image
                : ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                  imageUrl: widget.message.msg,
                  placeholder: (context, url) =>
                  const Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.image, size: 70)
              ),
            ),
            ),
          ),

        //message time
        Padding(
          padding: EdgeInsets.only(right: mq.width * .04),
          child: Text(
            MyDateUtil.getFormattedTime(
                context: context, time: widget.message.sent),
              style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  //our or user message
  Widget _greenMessage(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        //message time
        Row(
          children: [
            //for adding some space
            SizedBox(width: mq.width * .04),

            //double tick blue icon for message read
             if(widget.message.read.isNotEmpty)
                const Icon(Icons.done_all_rounded, color: Colors.blue, size: 20),

            //for adding some space
            SizedBox(width: 2),

            //sent time
            Text(
              MyDateUtil.getFormattedTime(
                  context: context, time: widget.message.sent),
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),

        //message content
        Flexible(
          child: Container(
            padding: EdgeInsets.all(widget.message.type == MessageType.image
                ? mq.width * .03
                : mq.width * .04),
            margin: EdgeInsets.symmetric(
                horizontal: mq.width * .04, vertical: mq.height * .01
            ),
            decoration: BoxDecoration(
                color: const Color.fromARGB(255, 218, 255, 176),
                border: Border.all(color: Colors.lightGreen),
                //making borders curved
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30))),
            child: widget.message.type == MessageType.text ?
              Text(
              widget.message.msg,
              style: TextStyle(fontSize: 15, color: Colors.black87),
              )
              //show image
              : ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                imageUrl: widget.message.msg,
                placeholder: (context, url) =>
                    const Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                errorWidget: (context, url, error) => const Icon(Icons.image, size: 70)
                ),
            ),
          ),
        ),
      ],
    );
  }
}

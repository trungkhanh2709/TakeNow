import 'package:flutter/material.dart';
import 'package:takenow/api/apis.dart';
import 'package:takenow/models/message.dart';

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        //message content
        Flexible(
          child: Container(
            padding: EdgeInsets.all(mq.width * .04),
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
            child: Text(
                widget.message.msg,
                style: TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ),

        //message time
        Padding(
          padding: EdgeInsets.only(right: mq.width * .04),
          child: Text(
              widget.message.sent,
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
            const Icon(Icons.done_all_rounded, color: Colors.blue, size: 20),

            //for adding some space
            SizedBox(width: 2),

            //read time
            Text(
              '${widget.message.read}12:00 AM',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),

        //message content
        Flexible(
          child: Container(
            padding: EdgeInsets.all(mq.width * .04),
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
            child: Text(
              widget.message.msg,
              style: TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }
}

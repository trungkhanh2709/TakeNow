import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:takenow/api/apis.dart';
import 'package:takenow/helper/my_date_util.dart';
import 'package:takenow/models/message.dart';
import 'dart:developer';

import '../helper/dialogs.dart';
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
    bool isMe = APIs.user.uid == widget.message.fromId;
    return InkWell(
      onLongPress: (){
        _showBottomSheet(isMe);
      },
      child: isMe ? _greenMessage() : _blueMessage());
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
            style: const TextStyle(fontSize: 13, color: Colors.white),
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
              const Icon(Icons.done_all_rounded, color: Colors.lightBlueAccent, size: 20),

            //for adding some space
            SizedBox(width: 2),

            //sent time
            Text(
              MyDateUtil.getFormattedTime(
                  context: context, time: widget.message.sent),
              style: const TextStyle(fontSize: 13, color: Colors.white),
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

  void _showBottomSheet(bool isMe) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          children: [

            Container(
              height: 4,
              margin: EdgeInsets.symmetric(vertical: mq.height * 0.015, horizontal: mq.width * .4),
              decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(8)),
            ),

            widget.message.type == MessageType.text
              ?
              //copy option
              _OptionItem(
                  icon: const Icon(Icons.copy_all_rounded,
                      color: Colors.blue, size: 26),
                  name: 'Copy Text',
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: widget.message.msg)).then((value) {
                      //for hiding bottom sheet
                      Navigator.pop(context);

                      Dialogs.showSnackbar(context, 'Text Copied!');
                    });
                  })
              ://copy option
              _OptionItem(
                  icon: const Icon(Icons.download_rounded,
                      color: Colors.blue, size: 26),
                  name: 'Save Image',
                  onTap: () async {
                    try{
                      log('Image Url: ${widget.message.msg}');
                      await GallerySaver.saveImage(widget.message.msg, albumName: 'Take Now')
                          .then((success) {
                        Navigator.pop(context);
                        if(success != null && success) {
                          Dialogs.showSnackbar(context, 'Image Successfully Save!');
                        }
                      });
                    }
                    catch(e){
                      log('ErrorWhileSavingImg: $e');
                    }
                  }),

            if(isMe)
              Divider(
                color: Colors.black54,
                endIndent: mq.width * .04,
                indent: mq.width * .04,
              ),

            if(widget.message.type == MessageType.text && isMe)
              //edit option
              _OptionItem(
                  icon: const Icon(Icons.edit,
                      color: Colors.blue, size: 26),
                  name: 'Edit Message',
                  onTap: () {
                    //for hiding bottom sheet
                    Navigator.pop(context);
                    
                    _showMessageUpdateDialog();
                  }),

            //delete option
            if(isMe)
              _OptionItem(
                  icon: const Icon(Icons.delete_forever,
                      color: Colors.red, size: 26),
                  name: 'Delete Message',
                  onTap: () async {
                    await APIs.deleteMessage(widget.message).then((value) {
                      //for hiding bottom sheet
                      Navigator.pop(context);
                    });
                  }),

            Divider(
              color: Colors.black54,
              endIndent: mq.width * .04,
              indent: mq.width * .04,
            ),

            //sent time
            _OptionItem(
                icon: const Icon(Icons.remove_red_eye,
                    color: Colors.blue),
                name: 'Sent At: ${MyDateUtil.getMessageTime(context: context, time: widget.message.sent)}',
                onTap: () {}),

            //reading time
            _OptionItem(
                icon: const Icon(Icons.remove_red_eye,
                    color: Colors.green),
                name: widget.message.read.isEmpty
                  ? 'Read At: Not seen yet'
                  : 'Read At: ${MyDateUtil.getMessageTime(context: context, time: widget.message.read)}',
                onTap: () {}),
          ],
        );
      },
    );
  }

  void _showMessageUpdateDialog() {
    String updateMsg = widget.message.msg;
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          contentPadding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(
                Icons.message,
                color: Colors.blue,
                size: 28,
              ),
              Text(' Update Message')
            ],
          ),

          //content
          content: TextFormField(
            initialValue: updateMsg,
            maxLines: null,
            onChanged: (value) => updateMsg = value,
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
          ),

          //action
          actions: [
            MaterialButton(
                onPressed: () {
                  //hide alert dialog
                  Navigator.pop(context);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                )),

            MaterialButton(
                onPressed: () {
                  //hide alert dialog
                  Navigator.pop(context);
                  APIs.updateMessage(widget.message, updateMsg);
                },
                child: const Text(
                  'Update',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                ))
          ],
        ));
  }
}

class _OptionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  final VoidCallback onTap;

  const _OptionItem({required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () => onTap(),
        child: Padding(
          padding: EdgeInsets.only(
              left: mq.width * .05,
              top: mq.height * .015,
              bottom: mq.height * .015),
          child: Row(children: [
            icon,
            Flexible(
                child: Text('      $name',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      letterSpacing: 0.5)))
          ]),
        ));
  }
}


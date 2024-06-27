import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:takenow/models/chat_user.dart';

import '../models/chat_user.dart';
import '../models/post_user.dart';

class APIs {
  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static FirebaseStorage storage = FirebaseStorage.instance;


  static User get user => auth.currentUser!;

  //check user exists or not
  static Future<bool> userExists() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  static String getConversationID(String id) =>
      user.uid.hashCode <= id.hashCode
          ? '${user.uid}_$id'
          : '${id}_${user.uid}';

  //creating a new user
  static Future<void> createUser() async {
    final time = DateTime.now().microsecondsSinceEpoch.toString();
    final chatUser = ChatUser(
      name: user.displayName.toString(),
      id: user.uid,
      image: user.photoURL.toString(),
      about: "Hey, welcome to TakeNow!!!",
      createdAt: time,
      isOnline: false,
      lastActive: time,
      email: user.email.toString(),
      pushToken: '',
    );

    return await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatUser.toJson());
  }
  static Future<void> postPhoto(
       String caption, String imageUrl, Type type) async {
    //message sending time (also used as id)
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    //message to send
    final PostUser post = PostUser(
        caption: caption,
        imageUrl: imageUrl,
        timestamp: time,
        userId: user.uid,
        type: type
    );


    final ref = firestore
        .collection('posts')
        .doc(getConversationID(user.uid))
        .collection('post_image')
        .doc(time);
    await ref.set(post.toJson());
  }
//ham uppic
  static Future<void> upLoadPhoto(String caption,String userId,File file) async {
    final ext = file.path.split('.').last;
    final ref = storage.ref().child('images/${getConversationID(userId)}/${DateTime.now().millisecondsSinceEpoch}.$ext');
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {

    });

    //updating image in firestore database
    final imageUrl = await ref.getDownloadURL();
    await postPhoto(caption, imageUrl, Type.image);
  }
}

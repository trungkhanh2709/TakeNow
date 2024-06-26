import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:takenow/models/chat_user.dart';

class APIs {
  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static FirebaseStorage storage = FirebaseStorage.instance;
  static late ChatUser me;
  static User get user => auth.currentUser!;

  //check user exists or not
  static Future<bool> userExists() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  //getting current usser info
  static Future<void> getSelfInfo() async {
    await firestore
        .collection('users')
        .doc(user.uid)
        .get()
        .then((user) {
          if(user.exists){
            me = ChatUser.fromJson(user.data()!);
          } else{
            createUser().then((value) => getSelfInfo());
          }
    });
  }

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
        .set(chatUser.toJson())
        .then((value) {
          me = chatUser;
        });
  }

  // for getting all user from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(){
    return firestore
        .collection('users')
        .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  //for updating user information
  static Future<void> updateUserInfo() async {
    if(me == null){
      await getSelfInfo().then((_) {
        firestore.collection('users').doc(user.uid).update({
          'name' : me.name,
          'about' : me.about,
      });
    });
  } else {
      firestore.collection('users').doc(user.uid).update({
        'name': me.name,
        'about': me.about,
      });
    }
  }

  //update profile picture of user
  // Update profile picture of user
  static Future<void> updateProfilePicture(File file) async {
    try {
      // Kiểm tra nếu 'me' chưa được khởi tạo, thực hiện tải thông tin người dùng
      if (me == null) {
        await getSelfInfo().then((_) {
          // Sau khi 'me' đã được khởi tạo, tiến hành cập nhật ảnh đại diện
          _updateProfilePicture(file);
        });
      } else {
        // Nếu 'me' đã được khởi tạo trước đó, tiếp tục cập nhật ảnh đại diện
        _updateProfilePicture(file);
      }
    } catch (e) {
      print('Error updating profile picture: $e');
      throw e;
    }
  }

// Phương thức thực hiện cập nhật ảnh đại diện nội bộ
  static Future<void> _updateProfilePicture(File file) async {
    final ext = file.path.split('.').last;
    log('Extension: $ext');

    // Upload image to Firebase Storage
    final ref = storage.ref().child('profile_pictures/${user.uid}.$ext');
    await ref.putFile(file, SettableMetadata(contentType: 'image/$ext'));

    // Get download URL of the uploaded image
    final downloadURL = await ref.getDownloadURL();

    // Update image URL in Firestore
    await firestore
        .collection('users')
        .doc(user.uid)
        .update({'image': downloadURL});

    // Update local information
    me.image = downloadURL;

    log('Profile picture updated successfully');
  }
}

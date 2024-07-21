import 'dart:io';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart';
import 'package:takenow/models/chat_user.dart';

import 'package:takenow/models/message.dart';

import '../models/post_user.dart';

class APIs {
  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static FirebaseStorage storage = FirebaseStorage.instance;

  static late ChatUser me;

  static User get user => auth.currentUser!;

  //for accessing firebase messaging (Push Notification)
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  //for getting firebase messaging token
  static Future<void> getFirebaseMessagingToken() async {
    await fMessaging.requestPermission();

    await fMessaging.getToken().then((t) {
      if(t != null){
        me.pushToken = t;
        log('Push Token: $t');
      }
    });
  }

  // static Future<void> sendPushNotification() async {
  //   final body = {
  //     "to"
  //   };
  //   var response = await post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
  //       body: );
  //   log('Response status: ${response.statusCode}');
  //   log('Response body: ${response.body}');
  // }

  //check user exists or not
  static Future<bool> userExists() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  static String getConversationID(String id) =>
      user.uid.hashCode <= id.hashCode
          ? '${user.uid}_$id'
          : '${id}_${user.uid}';

  //getting current usser info
  static Future<void> getSelfInfo() async {
    await firestore
        .collection('users')
        .doc(user.uid)
        .get()
        .then((user) async {
      if(user.exists){
        me = ChatUser.fromJson(user.data()!);
        await getFirebaseMessagingToken();
        APIs.updateActiveStatus(true);
        log('My Data: ${user.data()}');
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
      friends: [],
      friendRequests: [],
    );

    return await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatUser.toJson());
  }

  // for getting all user from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(){
    return firestore
        .collection('users')
        .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  static Future<void> postPhoto(
      String caption, String imageUrl, PostType type, Set<String> selectedFriends, String idpost) async {
    // Post sending time (also used as ID)
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    // Post to send
    final PostUser post = PostUser(
        caption: caption,
        imageUrl: imageUrl,
        timestamp: time,
        userId: user.uid,
        type: type,
        visibleTo: selectedFriends.toList(),
      idpost: idpost,
      // Add selected friends here
    );

    final ref = firestore
        .collection('posts')
        .doc(getConversationID(user.uid))
        .collection('post_image')
        .doc(time);
    await ref.set(post.toJson());
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

  static Future<void> upLoadPhoto(String caption, String userId, File file, Set<String> selectedFriends, String idpost) async {
    final ext = file.path.split('.').last;
    final ref = storage.ref().child('images/${getConversationID(userId)}/${DateTime.now().millisecondsSinceEpoch}.$ext');
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      // Image uploaded
    });

    // Get image URL
    final imageUrl = await ref.getDownloadURL();
    await postPhoto(caption, imageUrl, PostType.image, selectedFriends,idpost);
  }


  //for getting specific user info
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(ChatUser chatUser) {
    return firestore
        .collection('users')
        .where('id', isNotEqualTo: chatUser.id)
        .snapshots();
  }

  //update online or last active status of user
  static Future<void> updateActiveStatus(bool isOnline) async{
    firestore.collection('users').doc(user.uid).update({
      'is_online' : isOnline,
      'last_active' : DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token' : me.pushToken,
    });
  }

  ///******************* Chat Screen Related APIs *******************///

  // for getting all message of a specific conversation from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMesage(
      ChatUser user){
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .snapshots();
  }

  //for sending message
  static Future<void> sendMessage(ChatUser chatUser, String msg, MessageType type) async {
    //message sending time (also used as id)
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    //message to send
    final Message message = Message(
        msg: msg,
        read: '',
        told: chatUser.id,
        type: type,
        sent: time,
        fromId: user.uid);
    
     final ref = firestore.collection('chats/${getConversationID(chatUser.id)}/messages/');
     await ref.doc(time).set(message.toJson());
  }

  //update read status of message
  static Future<void> updateMessageReadStatus(Message message) async{
    firestore
        .collection('chats/${getConversationID(message.fromId)}/messages/')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  //get only last message of a specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(ChatUser user){
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  //send chat image
  static Future<void> sendChatImage(ChatUser chatUser, File file) async{
    //gettng image file extension
    final ext = file.path.split('.').last;

    //storage file ref with path
    final ref = storage.ref().child(
        'images/${getConversationID(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');

    //uploading image
    await ref
      .putFile(file, SettableMetadata(contentType: 'image/$ext'))
      .then((pO) {
        log('Data Transferred: ${pO.bytesTransferred / 1000} kb');
    });

    //updating image in firestore database
    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, MessageType.image);
  }

  //Phương thức để thêm bạn bè
  static Future<bool> addFriend(String friendId) async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) return false;

      final userDoc = firestore.collection('users').doc(currentUser.uid);
      final friendDoc = firestore.collection('users').doc(friendId);

      // Kiểm tra xem người dùng có tồn tại không
      final friendSnapshot = await friendDoc.get();
      if (!friendSnapshot.exists) return false;

      // Gửi yêu cầu kết bạn
      await friendDoc.update({
        'friend_requests': FieldValue.arrayUnion([currentUser.uid])
      });

      return true;
      }catch(e){
      print('Error adding friend request: $e');
      return false;
    }
  }

  static Future<bool> respondToFriendRequest(String friendId, bool accept) async {
    try{
      final currentUser = auth.currentUser;
      if(currentUser == null) return false;

      final currentUserDoc = firestore.collection('users').doc(currentUser.uid);
      final friendUserDoc = firestore.collection('users').doc(friendId);

      final currentUserData = await currentUserDoc.get();
      final friendUserData = await friendUserDoc.get();

      if(accept){
        // Thêm bạn bè vào danh sách bạn bè của người dùng hiện tại
        await currentUserDoc.update({
          'friends': FieldValue.arrayUnion([friendId])
        });

        // Thêm người dùng hiện tại vào danh sách bạn bè của bạn
        await friendUserDoc.update({
          'friends': FieldValue.arrayUnion([currentUser.uid])
        });
      }

      // Xóa yêu cầu kết bạn
      await currentUserDoc.update({
        'friend_requests': FieldValue.arrayRemove([friendId])
      });

      return true;
    } catch (e){
      print('Error responding to friend request: $e');
      return false;
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getFriends() {
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('friends')
        .snapshots();
  }

  // Lấy các bài viết từ các bạn bè
  static Stream<QuerySnapshot<Map<String, dynamic>>> getFriendPosts() {
    return firestore
        .collection('posts')
        .where('userId', whereIn: me.friends) // Chỉ lấy các bài viết từ friends
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Future<bool> removeFriendRequest(String friendId) async {
    try {
      // Assume we have a collection 'friendRequests' storing friend requests
      String currentUserId = user.uid;
      await FirebaseFirestore.instance
          .collection('friendRequests')
          .doc(currentUserId)
          .collection('requests')
          .doc(friendId)
          .delete();
      return true;
    } catch (e) {
      print('Error removing friend request: $e');
      return false;
    }
  }

  //delete message
  static Future<void> deleteMessage(Message message) async {
    await firestore
        .collection('chats/${getConversationID(message.told)}/messages/')
        .doc(message.sent)
        .delete();
    if(message.type == MessageType.image){
      await storage.refFromURL(message.msg).delete();
    }
  }

  //update message
  static Future<void> updateMessage(Message message, String updateMsg) async {
    await firestore
        .collection('chats/${getConversationID(message.told)}/messages/')
        .doc(message.sent)
        .update({'msg': updateMsg});
  }
}

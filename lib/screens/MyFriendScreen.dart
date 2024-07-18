import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takenow/models/chat_user.dart';
import 'package:takenow/api/apis.dart';

class MyFriendScreen extends StatefulWidget {
  const MyFriendScreen({Key? key}) : super(key: key);

  @override
  _MyFriendScreenState createState() => _MyFriendScreenState();
}

class _MyFriendScreenState extends State<MyFriendScreen> {
  List<ChatUser> _list = [];

  @override
  void initState() {
    super.initState();
    _getFriends();
  }

  // Hàm lấy danh sách bạn bè từ Firestore
  Future<void> _getFriends() async {
    try {
      final currentUser = APIs.auth.currentUser;
      if (currentUser == null) return;

      final userDoc = await APIs.firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>?; // Dữ liệu người dùng
      final friendIds = userData?['friends'] is List
          ? List<String>.from(userData?['friends'] ?? [])
          : [];

      final friendDocs = await Future.wait(friendIds.map((id) => APIs.firestore.collection('users').doc(id).get()));
      _list = friendDocs.map((doc) => ChatUser.fromJson(doc.data()!)).toList();

      setState(() {}); // Cập nhật lại UI sau khi có dữ liệu
    } catch (e) {
      print('Error getting friends: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2F2E2E), // Màu nền cho Scaffold và AppBar
      appBar: AppBar(
        backgroundColor: Color(0xFF2F2E2E), // Màu nền cho AppBar
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/Refund_back_light.svg',
            width: 30,
            height: 30,
          ),
          onPressed: () {
            Navigator.pop(context); // Quay về màn hình trước đó (homescreen)
          },
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: APIs.firestore.collection('users').doc(APIs.auth.currentUser?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final userDoc = snapshot.data!;
          final userData = userDoc.data() as Map<String, dynamic>?; // Dữ liệu người dùng
          final friends = userData?['friends'] is List
              ? List<String>.from(userData?['friends'] ?? [])
              : [];

          if (friends.isEmpty) {
            return Center(
              child: Text('No Connection Found!', style: TextStyle(fontSize: 20, color: Colors.white)),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
            physics: BouncingScrollPhysics(),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friendId = friends[index];

              return FutureBuilder<DocumentSnapshot>(
                future: APIs.firestore.collection('users').doc(friendId).get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return ListTile(
                      title: Text('Loading...', style: TextStyle(color: Colors.white)),
                    );
                  }

                  final friend = snapshot.data!;
                  final chatUser = ChatUser.fromJson(friend.data() as Map<String, dynamic>);
                  return _buildFriendItem(chatUser);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFriendItem(ChatUser chatUser) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
      leading: CircleAvatar(
        backgroundImage: NetworkImage(chatUser.image ?? ''),
      ),
      title: Text(
        chatUser.name ?? '',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        chatUser.email ?? '',
        style: TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      trailing: GestureDetector(
        onTap: () {
          _confirmDeleteFriend(chatUser); // Hiển thị popup xác nhận xóa bạn bè
        },
        child: SvgPicture.asset(
          'assets/icons/Delete.svg', // Đường dẫn tới biểu tượng X SVG
          width: 16,
          height: 14,
          color: Colors.white, // Màu trắng cho biểu tượng X
        ),
      ),
    );
  }

  void _confirmDeleteFriend(ChatUser chatUser) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm'),
          content: Text('Are you sure you want to delete ${chatUser.name} from your friends list?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteFriend(chatUser);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFriend(ChatUser chatUser) async {
    try {
      final currentUser = APIs.auth.currentUser;
      if (currentUser == null) return;

      final userDoc = await APIs.firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>?; // Dữ liệu người dùng
      final List<String> friends = List<String>.from(userData?['friends'] ?? []);

      // Xóa ID của bạn bè khỏi danh sách người dùng hiện tại
      friends.remove(chatUser.id);

      // Cập nhật lại Firestore cho người dùng hiện tại
      await APIs.firestore.collection('users').doc(currentUser.uid).update({'friends': friends});

      // Cập nhật danh sách _list và giao diện
      setState(() {
        _list.removeWhere((user) => user.id == chatUser.id);
      });

      // Cập nhật danh sách bạn bè của người bị xóa
      final friendDoc = await APIs.firestore.collection('users').doc(chatUser.id).get();
      final friendData = friendDoc.data() as Map<String, dynamic>?; // Dữ liệu bạn bè
      final List<String> friendFriends = List<String>.from(friendData?['friends'] ?? []);

      // Xóa ID của người dùng hiện tại khỏi danh sách bạn bè của người bị xóa
      friendFriends.remove(currentUser.uid);

      // Cập nhật lại Firestore cho người bị xóa
      await APIs.firestore.collection('users').doc(chatUser.id).update({'friends': friendFriends});

    } catch (e) {
      print('Error deleting friend: $e');
    }
  }
}

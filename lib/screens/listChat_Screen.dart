import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takenow/api/apis.dart';
import 'package:takenow/models/chat_user.dart';
import 'package:takenow/widgets/chat_user_card.dart';

class ListChatScreen extends StatefulWidget {
  const ListChatScreen({super.key});

  @override
  State<ListChatScreen> createState() => _ListChatScreenState();
}

class _ListChatScreenState extends State<ListChatScreen> {
  List<ChatUser> _list = [];
  final List<ChatUser> _searchList = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _getFriends();
  }

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () {
          if (_isSearching) {
            setState(() {
              _isSearching = false;
            });
            return Future.value(false); // Không đóng màn hình khi đang tìm kiếm
          } else {
            return Future.value(true); // Đóng màn hình khi không tìm kiếm
          }
        },
        child: Scaffold(
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
            title: _isSearching
                ? TextField(
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Name, Email,...',
                hintStyle: TextStyle(color: Colors.white),
              ),
              autofocus: true,
              style: const TextStyle(fontSize: 17, letterSpacing: 0.5, color: Colors.white),
              onChanged: (val) {
                _searchList.clear();
                for (var i in _list) {
                  if (i.name.toLowerCase().contains(val.toLowerCase()) ||
                      i.email.toLowerCase().contains(val.toLowerCase())) {
                    _searchList.add(i);
                  }
                }
                setState(() {}); // Cập nhật lại UI khi có thay đổi trong danh sách tìm kiếm
              },
            )
                : const Text(
              '',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.clear : Icons.search,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching; // Đảo ngược trạng thái tìm kiếm
                    if (!_isSearching) {
                      _searchList.clear(); // Xóa danh sách tìm kiếm khi thoát khỏi trạng thái tìm kiếm
                    }
                  });
                },
              ),
            ],
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
                itemCount: _isSearching ? _searchList.length : _list.length,
                padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final friendId = friends[index];

                  return FutureBuilder<DocumentSnapshot>(
                    future: APIs.firestore.collection('users').doc(friendId).get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return ListTile(
                          title: Text('Đang tải...', style: TextStyle(color: Colors.white)),
                        );
                      }

                      final friend = snapshot.data!;
                      final chatUser = ChatUser.fromJson(friend.data() as Map<String, dynamic>);
                      return ChatUserCard(user: chatUser);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
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
}

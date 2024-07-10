import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:takenow/api/apis.dart';
import 'package:takenow/helper/dialogs.dart';

class FriendRequestsScreen extends StatefulWidget{
  const FriendRequestsScreen({Key? key}) : super(key: key);

  @override
  _FriendRequestsScreenState createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = APIs.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu cầu kết bạn'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: APIs.firestore.collection('users').doc(currentUser?.uid).snapshots(),
        builder: (context, snapshot) {
          if(!snapshot.hasData){
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data!;
          final friendRequest = List<String>.from(user['friend_requests'] ?? []);

          return ListView.builder(
              itemCount: friendRequest.length,
              itemBuilder: (context, index){
                final friendId = friendRequest[index];

                return FutureBuilder<DocumentSnapshot>(
                  future: APIs.firestore.collection('users').doc(friendId).get(),
                  builder: (context, snapshot){
                    if(!snapshot.hasData){
                      return const ListTile(
                        title: Text('Đang tải...'),
                      );
                    }

                    final friend = snapshot.data!;
                    return ListTile(
                      title: Text(friend['name']),
                      subtitle: Text(friend['email']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                              onPressed: () => _respondToRequest(friendId, true),
                              child: const Text('Chấp nhận'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                              onPressed: () => _respondToRequest(friendId, false),
                              child: const Text('Từ chối'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
          );
        },
      ),
    );
  }

  void _respondToRequest(String friendId, bool accept){
    APIs.respondToFriendRequest(friendId, accept).then((success) {
      if(success){
        Dialogs.showSnackbar(context, accept ? 'Đã chấp nhận lời mời kết bạn,' : 'Đã từ chối lời mời kết bạn.');
  } else{
        Dialogs.showSnackbar(context, 'Đã xảy ra lỗi khi phản hồi yêu cầu kết bạn.');
  }
  }).catchError((error) {
    Dialogs.showSnackbar(context, 'Lỗi: $error');
  });
  }
}


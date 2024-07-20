import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      backgroundColor: Color(0xFF2F2E2E),
      appBar: AppBar(
        title: const Text('Friend Request'),
        backgroundColor: Color(0xFF2F2E2E),
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
                        title: Text('Loading...'),
                      );
                    }

                    final friend = snapshot.data!;
                    return ListTile(
                      title: Text(friend['name'], style: TextStyle(color: Colors.white),),
                      subtitle: Text(friend['email'], style: TextStyle(color: Colors.white),),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                              onPressed: () => _respondToRequest(friendId, true),
                              child: const Text('Accept'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                              onPressed: () => _respondToRequest(friendId, false),
                              child: const Text('Reject'),
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
        Dialogs.showSnackbar(context, accept ? 'has accepted the friend request' : 'declined the friend request.');
  } else{
        Dialogs.showSnackbar(context, 'An error occurred while responding to the friend request.');
  }
  }).catchError((error) {
    Dialogs.showSnackbar(context, 'Error: $error');
  });
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:takenow/api/apis.dart';
import 'package:takenow/helper/dialogs.dart';

class FriendSearchScreen extends StatefulWidget{
  const FriendSearchScreen({Key? key}) : super(key: key);

  _FriendSearchScreenState createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen>{
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];

  void _searchFriends (String query) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .get();

    setState(() {
      _searchResults = result.docs;
    });
  }

  void _sendFriendRequest(String friendId) {
    APIs.addFriend(friendId).then((success) {
      if(success) {
        Dialogs.showSnackbar(context, 'Send friend request successfully!');
      } else {
        Dialogs.showSnackbar(context, 'Sending friend request failed.');
      }
    }).catchError((error) {
      Dialogs.showSnackbar(context, 'Lỗi: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find your friend'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Enter the name, email or ID',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _searchFriends(_searchController.text),
                )
              ),
            ),

            Expanded(
                child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index){
                      final user = _searchResults[index];
                      return ListTile(
                        title: Text(user['name']),
                        subtitle: Text(user['email']),
                        trailing: ElevatedButton(
                          onPressed: () => _sendFriendRequest(user.id),
                          child: const Text('Send Request'),
                        ),
                      );
                    },
                ),
            ),
          ],
        ),
      ),
    );
  }
}
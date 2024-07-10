import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:takenow/api/apis.dart';
import 'package:takenow/main.dart';
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
    // APIs.getSelfInfo();
    _getFriends();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //for hidding keyboard when a tap is detected on screen
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        //if search is on & back button is pressed then close search
        //or else simple close current screen on back button click
        onWillPop: () {
          if (_isSearching) {
            setState(() {
              _isSearching = !_isSearching;
            });
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            leading: const Icon(CupertinoIcons.home),
            title: _isSearching
                ? TextField(
                    decoration: const InputDecoration(
                        border: InputBorder.none, hintText: 'Name, Email,...'),
                    autofocus: true,
                    style: const TextStyle(fontSize: 17, letterSpacing: 0.5),
                    //when search text changes then updated search list
                    onChanged: (val) {
                      //search logic
                      _searchList.clear();

                      for (var i in _list) {
                        if (i.name.toLowerCase().contains(val.toLowerCase()) ||
                            i.email.toLowerCase().contains(val.toLowerCase())) {
                          _searchList.add(i);
                        }
                        setState(() {
                          _searchList;
                        });
                      }
                    },
                  )
                : const Text('TakeNow2'),
            actions: [
              //search user button
              IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                    });
                  },
                  icon: Icon(_isSearching
                      ? CupertinoIcons.clear_circled_solid
                      : Icons.search)
              ),
            ],
          ),

          //floating button to add new user
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FloatingActionButton(
                onPressed: () async {
                  await APIs.auth.signOut();
                  await GoogleSignIn().signOut();
                },
                child: const Icon(Icons.add_comment_rounded)),
          ),

          body: StreamBuilder<DocumentSnapshot>(
            stream: APIs.firestore.collection('users').doc(APIs.auth.currentUser?.uid).snapshots(),
            builder: (context, snapshot){
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userDoc = snapshot.data!;
            final userData = userDoc.data() as Map<String, dynamic>?; // Chuyển đổi kiểu dữ liệu
            final friends = userData?['friends'] is List
                ? List<String>.from(userData?['friends'] ?? [])
                : [];

            if (friends.isEmpty) {
            return const Center(
            child: Text('No Connection Found!', style: TextStyle(fontSize: 20)),
            );
            }
            return ListView.builder(
            itemCount: _isSearching ? _searchList.length : _list.length,
            padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * .01),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
            final friendId = friends[index];

            return FutureBuilder<DocumentSnapshot>(
            future: APIs.firestore.collection('users').doc(friendId).get(),
            builder: (context, snapshot) {
            if (!snapshot.hasData) {
            return const ListTile(
            title: Text('Đang tải...'),
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


  Future<void> _getFriends() async {
    try {
      final currentUser = APIs.auth.currentUser;
      if (currentUser == null) return;

      final userDoc = await APIs.firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>?; // Chuyển đổi kiểu dữ liệu
      final friendIds = userData?['friends'] is List
          ? List<String>.from(userData?['friends'] ?? [])
          : [];

      final friendDocs = await Future.wait(friendIds.map((id) => APIs.firestore.collection('users').doc(id).get()));
      _list = friendDocs.map((doc) => ChatUser.fromJson(doc.data()!)).toList();

      setState(() {});
    } catch (e) {
      print('Error getting friends: $e');
    }
  }
}

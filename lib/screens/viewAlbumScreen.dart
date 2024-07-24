import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rxdart/rxdart.dart';
import 'package:takenow/Class/Globals.dart';
import 'package:takenow/screens/viewPhotoFromAlbum.dart';
import 'package:takenow/widgets/album_user_cart.dart';

class ViewAlbumScreen extends StatefulWidget {
  const ViewAlbumScreen({Key? key}) : super(key: key);

  @override
  State<ViewAlbumScreen> createState() => _ViewAlbumScreenState();
}

class _ViewAlbumScreenState extends State<ViewAlbumScreen> {
  String? userLogin = Globals.getGoogleUserId();
  User? currentUser;
  List<String> _selectedFriendIds = [];
  String selectedFriendName = 'All Friends';

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser; // Get the current user
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F2E2E),
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/Refund_back_light.svg',
            width: 30,
            height: 30,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Center(
          child: GestureDetector(
            onTap: () {
              _showFriendsList(context);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: Color.fromRGBO(88, 81, 81, 1),
                borderRadius: BorderRadius.circular(40.0),
              ),
              child: Text(
                selectedFriendName,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ),
        actions: [SizedBox(width: 50)],
      ),
      backgroundColor: const Color(0xFF2F2E2E),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 11.0),
        child: StreamBuilder<List<DocumentSnapshot>>(
          stream: _selectedFriendIds.isEmpty
              ? CombineLatestStream.list([
                  FirebaseFirestore.instance
                      .collectionGroup('post_image')
                      .orderBy('timestamp', descending: true)
                      .where('visibleTo', arrayContains: userLogin)
                      .snapshots()
                      .map((snapshot) => snapshot.docs),
                  FirebaseFirestore.instance
                      .collectionGroup('post_image')
                      .orderBy('timestamp', descending: true)
                      .where('userId', isEqualTo: userLogin)
                      .snapshots()
                      .map((snapshot) => snapshot.docs),
                ]).map((list) => list.expand((docs) => docs).toList())
              : FirebaseFirestore.instance
                  .collectionGroup('post_image')
                  .orderBy('timestamp', descending: true)
                  .where('visibleTo', arrayContains: userLogin)
                  .where('userId', whereIn: _selectedFriendIds)
                  .snapshots()
                  .map((snapshot) => snapshot.docs),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return Center(child: CircularProgressIndicator());
              default:
                List<DocumentSnapshot> documents = snapshot.data ?? [];

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8.0,
                    crossAxisSpacing: 8.0,
                  ),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    String imageUrl = documents[index]['imageUrl'];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewPhotoFromAlbum(
                              posts: documents,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      child: AlbumUserCard(
                        imageUrl: imageUrl,
                      ),
                    );
                  },
                );
            }
          },
        ),
      ),
    );
  }

  void _showFriendsList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (BuildContext context) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                  child: Text('Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.white)));
            } else if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                  child: Text('No friends found',
                      style: TextStyle(color: Colors.white)));
            }

            List<dynamic> friends = snapshot.data!['friends'] ?? [];
            List<String> friendIds = friends.cast<String>();

            return ListView(
              padding: EdgeInsets.only(top: 50.0),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                  leading: Icon(Icons.group, color: Colors.white),
                  title: Text('All Friends',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    setState(() {
                      _selectedFriendIds.clear();
                      selectedFriendName = 'All Friends';
                    });
                    Navigator.pop(context);
                  },
                ),
                if (friends.isNotEmpty)
                  ...friendIds.map((friendId) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(friendId)
                          .get(),
                      builder: (context, friendSnapshot) {
                        if (friendSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return ListTile(
                            title: Text('Loading...',
                                style: TextStyle(color: Colors.white)),
                          );
                        } else if (friendSnapshot.hasError) {
                          return ListTile(
                            title: Text('Error: ${friendSnapshot.error}',
                                style: TextStyle(color: Colors.white)),
                          );
                        } else if (!friendSnapshot.hasData ||
                            !friendSnapshot.data!.exists) {
                          return ListTile(
                            title: Text('Friend not found',
                                style: TextStyle(color: Colors.white)),
                          );
                        }

                        String friendName = friendSnapshot.data!['name'];

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(friendSnapshot.data!['image']),
                          ),
                          title: Text(friendName,
                              style: TextStyle(color: Colors.white)),
                          onTap: () {
                            setState(() {
                              _selectedFriendIds = [friendId];
                              selectedFriendName = friendName;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  }).toList(),
              ],
            );
          },
        );
      },
    );
  }
}

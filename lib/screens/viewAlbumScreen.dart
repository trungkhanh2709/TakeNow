import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:takenow/Class/Globals.dart';
import 'package:takenow/widgets/album_user_cart.dart';

class ViewAlbumScreen extends StatefulWidget {
  const ViewAlbumScreen({Key? key}) : super(key: key);

  @override
  State<ViewAlbumScreen> createState() => _ViewAlbumScreenState();
}

class _ViewAlbumScreenState extends State<ViewAlbumScreen> {
  String? userLogin = Globals.getGoogleUserId();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Album'),
      ),
      backgroundColor: const Color(0xFF2F2E2E),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 11.0),
        child: StreamBuilder<List<DocumentSnapshot>>(
          stream: CombineLatestStream.list([
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
          ]).map((list) => list.expand((docs) => docs).toList()),
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

                    return AlbumUserCard(
                      imageUrl: imageUrl,
                    );
                  },
                );
            }
          },
        ),
      ),
    );
  }
}

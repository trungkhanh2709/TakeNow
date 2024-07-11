import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth package
import 'package:takenow/widgets/album_user_cart.dart';
import 'package:takenow/screens/viewPhotoFromAlbum.dart'; // Import your ViewPhotoFromAlbum screen

class ViewAlbumScreen extends StatefulWidget {
  const ViewAlbumScreen({Key? key}) : super(key: key);

  @override
  State<ViewAlbumScreen> createState() => _ViewAlbumScreenState();
}

class _ViewAlbumScreenState extends State<ViewAlbumScreen> {
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser; // Get the current user
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Album'),
      ),
      backgroundColor: const Color(0xFF2F2E2E),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collectionGroup('post_image')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return const Center(child: CircularProgressIndicator());
              default:
                if (!snapshot.hasData || currentUser == null) {
                  return const Center(child: Text('No data available'));
                }

                List<DocumentSnapshot> documents = snapshot.data!.docs.where((document) {
                  List<dynamic> visibleTo = document['visibleTo'];
                  return visibleTo.contains(currentUser!.uid);
                }).toList();

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8.0,
                    crossAxisSpacing: 8.0,
                  ),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    String imageUrl = documents[index]['imageUrl'];
                    String caption = documents[index]['caption'];
                    String userId = documents[index]['userId'];
                    String timestamp = documents[index]['timestamp'];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewPhotoFromAlbum(
                              imageUrl: imageUrl,
                              caption: caption,
                              userId: userId,
                              timestamp: timestamp,
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
}

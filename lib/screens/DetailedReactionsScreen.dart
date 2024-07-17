import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:takenow/models/reaction.dart';

class DetailedReactionsScreen extends StatelessWidget {
  final String postId;

  const DetailedReactionsScreen({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detailed Reactions'),
      ),
      body: FutureBuilder<List<Reaction>>(
        future: _fetchAllReactions(postId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No reactions yet.'));
          } else {
            List<Reaction> reactions = snapshot.data!;
            return ListView.builder(
              itemCount: reactions.length,
              itemBuilder: (context, index) {
                Reaction reaction = reactions[index];
                return ListTile(
                  title: Text(reaction.userId),
                  subtitle: Text(reaction.reactionType),
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<List<Reaction>> _fetchAllReactions(String postId) async {
    final reactionsRef = FirebaseFirestore.instance
        .collection('reactions')
        .doc(postId)
        .collection('user_reactions');

    final snapshot = await reactionsRef.get();
    List<Reaction> reactions = [];

    for (var userDoc in snapshot.docs) {
      final userReactionsRef = userDoc.reference.collection('reactions');
      final userReactionsSnapshot = await userReactionsRef.get();
      for (var reactionDoc in userReactionsSnapshot.docs) {
        reactions.add(Reaction.fromJson(reactionDoc.data()));
      }
    }
    return reactions;
  }
}

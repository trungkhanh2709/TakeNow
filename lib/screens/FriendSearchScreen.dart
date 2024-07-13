import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:takenow/api/apis.dart';
import 'package:takenow/helper/dialogs.dart';

class FriendSearchScreen extends StatefulWidget{
  const FriendSearchScreen({Key? key}) : super(key: key);

  @override
  _FriendSearchScreenState createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen>{
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];

   Future<List<DocumentSnapshot>> _searchFriends (String query) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return result.docs;
  }

  void _sendFriendRequest(String friendId) {
    APIs.addFriend(friendId).then((success) {
      if (success) {
        setState(() {
          // Update friends list in _searchResults (if needed)
          _searchResults.forEach((userDoc) {
            if (userDoc.id == friendId) {
              // Cast userDoc.data() to Map<String, dynamic>
              var userData = userDoc.data() as Map<String, dynamic>?;

              // Check if userData is not null and has 'friends' list
              if (userData != null && userData.containsKey('friends')) {
                var friendsList = List<String>.from(userData['friends']);
                friendsList.add(friendId);

                // Update 'friends' list in userData
                userData['friends'] = friendsList;

                // Update userDoc in _searchResults
                // Note: If _searchResults is based on Firestore snapshots, you'll need to update Firestore too.
                // userDoc.reference.update(userData); // Uncomment if _searchResults is based on Firestore snapshots
              }
            }
          });
        });
        Dialogs.showSnackbar(context, 'Send friend request successfully!');
      } else {
        Dialogs.showSnackbar(context, 'Sending friend request failed.');
      }
    }).catchError((error) {
      Dialogs.showSnackbar(context, 'Error: $error');
    });
  }

  Future<bool> isFriend(String friendId) async {
    String currentUserUid = APIs.user.uid;

    try {
      DocumentSnapshot friendDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .collection('friends')
          .doc(friendId)
          .get();

      bool isFriend = friendDoc.exists;
      print('Friend exists: $isFriend');
      return isFriend;
    } catch (error) {
      print('Error checking friend status: $error');
      return false;
    }
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
            TypeAheadField<DocumentSnapshot>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Enter the email',
                  suffixIcon: Icon(Icons.search),
                ),
              ),
              suggestionsCallback: (pattern) async {
                return await _searchFriends(pattern);
              },
              itemBuilder: (context, suggestion) {
                final user = suggestion.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(user['name']),
                  subtitle: Text(user['email']),
                  trailing: FutureBuilder<bool>(
                    future: isFriend(suggestion.id),
                    builder: (context, AsyncSnapshot<bool> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return const Text('Error');
                      } else {
                        bool isFriend = snapshot.data ?? false;
                        return isFriend
                            ? ElevatedButton(
                            onPressed: () {},
                            child: const Text('Message'),
                        ) : ElevatedButton(
                            onPressed: () => _sendFriendRequest(suggestion.id),
                            child: const Text('Send Request'),
                        );
                      }
                    },
                  )
                );
              },
              onSuggestionSelected: (suggestion) {
                final user = suggestion.data() as Map<String, dynamic>;
                _sendFriendRequest(suggestion.id);
                setState(() {
                  _searchResults = [suggestion];
                });
              },
              noItemsFoundBuilder: (context) => const ListTile(
                title: Text('No user found'),
              ),
            ),
            Expanded(
                child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index){
                      final user = _searchResults[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(user['name']),
                        subtitle: Text(user['email']),
                          trailing: FutureBuilder<bool>(
                            future: isFriend(_searchResults[index].id),
                            builder: (context, AsyncSnapshot<bool> snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return const Text('Error');
                              } else {
                                bool isFriend = snapshot.data ?? false;
                                return isFriend
                                    ? ElevatedButton(
                                      onPressed: () {},
                                      child: const Text('Message'),
                                    ) : ElevatedButton(
                                      onPressed: () => _sendFriendRequest(_searchResults[index].id),
                                      child: const Text('Send Request'),
                                    );
                              }
                            },
                          )
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
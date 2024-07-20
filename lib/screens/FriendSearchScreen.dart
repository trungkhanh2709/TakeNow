import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:takenow/api/apis.dart';
import 'package:takenow/helper/dialogs.dart';

class FriendSearchScreen extends StatefulWidget {
  const FriendSearchScreen({Key? key}) : super(key: key);

  @override
  _FriendSearchScreenState createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  DocumentSnapshot? _selectedUser;
  bool _friendRequestSent = false; // Track if friend request has been sent
  bool _isAlreadyFriend = false;
  Stream<DocumentSnapshot>? _userStream;

  Future<List<DocumentSnapshot>> _searchFriends(String query) async {
    String currentUserUid = APIs.user.uid;

    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThanOrEqualTo: '$query\uf8ff')
        .where(FieldPath.documentId, isNotEqualTo: currentUserUid)
        .get();

    return result.docs;
  }

  void _sendFriendRequest(String friendId) {
    // Call API function to send friend request
    APIs.addFriend(friendId).then((success) {
      if (success) {
        setState(() {
          // Update UI to show "Request Sent"
          _friendRequestSent = true;
        });
        Dialogs.showSnackbar(context, 'Friend request sent successfully!');
        _startListeningToUser(friendId);
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
      // Get the current user's document
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .get();

      // Check if currentUserDoc exists and contains 'friends' field
      if (currentUserDoc.exists) {
        var userData = currentUserDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('friends')) {
          var friendList = List<String>.from(userData['friends']);
          bool isFriend = friendList.contains(friendId);
          return isFriend;
        }
      }
      return false;
    } catch (error) {
      print('Error checking friend status: $error');
      return false;
    }
  }

  void _startListeningToUser(String friendId){
    String currentUserUid = APIs.user.uid;
    _userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .snapshots();

    _userStream!.listen((snapshot) {
      if(snapshot.exists){
        var userData = snapshot.data() as Map<String, dynamic>;
        if (userData.containsKey('friends')) {
          var friendList = List<String>.from(userData['friends']);
          bool isFriendStatus = friendList.contains(friendId);

          setState(() {
            _isAlreadyFriend = isFriendStatus;
            if(isFriendStatus){
              _friendRequestSent = false;
            }
          });

          if(isFriendStatus){
            Dialogs.showSnackbar(context, 'Friend request accepted!');
            _userStream = null;
          }
        }
      }
    });
  }

  void _showUserDetails(DocumentSnapshot userDoc) {
    setState(() {
      _selectedUser = userDoc;
    });

    _focusNode.unfocus();

    isFriend(userDoc.id).then((isFriend) {
      setState(() {
        _isAlreadyFriend = isFriend; // Update friend request status
        _friendRequestSent = false; // Reset request sent status if already friends
      });
    });
  }

  void _searchAndDisplayUser(String query) async {
    List<DocumentSnapshot> results = await _searchFriends(query);
    if (results.isNotEmpty) {
      _showUserDetails(results.first);
    } else {
      _selectedUser = null;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xFF2F2E2E),
      appBar: AppBar(
        title: const Text('Find your friend'),
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
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TypeAheadField<DocumentSnapshot>(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Enter the email',
                        labelStyle: TextStyle(color: Colors.white),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.search, color: Colors.white),
                          onPressed: () {
                            String query = _searchController.text.trim();
                            _searchAndDisplayUser(query);
                          },
                        ),
                      ),
                    ),
                    suggestionsCallback: (pattern) async {
                      if (pattern.isEmpty) {
                        return [];
                      } else {
                        return await _searchFriends(pattern);
                      }
                    },
                    itemBuilder: (context, suggestion) {
                      final user = suggestion.data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(user['name']),
                        subtitle: Text(user['email']),
                        onTap: () => _showUserDetails(suggestion),
                      );
                    },
                    onSuggestionSelected: (suggestion) {
                      _showUserDetails(suggestion);
                    },
                    noItemsFoundBuilder: (context) => const ListTile(
                      title: Text('No user found'),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.04),
            if (_selectedUser != null)
              Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: screenWidth * 0.05,
                      backgroundImage: NetworkImage(
                        (_selectedUser!.data() as Map<String, dynamic>)['image'],
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (_selectedUser!.data() as Map<String, dynamic>)['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.01),
                          Text(
                            (_selectedUser!.data() as Map<String, dynamic>)['email'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Padding(
                      padding: EdgeInsets.only(right: screenWidth * 0.02),
                      child: _isAlreadyFriend
                          ? const Text(
                        'Already Friend',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                        textAlign: TextAlign.right,
                      )
                      : _friendRequestSent
                          ? const Text(
                            'Request Sent',
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                            textAlign: TextAlign.right,
                      )
                          : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          minimumSize: Size(0, 0),
                        ),
                        onPressed: () {
                          _sendFriendRequest(_selectedUser!.id);
                        },
                        child: const Text(
                          'Add Friend',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
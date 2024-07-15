import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:takenow/Class/Globals.dart';

class EditGroupScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String groupImageUrl;

  EditGroupScreen({required this.groupId, required this.groupName, required this.groupImageUrl});

  @override
  _EditGroupScreenState createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  String groupName = '';
  Set<String> groupMembers = {};
  List<Map<String, dynamic>> friendsList = [];
  File? _groupImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    groupName = widget.groupName;
    fetchGroupDetails();
    fetchFriendsList();
  }

  Future<void> fetchGroupDetails() async {
    DocumentSnapshot groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();
    if (groupDoc.exists) {
      List<String> membersIds = List<String>.from(groupDoc['members']);
      setState(() {
        groupMembers = membersIds.toSet();
      });
    }
  }

  Future<void> fetchFriendsList() async {
    String userId = Globals.getGoogleUserId().toString();
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    if (userDoc.exists) {
      List<String> friendsIds = List<String>.from(userDoc['friends']);
      List<Map<String, dynamic>> tempFriendsList = [];
      for (String friendId in friendsIds) {
        DocumentSnapshot friendDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendId)
            .get();
        if (friendDoc.exists) {
          tempFriendsList.add({
            'id': friendDoc.id,
            'name': friendDoc['name'],
            'image': friendDoc['image'],
          });
        }
      }
      setState(() {
        friendsList = tempFriendsList;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _groupImage = File(pickedFile.path);
      });
    }
  }

  Future<void> updateGroup() async {
    if (groupName.isNotEmpty && groupMembers.isNotEmpty) {
      String imageUrl = widget.groupImageUrl;
      if (_groupImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('group_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = storageRef.putFile(_groupImage!);
        final snapshot = await uploadTask.whenComplete(() {});
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
        'nameOfGroup': groupName,
        'members': groupMembers.toList(),
        'image': imageUrl,
      });

      Navigator.pop(context);
    } else {
      // Show an error message if the group name or members are empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a group name and add members.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF2F2E2E),
        title: Text('Edit Group', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon:  SvgPicture.asset(
            'assets/icons/Refund_back_light.svg',
            width: 30,
            height: 30,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      backgroundColor: Color(0xFF2F2E2E),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery),
                child: Stack(
                  children: [
                    Container(
                      height: 210,
                      width: 210,
                      padding: EdgeInsets.all(5), // Padding to create the border
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.purple, width: 5),
                      ),
                      child: ClipOval(
                        child: _groupImage != null
                            ? Image.file(
                          _groupImage!,
                          height: 200,
                          width: 200,
                          fit: BoxFit.cover,
                        )
                            : widget.groupImageUrl.isNotEmpty
                            ? Image.network(
                          widget.groupImageUrl,
                          height: 200,
                          width: 200,
                          fit: BoxFit.cover,
                        )
                            : Center(
                          child: Icon(Icons.image, size: 50, color: Colors.white),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.edit, color: Colors.white),
                          onPressed: () => _pickImage(ImageSource.gallery),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(labelText: 'Group Name', labelStyle: TextStyle(color: Colors.white)),
              style: TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  groupName = value;
                });
              },
              controller: TextEditingController(text: groupName),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: friendsList.length,
                itemBuilder: (context, index) {
                  final friend = friendsList[index];
                  final isSelected = groupMembers.contains(friend['id']);

                  return ListTile(
                    leading: friend['image'].isNotEmpty
                        ? ClipOval(
                      child: Image.network(
                        friend['image'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                        : ClipOval(
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    title: Text(friend['name'], style: TextStyle(color: Colors.white)),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            groupMembers.add(friend['id']);
                          } else {
                            groupMembers.remove(friend['id']);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 50),
                child: TextButton(
                  onPressed: updateGroup,
                  style: TextButton.styleFrom(
                    backgroundColor: Color(0xFF2F2E2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                    child: Text(
                      'Update',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

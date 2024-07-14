import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:takenow/Class/Globals.dart';

class CreateGroupScreen extends StatefulWidget {
  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  String userId = Globals.getGoogleUserId().toString();
  String groupName = '';
  Set<String> groupMembers = {};
  List<Map<String, dynamic>> friendsList = [];
  File? _groupImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchFriendsList();
  }

  Future<void> fetchFriendsList() async {
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

  Future<void> createGroup() async {
    if (groupName.isNotEmpty && groupMembers.isNotEmpty) {
      String imageUrl = '';
      if (_groupImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('group_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = storageRef.putFile(_groupImage!);
        final snapshot = await uploadTask.whenComplete(() => {});
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('groups').add({
        'userId': userId,
        'nameOfGroup': groupName,
        'members': groupMembers.toList(),
        'image': imageUrl,
      });

      Navigator.of(context).pop(); // Close the screen after creating the group
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Group'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: (value) {
                groupName = value;
              },
              decoration: InputDecoration(
                hintText: 'Group Name',
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera),
                  label: Text('Capture Image'),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: Icon(Icons.photo_library),
                  label: Text('Select from Gallery'),
                ),
              ],
            ),
            SizedBox(height: 10),
            if (_groupImage != null)
              Image.file(
                _groupImage!,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: friendsList.length,
                itemBuilder: (context, index) {
                  final friend = friendsList[index];
                  return CheckboxListTile(
                    title: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: friend['image'] != null
                              ? NetworkImage(friend['image'])
                              : null,
                          radius: 20,
                          child: friend['image'] == null
                              ? Icon(Icons.person)
                              : null,
                        ),
                        SizedBox(width: 10),
                        Text(friend['name']),
                      ],
                    ),
                    value: groupMembers.contains(friend['id']),
                    onChanged: (bool? selected) {
                      setState(() {
                        if (selected == true) {
                          groupMembers.add(friend['id']);
                        } else {
                          groupMembers.remove(friend['id']);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: createGroup,
              child: Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }
}
